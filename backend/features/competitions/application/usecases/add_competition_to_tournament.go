package usecases

import (
	"context"

	"backend/features/competitions/application/dto"
	domainerrors "backend/features/competitions/domain/errors"
	"backend/features/competitions/domain/repositories"

	"go.mongodb.org/mongo-driver/bson/primitive"
)

// AddCompetitionToTournamentUseCase handles adding competitions to tournaments
type AddCompetitionToTournamentUseCase struct {
	tournamentRepo  repositories.TournamentRepository
	competitionRepo repositories.CompetitionRepository
}

// NewAddCompetitionToTournamentUseCase creates a new instance
func NewAddCompetitionToTournamentUseCase(
	tournamentRepo repositories.TournamentRepository,
	competitionRepo repositories.CompetitionRepository,
) *AddCompetitionToTournamentUseCase {
	return &AddCompetitionToTournamentUseCase{
		tournamentRepo:  tournamentRepo,
		competitionRepo: competitionRepo,
	}
}

// Execute adds a competition to a tournament
// Authorization: Only tournament organizer or admins can add competitions
func (uc *AddCompetitionToTournamentUseCase) Execute(ctx context.Context, tournamentID, competitionID string, userID primitive.ObjectID, userRole string) (*dto.TournamentResponse, error) {
	// Parse tournament ID
	tournamentOID, err := primitive.ObjectIDFromHex(tournamentID)
	if err != nil {
		return nil, domainerrors.ErrInvalidInput
	}

	// Parse competition ID
	competitionOID, err := primitive.ObjectIDFromHex(competitionID)
	if err != nil {
		return nil, domainerrors.ErrInvalidInput
	}

	// Get tournament to verify ownership
	tournament, err := uc.tournamentRepo.FindByID(ctx, tournamentOID)
	if err != nil {
		return nil, err
	}

	// Authorization check: must be organizer or admin
	if userRole != "admin" && userRole != "verified_special" && tournament.OrganizerID != userID {
		return nil, domainerrors.ErrUnauthorized
	}

	// Verify competition exists
	competition, err := uc.competitionRepo.FindByID(ctx, competitionOID)
	if err != nil {
		return nil, err
	}

	// Verify competition discipline matches tournament sport type
	if competition.Discipline != tournament.SportType {
		return nil, domainerrors.ErrInvalidInput
	}

	// Check if competition is already added
	for _, existingCompID := range tournament.CompetitionIDs {
		if existingCompID == competitionOID {
			return nil, domainerrors.ErrDuplicateEntry
		}
	}

	// Add competition to tournament
	if err := uc.tournamentRepo.AddCompetition(ctx, tournamentOID, competitionOID); err != nil {
		return nil, err
	}

	// Get updated tournament
	updatedTournament, err := uc.tournamentRepo.FindByID(ctx, tournamentOID)
	if err != nil {
		return nil, err
	}

	// Convert to response
	return dto.ToTournamentResponse(updatedTournament), nil
}
