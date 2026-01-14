package usecases

import (
	"context"
	"errors"
	"fmt"

	"backend/features/competitions/domain/entities"
	"backend/features/competitions/domain/repositories"

	"go.mongodb.org/mongo-driver/bson/primitive"
)

// BypassJudgeRequirementUseCase handles bypassing minimum judge requirement
// Use case: Only 2 of 3 judges showed up, organizer decides to proceed with reduced panel
type BypassJudgeRequirementUseCase struct {
	heatRepo repositories.HeatRepository
}

// NewBypassJudgeRequirementUseCase creates a new BypassJudgeRequirementUseCase
func NewBypassJudgeRequirementUseCase(heatRepo repositories.HeatRepository) *BypassJudgeRequirementUseCase {
	return &BypassJudgeRequirementUseCase{
		heatRepo: heatRepo,
	}
}

// Execute bypasses the minimum judge requirement by updating MinJudgesActive
// This allows the heat to start/continue with fewer judges than originally configured
//
// Parameters:
// - heatID: The heat to modify
// - newMinJudges: The new minimum number of judges required (must be > 0)
// - bypassReason: Reason for bypassing (for audit trail)
//
// Business Rules:
// - Cannot reduce to 0 (must have at least 1 judge)
// - Can only bypass if check-in is enabled
// - NewMinJudges must be <= current number of checked-in judges
func (uc *BypassJudgeRequirementUseCase) Execute(ctx context.Context, heatID string, newMinJudges int, bypassReason string) error {
	// Validate inputs
	if newMinJudges <= 0 {
		return errors.New("minimum judges must be at least 1")
	}

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

	// Verify check-in is enabled
	if !heat.CheckInEnabled {
		return errors.New("cannot bypass judge requirement when check-in is not enabled")
	}

	// Verify heat has judge role in required roles
	hasJudgeRole := false
	for _, role := range heat.RequiredRoles {
		if role == entities.HeatRoleJudge {
			hasJudgeRole = true
			break
		}
	}

	if !hasJudgeRole {
		return errors.New("heat does not have judge role configured")
	}

	// Get current number of checked-in judges
	checkedInJudges := heat.GetCheckedInCount(entities.HeatRoleJudge)

	// Validate new minimum doesn't exceed checked-in count
	if newMinJudges > checkedInJudges {
		return fmt.Errorf("cannot set minimum to %d when only %d judges are checked in", newMinJudges, checkedInJudges)
	}

	// Update minimum judges
	heat.MinJudgesActive = newMinJudges
	heat.UpdatedAt = heat.UpdatedAt // Trigger update timestamp via entity method would be better

	// Update heat in database
	if err := uc.heatRepo.Update(ctx, heat); err != nil {
		return fmt.Errorf("failed to update heat: %w", err)
	}

	// TODO: Log bypass action for audit trail
	fmt.Printf("INFO: Judge requirement bypassed for heat %s. New minimum: %d. Reason: %s\n",
		heatID, newMinJudges, bypassReason)

	return nil
}
