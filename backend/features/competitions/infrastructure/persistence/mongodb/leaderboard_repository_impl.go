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

type leaderboardRepositoryImpl struct {
	collection *mongo.Collection
}

// NewLeaderboardRepository creates a new MongoDB leaderboard repository
func NewLeaderboardRepository(db *mongo.Database) repositories.LeaderboardRepository {
	return &leaderboardRepositoryImpl{
		collection: db.Collection("leaderboards"),
	}
}

func (r *leaderboardRepositoryImpl) Save(ctx context.Context, leaderboard *entities.Leaderboard) error {
	leaderboard.CreatedAt = time.Now()
	leaderboard.UpdatedAt = time.Now()

	_, err := r.collection.InsertOne(ctx, leaderboard)
	if err != nil {
		return domainerrors.ErrDatabaseOperation
	}

	return nil
}

func (r *leaderboardRepositoryImpl) Update(ctx context.Context, leaderboard *entities.Leaderboard) error {
	leaderboard.PrepareForUpdate()

	filter := bson.M{"_id": leaderboard.ID}
	update := bson.M{"$set": leaderboard}

	result, err := r.collection.UpdateOne(ctx, filter, update)
	if err != nil {
		return domainerrors.ErrDatabaseOperation
	}

	if result.MatchedCount == 0 {
		return domainerrors.ErrLeaderboardNotFound
	}

	return nil
}

func (r *leaderboardRepositoryImpl) FindByID(ctx context.Context, id primitive.ObjectID) (*entities.Leaderboard, error) {
	var leaderboard entities.Leaderboard
	err := r.collection.FindOne(ctx, bson.M{"_id": id}).Decode(&leaderboard)
	if err != nil {
		if err == mongo.ErrNoDocuments {
			return nil, domainerrors.ErrLeaderboardNotFound
		}
		return nil, domainerrors.ErrDatabaseOperation
	}

	return &leaderboard, nil
}

func (r *leaderboardRepositoryImpl) FindByCompetitionID(ctx context.Context, competitionID primitive.ObjectID) (*entities.Leaderboard, error) {
	var leaderboard entities.Leaderboard
	err := r.collection.FindOne(ctx, bson.M{"competitionId": competitionID}).Decode(&leaderboard)
	if err != nil {
		if err == mongo.ErrNoDocuments {
			return nil, nil // Return nil if leaderboard doesn't exist yet
		}
		return nil, domainerrors.ErrDatabaseOperation
	}

	return &leaderboard, nil
}

func (r *leaderboardRepositoryImpl) Delete(ctx context.Context, id primitive.ObjectID) error {
	result, err := r.collection.DeleteOne(ctx, bson.M{"_id": id})
	if err != nil {
		return domainerrors.ErrDatabaseOperation
	}

	if result.DeletedCount == 0 {
		return domainerrors.ErrLeaderboardNotFound
	}

	return nil
}
