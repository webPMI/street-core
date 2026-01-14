package usecases

import (
	"context"
	"log"

	"backend/features/competitions/domain/entities"
	domainerrors "backend/features/competitions/domain/errors"
	"backend/features/competitions/domain/repositories"

	"go.mongodb.org/mongo-driver/bson/primitive"
)

// EndCompetitionUseCase handles ending a competition
type EndCompetitionUseCase struct {
	repo repositories.CompetitionRepository
}

// NewEndCompetitionUseCase creates a new end competition use case
func NewEndCompetitionUseCase(repo repositories.CompetitionRepository) *EndCompetitionUseCase {
	return &EndCompetitionUseCase{repo: repo}
}

// Execute ends a competition
func (uc *EndCompetitionUseCase) Execute(
	ctx context.Context,
	competitionID string,
	userID primitive.ObjectID,
	userRole string,
) (*entities.Competition, error) {
	// Convert ID
	competitionOID, err := primitive.ObjectIDFromHex(competitionID)
	if err != nil {
		log.Printf("[EndCompetition] Invalid competition ID: %v", err)
		return nil, domainerrors.ErrInvalidInput
	}

	// Fetch competition
	competition, err := uc.repo.FindByID(ctx, competitionOID)
	if err != nil {
		log.Printf("[EndCompetition] Competition not found: %v", err)
		return nil, domainerrors.ErrCompetitionNotFound
	}

	// Authorization: Only owner or admin can end
	if !competition.IsOwner(userID) && userRole != "admin" {
		log.Printf("[EndCompetition] Unauthorized: user %s is not owner or admin", userID.Hex())
		return nil, domainerrors.ErrNotOwner
	}

	// Validate status - can only end live competitions
	if competition.Status != entities.StatusLive {
		log.Printf("[EndCompetition] Invalid status: %s (expected live)", competition.Status)
		return nil, domainerrors.ErrInvalidStatus
	}

	// Mark as completed
	competition.MarkAsCompleted()

	// Update in database
	if err := uc.repo.Update(ctx, competition); err != nil {
		log.Printf("[EndCompetition] Failed to update: %v", err)
		return nil, domainerrors.ErrDatabaseOperation
	}

	log.Printf("[EndCompetition] Competition %s ended successfully", competitionID)
	return competition, nil
}
