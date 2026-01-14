package usecases

import (
	"context"
	"errors"
	"fmt"

	"backend/features/competitions/domain/repositories"

	"go.mongodb.org/mongo-driver/bson/primitive"
)

// ResetHeatsUseCase handles resetting (deleting) all heats and scores for a round
// This is a DESTRUCTIVE operation requiring double confirmation from the frontend
type ResetHeatsUseCase struct {
	heatRepo  repositories.HeatRepository
	roundRepo repositories.RoundRepository
	scoreRepo repositories.ScoreRepository
}

// NewResetHeatsUseCase creates a new ResetHeatsUseCase
func NewResetHeatsUseCase(
	heatRepo repositories.HeatRepository,
	roundRepo repositories.RoundRepository,
	scoreRepo repositories.ScoreRepository,
) *ResetHeatsUseCase {
	return &ResetHeatsUseCase{
		heatRepo:  heatRepo,
		roundRepo: roundRepo,
		scoreRepo: scoreRepo,
	}
}

// ResetHeatsRequest contains the confirmation token for safety
type ResetHeatsRequest struct {
	RoundID          string
	ConfirmationText string // Must match "RESET HEATS" exactly
}

// Execute deletes all heats and associated scores for a round
// Requires confirmation text to prevent accidental deletion
func (uc *ResetHeatsUseCase) Execute(ctx context.Context, req ResetHeatsRequest) error {
	// Safety check: Require exact confirmation text
	if req.ConfirmationText != "RESET HEATS" {
		return errors.New("confirmation text must match 'RESET HEATS'")
	}

	// Parse round ID
	roundObjID, err := primitive.ObjectIDFromHex(req.RoundID)
	if err != nil {
		return errors.New("invalid round ID")
	}

	// Get round
	round, err := uc.roundRepo.FindByID(ctx, roundObjID)
	if err != nil {
		return errors.New("round not found")
	}

	// Get all heats for this round
	heats, err := uc.heatRepo.FindByRoundID(ctx, roundObjID)
	if err != nil {
		return fmt.Errorf("failed to get heats: %w", err)
	}

	if len(heats) == 0 {
		return errors.New("no heats to reset")
	}

	// Count total scores that will be deleted (for logging/audit)
	totalScoresDeleted := 0
	for _, heat := range heats {
		scores, err := uc.scoreRepo.FindByHeat(ctx, round.CompetitionID, heat.ID.Hex())
		if err == nil {
			totalScoresDeleted += len(scores)
		}
	}

	// Log the destructive operation
	fmt.Printf("RESET HEATS: Round %s - Deleting %d heats and %d scores\n",
		req.RoundID, len(heats), totalScoresDeleted)

	// Delete all scores associated with heats in this round
	for _, heat := range heats {
		// Get scores for this heat
		scores, err := uc.scoreRepo.FindByHeat(ctx, round.CompetitionID, heat.ID.Hex())
		if err != nil {
			fmt.Printf("Warning: Failed to get scores for heat %s: %v\n", heat.ID.Hex(), err)
			continue
		}

		// Delete each score
		for _, score := range scores {
			if err := uc.scoreRepo.Delete(ctx, score.ID); err != nil {
				fmt.Printf("Warning: Failed to delete score %s: %v\n", score.ID.Hex(), err)
			}
		}
	}

	// Delete all heats
	if err := uc.heatRepo.DeleteByRoundID(ctx, roundObjID); err != nil {
		return fmt.Errorf("failed to delete heats: %w", err)
	}

	// Update round to disable heats
	round.DisableHeats()
	if err := uc.roundRepo.Update(ctx, round); err != nil {
		return fmt.Errorf("failed to update round: %w", err)
	}

	fmt.Printf("RESET HEATS COMPLETE: Round %s cleaned successfully\n", req.RoundID)

	return nil
}
