package repositories

import (
	"context"

	"backend/features/competitions/domain/entities"
	"go.mongodb.org/mongo-driver/bson/primitive"
)

// HeatSnapshotRepository defines operations for managing heat state snapshots
// Used for freeze/rollback functionality to handle real-world crisis scenarios
type HeatSnapshotRepository interface {
	// Create creates a new heat state snapshot
	Create(ctx context.Context, snapshot *entities.HeatStateSnapshot) error

	// GetByID retrieves a snapshot by its ID
	GetByID(ctx context.Context, id primitive.ObjectID) (*entities.HeatStateSnapshot, error)

	// GetLatest retrieves the most recent snapshot for a heat (any type)
	GetLatest(ctx context.Context, heatID primitive.ObjectID) (*entities.HeatStateSnapshot, error)

	// GetLatestByType retrieves the most recent snapshot of a specific type for a heat
	// snapshotType: "freeze" or "rollback"
	GetLatestByType(ctx context.Context, heatID primitive.ObjectID, snapshotType string) (*entities.HeatStateSnapshot, error)

	// GetHistory retrieves snapshot history for a heat, ordered by creation time (newest first)
	// limit: maximum number of snapshots to return (0 = no limit)
	GetHistory(ctx context.Context, heatID primitive.ObjectID, limit int) ([]*entities.HeatStateSnapshot, error)

	// MarkAsRestored marks a snapshot as restored
	MarkAsRestored(ctx context.Context, snapshotID primitive.ObjectID, restoredBy primitive.ObjectID) error

	// DeleteOlderThan deletes snapshots older than specified days (for cleanup)
	// Returns number of deleted snapshots
	DeleteOlderThan(ctx context.Context, days int) (int64, error)

	// GetByCompetitionID retrieves all snapshots for a competition
	GetByCompetitionID(ctx context.Context, competitionID primitive.ObjectID) ([]*entities.HeatStateSnapshot, error)

	// CountByHeat returns the number of snapshots for a heat
	CountByHeat(ctx context.Context, heatID primitive.ObjectID) (int64, error)

	// GetUnrestoredSnapshots retrieves all snapshots that haven't been restored yet
	GetUnrestoredSnapshots(ctx context.Context, heatID primitive.ObjectID) ([]*entities.HeatStateSnapshot, error)
}
