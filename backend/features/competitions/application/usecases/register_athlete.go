package usecases

import (
	"context"

	domainerrors "backend/features/competitions/domain/errors"
	"backend/features/competitions/domain/repositories"

	"go.mongodb.org/mongo-driver/bson/primitive"
)

// RegisterAthleteUseCase handles athlete registration for competitions
type RegisterAthleteUseCase struct {
	repo repositories.CompetitionRepository
}

// NewRegisterAthleteUseCase creates a new instance
func NewRegisterAthleteUseCase(repo repositories.CompetitionRepository) *RegisterAthleteUseCase {
	return &RegisterAthleteUseCase{
		repo: repo,
	}
}

// Execute registers an athlete for a competition
// Authorization: Authenticated users can register themselves
func (uc *RegisterAthleteUseCase) Execute(ctx context.Context, competitionID, athleteID string, userID primitive.ObjectID, userRole string) error {
	// Parse IDs
	compID, err := primitive.ObjectIDFromHex(competitionID)
	if err != nil {
		return domainerrors.ErrInvalidInput
	}

	athID, err := primitive.ObjectIDFromHex(athleteID)
	if err != nil {
		return domainerrors.ErrInvalidInput
	}

	// Fetch competition
	competition, err := uc.repo.FindByID(ctx, compID)
	if err != nil {
		return domainerrors.ErrCompetitionNotFound
	}

	// Check if registration is open
	if !competition.CanRegister() {
		return domainerrors.ErrRegistrationClosed
	}

	// Check if already registered
	if competition.IsAthleteRegistered(athID) {
		return domainerrors.ErrAlreadyRegistered
	}

	// Add athlete to competition
	if err := competition.AddAthlete(athID); err != nil {
		return err
	}

	// Update in repository
	if err := uc.repo.Update(ctx, competition); err != nil {
		return domainerrors.ErrDatabaseOperation
	}

	return nil
}

// Unregister removes an athlete from a competition
func (uc *RegisterAthleteUseCase) Unregister(ctx context.Context, competitionID, athleteID string, userID primitive.ObjectID, userRole string) error {
	// Parse IDs
	compID, err := primitive.ObjectIDFromHex(competitionID)
	if err != nil {
		return domainerrors.ErrInvalidInput
	}

	athID, err := primitive.ObjectIDFromHex(athleteID)
	if err != nil {
		return domainerrors.ErrInvalidInput
	}

	// Fetch competition
	competition, err := uc.repo.FindByID(ctx, compID)
	if err != nil {
		return domainerrors.ErrCompetitionNotFound
	}

	// Check if already registered
	if !competition.IsAthleteRegistered(athID) {
		return domainerrors.ErrNotRegistered
	}

	// Cannot unregister after competition has started
	if competition.Status != "upcoming" {
		return domainerrors.ErrCompetitionStarted
	}

	// Remove athlete from competition
	if err := competition.RemoveAthlete(athID); err != nil {
		return err
	}

	// Update in repository
	if err := uc.repo.Update(ctx, competition); err != nil {
		return domainerrors.ErrDatabaseOperation
	}

	return nil
}
