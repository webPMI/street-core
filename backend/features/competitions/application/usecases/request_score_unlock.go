package usecases

import (
	"context"
	"errors"
	"fmt"

	"backend/features/competitions/domain/repositories"

	"go.mongodb.org/mongo-driver/bson/primitive"
)

// RequestScoreUnlockUseCase handles judge requests to unlock a score for correction
type RequestScoreUnlockUseCase struct {
	scoreRepo repositories.ScoreRepository
}

// NewRequestScoreUnlockUseCase creates a new RequestScoreUnlockUseCase
func NewRequestScoreUnlockUseCase(scoreRepo repositories.ScoreRepository) *RequestScoreUnlockUseCase {
	return &RequestScoreUnlockUseCase{
		scoreRepo: scoreRepo,
	}
}

// Execute allows a judge to request permission to unlock and edit a submitted score
//
// Business Rules:
// - Only the original judge who submitted the score can request unlock
// - Score must be locked
// - Cannot request if there's already a pending unlock request
// - Cannot request if score is already within active grace period
//
// Workflow:
// 1. Judge realizes they made an error after submitting
// 2. Judge requests unlock via this use case
// 3. Organizer sees notification and must authorize via AuthorizeScoreUnlockUseCase
// 4. If authorized, judge gets time-limited window to edit
func (uc *RequestScoreUnlockUseCase) Execute(ctx context.Context, scoreID string, judgeID string) error {
	// Parse score ID
	scoreObjID, err := primitive.ObjectIDFromHex(scoreID)
	if err != nil {
		return errors.New("invalid score ID format")
	}

	// Parse judge ID
	judgeObjID, err := primitive.ObjectIDFromHex(judgeID)
	if err != nil {
		return errors.New("invalid user ID")
	}

	// Get score
	score, err := uc.scoreRepo.FindByID(ctx, scoreObjID)
	if err != nil {
		return errors.New("score not found")
	}

	// Use domain logic to request unlock
	if err := score.RequestUnlock(judgeObjID); err != nil {
		return err
	}

	// Update score in database
	if err := uc.scoreRepo.Update(ctx, score); err != nil {
		return fmt.Errorf("failed to update score: %w", err)
	}

	// TODO: Send notification to organizer about unlock request
	fmt.Printf("INFO: Score unlock requested - ScoreID: %s, JudgeID: %s\n", scoreID, judgeID)

	return nil
}
