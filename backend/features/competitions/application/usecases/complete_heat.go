package usecases

import (
	"context"
	"errors"
	"fmt"

	"backend/features/competitions/domain/repositories"

	"go.mongodb.org/mongo-driver/bson/primitive"
)

// CompleteHeatUseCase handles completing a heat and auto-advancing CurrentHeat
type CompleteHeatUseCase struct {
	heatRepo  repositories.HeatRepository
	roundRepo repositories.RoundRepository
}

// NewCompleteHeatUseCase creates a new CompleteHeatUseCase
func NewCompleteHeatUseCase(
	heatRepo repositories.HeatRepository,
	roundRepo repositories.RoundRepository,
) *CompleteHeatUseCase {
	return &CompleteHeatUseCase{
		heatRepo:  heatRepo,
		roundRepo: roundRepo,
	}
}

// Execute completes a heat and auto-advances Round.CurrentHeat
// This allows frontend to detect the change easily via Round polling/refresh
func (uc *CompleteHeatUseCase) Execute(ctx context.Context, heatID string) error {
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

	// Complete the heat
	if err := heat.Complete(); err != nil {
		return fmt.Errorf("cannot complete heat: %w", err)
	}

	// Update heat in database
	if err := uc.heatRepo.Update(ctx, heat); err != nil {
		return fmt.Errorf("failed to update heat: %w", err)
	}

	// Get round to update CurrentHeat
	round, err := uc.roundRepo.FindByID(ctx, heat.RoundID)
	if err != nil {
		// Heat was completed but round update failed - log warning
		fmt.Printf("Warning: Failed to get round for heat %s: %v\n", heatID, err)
		return nil // Don't fail the entire operation
	}

	// Find index of this heat in round's HeatIDs
	heatIndex := -1
	for i, id := range round.HeatIDs {
		if id == heat.ID.Hex() {
			heatIndex = i
			break
		}
	}

	if heatIndex == -1 {
		fmt.Printf("Warning: Heat %s not found in round heat list\n", heatID)
		return nil
	}

	// Auto-advance to next heat if not at the end
	if heatIndex < len(round.HeatIDs)-1 {
		// Update CurrentHeat to next heat's index
		round.CurrentHeat = heatIndex + 1

		if err := uc.roundRepo.Update(ctx, round); err != nil {
			// Log warning but don't fail - heat is already completed
			fmt.Printf("Warning: Failed to auto-advance CurrentHeat for round %s: %v\n", round.ID.Hex(), err)
		}
	} else {
		// This was the last heat - CurrentHeat stays at last position
		fmt.Printf("Info: Heat %s was the last heat in round %s\n", heatID, round.ID.Hex())
	}

	return nil
}
