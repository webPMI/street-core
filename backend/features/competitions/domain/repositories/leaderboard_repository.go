package repositories

import (
	"context"

	"backend/features/competitions/domain/entities"

	"go.mongodb.org/mongo-driver/bson/primitive"
)

// LeaderboardRepository defines the interface for leaderboard persistence
type LeaderboardRepository interface {
	// Save creates a new leaderboard
	Save(ctx context.Context, leaderboard *entities.Leaderboard) error

	// Update updates an existing leaderboard
	Update(ctx context.Context, leaderboard *entities.Leaderboard) error

	// FindByID retrieves a leaderboard by ID
	FindByID(ctx context.Context, id primitive.ObjectID) (*entities.Leaderboard, error)

	// FindByCompetitionID retrieves the leaderboard for a competition
	FindByCompetitionID(ctx context.Context, competitionID primitive.ObjectID) (*entities.Leaderboard, error)

	// Delete deletes a leaderboard
	Delete(ctx context.Context, id primitive.ObjectID) error
}
