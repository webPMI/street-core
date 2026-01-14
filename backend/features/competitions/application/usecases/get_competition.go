package usecases

import (
	"context"

	"backend/features/competitions/application/dto"
	domainerrors "backend/features/competitions/domain/errors"
	"backend/features/competitions/domain/repositories"

	"go.mongodb.org/mongo-driver/bson/primitive"
)

// GetCompetitionUseCase handles getting a single competition by ID
type GetCompetitionUseCase struct {
	repo repositories.CompetitionRepository
}

// NewGetCompetitionUseCase creates a new instance
func NewGetCompetitionUseCase(repo repositories.CompetitionRepository) *GetCompetitionUseCase {
	return &GetCompetitionUseCase{
		repo: repo,
	}
}

// Execute gets a competition by ID
// Authorization: Public access
func (uc *GetCompetitionUseCase) Execute(ctx context.Context, competitionID string) (*dto.CompetitionResponse, error) {
	// Parse competition ID
	id, err := primitive.ObjectIDFromHex(competitionID)
	if err != nil {
		return nil, domainerrors.ErrInvalidInput
	}

	// Fetch competition from repository
	competition, err := uc.repo.FindByID(ctx, id)
	if err != nil {
		return nil, domainerrors.ErrCompetitionNotFound
	}

	// Convert to response DTO
	response := dto.ToCompetitionResponse(competition)
	return &response, nil
}
