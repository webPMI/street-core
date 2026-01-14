package repositories

import (
	"context"

	"backend/features/competitions/domain/entities"

	"go.mongodb.org/mongo-driver/bson/primitive"
)

// EmergencyAuditRepository defines the interface for emergency audit data access
// Optimized for fast writes during emergency situations
type EmergencyAuditRepository interface {
	// Create creates a new emergency action (optimized for speed)
	Create(ctx context.Context, action *entities.EmergencyAction) error

	// CreateAsync creates an action asynchronously (fire-and-forget for zero latency)
	CreateAsync(action *entities.EmergencyAction) error

	// Update updates an existing emergency action
	Update(ctx context.Context, action *entities.EmergencyAction) error

	// CreateBroadcast creates a new emergency broadcast
	CreateBroadcast(ctx context.Context, broadcast *entities.EmergencyBroadcast) error

	// Query operations
	FindByID(ctx context.Context, id primitive.ObjectID) (*entities.EmergencyAction, error)
	FindByCompetition(ctx context.Context, competitionID primitive.ObjectID, limit int) ([]*entities.EmergencyAction, error)
	FindByHeat(ctx context.Context, heatID primitive.ObjectID, limit int) ([]*entities.EmergencyAction, error)
	FindByActionType(ctx context.Context, competitionID primitive.ObjectID, actionType string, limit int) ([]*entities.EmergencyAction, error)
	FindUnresolved(ctx context.Context, competitionID primitive.ObjectID) ([]*entities.EmergencyAction, error)

	// Broadcast operations
	GetBroadcastByID(ctx context.Context, id primitive.ObjectID) (*entities.EmergencyBroadcast, error)
	GetActiveBroadcasts(ctx context.Context, competitionID primitive.ObjectID) ([]*entities.EmergencyBroadcast, error)
	AcknowledgeBroadcast(ctx context.Context, broadcastID, userID primitive.ObjectID) error
}
