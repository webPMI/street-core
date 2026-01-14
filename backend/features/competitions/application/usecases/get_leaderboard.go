package usecases

import (
	"context"

	"backend/features/competitions/domain/entities"
	domainerrors "backend/features/competitions/domain/errors"
	"backend/features/competitions/domain/repositories"

	"go.mongodb.org/mongo-driver/bson/primitive"
)

// GetLeaderboardUseCase handles retrieving the leaderboard for a competition
type GetLeaderboardUseCase struct {
	leaderboardRepo repositories.LeaderboardRepository
	compRepo        repositories.CompetitionRepository
}

// NewGetLeaderboardUseCase creates a new instance
func NewGetLeaderboardUseCase(
	leaderboardRepo repositories.LeaderboardRepository,
	compRepo repositories.CompetitionRepository,
) *GetLeaderboardUseCase {
	return &GetLeaderboardUseCase{
		leaderboardRepo: leaderboardRepo,
		compRepo:        compRepo,
	}
}

// Execute retrieves the leaderboard for a competition
func (uc *GetLeaderboardUseCase) Execute(ctx context.Context, competitionID string) (*entities.Leaderboard, error) {
	compID, err := primitive.ObjectIDFromHex(competitionID)
	if err != nil {
		return nil, domainerrors.ErrInvalidInput
	}

	// Verify competition exists
	_, err = uc.compRepo.FindByID(ctx, compID)
	if err != nil {
		return nil, domainerrors.ErrCompetitionNotFound
	}

	// Get leaderboard
	leaderboard, err := uc.leaderboardRepo.FindByCompetitionID(ctx, compID)
	if err != nil {
		return nil, err
	}

	if leaderboard == nil {
		// Return empty leaderboard if none exists yet
		return entities.NewLeaderboard(compID), nil
	}

	return leaderboard, nil
}

// ExecuteWithCheck retrieves the leaderboard only if results are published
func (uc *GetLeaderboardUseCase) ExecuteWithCheck(ctx context.Context, competitionID string, userID primitive.ObjectID, userRole string) (*entities.Leaderboard, error) {
	compID, err := primitive.ObjectIDFromHex(competitionID)
	if err != nil {
		return nil, domainerrors.ErrInvalidInput
	}

	// Get competition
	competition, err := uc.compRepo.FindByID(ctx, compID)
	if err != nil {
		return nil, domainerrors.ErrCompetitionNotFound
	}

	// Check if user has permission to view leaderboard
	// Admin, organizer, and judges can always see
	// Public can only see if results are published or showLiveResults is enabled
	canView := userRole == "admin" ||
		competition.IsOwner(userID) ||
		competition.IsJudge(userID) ||
		competition.IsResultsPublished ||
		competition.ShowLiveResults

	if !canView {
		return nil, domainerrors.ErrResultsNotPublished
	}

	// Get leaderboard
	leaderboard, err := uc.leaderboardRepo.FindByCompetitionID(ctx, compID)
	if err != nil {
		return nil, err
	}

	if leaderboard == nil {
		return entities.NewLeaderboard(compID), nil
	}

	return leaderboard, nil
}
