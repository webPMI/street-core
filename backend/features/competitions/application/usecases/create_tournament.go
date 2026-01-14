package usecases

import (
	"context"

	"backend/features/competitions/application/dto"
	"backend/features/competitions/domain/entities"
	domainerrors "backend/features/competitions/domain/errors"
	"backend/features/competitions/domain/repositories"

	"go.mongodb.org/mongo-driver/bson/primitive"
)

// CreateTournamentUseCase handles tournament creation
type CreateTournamentUseCase struct {
	tournamentRepo repositories.TournamentRepository
}

// NewCreateTournamentUseCase creates a new instance
func NewCreateTournamentUseCase(tournamentRepo repositories.TournamentRepository) *CreateTournamentUseCase {
	return &CreateTournamentUseCase{
		tournamentRepo: tournamentRepo,
	}
}

// Execute creates a new tournament
// Authorization: Admin or Organizers can create tournaments
func (uc *CreateTournamentUseCase) Execute(ctx context.Context, req dto.CreateTournamentRequest, userID primitive.ObjectID, userRole string) (*dto.TournamentResponse, error) {
	// Authorization check
	if userRole != "admin" && userRole != "verified_special" && userRole != "organizer" {
		return nil, domainerrors.ErrUnauthorized
	}

	// Validate dates
	if req.StartDate.After(req.EndDate) {
		return nil, domainerrors.ErrInvalidInput
	}

	// Create tournament entity
	tournament := entities.NewTournament(
		req.Title,
		req.Description,
		userID,
		req.SportType,
		req.Discipline,
		req.Format,
	)

	// Set optional fields
	tournament.Category = req.Category

	// Set schedule
	tournament.Schedule = entities.TournamentSchedule{
		StartDate: req.StartDate,
		EndDate:   req.EndDate,
		Season:    req.Season,
		Year:      req.Year,
		TimeZone:  req.TimeZone,
		Venue:     req.Venue,
		Country:   req.Country,
	}

	// Set scoring system
	tournament.ScoringSystem = req.ScoringSystem
	tournament.ScoringConfig = entities.TournamentScoringConfig{
		PointsMap:       req.ScoringConfig.PointsMap,
		CountBestOf:     req.ScoringConfig.CountBestOf,
		CustomFormula:   req.ScoringConfig.CustomFormula,
		TimeAggregation: req.ScoringConfig.TimeAggregation,
		TieBreaker:      req.ScoringConfig.TieBreaker,
		MinimumRaces:    req.ScoringConfig.MinimumRaces,
		DropWorst:       req.ScoringConfig.DropWorst,
		Multiplier:      req.ScoringConfig.Multiplier,
	}

	// Set registration config
	tournament.Registration = entities.TournamentRegistrationConfig{
		MaxParticipants:          req.Registration.MaxParticipants,
		RegistrationDeadline:     req.Registration.RegistrationDeadline,
		RegistrationStatus:       entities.TournamentRegistrationOpen,
		AllowLateRegistration:    req.Registration.AllowLateRegistration,
		RequiresApproval:         req.Registration.RequiresApproval,
		EntryFee:                 req.Registration.EntryFee,
		Currency:                 req.Registration.Currency,
		AllowIndividualRaceEntry: req.Registration.AllowIndividualRaceEntry,
	}

	// Set media and other fields
	tournament.Prizes = req.Prizes
	tournament.Rules = req.Rules
	tournament.BannerUrl = req.BannerUrl
	tournament.PosterUrl = req.PosterUrl
	tournament.Tags = req.Tags
	tournament.IsPublic = req.IsPublic
	tournament.IsFeatured = req.IsFeatured

	// Validate tournament
	if err := tournament.Validate(); err != nil {
		return nil, err
	}

	// Save to repository
	if err := uc.tournamentRepo.Save(ctx, tournament); err != nil {
		return nil, err
	}

	// Convert to response
	return dto.ToTournamentResponse(tournament), nil
}
