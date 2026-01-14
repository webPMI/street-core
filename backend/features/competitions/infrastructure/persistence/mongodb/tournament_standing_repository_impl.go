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

// TournamentStandingRepositoryImpl implements the TournamentStandingRepository interface
type TournamentStandingRepositoryImpl struct {
	collection *mongo.Collection
}

// NewTournamentStandingRepository creates a new tournament standing repository
func NewTournamentStandingRepository(db *mongo.Database) repositories.TournamentStandingRepository {
	return &TournamentStandingRepositoryImpl{
		collection: db.Collection("tournament_standings"),
	}
}

// Save creates a new standing
func (r *TournamentStandingRepositoryImpl) Save(ctx context.Context, standing *entities.TournamentStanding) error {
	_, err := r.collection.InsertOne(ctx, standing)
	if err != nil {
		if mongo.IsDuplicateKeyError(err) {
			return domainerrors.ErrDuplicateEntry
		}
		return domainerrors.ErrDatabaseOperation
	}
	return nil
}

// Update updates an existing standing
func (r *TournamentStandingRepositoryImpl) Update(ctx context.Context, standing *entities.TournamentStanding) error {
	standing.PrepareForUpdate()

	filter := bson.M{"_id": standing.ID}
	update := bson.M{"$set": standing}

	result, err := r.collection.UpdateOne(ctx, filter, update)
	if err != nil {
		return domainerrors.ErrDatabaseOperation
	}

	if result.MatchedCount == 0 {
		return domainerrors.ErrCompetitionNotFound
	}

	return nil
}

// FindByID finds a standing by ID
func (r *TournamentStandingRepositoryImpl) FindByID(ctx context.Context, id primitive.ObjectID) (*entities.TournamentStanding, error) {
	var standing entities.TournamentStanding
	filter := bson.M{"_id": id}

	err := r.collection.FindOne(ctx, filter).Decode(&standing)
	if err != nil {
		if err == mongo.ErrNoDocuments {
			return nil, domainerrors.ErrCompetitionNotFound
		}
		return nil, domainerrors.ErrDatabaseOperation
	}

	return &standing, nil
}

// Delete deletes a standing
func (r *TournamentStandingRepositoryImpl) Delete(ctx context.Context, id primitive.ObjectID) error {
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

// FindByTournamentID finds all standings for a tournament
func (r *TournamentStandingRepositoryImpl) FindByTournamentID(ctx context.Context, tournamentID primitive.ObjectID) ([]*entities.TournamentStanding, error) {
	filter := bson.M{"tournamentId": tournamentID}

	cursor, err := r.collection.Find(ctx, filter)
	if err != nil {
		return nil, domainerrors.ErrDatabaseOperation
	}
	defer cursor.Close(ctx)

	var standings []*entities.TournamentStanding
	if err := cursor.All(ctx, &standings); err != nil {
		return nil, domainerrors.ErrDatabaseOperation
	}

	return standings, nil
}

// FindByTournamentIDSorted finds all standings for a tournament sorted by position
func (r *TournamentStandingRepositoryImpl) FindByTournamentIDSorted(ctx context.Context, tournamentID primitive.ObjectID) ([]*entities.TournamentStanding, error) {
	filter := bson.M{"tournamentId": tournamentID}
	findOptions := options.Find().SetSort(bson.M{"position": 1})

	cursor, err := r.collection.Find(ctx, filter, findOptions)
	if err != nil {
		return nil, domainerrors.ErrDatabaseOperation
	}
	defer cursor.Close(ctx)

	var standings []*entities.TournamentStanding
	if err := cursor.All(ctx, &standings); err != nil {
		return nil, domainerrors.ErrDatabaseOperation
	}

	return standings, nil
}

// FindByTournamentAndAthleteID finds a specific standing
func (r *TournamentStandingRepositoryImpl) FindByTournamentAndAthleteID(ctx context.Context, tournamentID, athleteID primitive.ObjectID) (*entities.TournamentStanding, error) {
	var standing entities.TournamentStanding
	filter := bson.M{
		"tournamentId": tournamentID,
		"athleteId":    athleteID,
	}

	err := r.collection.FindOne(ctx, filter).Decode(&standing)
	if err != nil {
		if err == mongo.ErrNoDocuments {
			return nil, domainerrors.ErrCompetitionNotFound
		}
		return nil, domainerrors.ErrDatabaseOperation
	}

	return &standing, nil
}

// FindByAthleteID finds all standings for an athlete
func (r *TournamentStandingRepositoryImpl) FindByAthleteID(ctx context.Context, athleteID primitive.ObjectID) ([]*entities.TournamentStanding, error) {
	filter := bson.M{"athleteId": athleteID}

	cursor, err := r.collection.Find(ctx, filter)
	if err != nil {
		return nil, domainerrors.ErrDatabaseOperation
	}
	defer cursor.Close(ctx)

	var standings []*entities.TournamentStanding
	if err := cursor.All(ctx, &standings); err != nil {
		return nil, domainerrors.ErrDatabaseOperation
	}

	return standings, nil
}

// SaveMany creates multiple standings
func (r *TournamentStandingRepositoryImpl) SaveMany(ctx context.Context, standings []*entities.TournamentStanding) error {
	docs := make([]interface{}, len(standings))
	for i, standing := range standings {
		docs[i] = standing
	}

	_, err := r.collection.InsertMany(ctx, docs)
	if err != nil {
		return domainerrors.ErrDatabaseOperation
	}

	return nil
}

// UpdateMany updates multiple standings
func (r *TournamentStandingRepositoryImpl) UpdateMany(ctx context.Context, standings []*entities.TournamentStanding) error {
	// Use bulk write for efficiency
	var writes []mongo.WriteModel

	for _, standing := range standings {
		standing.PrepareForUpdate()
		filter := bson.M{"_id": standing.ID}
		update := bson.M{"$set": standing}
		writes = append(writes, mongo.NewUpdateOneModel().SetFilter(filter).SetUpdate(update))
	}

	if len(writes) == 0 {
		return nil
	}

	_, err := r.collection.BulkWrite(ctx, writes)
	if err != nil {
		return domainerrors.ErrDatabaseOperation
	}

	return nil
}

// AddResult adds a competition result to a standing
func (r *TournamentStandingRepositoryImpl) AddResult(ctx context.Context, standingID primitive.ObjectID, result entities.CompetitionResult) error {
	filter := bson.M{"_id": standingID}
	update := bson.M{
		"$push": bson.M{"results": result},
		"$inc":  bson.M{"competitionsEntered": 1},
		"$set":  bson.M{"updatedAt": time.Now()},
	}

	res, err := r.collection.UpdateOne(ctx, filter, update)
	if err != nil {
		return domainerrors.ErrDatabaseOperation
	}

	if res.MatchedCount == 0 {
		return domainerrors.ErrCompetitionNotFound
	}

	return nil
}

// RecalculateStandings recalculates all standings for a tournament
func (r *TournamentStandingRepositoryImpl) RecalculateStandings(ctx context.Context, tournamentID primitive.ObjectID, scoringConfig entities.TournamentScoringConfig) error {
	// Get all standings
	standings, err := r.FindByTournamentIDSorted(ctx, tournamentID)
	if err != nil {
		return err
	}

	// Recalculate each standing
	for _, standing := range standings {
		standing.RecalculateStanding()
	}

	// Sort by counted points (descending)
	// Simple bubble sort for now
	for i := 0; i < len(standings)-1; i++ {
		for j := i + 1; j < len(standings); j++ {
			if standings[i].CountedPoints < standings[j].CountedPoints {
				standings[i], standings[j] = standings[j], standings[i]
			}
		}
	}

	// Update positions
	for i, standing := range standings {
		standing.UpdatePosition(i + 1)
	}

	// Save all standings
	return r.UpdateMany(ctx, standings)
}

// GetTopStandings gets the top N standings
func (r *TournamentStandingRepositoryImpl) GetTopStandings(ctx context.Context, tournamentID primitive.ObjectID, limit int) ([]*entities.TournamentStanding, error) {
	filter := bson.M{"tournamentId": tournamentID}
	findOptions := options.Find().
		SetSort(bson.M{"position": 1}).
		SetLimit(int64(limit))

	cursor, err := r.collection.Find(ctx, filter, findOptions)
	if err != nil {
		return nil, domainerrors.ErrDatabaseOperation
	}
	defer cursor.Close(ctx)

	var standings []*entities.TournamentStanding
	if err := cursor.All(ctx, &standings); err != nil {
		return nil, domainerrors.ErrDatabaseOperation
	}

	return standings, nil
}

// GetQualifiedAthletes gets all qualified athletes
func (r *TournamentStandingRepositoryImpl) GetQualifiedAthletes(ctx context.Context, tournamentID primitive.ObjectID) ([]*entities.TournamentStanding, error) {
	filter := bson.M{
		"tournamentId": tournamentID,
		"isQualified":  true,
	}
	findOptions := options.Find().SetSort(bson.M{"position": 1})

	cursor, err := r.collection.Find(ctx, filter, findOptions)
	if err != nil {
		return nil, domainerrors.ErrDatabaseOperation
	}
	defer cursor.Close(ctx)

	var standings []*entities.TournamentStanding
	if err := cursor.All(ctx, &standings); err != nil {
		return nil, domainerrors.ErrDatabaseOperation
	}

	return standings, nil
}
