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

type heatRepositoryImpl struct {
	collection *mongo.Collection
}

// NewHeatRepository creates a new MongoDB heat repository
func NewHeatRepository(db *mongo.Database) repositories.HeatRepository {
	return &heatRepositoryImpl{
		collection: db.Collection("heats"),
	}
}

func (r *heatRepositoryImpl) Save(ctx context.Context, heat *entities.Heat) error {
	heat.CreatedAt = time.Now()
	heat.UpdatedAt = time.Now()

	_, err := r.collection.InsertOne(ctx, heat)
	if err != nil {
		return domainerrors.ErrDatabaseOperation
	}

	return nil
}

func (r *heatRepositoryImpl) Update(ctx context.Context, heat *entities.Heat) error {
	heat.UpdatedAt = time.Now()

	filter := bson.M{"_id": heat.ID}
	update := bson.M{"$set": heat}

	result, err := r.collection.UpdateOne(ctx, filter, update)
	if err != nil {
		return domainerrors.ErrDatabaseOperation
	}

	if result.MatchedCount == 0 {
		return domainerrors.ErrCompetitionNotFound
	}

	return nil
}

func (r *heatRepositoryImpl) FindByID(ctx context.Context, id primitive.ObjectID) (*entities.Heat, error) {
	var heat entities.Heat
	err := r.collection.FindOne(ctx, bson.M{"_id": id}).Decode(&heat)
	if err != nil {
		if err == mongo.ErrNoDocuments {
			return nil, domainerrors.ErrCompetitionNotFound
		}
		return nil, domainerrors.ErrDatabaseOperation
	}

	return &heat, nil
}

func (r *heatRepositoryImpl) FindByRoundID(ctx context.Context, roundID primitive.ObjectID) ([]*entities.Heat, error) {
	filter := bson.M{"roundId": roundID}
	opts := options.Find().SetSort(bson.D{{Key: "order", Value: 1}}) // Sort by order ascending

	cursor, err := r.collection.Find(ctx, filter, opts)
	if err != nil {
		return nil, domainerrors.ErrDatabaseOperation
	}
	defer cursor.Close(ctx)

	var heats []*entities.Heat
	if err := cursor.All(ctx, &heats); err != nil {
		return nil, domainerrors.ErrDatabaseOperation
	}

	return heats, nil
}

func (r *heatRepositoryImpl) FindByCategoryAndRound(ctx context.Context, categoryID, roundID primitive.ObjectID) ([]*entities.Heat, error) {
	filter := bson.M{
		"categoryId": categoryID,
		"roundId":    roundID,
	}
	opts := options.Find().SetSort(bson.D{{Key: "order", Value: 1}})

	cursor, err := r.collection.Find(ctx, filter, opts)
	if err != nil {
		return nil, domainerrors.ErrDatabaseOperation
	}
	defer cursor.Close(ctx)

	var heats []*entities.Heat
	if err := cursor.All(ctx, &heats); err != nil {
		return nil, domainerrors.ErrDatabaseOperation
	}

	return heats, nil
}

func (r *heatRepositoryImpl) FindByCompetitionID(ctx context.Context, competitionID primitive.ObjectID) ([]*entities.Heat, error) {
	filter := bson.M{"competitionId": competitionID}
	opts := options.Find().SetSort(bson.D{{Key: "order", Value: 1}})

	cursor, err := r.collection.Find(ctx, filter, opts)
	if err != nil {
		return nil, domainerrors.ErrDatabaseOperation
	}
	defer cursor.Close(ctx)

	var heats []*entities.Heat
	if err := cursor.All(ctx, &heats); err != nil {
		return nil, domainerrors.ErrDatabaseOperation
	}

	return heats, nil
}

func (r *heatRepositoryImpl) Delete(ctx context.Context, id primitive.ObjectID) error {
	filter := bson.M{"_id": id}

	result, err := r.collection.DeleteOne(ctx, filter)
	if err != nil {
		return domainerrors.ErrDatabaseOperation
	}

	if result.DeletedCount == 0 {
		return domainerrors.ErrCompetitionNotFound
	}

	return nil
}

func (r *heatRepositoryImpl) DeleteByRoundID(ctx context.Context, roundID primitive.ObjectID) error {
	filter := bson.M{"roundId": roundID}

	_, err := r.collection.DeleteMany(ctx, filter)
	if err != nil {
		return domainerrors.ErrDatabaseOperation
	}

	return nil
}
