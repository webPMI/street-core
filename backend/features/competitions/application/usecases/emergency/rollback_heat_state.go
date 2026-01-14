package emergency

import (
	"context"
	"errors"
	"fmt"

	"backend/features/competitions/domain/repositories"

	"go.mongodb.org/mongo-driver/bson/primitive"
)

// RollbackHeatStateUseCase handles undo operations for organizer mistakes
// Real-world scenario: Organizer makes a mistake, needs to undo last action
// Used in X-Games, UCI BMX for critical corrections
type RollbackHeatStateUseCase struct {
	heatRepo     repositories.HeatRepository
	scoreRepo    repositories.ScoreRepository
	snapshotRepo repositories.HeatSnapshotRepository
}

// NewRollbackHeatStateUseCase creates a new RollbackHeatStateUseCase
func NewRollbackHeatStateUseCase(
	heatRepo repositories.HeatRepository,
	scoreRepo repositories.ScoreRepository,
	snapshotRepo repositories.HeatSnapshotRepository,
) *RollbackHeatStateUseCase {
	return &RollbackHeatStateUseCase{
		heatRepo:     heatRepo,
		scoreRepo:    scoreRepo,
		snapshotRepo: snapshotRepo,
	}
}

// Execute rolls back heat to previous state using latest snapshot
func (uc *RollbackHeatStateUseCase) Execute(ctx context.Context, heatID string, rolledBackBy string) error {
	// Parse ObjectIDs
	heatObjID, err := primitive.ObjectIDFromHex(heatID)
	if err != nil {
		return errors.New("invalid heat ID format")
	}
	rolledBackByObjID, err := primitive.ObjectIDFromHex(rolledBackBy)
	if err != nil {
		return errors.New("invalid user ID format")
	}

	// Fetch heat
	_, err = uc.heatRepo.FindByID(ctx, heatObjID)
	if err != nil {
		return errors.New("heat not found")
	}

	// Get latest snapshot for heat
	snapshot, err := uc.snapshotRepo.GetLatest(ctx, heatObjID)
	if err != nil {
		return errors.New("no snapshot history found for this heat")
	}

	// Check if snapshot already restored
	if snapshot.HasBeenRestored() {
		return errors.New("latest snapshot has already been restored")
	}

	// Restore heat state from snapshot
	// In production, you'd unmarshal and restore the heat and scores here
	heat, err := snapshot.GetHeat()
	if err != nil {
		return fmt.Errorf("failed to unmarshal heat from snapshot: %w", err)
	}

	// Update heat with restored state
	if err := uc.heatRepo.Update(ctx, heat); err != nil {
		return fmt.Errorf("failed to restore heat state: %w", err)
	}

	// Restore scores
	scores, err := snapshot.GetScores()
	if err != nil {
		return fmt.Errorf("failed to unmarshal scores from snapshot: %w", err)
	}

	for _, score := range scores {
		if err := uc.scoreRepo.Update(ctx, score); err != nil {
			return fmt.Errorf("failed to restore score: %w", err)
		}
	}

	// Mark snapshot as restored
	if err := uc.snapshotRepo.MarkAsRestored(ctx, snapshot.ID, rolledBackByObjID); err != nil {
		return fmt.Errorf("failed to mark snapshot as restored: %w", err)
	}

	return nil
}
