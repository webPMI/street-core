package usecases

import (
	"context"

	domainerrors "backend/features/competitions/domain/errors"
	"backend/features/competitions/domain/repositories"

	"go.mongodb.org/mongo-driver/bson/primitive"
)

// DeleteCompetitionUseCase handles competition deletion
type DeleteCompetitionUseCase struct {
	repo repositories.CompetitionRepository
}

// NewDeleteCompetitionUseCase creates a new instance
func NewDeleteCompetitionUseCase(repo repositories.CompetitionRepository) *DeleteCompetitionUseCase {
	return &DeleteCompetitionUseCase{
		repo: repo,
	}
}

// Execute deletes a competition
// Authorization: Only competition owner or Admin
func (uc *DeleteCompetitionUseCase) Execute(ctx context.Context, competitionID string, userID primitive.ObjectID, userRole string) error {
	// Parse competition ID
	id, err := primitive.ObjectIDFromHex(competitionID)
	if err != nil {
		return domainerrors.ErrInvalidInput
	}

	// Fetch existing competition to check ownership
	competition, err := uc.repo.FindByID(ctx, id)
	if err != nil {
		return domainerrors.ErrCompetitionNotFound
	}

	// Authorization check: Only owner or admin can delete
	if userRole != "admin" && !competition.IsOwner(userID) {
		return domainerrors.ErrNotOwner
	}

	// Cannot delete competition once it has started (except admin)
	if competition.Status != "upcoming" && userRole != "admin" {
		return domainerrors.ErrCompetitionStarted
	}

	// Delete from repository
	if err := uc.repo.Delete(ctx, id); err != nil {
		return domainerrors.ErrDatabaseOperation
	}

	return nil
}
