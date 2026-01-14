package usecases

import (
	"context"
	"errors"
	"fmt"

	"backend/features/competitions/domain/repositories"

	"go.mongodb.org/mongo-driver/bson/primitive"
)

// PauseHeatUseCase handles emergency pause of a heat (blocks all scoring)
type PauseHeatUseCase struct {
	heatRepo repositories.HeatRepository
}

// NewPauseHeatUseCase creates a new PauseHeatUseCase
func NewPauseHeatUseCase(heatRepo repositories.HeatRepository) *PauseHeatUseCase {
	return &PauseHeatUseCase{
		heatRepo: heatRepo,
	}
}

// Execute pauses a heat, blocking all score submissions until resumed
//
// Use Cases:
// - Technical issue (e.g., timing system failure)
// - Athlete injury requiring medical attention
// - Equipment malfunction
// - Dispute/protest that needs resolution
// - Weather conditions (outdoor events)
//
// Business Rules:
// - Can only pause active heats
// - All score submissions are blocked while paused
// - Frontend judges see immediate lock screen
// - Requires explicit reason for audit trail
func (uc *PauseHeatUseCase) Execute(ctx context.Context, heatID string, userID string, reason string) error {
	// Validate inputs
	if reason == "" {
		return errors.New("pause reason is required")
	}

	// Parse heat ID
	heatObjID, err := primitive.ObjectIDFromHex(heatID)
	if err != nil {
		return errors.New("invalid heat ID")
	}

	// Parse user ID
	userObjID, err := primitive.ObjectIDFromHex(userID)
	if err != nil {
		return errors.New("invalid user ID")
	}

	// Get heat
	heat, err := uc.heatRepo.FindByID(ctx, heatObjID)
	if err != nil {
		return errors.New("heat not found")
	}

	// Use domain logic to pause heat
	if err := heat.Pause(userObjID, reason); err != nil {
		return err
	}

	// Update heat in database
	if err := uc.heatRepo.Update(ctx, heat); err != nil {
		return fmt.Errorf("failed to update heat: %w", err)
	}

	// TODO: Send real-time notification to all judges
	// TODO: Log pause action for audit trail
	fmt.Printf("INFO: Heat paused - HeatID: %s, UserID: %s, Reason: %s\n",
		heatID, userID, reason)

	return nil
}

// ResumeHeatUseCase handles resuming a paused heat
type ResumeHeatUseCase struct {
	heatRepo repositories.HeatRepository
}

// NewResumeHeatUseCase creates a new ResumeHeatUseCase
func NewResumeHeatUseCase(heatRepo repositories.HeatRepository) *ResumeHeatUseCase {
	return &ResumeHeatUseCase{
		heatRepo: heatRepo,
	}
}

// Execute resumes a paused heat, allowing score submissions again
//
// Business Rules:
// - Heat must be in paused status
// - Clears pause metadata (pausedBy, pausedAt, pauseReason)
// - Restores heat to active status
// - Frontend judges can submit scores again
func (uc *ResumeHeatUseCase) Execute(ctx context.Context, heatID string) error {
	// Parse heat ID
	heatObjID, err := primitive.ObjectIDFromHex(heatID)
	if err != nil {
		return errors.New("invalid heat ID")
	}

	// Get heat
	heat, err := uc.heatRepo.FindByID(ctx, heatObjID)
	if err != nil {
		return errors.New("heat not found")
	}

	// Use domain logic to resume heat
	if err := heat.Resume(); err != nil {
		return err
	}

	// Update heat in database
	if err := uc.heatRepo.Update(ctx, heat); err != nil {
		return fmt.Errorf("failed to update heat: %w", err)
	}

	// TODO: Send real-time notification to all judges
	// TODO: Log resume action for audit trail
	fmt.Printf("INFO: Heat resumed - HeatID: %s\n", heatID)

	return nil
}
