package repositories

import (
	"context"

	"backend/features/competitions/domain/entities"

	"go.mongodb.org/mongo-driver/bson/primitive"
)

// JudgeInvitationRepository defines the interface for judge invitation data access
type JudgeInvitationRepository interface {
	// Basic CRUD operations
	Save(ctx context.Context, invitation *entities.JudgeInvitation) error
	Update(ctx context.Context, invitation *entities.JudgeInvitation) error
	FindByID(ctx context.Context, id primitive.ObjectID) (*entities.JudgeInvitation, error)
	Delete(ctx context.Context, id primitive.ObjectID) error

	// Query operations
	FindByCompetitionID(ctx context.Context, competitionID primitive.ObjectID, status string, page, limit int) ([]*entities.JudgeInvitation, int64, error)
	FindByUserID(ctx context.Context, userID primitive.ObjectID, status string, page, limit int) ([]*entities.JudgeInvitation, int64, error)
	FindPendingByCompetitionAndUser(ctx context.Context, competitionID, userID primitive.ObjectID) (*entities.JudgeInvitation, error)

	// Bulk operations
	ExpireOldInvitations(ctx context.Context) (int64, error)
}
