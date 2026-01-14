package repositories

import (
	"context"

	"backend/features/competitions/domain/entities"

	"go.mongodb.org/mongo-driver/bson/primitive"
)

// CategoryRepository defines the interface for category data access
type CategoryRepository interface {
	// Basic CRUD operations
	Save(ctx context.Context, category *entities.Category) error
	Update(ctx context.Context, category *entities.Category) error
	FindByID(ctx context.Context, id primitive.ObjectID) (*entities.Category, error)
	FindByCompetitionID(ctx context.Context, competitionID primitive.ObjectID, page, limit int) ([]*entities.Category, int64, error)
	Delete(ctx context.Context, id primitive.ObjectID) error

	// Participant operations
	AddParticipant(ctx context.Context, categoryID, participantID primitive.ObjectID) error
	RemoveParticipant(ctx context.Context, categoryID, participantID primitive.ObjectID) error
	IsParticipant(ctx context.Context, categoryID, participantID primitive.ObjectID) (bool, error)

	// Judge operations
	AddJudge(ctx context.Context, categoryID, judgeID primitive.ObjectID) error
	RemoveJudge(ctx context.Context, categoryID, judgeID primitive.ObjectID) error
	IsJudge(ctx context.Context, categoryID, judgeID primitive.ObjectID) (bool, error)
}
