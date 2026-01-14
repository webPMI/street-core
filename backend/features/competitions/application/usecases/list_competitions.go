package usecases

import (
	"context"

	"backend/features/competitions/application/dto"
	domainerrors "backend/features/competitions/domain/errors"
	"backend/features/competitions/domain/repositories"
)

// ListCompetitionsUseCase handles listing competitions with pagination
type ListCompetitionsUseCase struct {
	repo repositories.CompetitionRepository
}

// NewListCompetitionsUseCase creates a new instance
func NewListCompetitionsUseCase(repo repositories.CompetitionRepository) *ListCompetitionsUseCase {
	return &ListCompetitionsUseCase{
		repo: repo,
	}
}

// Execute lists competitions with pagination and filters
// Authorization: Public access
func (uc *ListCompetitionsUseCase) Execute(ctx context.Context, page, limit int, filters map[string]interface{}) ([]dto.CompetitionResponse, int64, error) {
	// Validate pagination params
	if page < 1 {
		page = 1
	}
	if limit < 1 {
		limit = 20
	}
	if limit > 100 {
		limit = 100
	}

	// Fetch competitions from repository
	competitions, total, err := uc.repo.FindAll(ctx, page, limit, filters)
	if err != nil {
		return nil, 0, domainerrors.ErrDatabaseOperation
	}

	// Convert to response DTOs
	responses := make([]dto.CompetitionResponse, len(competitions))
	for i, comp := range competitions {
		responses[i] = dto.ToCompetitionResponse(comp)
	}

	return responses, total, nil
}

// ExecuteUpcoming lists upcoming competitions
func (uc *ListCompetitionsUseCase) ExecuteUpcoming(ctx context.Context, page, limit int, filters map[string]interface{}) ([]dto.CompetitionResponse, int64, error) {
	// Validate pagination params
	if page < 1 {
		page = 1
	}
	if limit < 1 {
		limit = 20
	}
	if limit > 100 {
		limit = 100
	}

	// Fetch upcoming competitions
	competitions, total, err := uc.repo.FindUpcoming(ctx, page, limit, filters)
	if err != nil {
		return nil, 0, domainerrors.ErrDatabaseOperation
	}

	// Convert to response DTOs
	responses := make([]dto.CompetitionResponse, len(competitions))
	for i, comp := range competitions {
		responses[i] = dto.ToCompetitionResponse(comp)
	}

	return responses, total, nil
}

// ExecuteLive lists live competitions
func (uc *ListCompetitionsUseCase) ExecuteLive(ctx context.Context, page, limit int, filters map[string]interface{}) ([]dto.CompetitionResponse, int64, error) {
	// Validate pagination params
	if page < 1 {
		page = 1
	}
	if limit < 1 {
		limit = 20
	}
	if limit > 100 {
		limit = 100
	}

	// Fetch live competitions
	competitions, total, err := uc.repo.FindLive(ctx, page, limit, filters)
	if err != nil {
		return nil, 0, domainerrors.ErrDatabaseOperation
	}

	// Convert to response DTOs
	responses := make([]dto.CompetitionResponse, len(competitions))
	for i, comp := range competitions {
		responses[i] = dto.ToCompetitionResponse(comp)
	}

	return responses, total, nil
}
