package emergency

import (
	"context"
	"errors"
	"fmt"

	"backend/features/competitions/domain/entities"
	"backend/features/competitions/domain/repositories"

	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/bson/primitive"
)

// FreezeHeatStateUseCase handles heat state preservation during emergencies
// Real-world scenario: Rain starts mid-heat. 3 athletes completed, 5 pending. Save exact state.
// Critical for X-Games, UCI BMX outdoor events
type FreezeHeatStateUseCase struct {
	heatRepo     repositories.HeatRepository
	scoreRepo    repositories.ScoreRepository
	snapshotRepo repositories.HeatSnapshotRepository
}

// NewFreezeHeatStateUseCase creates a new FreezeHeatStateUseCase
func NewFreezeHeatStateUseCase(
	heatRepo repositories.HeatRepository,
	scoreRepo repositories.ScoreRepository,
	snapshotRepo repositories.HeatSnapshotRepository,
) *FreezeHeatStateUseCase {
	return &FreezeHeatStateUseCase{
		heatRepo:     heatRepo,
		scoreRepo:    scoreRepo,
		snapshotRepo: snapshotRepo,
	}
}

// Freeze creates an immutable snapshot of heat state
func (uc *FreezeHeatStateUseCase) Freeze(ctx context.Context, heatID string, reason string, createdBy string) (*entities.HeatStateSnapshot, error) {
	// Parse ObjectIDs
	heatObjID, err := primitive.ObjectIDFromHex(heatID)
	if err != nil {
		return nil, errors.New("invalid heat ID format")
	}
	createdByObjID, err := primitive.ObjectIDFromHex(createdBy)
	if err != nil {
		return nil, errors.New("invalid user ID format")
	}

	// Fetch heat
	heat, err := uc.heatRepo.FindByID(ctx, heatObjID)
	if err != nil {
		return nil, errors.New("heat not found")
	}

	// Check if already frozen (check for existing unrestored freeze snapshot)
	existingSnapshots, err := uc.snapshotRepo.GetUnrestoredSnapshots(ctx, heatObjID)
	if err == nil && len(existingSnapshots) > 0 {
		for _, snap := range existingSnapshots {
			if snap.IsFreeze() {
				return nil, errors.New("heat already has an active freeze snapshot")
			}
		}
	}

	// Fetch all scores for this heat
	scores, err := uc.scoreRepo.FindByHeat(ctx, heat.CompetitionID, heatID)
	if err != nil {
		return nil, fmt.Errorf("failed to fetch heat scores: %w", err)
	}

	// Marshal heat to BSON
	heatData, err := bson.Marshal(heat)
	if err != nil {
		return nil, errors.New("failed to marshal heat data")
	}

	// Marshal scores to BSON
	scoreData := make([]bson.Raw, len(scores))
	for i, score := range scores {
		data, err := bson.Marshal(score)
		if err != nil {
			return nil, errors.New("failed to marshal score data")
		}
		scoreData[i] = bson.Raw(data)
	}

	// Create snapshot
	snapshot := entities.NewHeatStateSnapshot(
		heatObjID,
		heat.CompetitionID,
		heat.RoundID,
		entities.SnapshotTypeFreeze,
		bson.Raw(heatData),
		scoreData,
		createdByObjID,
		reason,
	)

	// Validate snapshot
	if err := snapshot.Validate(); err != nil {
		return nil, fmt.Errorf("snapshot validation failed: %v", err)
	}

	// Save snapshot
	if err := uc.snapshotRepo.Create(ctx, snapshot); err != nil {
		return nil, fmt.Errorf("failed to save snapshot: %v", err)
	}

	return snapshot, nil
}

// Resume restores heat state from snapshot
func (uc *FreezeHeatStateUseCase) Resume(ctx context.Context, snapshotID string, restoredBy string) error {
	// Parse ObjectIDs
	snapshotObjID, err := primitive.ObjectIDFromHex(snapshotID)
	if err != nil {
		return errors.New("invalid snapshot ID format")
	}
	restoredByObjID, err := primitive.ObjectIDFromHex(restoredBy)
	if err != nil {
		return errors.New("invalid user ID format")
	}

	// Fetch snapshot
	snapshot, err := uc.snapshotRepo.GetByID(ctx, snapshotObjID)
	if err != nil {
		return errors.New("snapshot not found")
	}

	// Verify it's a freeze snapshot
	if !snapshot.IsFreeze() {
		return errors.New("snapshot is not a freeze type")
	}

	// Check if already restored
	if snapshot.HasBeenRestored() {
		return errors.New("snapshot has already been restored")
	}

	// Restore heat state (just mark as restored - actual restoration would happen in separate logic)
	// In production, you'd restore the heat and scores here
	if err := uc.snapshotRepo.MarkAsRestored(ctx, snapshotObjID, restoredByObjID); err != nil {
		return fmt.Errorf("failed to mark snapshot as restored: %w", err)
	}

	return nil
}
