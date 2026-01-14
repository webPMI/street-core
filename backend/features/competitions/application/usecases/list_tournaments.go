package usecases

import (
	"context"

	"backend/features/competitions/application/dto"
	domainerrors "backend/features/competitions/domain/errors"
	"backend/features/competitions/domain/repositories"

	"go.mongodb.org/mongo-driver/bson/primitive"
)

// ListTournamentsUseCase handles listing tournaments
type ListTournamentsUseCase struct {
	tournamentRepo repositories.TournamentRepository
}

// NewListTournamentsUseCase creates a new instance
func NewListTournamentsUseCase(tournamentRepo repositories.TournamentRepository) *ListTournamentsUseCase {
	return &ListTournamentsUseCase{
		tournamentRepo: tournamentRepo,
	}
}

// Execute lists tournaments with pagination and filters
func (uc *ListTournamentsUseCase) Execute(ctx context.Context, page, limit int, filters map[string]interface{}) ([]*dto.TournamentResponse, int64, error) {
	// Default pagination
	if page < 1 {
		page = 1
	}
	if limit < 1 || limit > 100 {
		limit = 20
	}

	// Get tournaments from repository
	tournaments, total, err := uc.tournamentRepo.FindAll(ctx, page, limit, filters)
	if err != nil {
		return nil, 0, err
	}

	// Convert to response
	responses := dto.ToTournamentResponses(tournaments)

	return responses, total, nil
}

// ExecuteByStatus lists tournaments by status
func (uc *ListTournamentsUseCase) ExecuteByStatus(ctx context.Context, status string, page, limit int) ([]*dto.TournamentResponse, int64, error) {
	// Default pagination
	if page < 1 {
		page = 1
	}
	if limit < 1 || limit > 100 {
		limit = 20
	}

	// Get tournaments from repository
	tournaments, total, err := uc.tournamentRepo.FindByStatus(ctx, status, page, limit)
	if err != nil {
		return nil, 0, err
	}

	// Convert to response
	responses := dto.ToTournamentResponses(tournaments)

	return responses, total, nil
}

// ExecuteUpcoming lists upcoming tournaments
func (uc *ListTournamentsUseCase) ExecuteUpcoming(ctx context.Context, page, limit int, filters map[string]interface{}) ([]*dto.TournamentResponse, int64, error) {
	// Default pagination
	if page < 1 {
		page = 1
	}
	if limit < 1 || limit > 100 {
		limit = 20
	}

	// Get upcoming tournaments
	tournaments, total, err := uc.tournamentRepo.FindUpcoming(ctx, page, limit, filters)
	if err != nil {
		return nil, 0, err
	}

	// Convert to response
	responses := dto.ToTournamentResponses(tournaments)

	return responses, total, nil
}

// ExecuteLive lists live tournaments
func (uc *ListTournamentsUseCase) ExecuteLive(ctx context.Context, page, limit int, filters map[string]interface{}) ([]*dto.TournamentResponse, int64, error) {
	// Default pagination
	if page < 1 {
		page = 1
	}
	if limit < 1 || limit > 100 {
		limit = 20
	}

	// Get live tournaments
	tournaments, total, err := uc.tournamentRepo.FindLive(ctx, page, limit, filters)
	if err != nil {
		return nil, 0, err
	}

	// Convert to response
	responses := dto.ToTournamentResponses(tournaments)

	return responses, total, nil
}

// ExecuteByOrganizerID lists tournaments by organizer
func (uc *ListTournamentsUseCase) ExecuteByOrganizerID(ctx context.Context, organizerID string, page, limit int) ([]*dto.TournamentResponse, int64, error) {
	// Parse organizer ID
	id, err := primitive.ObjectIDFromHex(organizerID)
	if err != nil {
		return nil, 0, domainerrors.ErrInvalidInput
	}

	// Default pagination
	if page < 1 {
		page = 1
	}
	if limit < 1 || limit > 100 {
		limit = 20
	}

	// Get tournaments from repository
	tournaments, total, err := uc.tournamentRepo.FindByOrganizerID(ctx, id, page, limit)
	if err != nil {
		return nil, 0, err
	}

	// Convert to response
	responses := dto.ToTournamentResponses(tournaments)

	return responses, total, nil
}
