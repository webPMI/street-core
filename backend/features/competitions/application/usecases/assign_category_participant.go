package usecases

import (
	"context"

	"backend/features/competitions/domain/entities"
	"backend/features/competitions/domain/repositories"

	"go.mongodb.org/mongo-driver/bson/primitive"
)

// AssignCategoryParticipantUseCase handles assigning participants to a category
type AssignCategoryParticipantUseCase struct {
	categoryRepo repositories.CategoryRepository
}

// NewAssignCategoryParticipantUseCase creates a new AssignCategoryParticipantUseCase
func NewAssignCategoryParticipantUseCase(categoryRepo repositories.CategoryRepository) *AssignCategoryParticipantUseCase {
	return &AssignCategoryParticipantUseCase{
		categoryRepo: categoryRepo,
	}
}

// AddParticipant adds a participant to a category
func (uc *AssignCategoryParticipantUseCase) AddParticipant(ctx context.Context, categoryID, participantID string) error {
	// Parse IDs
	catObjID, err := primitive.ObjectIDFromHex(categoryID)
	if err != nil {
		return err
	}
	partObjID, err := primitive.ObjectIDFromHex(participantID)
	if err != nil {
		return err
	}

	// Check if category exists and is not full
	category, err := uc.categoryRepo.FindByID(ctx, catObjID)
	if err != nil {
		return err
	}

	// Check if already a participant
	if category.IsParticipant(partObjID) {
		return entities.ErrAlreadyInCategory
	}

	// Check if category is full
	if category.MaxParticipants > 0 && category.CurrentParticipants >= category.MaxParticipants {
		return entities.ErrCategoryFull
	}

	return uc.categoryRepo.AddParticipant(ctx, catObjID, partObjID)
}

// RemoveParticipant removes a participant from a category
func (uc *AssignCategoryParticipantUseCase) RemoveParticipant(ctx context.Context, categoryID, participantID string) error {
	// Parse IDs
	catObjID, err := primitive.ObjectIDFromHex(categoryID)
	if err != nil {
		return err
	}
	partObjID, err := primitive.ObjectIDFromHex(participantID)
	if err != nil {
		return err
	}

	// Check if category exists
	category, err := uc.categoryRepo.FindByID(ctx, catObjID)
	if err != nil {
		return err
	}

	// Check if participant exists in category
	if !category.IsParticipant(partObjID) {
		return entities.ErrNotInCategory
	}

	return uc.categoryRepo.RemoveParticipant(ctx, catObjID, partObjID)
}
