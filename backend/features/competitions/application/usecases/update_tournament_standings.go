package usecases

import (
	"context"

	"backend/features/competitions/application/dto"
	domainerrors "backend/features/competitions/domain/errors"
	"backend/features/competitions/domain/repositories"

	"go.mongodb.org/mongo-driver/bson/primitive"
)

// UpdateTournamentStandingsUseCase handles recalculating tournament standings
type UpdateTournamentStandingsUseCase struct {
	tournamentRepo repositories.TournamentRepository
	standingRepo   repositories.TournamentStandingRepository
}

// NewUpdateTournamentStandingsUseCase creates a new instance
func NewUpdateTournamentStandingsUseCase(
	tournamentRepo repositories.TournamentRepository,
	standingRepo repositories.TournamentStandingRepository,
) *UpdateTournamentStandingsUseCase {
	return &UpdateTournamentStandingsUseCase{
		tournamentRepo: tournamentRepo,
		standingRepo:   standingRepo,
	}
}

// Execute recalculates standings for a tournament
func (uc *UpdateTournamentStandingsUseCase) Execute(ctx context.Context, tournamentID string) ([]*dto.TournamentStandingResponse, error) {
	// Parse tournament ID
	tournamentOID, err := primitive.ObjectIDFromHex(tournamentID)
	if err != nil {
		return nil, domainerrors.ErrInvalidInput
	}

	// Get tournament to retrieve scoring config
	tournament, err := uc.tournamentRepo.FindByID(ctx, tournamentOID)
	if err != nil {
		return nil, err
	}

	// Recalculate standings using the tournament's scoring configuration
	if err := uc.standingRepo.RecalculateStandings(ctx, tournamentOID, tournament.ScoringConfig); err != nil {
		return nil, err
	}

	// Get updated standings sorted by position
	standings, err := uc.standingRepo.FindByTournamentIDSorted(ctx, tournamentOID)
	if err != nil {
		return nil, err
	}

	// Convert to response
	return dto.ToTournamentStandingResponses(standings), nil
}

// ExecuteForTopN gets top N standings after recalculation
func (uc *UpdateTournamentStandingsUseCase) ExecuteForTopN(ctx context.Context, tournamentID string, limit int) ([]*dto.TournamentStandingResponse, error) {
	// Parse tournament ID
	tournamentOID, err := primitive.ObjectIDFromHex(tournamentID)
	if err != nil {
		return nil, domainerrors.ErrInvalidInput
	}

	// Get tournament to retrieve scoring config
	tournament, err := uc.tournamentRepo.FindByID(ctx, tournamentOID)
	if err != nil {
		return nil, err
	}

	// Recalculate standings
	if err := uc.standingRepo.RecalculateStandings(ctx, tournamentOID, tournament.ScoringConfig); err != nil {
		return nil, err
	}

	// Get top N standings
	standings, err := uc.standingRepo.GetTopStandings(ctx, tournamentOID, limit)
	if err != nil {
		return nil, err
	}

	// Convert to response
	return dto.ToTournamentStandingResponses(standings), nil
}
