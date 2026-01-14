package usecases

import (
	"context"
	"errors"
	"fmt"

	"backend/features/competitions/domain/repositories"

	"go.mongodb.org/mongo-driver/bson/primitive"
)

// AuthorizeScoreUnlockUseCase handles organizer authorization of score unlock requests
type AuthorizeScoreUnlockUseCase struct {
	scoreRepo       repositories.ScoreRepository
	competitionRepo repositories.CompetitionRepository
}

// NewAuthorizeScoreUnlockUseCase creates a new AuthorizeScoreUnlockUseCase
func NewAuthorizeScoreUnlockUseCase(
	scoreRepo repositories.ScoreRepository,
	competitionRepo repositories.CompetitionRepository,
) *AuthorizeScoreUnlockUseCase {
	return &AuthorizeScoreUnlockUseCase{
		scoreRepo:       scoreRepo,
		competitionRepo: competitionRepo,
	}
}

// Execute authorizes a pending unlock request, granting time-limited edit access
//
// Parameters:
// - scoreID: The score to unlock
// - organizerID: The organizer authorizing the unlock
// - gracePeriodMinutes: Optional override for grace period (0 = use competition default)
//
// Business Rules:
// - Must have a pending unlock request
// - Grace period comes from competition config unless overridden
// - Creates time-limited window (e.g., 5 minutes) for judge to edit
// - Score auto-locks when grace period expires
//
// Workflow:
// 1. Organizer sees unlock request notification
// 2. Organizer approves via this use case
// 3. Judge gets notification "You have 5 minutes to edit"
// 4. After grace period, score auto-locks again
func (uc *AuthorizeScoreUnlockUseCase) Execute(ctx context.Context, scoreID string, organizerID string, gracePeriodMinutes int) error {
	// Parse score ID
	scoreObjID, err := primitive.ObjectIDFromHex(scoreID)
	if err != nil {
		return errors.New("invalid score ID format")
	}

	// Parse organizer ID
	organizerObjID, err := primitive.ObjectIDFromHex(organizerID)
	if err != nil {
		return errors.New("invalid user ID")
	}

	// Get score
	score, err := uc.scoreRepo.FindByID(ctx, scoreObjID)
	if err != nil {
		return errors.New("score not found")
	}

	// If grace period not specified, get from competition config
	if gracePeriodMinutes == 0 {
		competition, err := uc.competitionRepo.FindByID(ctx, score.CompetitionID)
		if err != nil {
			return errors.New("competition not found")
		}

		// Use competition's configured grace period
		gracePeriodMinutes = competition.ScoreGracePeriodMinutes

		// Default to 5 minutes if not configured
		if gracePeriodMinutes == 0 {
			gracePeriodMinutes = 5
		}
	}

	// Use domain logic to authorize unlock
	if err := score.AuthorizeUnlock(organizerObjID, gracePeriodMinutes); err != nil {
		return uc.mapAuthorizeUnlockError(err)
	}

	// Update score in database
	if err := uc.scoreRepo.Update(ctx, score); err != nil {
		return fmt.Errorf("failed to update score: %w", err)
	}

	// TODO: Send notification to judge that unlock was approved
	fmt.Printf("INFO: Score unlock authorized - ScoreID: %s, OrganizerID: %s, GracePeriod: %d minutes\n",
		scoreID, organizerID, gracePeriodMinutes)

	return nil
}

// Deny rejects a pending unlock request
func (uc *AuthorizeScoreUnlockUseCase) Deny(ctx context.Context, scoreID string, organizerID string, denyReason string) error {
	// Parse score ID
	scoreObjID, err := primitive.ObjectIDFromHex(scoreID)
	if err != nil {
		return errors.New("invalid score ID format")
	}

	// Get score
	score, err := uc.scoreRepo.FindByID(ctx, scoreObjID)
	if err != nil {
		return errors.New("score not found")
	}

	// Verify there's a pending request
	if score.UnlockRequestedAt == nil {
		return errors.New("no unlock request to deny")
	}

	// Clear the unlock request
	score.ClearUnlockRequest()

	// Update score in database
	if err := uc.scoreRepo.Update(ctx, score); err != nil {
		return fmt.Errorf("failed to update score: %w", err)
	}

	// TODO: Send notification to judge that unlock was denied
	fmt.Printf("INFO: Score unlock denied - ScoreID: %s, OrganizerID: %s, Reason: %s\n",
		scoreID, organizerID, denyReason)

	return nil
}

// mapAuthorizeUnlockError maps domain errors to standard errors
func (uc *AuthorizeScoreUnlockUseCase) mapAuthorizeUnlockError(err error) error {
	// Just return the error as-is since we're using standard errors now
	return err
}
