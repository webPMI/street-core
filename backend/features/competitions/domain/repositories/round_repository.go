package repositories

import (
	"context"

	"backend/features/competitions/domain/entities"

	"go.mongodb.org/mongo-driver/bson/primitive"
)

// RoundRepository defines the interface for round persistence operations
type RoundRepository interface {
	// Save creates a new round
	Save(ctx context.Context, round *entities.Round) error

	// Update updates an existing round
	Update(ctx context.Context, round *entities.Round) error

	// FindByID retrieves a round by its ID
	FindByID(ctx context.Context, id primitive.ObjectID) (*entities.Round, error)

	// FindByCompetitionID retrieves all rounds for a competition
	FindByCompetitionID(ctx context.Context, competitionID primitive.ObjectID) ([]*entities.Round, error)

	// Delete removes a round
	Delete(ctx context.Context, id primitive.ObjectID) error

	// DeleteByCompetitionID removes all rounds for a competition
	DeleteByCompetitionID(ctx context.Context, competitionID primitive.ObjectID) error
}
