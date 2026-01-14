package repositories

import (
	"context"

	"backend/features/competitions/domain/entities"
	"go.mongodb.org/mongo-driver/bson/primitive"
)

// HeatRepository defines operations for managing heats
type HeatRepository interface {
	// Save creates a new heat
	Save(ctx context.Context, heat *entities.Heat) error

	// Update updates an existing heat
	Update(ctx context.Context, heat *entities.Heat) error

	// FindByID retrieves a heat by ID
	FindByID(ctx context.Context, id primitive.ObjectID) (*entities.Heat, error)

	// FindByRoundID retrieves all heats for a specific round
	FindByRoundID(ctx context.Context, roundID primitive.ObjectID) ([]*entities.Heat, error)

	// FindByCategoryAndRound retrieves heats for a specific category and round
	FindByCategoryAndRound(ctx context.Context, categoryID, roundID primitive.ObjectID) ([]*entities.Heat, error)

	// FindByCompetitionID retrieves all heats for a competition
	FindByCompetitionID(ctx context.Context, competitionID primitive.ObjectID) ([]*entities.Heat, error)

	// Delete removes a heat
	Delete(ctx context.Context, id primitive.ObjectID) error

	// DeleteByRoundID removes all heats for a round
	DeleteByRoundID(ctx context.Context, roundID primitive.ObjectID) error
}
