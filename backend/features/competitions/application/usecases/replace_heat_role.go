package usecases

import (
	"context"
	"errors"
	"fmt"

	"backend/features/competitions/domain/repositories"

	"go.mongodb.org/mongo-driver/bson/primitive"
)

// ReplaceHeatRoleUseCase handles replacing a user in a heat role (contingency management)
// Example: Judge gets sick and needs to be replaced mid-competition
type ReplaceHeatRoleUseCase struct {
	heatRepo repositories.HeatRepository
}

// NewReplaceHeatRoleUseCase creates a new ReplaceHeatRoleUseCase
func NewReplaceHeatRoleUseCase(heatRepo repositories.HeatRepository) *ReplaceHeatRoleUseCase {
	return &ReplaceHeatRoleUseCase{
		heatRepo: heatRepo,
	}
}

// Execute replaces a user in a role with another user
// This is an atomic operation that:
// 1. Unassigns the old user (and checks them out if they were checked in)
// 2. Assigns the new user
// If any step fails, the operation is rolled back
func (uc *ReplaceHeatRoleUseCase) Execute(ctx context.Context, heatID string, role string, oldUserID string, newUserID string) error {
	// Validate inputs
	if oldUserID == newUserID {
		return errors.New("old and new user cannot be the same")
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
		return errors.New("check-in not enabled for this heat")
	}

	// Verify old user is assigned to this role
	if !heat.IsRoleAssigned(role, oldUserID) {
		return fmt.Errorf("user %s is not assigned to role %s", oldUserID, role)
	}

	// Use domain method to replace role atomically
	if err := heat.ReplaceRole(role, oldUserID, newUserID); err != nil {
		return err
	}

	// Update heat in database
	if err := uc.heatRepo.Update(ctx, heat); err != nil {
		return fmt.Errorf("failed to update heat: %w", err)
	}

	return nil
}
