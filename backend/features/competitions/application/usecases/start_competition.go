package usecases

import (
	"context"
	"log"

	"backend/features/competitions/domain/entities"
	domainerrors "backend/features/competitions/domain/errors"
	"backend/features/competitions/domain/repositories"

	"go.mongodb.org/mongo-driver/bson/primitive"
	"go.mongodb.org/mongo-driver/mongo"
)

// StartCompetitionUseCase handles starting a competition
type StartCompetitionUseCase struct {
	repo         repositories.CompetitionRepository
	categoryRepo repositories.CategoryRepository
	db           *mongo.Database
}

// NewStartCompetitionUseCase creates a new start competition use case
func NewStartCompetitionUseCase(
	repo repositories.CompetitionRepository,
	categoryRepo repositories.CategoryRepository,
	db *mongo.Database,
) *StartCompetitionUseCase {
	return &StartCompetitionUseCase{
		repo:         repo,
		categoryRepo: categoryRepo,
		db:           db,
	}
}

// Execute starts a competition
func (uc *StartCompetitionUseCase) Execute(
	ctx context.Context,
	competitionID string,
	userID primitive.ObjectID,
	userRole string,
) (*entities.Competition, error) {
	// Convert ID
	competitionOID, err := primitive.ObjectIDFromHex(competitionID)
	if err != nil {
		log.Printf("[StartCompetition] Invalid competition ID: %v", err)
		return nil, domainerrors.ErrInvalidInput
	}

	// Fetch competition
	competition, err := uc.repo.FindByID(ctx, competitionOID)
	if err != nil {
		log.Printf("[StartCompetition] Competition not found: %v", err)
		return nil, domainerrors.ErrCompetitionNotFound
	}

	// Authorization: Owner, Admin, or Head Judge can start
	if !competition.IsOwner(userID) && userRole != "admin" && !competition.IsHeadJudge(userID) {
		log.Printf("[StartCompetition] Unauthorized: user %s is not owner, admin, or head judge", userID.Hex())
		return nil, domainerrors.ErrNotOwner
	}

	// Validate status - can only start upcoming competitions
	if competition.Status != entities.StatusUpcoming {
		log.Printf("[StartCompetition] Invalid status: %s (expected upcoming)", competition.Status)
		return nil, domainerrors.ErrInvalidStatus
	}

	// Validate minimum participants
	if competition.Registration.MinParticipants > 0 &&
		competition.Registration.CurrentParticipants < competition.Registration.MinParticipants {
		log.Printf("[StartCompetition] Not enough participants: %d (required: %d)",
			competition.Registration.CurrentParticipants,
			competition.Registration.MinParticipants)
		return nil, domainerrors.ErrInsufficientPermissions // Using this for "insufficient participants"
	}

	// Validate categories are configured
	categories, categoriesCount, err := uc.categoryRepo.FindByCompetitionID(ctx, competitionOID, 1, 100)
	if err != nil {
		log.Printf("[StartCompetition] Failed to fetch categories: %v", err)
		return nil, domainerrors.ErrDatabaseOperation
	}

	if categoriesCount == 0 {
		log.Printf("[StartCompetition] No categories configured")
		return nil, entities.ErrNoCategoriesConfigured
	}

	// Validate at least one category has scoring criteria configured
	hasCriteriaConfigured := false
	for _, category := range categories {
		if category.ScoringCriteria != nil && len(category.ScoringCriteria.Criteria) > 0 {
			hasCriteriaConfigured = true
			break
		}
	}

	if !hasCriteriaConfigured {
		log.Printf("[StartCompetition] No categories have scoring criteria configured")
		return nil, entities.ErrCategoriesWithoutCriteria
	}

	// Close registration
	competition.CloseRegistration()

	// Mark as live
	competition.MarkAsLive()

	// Update in database
	if err := uc.repo.Update(ctx, competition); err != nil {
		log.Printf("[StartCompetition] Failed to update: %v", err)
		return nil, domainerrors.ErrDatabaseOperation
	}

	// Create notifications asynchronously (non-blocking)
	go uc.createStartNotifications(context.Background(), competition)

	log.Printf("[StartCompetition] Competition %s started successfully", competitionID)
	return competition, nil
}

// createStartNotifications creates notifications for participants and judges
// This runs in the background and should not block the main operation
func (uc *StartCompetitionUseCase) createStartNotifications(ctx context.Context, competition *entities.Competition) {
	// TODO: Implement notification creation
	// For now, just log
	log.Printf("[StartCompetition] Creating notifications for competition %s", competition.ID.Hex())
	log.Printf("[StartCompetition] - Notifying %d participants", len(competition.Registration.RegisteredAthleteIDs))
	log.Printf("[StartCompetition] - Notifying %d judges", len(competition.JudgeIDs))

	// Future implementation:
	// 1. Create "competition_started" notifications for all registered athletes
	// 2. Create "competition_ready_to_judge" notifications for all judges
	// Use the notification service from profile module
}
