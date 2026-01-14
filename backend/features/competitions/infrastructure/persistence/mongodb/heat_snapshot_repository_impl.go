package mongodb

import (
	"context"
	"time"

	"backend/features/competitions/domain/entities"
	domainerrors "backend/features/competitions/domain/errors"
	"backend/features/competitions/domain/repositories"

	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/bson/primitive"
	"go.mongodb.org/mongo-driver/mongo"
	"go.mongodb.org/mongo-driver/mongo/options"
)

type heatSnapshotRepositoryImpl struct {
	collection *mongo.Collection
}

// NewHeatSnapshotRepository creates a new MongoDB heat snapshot repository
//
// Collection: heat_state_snapshots
//
// Indexes Required:
// 1. {heatId: 1, createdAt: -1}
//    - Purpose: Get latest snapshot for a heat
//    - Used by: GetLatest, GetHistory
//
// 2. {competitionId: 1, createdAt: -1}
//    - Purpose: Competition-wide snapshot queries
//    - Used by: GetByCompetitionID, admin dashboards
//
// 3. {snapshotType: 1, heatId: 1, createdAt: -1}
//    - Purpose: Type-specific lookups (freeze vs rollback)
//    - Used by: GetLatestByType
//
// 4. {heatId: 1, isRestored: 1}
//    - Purpose: Find unrestored snapshots
//    - Used by: GetUnrestoredSnapshots
//
// 5. {createdAt: 1} with TTL 90 days
//    - Purpose: Automatic cleanup of old snapshots
//    - Retention: 90 days (configurable via MongoDB)
//
// To create indexes, run:
//   db.heat_state_snapshots.createIndex({heatId: 1, createdAt: -1})
//   db.heat_state_snapshots.createIndex({competitionId: 1, createdAt: -1})
//   db.heat_state_snapshots.createIndex({snapshotType: 1, heatId: 1, createdAt: -1})
//   db.heat_state_snapshots.createIndex({heatId: 1, isRestored: 1})
//   db.heat_state_snapshots.createIndex({createdAt: 1}, {expireAfterSeconds: 7776000})
func NewHeatSnapshotRepository(db *mongo.Database) repositories.HeatSnapshotRepository {
	return &heatSnapshotRepositoryImpl{
		collection: db.Collection("heat_state_snapshots"),
	}
}

func (r *heatSnapshotRepositoryImpl) Create(ctx context.Context, snapshot *entities.HeatStateSnapshot) error {
	// Validate snapshot before saving
	if err := snapshot.Validate(); err != nil {
		return err
	}

	snapshot.CreatedAt = time.Now()

	_, err := r.collection.InsertOne(ctx, snapshot)
	if err != nil {
		return domainerrors.ErrDatabaseOperation
	}

	return nil
}

func (r *heatSnapshotRepositoryImpl) GetByID(ctx context.Context, id primitive.ObjectID) (*entities.HeatStateSnapshot, error) {
	var snapshot entities.HeatStateSnapshot
	err := r.collection.FindOne(ctx, bson.M{"_id": id}).Decode(&snapshot)
	if err != nil {
		if err == mongo.ErrNoDocuments {
			return nil, domainerrors.ErrCompetitionNotFound
		}
		return nil, domainerrors.ErrDatabaseOperation
	}

	return &snapshot, nil
}

func (r *heatSnapshotRepositoryImpl) GetLatest(ctx context.Context, heatID primitive.ObjectID) (*entities.HeatStateSnapshot, error) {
	filter := bson.M{"heatId": heatID}
	opts := options.FindOne().SetSort(bson.D{{Key: "createdAt", Value: -1}})

	var snapshot entities.HeatStateSnapshot
	err := r.collection.FindOne(ctx, filter, opts).Decode(&snapshot)
	if err != nil {
		if err == mongo.ErrNoDocuments {
			return nil, nil // No snapshot found is not an error
		}
		return nil, domainerrors.ErrDatabaseOperation
	}

	return &snapshot, nil
}

func (r *heatSnapshotRepositoryImpl) GetLatestByType(ctx context.Context, heatID primitive.ObjectID, snapshotType string) (*entities.HeatStateSnapshot, error) {
	filter := bson.M{
		"heatId":       heatID,
		"snapshotType": snapshotType,
	}
	opts := options.FindOne().SetSort(bson.D{{Key: "createdAt", Value: -1}})

	var snapshot entities.HeatStateSnapshot
	err := r.collection.FindOne(ctx, filter, opts).Decode(&snapshot)
	if err != nil {
		if err == mongo.ErrNoDocuments {
			return nil, nil // No snapshot found is not an error
		}
		return nil, domainerrors.ErrDatabaseOperation
	}

	return &snapshot, nil
}

func (r *heatSnapshotRepositoryImpl) GetHistory(ctx context.Context, heatID primitive.ObjectID, limit int) ([]*entities.HeatStateSnapshot, error) {
	filter := bson.M{"heatId": heatID}
	opts := options.Find().SetSort(bson.D{{Key: "createdAt", Value: -1}})

	if limit > 0 {
		opts.SetLimit(int64(limit))
	}

	cursor, err := r.collection.Find(ctx, filter, opts)
	if err != nil {
		return nil, domainerrors.ErrDatabaseOperation
	}
	defer cursor.Close(ctx)

	var snapshots []*entities.HeatStateSnapshot
	if err := cursor.All(ctx, &snapshots); err != nil {
		return nil, domainerrors.ErrDatabaseOperation
	}

	return snapshots, nil
}

func (r *heatSnapshotRepositoryImpl) MarkAsRestored(ctx context.Context, snapshotID primitive.ObjectID, restoredBy primitive.ObjectID) error {
	now := time.Now()
	filter := bson.M{"_id": snapshotID}
	update := bson.M{
		"$set": bson.M{
			"isRestored": true,
			"restoredAt": now,
			"restoredBy": restoredBy,
		},
	}

	result, err := r.collection.UpdateOne(ctx, filter, update)
	if err != nil {
		return domainerrors.ErrDatabaseOperation
	}

	if result.MatchedCount == 0 {
		return domainerrors.ErrCompetitionNotFound
	}

	return nil
}

func (r *heatSnapshotRepositoryImpl) DeleteOlderThan(ctx context.Context, days int) (int64, error) {
	cutoffDate := time.Now().AddDate(0, 0, -days)
	filter := bson.M{
		"createdAt": bson.M{"$lt": cutoffDate},
	}

	result, err := r.collection.DeleteMany(ctx, filter)
	if err != nil {
		return 0, domainerrors.ErrDatabaseOperation
	}

	return result.DeletedCount, nil
}

func (r *heatSnapshotRepositoryImpl) GetByCompetitionID(ctx context.Context, competitionID primitive.ObjectID) ([]*entities.HeatStateSnapshot, error) {
	filter := bson.M{"competitionId": competitionID}
	opts := options.Find().SetSort(bson.D{{Key: "createdAt", Value: -1}})

	cursor, err := r.collection.Find(ctx, filter, opts)
	if err != nil {
		return nil, domainerrors.ErrDatabaseOperation
	}
	defer cursor.Close(ctx)

	var snapshots []*entities.HeatStateSnapshot
	if err := cursor.All(ctx, &snapshots); err != nil {
		return nil, domainerrors.ErrDatabaseOperation
	}

	return snapshots, nil
}

func (r *heatSnapshotRepositoryImpl) CountByHeat(ctx context.Context, heatID primitive.ObjectID) (int64, error) {
	filter := bson.M{"heatId": heatID}

	count, err := r.collection.CountDocuments(ctx, filter)
	if err != nil {
		return 0, domainerrors.ErrDatabaseOperation
	}

	return count, nil
}

func (r *heatSnapshotRepositoryImpl) GetUnrestoredSnapshots(ctx context.Context, heatID primitive.ObjectID) ([]*entities.HeatStateSnapshot, error) {
	filter := bson.M{
		"heatId":     heatID,
		"isRestored": false,
	}
	opts := options.Find().SetSort(bson.D{{Key: "createdAt", Value: -1}})

	cursor, err := r.collection.Find(ctx, filter, opts)
	if err != nil {
		return nil, domainerrors.ErrDatabaseOperation
	}
	defer cursor.Close(ctx)

	var snapshots []*entities.HeatStateSnapshot
	if err := cursor.All(ctx, &snapshots); err != nil {
		return nil, domainerrors.ErrDatabaseOperation
	}

	return snapshots, nil
}
