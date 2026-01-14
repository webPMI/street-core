package usecases

import (
	"context"

	"backend/features/competitions/application/dto"
	domainerrors "backend/features/competitions/domain/errors"
	"backend/features/competitions/domain/repositories"

	"go.mongodb.org/mongo-driver/bson/primitive"
)

// GetTournamentUseCase handles getting tournament details
type GetTournamentUseCase struct {
	tournamentRepo repositories.TournamentRepository
}

// NewGetTournamentUseCase creates a new instance
func NewGetTournamentUseCase(tournamentRepo repositories.TournamentRepository) *GetTournamentUseCase {
	return &GetTournamentUseCase{
		tournamentRepo: tournamentRepo,
	}
}

// Execute gets tournament details by ID
func (uc *GetTournamentUseCase) Execute(ctx context.Context, tournamentID string) (*dto.TournamentResponse, error) {
	// Parse tournament ID
	id, err := primitive.ObjectIDFromHex(tournamentID)
	if err != nil {
		return nil, domainerrors.ErrInvalidInput
	}

	// Get tournament from repository
	tournament, err := uc.tournamentRepo.FindByID(ctx, id)
	if err != nil {
		return nil, err
	}

	// Convert to response
	return dto.ToTournamentResponse(tournament), nil
}
