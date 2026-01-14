package usecases

import (
	"context"
	"log"

	"backend/features/competitions/domain/entities"
	domainerrors "backend/features/competitions/domain/errors"
	"backend/features/competitions/domain/repositories"

	"go.mongodb.org/mongo-driver/bson/primitive"
)

// PublishResultsUseCase handles publishing competition results
type PublishResultsUseCase struct {
	repo repositories.CompetitionRepository
}

// NewPublishResultsUseCase creates a new publish results use case
func NewPublishResultsUseCase(repo repositories.CompetitionRepository) *PublishResultsUseCase {
	return &PublishResultsUseCase{repo: repo}
}

// Execute publishes competition results
func (uc *PublishResultsUseCase) Execute(
	ctx context.Context,
	competitionID string,
	userID primitive.ObjectID,
	userRole string,
) (*entities.Competition, error) {
	// Convert ID
	competitionOID, err := primitive.ObjectIDFromHex(competitionID)
	if err != nil {
		log.Printf("[PublishResults] Invalid competition ID: %v", err)
		return nil, domainerrors.ErrInvalidInput
	}

	// Fetch competition
	competition, err := uc.repo.FindByID(ctx, competitionOID)
	if err != nil {
		log.Printf("[PublishResults] Competition not found: %v", err)
		return nil, domainerrors.ErrCompetitionNotFound
	}

	// Authorization: Only owner or admin can publish results
	if !competition.IsOwner(userID) && userRole != "admin" {
		log.Printf("[PublishResults] Unauthorized: user %s is not owner or admin", userID.Hex())
		return nil, domainerrors.ErrNotOwner
	}

	// Validate status - can only publish results for completed or live competitions
	if competition.Status != entities.StatusCompleted && competition.Status != entities.StatusLive {
		log.Printf("[PublishResults] Invalid status: %s (expected completed or live)", competition.Status)
		return nil, domainerrors.ErrInvalidStatus
	}

	// Check if already published
	if competition.IsResultsPublished {
		log.Printf("[PublishResults] Results already published for competition %s", competitionID)
		return competition, nil // Return success if already published
	}

	// Publish results
	if err := competition.PublishResults(); err != nil {
		log.Printf("[PublishResults] Failed to publish: %v", err)
		return nil, err
	}

	// Update in database
	if err := uc.repo.Update(ctx, competition); err != nil {
		log.Printf("[PublishResults] Failed to update: %v", err)
		return nil, domainerrors.ErrDatabaseOperation
	}

	log.Printf("[PublishResults] Results published successfully for competition %s", competitionID)
	return competition, nil
}
