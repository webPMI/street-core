package usecases

import (
	"context"

	"backend/features/competitions/domain/entities"
	domainerrors "backend/features/competitions/domain/errors"
	"backend/features/competitions/domain/repositories"

	"go.mongodb.org/mongo-driver/bson/primitive"
)

// GetScoresUseCase handles retrieving scores for a competition
type GetScoresUseCase struct {
	scoreRepo repositories.ScoreRepository
}

// NewGetScoresUseCase creates a new instance
func NewGetScoresUseCase(scoreRepo repositories.ScoreRepository) *GetScoresUseCase {
	return &GetScoresUseCase{
		scoreRepo: scoreRepo,
	}
}

// Execute retrieves all scores for a competition
func (uc *GetScoresUseCase) Execute(ctx context.Context, competitionID string) ([]*entities.Score, error) {
	compID, err := primitive.ObjectIDFromHex(competitionID)
	if err != nil {
		return nil, domainerrors.ErrInvalidInput
	}

	scores, err := uc.scoreRepo.FindByCompetitionID(ctx, compID)
	if err != nil {
		return nil, err
	}

	return scores, nil
}

// ExecuteByAthlete retrieves scores for a specific athlete in a competition
func (uc *GetScoresUseCase) ExecuteByAthlete(ctx context.Context, competitionID, athleteID string) ([]*entities.Score, error) {
	compID, err := primitive.ObjectIDFromHex(competitionID)
	if err != nil {
		return nil, domainerrors.ErrInvalidInput
	}

	athID, err := primitive.ObjectIDFromHex(athleteID)
	if err != nil {
		return nil, domainerrors.ErrInvalidInput
	}

	scores, err := uc.scoreRepo.FindByCompetitionAndAthlete(ctx, compID, athID)
	if err != nil {
		return nil, err
	}

	return scores, nil
}

// ExecuteByRound retrieves scores for a specific round
func (uc *GetScoresUseCase) ExecuteByRound(ctx context.Context, competitionID, roundID string) ([]*entities.Score, error) {
	compID, err := primitive.ObjectIDFromHex(competitionID)
	if err != nil {
		return nil, domainerrors.ErrInvalidInput
	}

	scores, err := uc.scoreRepo.FindByCompetitionAndRound(ctx, compID, roundID)
	if err != nil {
		return nil, err
	}

	return scores, nil
}
