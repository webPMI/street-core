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
)

type scoreRepositoryImpl struct {
	collection *mongo.Collection
}

// NewScoreRepository creates a new MongoDB score repository
func NewScoreRepository(db *mongo.Database) repositories.ScoreRepository {
	return &scoreRepositoryImpl{
		collection: db.Collection("scores"),
	}
}

func (r *scoreRepositoryImpl) Save(ctx context.Context, score *entities.Score) error {
	score.CreatedAt = time.Now()
	score.UpdatedAt = time.Now()

	if err := score.Validate(); err != nil {
		return err
	}

	_, err := r.collection.InsertOne(ctx, score)
	if err != nil {
		return domainerrors.ErrDatabaseOperation
	}

	return nil
}

func (r *scoreRepositoryImpl) Update(ctx context.Context, score *entities.Score) error {
	score.PrepareForUpdate()

	filter := bson.M{"_id": score.ID}
	update := bson.M{"$set": score}

	result, err := r.collection.UpdateOne(ctx, filter, update)
	if err != nil {
		return domainerrors.ErrDatabaseOperation
	}

	if result.MatchedCount == 0 {
		return domainerrors.ErrCompetitionNotFound
	}

	return nil
}

func (r *scoreRepositoryImpl) FindByID(ctx context.Context, id primitive.ObjectID) (*entities.Score, error) {
	var score entities.Score
	err := r.collection.FindOne(ctx, bson.M{"_id": id}).Decode(&score)
	if err != nil {
		if err == mongo.ErrNoDocuments {
			return nil, domainerrors.ErrCompetitionNotFound
		}
		return nil, domainerrors.ErrDatabaseOperation
	}

	return &score, nil
}

func (r *scoreRepositoryImpl) FindByCompetitionID(ctx context.Context, competitionID primitive.ObjectID) ([]*entities.Score, error) {
	filter := bson.M{"competitionId": competitionID}
	cursor, err := r.collection.Find(ctx, filter)
	if err != nil {
		return nil, domainerrors.ErrDatabaseOperation
	}
	defer cursor.Close(ctx)

	var scores []*entities.Score
	if err := cursor.All(ctx, &scores); err != nil {
		return nil, domainerrors.ErrDatabaseOperation
	}

	return scores, nil
}

func (r *scoreRepositoryImpl) FindByCompetitionAndAthlete(ctx context.Context, competitionID, athleteID primitive.ObjectID) ([]*entities.Score, error) {
	filter := bson.M{
		"competitionId": competitionID,
		"athleteId":     athleteID,
	}

	cursor, err := r.collection.Find(ctx, filter)
	if err != nil {
		return nil, domainerrors.ErrDatabaseOperation
	}
	defer cursor.Close(ctx)

	var scores []*entities.Score
	if err := cursor.All(ctx, &scores); err != nil {
		return nil, domainerrors.ErrDatabaseOperation
	}

	return scores, nil
}

func (r *scoreRepositoryImpl) FindByCompetitionAndRound(ctx context.Context, competitionID primitive.ObjectID, roundID string) ([]*entities.Score, error) {
	filter := bson.M{
		"competitionId": competitionID,
		"roundId":       roundID,
	}

	cursor, err := r.collection.Find(ctx, filter)
	if err != nil {
		return nil, domainerrors.ErrDatabaseOperation
	}
	defer cursor.Close(ctx)

	var scores []*entities.Score
	if err := cursor.All(ctx, &scores); err != nil {
		return nil, domainerrors.ErrDatabaseOperation
	}

	return scores, nil
}

func (r *scoreRepositoryImpl) FindByJudgeAndCompetition(ctx context.Context, judgeID, competitionID primitive.ObjectID) ([]*entities.Score, error) {
	filter := bson.M{
		"judgeId":       judgeID,
		"competitionId": competitionID,
	}

	cursor, err := r.collection.Find(ctx, filter)
	if err != nil {
		return nil, domainerrors.ErrDatabaseOperation
	}
	defer cursor.Close(ctx)

	var scores []*entities.Score
	if err := cursor.All(ctx, &scores); err != nil {
		return nil, domainerrors.ErrDatabaseOperation
	}

	return scores, nil
}

func (r *scoreRepositoryImpl) FindExistingScore(ctx context.Context, competitionID, athleteID, judgeID primitive.ObjectID, roundID string) (*entities.Score, error) {
	filter := bson.M{
		"competitionId": competitionID,
		"athleteId":     athleteID,
		"judgeId":       judgeID,
		"roundId":       roundID,
	}

	var score entities.Score
	err := r.collection.FindOne(ctx, filter).Decode(&score)
	if err != nil {
		if err == mongo.ErrNoDocuments {
			return nil, nil // Not found is not an error
		}
		return nil, domainerrors.ErrDatabaseOperation
	}

	return &score, nil
}

func (r *scoreRepositoryImpl) FindByHeat(ctx context.Context, competitionID primitive.ObjectID, heatID string) ([]*entities.Score, error) {
	filter := bson.M{
		"competitionId": competitionID,
		"heatId":        heatID,
	}

	cursor, err := r.collection.Find(ctx, filter)
	if err != nil {
		return nil, domainerrors.ErrDatabaseOperation
	}
	defer cursor.Close(ctx)

	var scores []*entities.Score
	if err := cursor.All(ctx, &scores); err != nil {
		return nil, domainerrors.ErrDatabaseOperation
	}

	return scores, nil
}

func (r *scoreRepositoryImpl) Delete(ctx context.Context, id primitive.ObjectID) error {
	result, err := r.collection.DeleteOne(ctx, bson.M{"_id": id})
	if err != nil {
		return domainerrors.ErrDatabaseOperation
	}

	if result.DeletedCount == 0 {
		return domainerrors.ErrCompetitionNotFound
	}

	return nil
}
