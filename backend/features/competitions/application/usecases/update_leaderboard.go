package usecases

import (
	"context"
	"log"

	"backend/pkg/users"
	"backend/features/competitions/domain/entities"
	domainerrors "backend/features/competitions/domain/errors"
	"backend/features/competitions/domain/repositories"

	"go.mongodb.org/mongo-driver/bson/primitive"
)

// UpdateLeaderboardUseCase handles leaderboard calculation and updates
type UpdateLeaderboardUseCase struct {
	leaderboardRepo repositories.LeaderboardRepository
	scoreRepo       repositories.ScoreRepository
	compRepo        repositories.CompetitionRepository
	userClient      users.UserClient
}

// NewUpdateLeaderboardUseCase creates a new instance
func NewUpdateLeaderboardUseCase(
	leaderboardRepo repositories.LeaderboardRepository,
	scoreRepo repositories.ScoreRepository,
	compRepo repositories.CompetitionRepository,
	userClient users.UserClient,
) *UpdateLeaderboardUseCase {
	return &UpdateLeaderboardUseCase{
		leaderboardRepo: leaderboardRepo,
		scoreRepo:       scoreRepo,
		compRepo:        compRepo,
		userClient:      userClient,
	}
}

// Execute calculates and updates the leaderboard for a competition
func (uc *UpdateLeaderboardUseCase) Execute(ctx context.Context, competitionID string) (*entities.Leaderboard, error) {
	compID, err := primitive.ObjectIDFromHex(competitionID)
	if err != nil {
		return nil, domainerrors.ErrInvalidInput
	}

	// Get competition details
	competition, err := uc.compRepo.FindByID(ctx, compID)
	if err != nil {
		return nil, domainerrors.ErrCompetitionNotFound
	}

	// Get all scores for the competition
	scores, err := uc.scoreRepo.FindByCompetitionID(ctx, compID)
	if err != nil {
		return nil, err
	}

	// Find or create leaderboard
	leaderboard, err := uc.leaderboardRepo.FindByCompetitionID(ctx, compID)
	if err != nil {
		return nil, err
	}

	if leaderboard == nil {
		// Create new leaderboard
		leaderboard = entities.NewLeaderboard(compID)
	}

	// Calculate athlete scores
	athleteScores := make(map[primitive.ObjectID]map[string]float64) // athleteID -> roundID -> totalScore
	athleteRoundCounts := make(map[primitive.ObjectID]map[string]int) // Count judges per round

	for _, score := range scores {
		if _, exists := athleteScores[score.AthleteID]; !exists {
			athleteScores[score.AthleteID] = make(map[string]float64)
			athleteRoundCounts[score.AthleteID] = make(map[string]int)
		}

		// Accumulate scores per round
		athleteScores[score.AthleteID][score.RoundID] += score.TotalScore
		athleteRoundCounts[score.AthleteID][score.RoundID]++
	}

	// Collect all athlete IDs for batch fetching
	athleteIDs := make([]primitive.ObjectID, 0, len(athleteScores))
	for athleteID := range athleteScores {
		athleteIDs = append(athleteIDs, athleteID)
	}

	// Fetch athlete details in a single batch request
	athleteInfoMap, err := uc.userClient.GetUsersBasicInfo(ctx, athleteIDs)
	if err != nil {
		log.Printf("[UpdateLeaderboard] Warning: Failed to fetch athlete details: %v", err)
		// Continue without names - not a fatal error
		athleteInfoMap = make(map[string]*users.UserBasicInfo)
	}

	// Calculate average scores (or use scoring criteria method)
	for athleteID, roundScores := range athleteScores {
		totalScore := 0.0
		numRounds := len(roundScores)

		for roundID, totalRoundScore := range roundScores {
			judgeCount := athleteRoundCounts[athleteID][roundID]
			// Average score from all judges for this round
			avgRoundScore := totalRoundScore / float64(judgeCount)
			roundScores[roundID] = avgRoundScore
			totalScore += avgRoundScore
		}

		// Apply scoring criteria if needed
		switch competition.ScoringCriteria.Type {
		case "average":
			if numRounds > 0 {
				totalScore = totalScore / float64(numRounds)
			}
		case "best_result":
			// Find best round score
			bestScore := 0.0
			for _, roundScore := range roundScores {
				if roundScore > bestScore {
					bestScore = roundScore
				}
			}
			totalScore = bestScore
		// "sum" is default - already calculated
		}

		// Create or update leaderboard entry
		entry := entities.LeaderboardEntry{
			AthleteID:   athleteID,
			TotalScore:  totalScore,
			RoundScores: roundScores,
		}

		// Populate athlete details from fetched data
		if athleteInfo, ok := athleteInfoMap[athleteID.Hex()]; ok {
			entry.AthleteName = athleteInfo.FullName()
			// AthleteNumber and Club info would come from athlete profile if available
		} else {
			log.Printf("[UpdateLeaderboard] Athlete %s not found in user data", athleteID.Hex())
		}

		leaderboard.AddEntry(entry)
	}

	// Sort leaderboard by score
	leaderboard.SortByScore()

	// Save or update leaderboard
	if leaderboard.CreatedAt.IsZero() {
		err = uc.leaderboardRepo.Save(ctx, leaderboard)
	} else {
		err = uc.leaderboardRepo.Update(ctx, leaderboard)
	}

	if err != nil {
		return nil, err
	}

	return leaderboard, nil
}
