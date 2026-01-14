package usecases

import (
	"context"
	"errors"
	"log"

	"backend/pkg/users"
	"backend/features/competitions/domain/entities"
	domainerrors "backend/features/competitions/domain/errors"
	"backend/features/competitions/domain/repositories"

	"go.mongodb.org/mongo-driver/bson/primitive"
)

// SubmitScoresUseCase handles score submission for competitions
type SubmitScoresUseCase struct {
	compRepo          repositories.CompetitionRepository
	scoreRepo         repositories.ScoreRepository
	heatRepo          repositories.HeatRepository
	updateLeaderboard *UpdateLeaderboardUseCase
	userClient        users.UserClient
}

// NewSubmitScoresUseCase creates a new instance
func NewSubmitScoresUseCase(
	compRepo repositories.CompetitionRepository,
	scoreRepo repositories.ScoreRepository,
	heatRepo repositories.HeatRepository,
	updateLeaderboard *UpdateLeaderboardUseCase,
	userClient users.UserClient,
) *SubmitScoresUseCase {
	return &SubmitScoresUseCase{
		compRepo:          compRepo,
		scoreRepo:         scoreRepo,
		heatRepo:          heatRepo,
		updateLeaderboard: updateLeaderboard,
		userClient:        userClient,
	}
}

// Execute submits a score for an athlete in a specific round/heat
// Authorization: Only assigned judges or Admin can submit scores
// heatID is optional - if empty, score applies to entire round
func (uc *SubmitScoresUseCase) Execute(ctx context.Context, competitionID, athleteID, roundID, heatID string, score float64, userID primitive.ObjectID, userRole string) error {
	// Parse IDs
	compID, err := primitive.ObjectIDFromHex(competitionID)
	if err != nil {
		return domainerrors.ErrInvalidInput
	}

	athID, err := primitive.ObjectIDFromHex(athleteID)
	if err != nil {
		return domainerrors.ErrInvalidInput
	}

	// Fetch competition
	competition, err := uc.compRepo.FindByID(ctx, compID)
	if err != nil {
		return domainerrors.ErrCompetitionNotFound
	}

	// Authorization check: Only judges or admin can submit scores
	if userRole != "admin" && !competition.IsJudge(userID) {
		return domainerrors.ErrNotJudge
	}

	// Check if scores can be submitted
	if !competition.CanSubmitScores() {
		return domainerrors.ErrCannotSubmitScore
	}

	// Validate score against criteria
	if score < competition.ScoringCriteria.MinScore || score > competition.ScoringCriteria.MaxScore {
		return domainerrors.ErrInvalidInput
	}

	// Check if athlete is registered
	if !competition.IsAthleteRegistered(athID) {
		return domainerrors.ErrNotRegistered
	}

	// ==========================================================================
	// CONCURRENCY GUARDS - Heat Validation
	// ==========================================================================
	if heatID != "" {
		heatObjID, err := primitive.ObjectIDFromHex(heatID)
		if err != nil {
			return domainerrors.ErrInvalidInput
		}

		// Fetch heat
		heat, err := uc.heatRepo.FindByID(ctx, heatObjID)
		if err != nil {
			// Heat not found could mean it was deleted
			if errors.Is(err, domainerrors.ErrDatabaseOperation) {
				return domainerrors.ErrHeatDeleted // HTTP 410 Gone
			}
			return domainerrors.ErrDatabaseOperation
		}

		// GUARD 1: Heat must NOT be completed
		if heat.IsCompleted() {
			log.Printf("[SubmitScores] CONFLICT: Heat %s is already completed/closed", heatID)
			return domainerrors.ErrHeatAlreadyClosed // HTTP 409 Conflict
		}

		// GUARD 2: Heat must be ACTIVE (strict mode for concurrency safety)
		if !heat.IsActive() {
			log.Printf("[SubmitScores] CONFLICT: Heat %s is not active (status: %s)", heatID, heat.Status)
			return domainerrors.ErrHeatNotActive // HTTP 409 Conflict
		}

		// GUARD 3: Athlete must be in this heat
		if !heat.HasAthlete(athID) {
			log.Printf("[SubmitScores] BAD REQUEST: Athlete %s not assigned to heat %s", athleteID, heatID)
			return domainerrors.ErrAthleteNotInHeat // HTTP 400 Bad Request
		}

		log.Printf("[SubmitScores] Heat validation passed for heat %s (status: %s)", heatID, heat.Status)
	}

	// Check if score already exists for this judge-athlete-round combination
	existingScore, err := uc.scoreRepo.FindExistingScore(ctx, compID, athID, userID, roundID)
	if err != nil {
		return err
	}

	if existingScore != nil {
		// Update existing score
		existingScore.TotalScore = score
		existingScore.PrepareForUpdate()
		err = uc.scoreRepo.Update(ctx, existingScore)
		if err != nil {
			return err
		}
	} else {
		// Create new score
		newScore := entities.NewScore(compID, athID, userID, roundID, score)

		// Add heatID if provided
		if heatID != "" {
			newScore.HeatID = heatID
		}

		// Fetch judge and athlete names
		userIDs := []primitive.ObjectID{userID, athID}
		userInfoMap, fetchErr := uc.userClient.GetUsersBasicInfo(ctx, userIDs)
		if fetchErr != nil {
			log.Printf("[SubmitScores] Warning: Failed to fetch user details: %v", fetchErr)
			// Continue without names - not a fatal error
		} else {
			if judgeInfo, ok := userInfoMap[userID.Hex()]; ok {
				newScore.JudgeName = judgeInfo.FullName()
			}
			if athleteInfo, ok := userInfoMap[athID.Hex()]; ok {
				newScore.AthleteName = athleteInfo.FullName()
			}
		}

		err = uc.scoreRepo.Save(ctx, newScore)
		if err != nil {
			return err
		}
	}

	// Update leaderboard asynchronously after score submission
	// Note: In production, this could be done via message queue for better performance
	if competition.AllowLiveScoring {
		_, err = uc.updateLeaderboard.Execute(ctx, competitionID)
		if err != nil {
			// Log error but don't fail the score submission
			log.Printf("[SubmitScores] Warning: Failed to update leaderboard for competition %s: %v", competitionID, err)
		} else {
			log.Printf("[SubmitScores] Leaderboard updated for competition %s after score submission", competitionID)
		}
	}

	return nil
}
