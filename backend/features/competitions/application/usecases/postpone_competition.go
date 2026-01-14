package usecases

import (
	"context"
	"log"

	"backend/features/competitions/domain/entities"
	domainerrors "backend/features/competitions/domain/errors"
	"backend/features/competitions/domain/repositories"

	"go.mongodb.org/mongo-driver/bson/primitive"
)

// PostponeCompetitionUseCase handles postponing a competition
type PostponeCompetitionUseCase struct {
	repo repositories.CompetitionRepository
}

// NewPostponeCompetitionUseCase creates a new postpone competition use case
func NewPostponeCompetitionUseCase(repo repositories.CompetitionRepository) *PostponeCompetitionUseCase {
	return &PostponeCompetitionUseCase{repo: repo}
}

// Execute postpones a competition
func (uc *PostponeCompetitionUseCase) Execute(
	ctx context.Context,
	competitionID string,
	userID primitive.ObjectID,
	userRole string,
) (*entities.Competition, error) {
	// Convert ID
	competitionOID, err := primitive.ObjectIDFromHex(competitionID)
	if err != nil {
		log.Printf("[PostponeCompetition] Invalid competition ID: %v", err)
		return nil, domainerrors.ErrInvalidInput
	}

	// Fetch competition
	competition, err := uc.repo.FindByID(ctx, competitionOID)
	if err != nil {
		log.Printf("[PostponeCompetition] Competition not found: %v", err)
		return nil, domainerrors.ErrCompetitionNotFound
	}

	// Authorization: Only owner or admin can postpone
	if !competition.IsOwner(userID) && userRole != "admin" {
		log.Printf("[PostponeCompetition] Unauthorized: user %s is not owner or admin", userID.Hex())
		return nil, domainerrors.ErrNotOwner
	}

	// Validate status - can only postpone upcoming or live competitions
	if competition.Status != entities.StatusUpcoming && competition.Status != entities.StatusLive {
		log.Printf("[PostponeCompetition] Invalid status: %s (expected upcoming or live)", competition.Status)
		return nil, domainerrors.ErrInvalidStatus
	}

	// Mark as postponed
	competition.MarkAsPostponed()

	// Update in database
	if err := uc.repo.Update(ctx, competition); err != nil {
		log.Printf("[PostponeCompetition] Failed to update: %v", err)
		return nil, domainerrors.ErrDatabaseOperation
	}

	log.Printf("[PostponeCompetition] Competition %s postponed successfully", competitionID)
	return competition, nil
}
