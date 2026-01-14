package usecases

import (
	"context"

	"backend/features/competitions/domain/entities"
	"backend/features/competitions/domain/repositories"

	"go.mongodb.org/mongo-driver/bson/primitive"
)

// GetMyCompetitionsUseCase handles retrieving competitions for an authenticated user
type GetMyCompetitionsUseCase struct {
	competitionRepo repositories.CompetitionRepository
}

// NewGetMyCompetitionsUseCase creates a new GetMyCompetitionsUseCase
func NewGetMyCompetitionsUseCase(competitionRepo repositories.CompetitionRepository) *GetMyCompetitionsUseCase {
	return &GetMyCompetitionsUseCase{
		competitionRepo: competitionRepo,
	}
}

// Execute retrieves competitions where the user is registered as an athlete
func (uc *GetMyCompetitionsUseCase) Execute(ctx context.Context, userID primitive.ObjectID, page, limit int) ([]*entities.Competition, int64, error) {
	return uc.competitionRepo.FindByAthleteID(ctx, userID, page, limit)
}

// ExecuteAsOrganizer retrieves competitions where the user is the organizer
func (uc *GetMyCompetitionsUseCase) ExecuteAsOrganizer(ctx context.Context, userID primitive.ObjectID, page, limit int) ([]*entities.Competition, int64, error) {
	return uc.competitionRepo.FindByOrganizerID(ctx, userID, page, limit)
}

// ExecuteAsJudge retrieves competitions where the user is a judge
func (uc *GetMyCompetitionsUseCase) ExecuteAsJudge(ctx context.Context, userID primitive.ObjectID, page, limit int) ([]*entities.Competition, int64, error) {
	filters := map[string]interface{}{
		"judgeIds": userID,
	}
	return uc.competitionRepo.FindAll(ctx, page, limit, filters)
}
