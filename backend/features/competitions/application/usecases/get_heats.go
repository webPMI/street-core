package usecases

import (
	"context"
	"errors"

	"backend/features/competitions/domain/entities"
	"backend/features/competitions/domain/repositories"

	"go.mongodb.org/mongo-driver/bson/primitive"
)

// GetHeatsUseCase handles retrieving heats by various filters
type GetHeatsUseCase struct {
	heatRepo repositories.HeatRepository
}

// NewGetHeatsUseCase creates a new GetHeatsUseCase
func NewGetHeatsUseCase(heatRepo repositories.HeatRepository) *GetHeatsUseCase {
	return &GetHeatsUseCase{
		heatRepo: heatRepo,
	}
}

// ExecuteByID retrieves a single heat by ID
func (uc *GetHeatsUseCase) ExecuteByID(ctx context.Context, heatID string) (*entities.Heat, error) {
	heatObjID, err := primitive.ObjectIDFromHex(heatID)
	if err != nil {
		return nil, errors.New("invalid heat ID")
	}

	return uc.heatRepo.FindByID(ctx, heatObjID)
}

// ExecuteByRound retrieves all heats for a round
func (uc *GetHeatsUseCase) ExecuteByRound(ctx context.Context, roundID string) ([]*entities.Heat, error) {
	roundObjID, err := primitive.ObjectIDFromHex(roundID)
	if err != nil {
		return nil, errors.New("invalid round ID")
	}

	return uc.heatRepo.FindByRoundID(ctx, roundObjID)
}

// ExecuteByCategoryAndRound retrieves heats for a specific category and round
func (uc *GetHeatsUseCase) ExecuteByCategoryAndRound(ctx context.Context, categoryID, roundID string) ([]*entities.Heat, error) {
	categoryObjID, err := primitive.ObjectIDFromHex(categoryID)
	if err != nil {
		return nil, errors.New("invalid category ID")
	}

	roundObjID, err := primitive.ObjectIDFromHex(roundID)
	if err != nil {
		return nil, errors.New("invalid round ID")
	}

	return uc.heatRepo.FindByCategoryAndRound(ctx, categoryObjID, roundObjID)
}

// ExecuteByCompetition retrieves all heats for a competition
func (uc *GetHeatsUseCase) ExecuteByCompetition(ctx context.Context, competitionID string) ([]*entities.Heat, error) {
	compObjID, err := primitive.ObjectIDFromHex(competitionID)
	if err != nil {
		return nil, errors.New("invalid competition ID")
	}

	return uc.heatRepo.FindByCompetitionID(ctx, compObjID)
}
