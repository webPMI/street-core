package usecases

import (
	"context"

	"backend/features/competitions/application/dto"
	domainerrors "backend/features/competitions/domain/errors"
	"backend/features/competitions/domain/repositories"

	"go.mongodb.org/mongo-driver/bson/primitive"
)

// UpdateCompetitionUseCase handles competition updates
type UpdateCompetitionUseCase struct {
	repo repositories.CompetitionRepository
}

// NewUpdateCompetitionUseCase creates a new instance
func NewUpdateCompetitionUseCase(repo repositories.CompetitionRepository) *UpdateCompetitionUseCase {
	return &UpdateCompetitionUseCase{
		repo: repo,
	}
}

// Execute updates a competition
// Authorization: Only competition owner or Admin
func (uc *UpdateCompetitionUseCase) Execute(ctx context.Context, competitionID string, req dto.UpdateCompetitionRequest, userID primitive.ObjectID, userRole string) (*dto.CompetitionResponse, error) {
	// Parse competition ID
	id, err := primitive.ObjectIDFromHex(competitionID)
	if err != nil {
		return nil, domainerrors.ErrInvalidInput
	}

	// Fetch existing competition
	competition, err := uc.repo.FindByID(ctx, id)
	if err != nil {
		return nil, domainerrors.ErrCompetitionNotFound
	}

	// Authorization check: Only owner or admin can update
	if userRole != "admin" && !competition.IsOwner(userID) {
		return nil, domainerrors.ErrNotOwner
	}

	// Cannot modify competition once it has started (except admin)
	if competition.Status != "upcoming" && userRole != "admin" {
		return nil, domainerrors.ErrCompetitionStarted
	}

	// Update fields if provided
	if req.Title != "" {
		competition.Title = req.Title
	}
	if req.Description != "" {
		competition.Description = req.Description
	}
	if req.CompetitionType != "" {
		competition.CompetitionType = req.CompetitionType
	}
	if req.Format != "" {
		competition.Format = req.Format
	}
	if req.Discipline != "" {
		competition.Discipline = req.Discipline
	}
	if req.Category != "" {
		competition.Category = req.Category
	}
	if req.Schedule != nil {
		competition.Schedule = req.Schedule.ToScheduleEntity()
	}
	if req.Registration != nil {
		// Update registration but preserve current participants count
		currentCount := competition.Registration.CurrentParticipants
		registeredIDs := competition.Registration.RegisteredAthleteIDs
		waitlistIDs := competition.Registration.WaitlistAthleteIDs
		participantStatus := competition.Registration.ParticipantStatus

		competition.Registration = req.Registration.ToRegistrationEntity()
		competition.Registration.CurrentParticipants = currentCount
		competition.Registration.RegisteredAthleteIDs = registeredIDs
		competition.Registration.WaitlistAthleteIDs = waitlistIDs
		competition.Registration.ParticipantStatus = participantStatus
	}
	if req.ScoringCriteria != nil {
		competition.ScoringCriteria = req.ScoringCriteria.ToScoringCriteriaEntity()
	}
	if req.RequiredJudges != nil {
		competition.RequiredJudges = *req.RequiredJudges
	}
	if req.TotalRounds != nil {
		competition.TotalRounds = *req.TotalRounds
	}
	if req.Rules != nil {
		competition.Rules = *req.Rules
	}
	if req.BannerUrl != nil {
		competition.BannerUrl = *req.BannerUrl
	}
	if len(req.ImageUrls) > 0 {
		competition.ImageUrls = req.ImageUrls
	}
	if len(req.Tags) > 0 {
		competition.Tags = req.Tags
	}

	// Prepare for update
	competition.PrepareForUpdate()

	// Validate
	if err := competition.Validate(); err != nil {
		return nil, err
	}

	// Update in repository
	if err := uc.repo.Update(ctx, competition); err != nil {
		return nil, domainerrors.ErrDatabaseOperation
	}

	// Convert to response DTO
	response := dto.ToCompetitionResponse(competition)
	return &response, nil
}
