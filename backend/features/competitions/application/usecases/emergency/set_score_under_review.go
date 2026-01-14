package emergency

import (
	"context"
	"errors"
	"fmt"
	"time"

	"backend/features/competitions/domain/repositories"

	"go.mongodb.org/mongo-driver/bson/primitive"
)

// SetScoreUnderReviewUseCase handles score protest management
// Real-world scenario: Coach files protest, score must be hidden until resolved
// Used in X-Games, UCI BMX, skateboarding competitions
type SetScoreUnderReviewUseCase struct {
	scoreRepo repositories.ScoreRepository
}

// NewSetScoreUnderReviewUseCase creates a new SetScoreUnderReviewUseCase
func NewSetScoreUnderReviewUseCase(scoreRepo repositories.ScoreRepository) *SetScoreUnderReviewUseCase {
	return &SetScoreUnderReviewUseCase{
		scoreRepo: scoreRepo,
	}
}

// SetUnderReview marks a score as under review (hidden from public leaderboards)
func (uc *SetScoreUnderReviewUseCase) SetUnderReview(ctx context.Context, scoreID string, reason string) error {
	// Parse ObjectID
	id, err := primitive.ObjectIDFromHex(scoreID)
	if err != nil {
		return errors.New("invalid score ID format")
	}

	// Fetch score
	score, err := uc.scoreRepo.FindByID(ctx, id)
	if err != nil {
		return errors.New("score not found")
	}

	// Check if already under review
	if score.IsUnderReview {
		return errors.New("score is already under review")
	}

	// Mark as under review
	now := time.Now()
	score.IsUnderReview = true
	score.ReviewReason = reason
	score.ReviewRequestedAt = &now
	score.PrepareForUpdate()

	// Update score
	if err := uc.scoreRepo.Update(ctx, score); err != nil {
		return fmt.Errorf("failed to update score: %w", err)
	}

	return nil
}

// ResolveReview resolves a review, either approving original score or updating it
func (uc *SetScoreUnderReviewUseCase) ResolveReview(ctx context.Context, scoreID string, approved bool, newScore *float64) error {
	// Parse ObjectID
	id, err := primitive.ObjectIDFromHex(scoreID)
	if err != nil {
		return errors.New("invalid score ID format")
	}

	// Fetch score
	score, err := uc.scoreRepo.FindByID(ctx, id)
	if err != nil {
		return errors.New("score not found")
	}

	// Check if under review
	if !score.IsUnderReview {
		return errors.New("score is not under review")
	}

	// Resolve review
	now := time.Now()
	score.IsUnderReview = false
	score.ReviewResolvedAt = &now
	score.ReviewApproved = &approved

	// If not approved and new score provided, update it
	if !approved && newScore != nil {
		score.TotalScore = *newScore
	}

	score.PrepareForUpdate()

	// Update score
	if err := uc.scoreRepo.Update(ctx, score); err != nil {
		return fmt.Errorf("failed to update score: %w", err)
	}

	return nil
}
