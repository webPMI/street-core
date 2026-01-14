package middlewares

import (
	"context"
	"fmt"

	"backend/features/competitions/domain/repositories"
	"backend/pkg/errors"

	"go.mongodb.org/mongo-driver/bson/primitive"
)

// CompetitionOwnershipValidator implements the middlewares.OwnershipValidator interface
// for competition resources.
//
// 🔒 SECURITY (CRITICAL-1 FIX): Validates that a user owns a competition before
// allowing update/delete operations. This provides defense-in-depth by checking
// ownership at the route layer BEFORE reaching the use case layer.
type CompetitionOwnershipValidator struct {
	competitionRepo repositories.CompetitionRepository
}

// NewCompetitionOwnershipValidator creates a new validator
func NewCompetitionOwnershipValidator(repo repositories.CompetitionRepository) *CompetitionOwnershipValidator {
	return &CompetitionOwnershipValidator{
		competitionRepo: repo,
	}
}

// CheckOwnership implements middlewares.OwnershipValidator
// Returns nil if user owns the competition, error otherwise
func (v *CompetitionOwnershipValidator) CheckOwnership(resourceID string, userID string) error {
	// Parse resource ID (competition ID)
	compID, err := primitive.ObjectIDFromHex(resourceID)
	if err != nil {
		return fmt.Errorf("invalid competition ID")
	}

	// Parse user ID
	userObjID, err := primitive.ObjectIDFromHex(userID)
	if err != nil {
		return fmt.Errorf("invalid user ID")
	}

	// Load competition from database
	competition, err := v.competitionRepo.FindByID(context.Background(), compID)
	if err != nil {
		return fmt.Errorf("competition not found")
	}

	// Check if user is the organizer
	if !competition.IsOwner(userObjID) {
		return errors.ErrPermissionDenied()
	}

	return nil
}
