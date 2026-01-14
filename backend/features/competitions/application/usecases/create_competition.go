package usecases

import (
	"context"

	"backend/features/competitions/application/dto"
	"backend/features/competitions/domain/entities"
	domainerrors "backend/features/competitions/domain/errors"
	"backend/features/competitions/domain/repositories"

	"go.mongodb.org/mongo-driver/bson/primitive"
)

// CreateCompetitionUseCase handles competition creation
type CreateCompetitionUseCase struct {
	repo repositories.CompetitionRepository
}

// NewCreateCompetitionUseCase creates a new instance
func NewCreateCompetitionUseCase(repo repositories.CompetitionRepository) *CreateCompetitionUseCase {
	return &CreateCompetitionUseCase{
		repo: repo,
	}
}

// Execute creates a new competition
// Authorization: Admin or Verified Special users can create competitions
func (uc *CreateCompetitionUseCase) Execute(ctx context.Context, req dto.CreateCompetitionRequest, userID primitive.ObjectID, userRole string) (*dto.CompetitionResponse, error) {
	// Authorization check: Only Admin or special users can create competitions
	// For now, we allow any authenticated user - in production this should check roles
	if userRole != "admin" && userRole != "verified_special" && userRole != "organizer" {
		return nil, domainerrors.ErrUnauthorized
	}

	// Parse optional ObjectIDs
	var eventID, clubID primitive.ObjectID
	var err error

	if req.EventID != "" {
		eventID, err = primitive.ObjectIDFromHex(req.EventID)
		if err != nil {
			return nil, domainerrors.ErrInvalidInput
		}
	}

	if req.ClubID != "" {
		clubID, err = primitive.ObjectIDFromHex(req.ClubID)
		if err != nil {
			return nil, domainerrors.ErrInvalidInput
		}
	}

	// Create competition entity
	competition := entities.NewCompetition(
		req.Title,
		req.Description,
		userID,
		req.CompetitionType,
		req.Format,
		req.Discipline,
	)

	// Set optional fields
	if !eventID.IsZero() {
		competition.EventID = eventID
	}
	if !clubID.IsZero() {
		competition.ClubID = clubID
	}
	competition.Category = req.Category

	// Set schedule
	competition.Schedule = req.Schedule.ToScheduleEntity()

	// Set registration
	if req.Registration.MaxParticipants > 0 || req.Registration.MinParticipants > 0 {
		registration := req.Registration.ToRegistrationEntity()
		competition.Registration = registration
	}

	// Set scoring criteria
	competition.ScoringCriteria = req.ScoringCriteria.ToScoringCriteriaEntity()

	// Set optional values
	if req.RequiredJudges > 0 {
		competition.RequiredJudges = req.RequiredJudges
	}
	if req.TotalRounds > 0 {
		competition.TotalRounds = req.TotalRounds
	}
	competition.Rules = req.Rules
	competition.BannerUrl = req.BannerUrl
	competition.ImageUrls = req.ImageUrls
	competition.Tags = req.Tags

	// Validate
	if err := competition.Validate(); err != nil {
		return nil, err
	}

	// Save to repository
	if err := uc.repo.Save(ctx, competition); err != nil {
		return nil, domainerrors.ErrDatabaseOperation
	}

	// Convert to response DTO
	response := dto.ToCompetitionResponse(competition)
	return &response, nil
}
