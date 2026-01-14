package emergency

import (
	"context"
	"errors"
	"fmt"

	"backend/features/competitions/domain/repositories"

	"go.mongodb.org/mongo-driver/bson/primitive"
)

// ResolveTieBreakUseCase handles tie-break resolution for identical scores
// Real-world scenario: Two athletes have exactly 85.50 points - who wins?
// X-Games/UCI BMX use configurable tie-break rules
type ResolveTieBreakUseCase struct {
	scoreRepo repositories.ScoreRepository
}

// NewResolveTieBreakUseCase creates a new ResolveTieBreakUseCase
func NewResolveTieBreakUseCase(scoreRepo repositories.ScoreRepository) *ResolveTieBreakUseCase {
	return &ResolveTieBreakUseCase{
		scoreRepo: scoreRepo,
	}
}

// Execute resolves a tie-break between two scores
// tieBreakRule: "highest_run" | "judge_preference" | "oldest_submission"
func (uc *ResolveTieBreakUseCase) Execute(ctx context.Context, score1ID, score2ID string, tieBreakRule string) error {
	// Validate input
	if score1ID == score2ID {
		return errors.New("cannot resolve tie-break for the same score")
	}

	// Validate tie-break rule
	validRules := map[string]bool{
		"highest_run":        true,
		"judge_preference":   true,
		"oldest_submission":  true,
	}
	if !validRules[tieBreakRule] {
		return fmt.Errorf("invalid tie-break rule: %s", tieBreakRule)
	}

	// Parse ObjectIDs
	id1, err := primitive.ObjectIDFromHex(score1ID)
	if err != nil {
		return errors.New("invalid score1 ID format")
	}
	id2, err := primitive.ObjectIDFromHex(score2ID)
	if err != nil {
		return errors.New("invalid score2 ID format")
	}

	// Fetch both scores
	score1, err := uc.scoreRepo.FindByID(ctx, id1)
	if err != nil {
		return errors.New("score 1 not found")
	}
	score2, err := uc.scoreRepo.FindByID(ctx, id2)
	if err != nil {
		return errors.New("score 2 not found")
	}

	// Verify they're from the same heat/round
	if score1.HeatID != score2.HeatID || score1.RoundID != score2.RoundID {
		return errors.New("scores must be from the same heat and round")
	}

	// Verify they're actually tied
	if score1.TotalScore != score2.TotalScore {
		return fmt.Errorf("scores are not tied: %.2f vs %.2f", score1.TotalScore, score2.TotalScore)
	}

	// Mark both as tied
	score1.IsTied = true
	score2.IsTied = true
	score1.TieBreaker = tieBreakRule
	score2.TieBreaker = tieBreakRule

	// Apply tie-break rule to determine winner
	var winnerID primitive.ObjectID
	switch tieBreakRule {
	case "highest_run":
		// In skateboarding/BMX, highest single run wins
		// For simplicity, use first criteria score as "run score"
		if len(score1.CriteriaScores) > 0 && len(score2.CriteriaScores) > 0 {
			max1 := getMaxCriteriaScore(score1.CriteriaScores)
			max2 := getMaxCriteriaScore(score2.CriteriaScores)
			if max1 > max2 {
				winnerID = score1.ID
			} else {
				winnerID = score2.ID
			}
		} else {
			// Fallback to oldest submission
			winnerID = score1.ID // First submitted wins
		}
	case "judge_preference":
		// Judge panel votes (simplified: score1 wins by default)
		winnerID = score1.ID
	case "oldest_submission":
		// First to submit wins
		if score1.SubmittedAt.Before(score2.SubmittedAt) {
			winnerID = score1.ID
		} else {
			winnerID = score2.ID
		}
	}

	// Mark winner with PhotoFinish flag (manual review indicator)
	if winnerID == score1.ID {
		score1.PhotoFinish = true
	} else {
		score2.PhotoFinish = true
	}

	// Update both scores
	score1.PrepareForUpdate()
	score2.PrepareForUpdate()

	if err := uc.scoreRepo.Update(ctx, score1); err != nil {
		return fmt.Errorf("failed to update score 1: %w", err)
	}
	if err := uc.scoreRepo.Update(ctx, score2); err != nil {
		return fmt.Errorf("failed to update score 2: %w", err)
	}

	return nil
}

// getMaxCriteriaScore returns the highest criteria score
func getMaxCriteriaScore(scores map[string]float64) float64 {
	max := 0.0
	for _, v := range scores {
		if v > max {
			max = v
		}
	}
	return max
}
