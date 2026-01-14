package mongodb

import (
	"context"
	"fmt"

	"backend/features/competitions/domain/entities"
	"backend/features/competitions/domain/repositories"

	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/bson/primitive"
	"go.mongodb.org/mongo-driver/mongo"
	"go.mongodb.org/mongo-driver/mongo/options"
)

const roundsCollection = "rounds"

// roundRepositoryImpl implements repositories.RoundRepository using MongoDB
type roundRepositoryImpl struct {
	collection *mongo.Collection
}

// NewRoundRepository creates a new MongoDB-backed round repository
func NewRoundRepository(db *mongo.Database) repositories.RoundRepository {
	return &roundRepositoryImpl{
		collection: db.Collection(roundsCollection),
	}
}

// Save creates a new round in the database
func (r *roundRepositoryImpl) Save(ctx context.Context, round *entities.Round) error {
	_, err := r.collection.InsertOne(ctx, round)
	if err != nil {
		return fmt.Errorf("failed to save round: %w", err)
	}
	return nil
}

// Update updates an existing round in the database
func (r *roundRepositoryImpl) Update(ctx context.Context, round *entities.Round) error {
	filter := bson.M{"_id": round.ID}
	update := bson.M{"$set": round}

	result, err := r.collection.UpdateOne(ctx, filter, update)
	if err != nil {
		return fmt.Errorf("failed to update round: %w", err)
	}

	if result.MatchedCount == 0 {
		return fmt.Errorf("round not found")
	}

	return nil
}

// FindByID retrieves a round by its ID
func (r *roundRepositoryImpl) FindByID(ctx context.Context, id primitive.ObjectID) (*entities.Round, error) {
	var round entities.Round
	err := r.collection.FindOne(ctx, bson.M{"_id": id}).Decode(&round)
	if err != nil {
		if err == mongo.ErrNoDocuments {
			return nil, fmt.Errorf("round not found")
		}
		return nil, fmt.Errorf("failed to find round: %w", err)
	}
	return &round, nil
}

// FindByCompetitionID retrieves all rounds for a competition, sorted by order
func (r *roundRepositoryImpl) FindByCompetitionID(ctx context.Context, competitionID primitive.ObjectID) ([]*entities.Round, error) {
	opts := options.Find().SetSort(bson.D{{Key: "order", Value: 1}})
	cursor, err := r.collection.Find(ctx, bson.M{"competitionId": competitionID}, opts)
	if err != nil {
		return nil, fmt.Errorf("failed to find rounds: %w", err)
	}
	defer cursor.Close(ctx)

	var rounds []*entities.Round
	if err := cursor.All(ctx, &rounds); err != nil {
		return nil, fmt.Errorf("failed to decode rounds: %w", err)
	}

	return rounds, nil
}

// Delete removes a round from the database
func (r *roundRepositoryImpl) Delete(ctx context.Context, id primitive.ObjectID) error {
	result, err := r.collection.DeleteOne(ctx, bson.M{"_id": id})
	if err != nil {
		return fmt.Errorf("failed to delete round: %w", err)
	}

	if result.DeletedCount == 0 {
		return fmt.Errorf("round not found")
	}

	return nil
}

// DeleteByCompetitionID removes all rounds for a competition
func (r *roundRepositoryImpl) DeleteByCompetitionID(ctx context.Context, competitionID primitive.ObjectID) error {
	_, err := r.collection.DeleteMany(ctx, bson.M{"competitionId": competitionID})
	if err != nil {
		return fmt.Errorf("failed to delete rounds: %w", err)
	}
	return nil
}
