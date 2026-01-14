package usecases

import (
	"context"
	"errors"
	"fmt"

	"backend/features/competitions/domain/repositories"

	"go.mongodb.org/mongo-driver/bson/primitive"
)

// CheckInToHeatUseCase handles check-in operations for heat roles
type CheckInToHeatUseCase struct {
	heatRepo repositories.HeatRepository
}

// NewCheckInToHeatUseCase creates a new CheckInToHeatUseCase
func NewCheckInToHeatUseCase(heatRepo repositories.HeatRepository) *CheckInToHeatUseCase {
	return &CheckInToHeatUseCase{
		heatRepo: heatRepo,
	}
}

// AssignRole assigns a user to a role (judge, speaker, marshall) for a heat
func (uc *CheckInToHeatUseCase) AssignRole(ctx context.Context, heatID string, role string, userID string) error {
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

	// Assign role using domain logic
	if err := heat.AssignRole(role, userID); err != nil {
		return err // Return domain error directly
	}

	// Update heat in database
	if err := uc.heatRepo.Update(ctx, heat); err != nil {
		return fmt.Errorf("failed to update heat: %w", err)
	}

	return nil
}

// CheckIn marks a user as checked-in for their assigned role
func (uc *CheckInToHeatUseCase) CheckIn(ctx context.Context, heatID string, role string, userID string) error {
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

	// Check in using domain logic
	if err := heat.CheckIn(role, userID); err != nil {
		return err // Return domain error directly
	}

	// Update heat in database
	if err := uc.heatRepo.Update(ctx, heat); err != nil {
		return fmt.Errorf("failed to update heat: %w", err)
	}

	return nil
}

// CheckOut marks a user as checked-out (used for role replacement)
func (uc *CheckInToHeatUseCase) CheckOut(ctx context.Context, heatID string, role string, userID string) error {
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

	// Check out using domain logic
	if err := heat.CheckOut(role, userID); err != nil {
		return err // Return domain error directly
	}

	// Update heat in database
	if err := uc.heatRepo.Update(ctx, heat); err != nil {
		return fmt.Errorf("failed to update heat: %w", err)
	}

	return nil
}

// UnassignRole removes a user from a role
func (uc *CheckInToHeatUseCase) UnassignRole(ctx context.Context, heatID string, role string, userID string) error {
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

	// Unassign role using domain logic
	if err := heat.UnassignRole(role, userID); err != nil {
		return err // Return domain error directly
	}

	// Update heat in database
	if err := uc.heatRepo.Update(ctx, heat); err != nil {
		return fmt.Errorf("failed to update heat: %w", err)
	}

	return nil
}
