package usecases

import (
	"context"

	"backend/features/competitions/application/dto"
	"backend/features/competitions/domain/entities"
	"backend/features/competitions/domain/repositories"

	"go.mongodb.org/mongo-driver/bson/primitive"
)

// UpdateCategoryUseCase handles updating a category
type UpdateCategoryUseCase struct {
	categoryRepo repositories.CategoryRepository
}

// NewUpdateCategoryUseCase creates a new UpdateCategoryUseCase
func NewUpdateCategoryUseCase(categoryRepo repositories.CategoryRepository) *UpdateCategoryUseCase {
	return &UpdateCategoryUseCase{
		categoryRepo: categoryRepo,
	}
}

// Execute updates an existing category
func (uc *UpdateCategoryUseCase) Execute(ctx context.Context, categoryID string, req dto.UpdateCategoryRequest) (*entities.Category, error) {
	// Parse category ID
	catObjID, err := primitive.ObjectIDFromHex(categoryID)
	if err != nil {
		return nil, err
	}

	// Get existing category
	category, err := uc.categoryRepo.FindByID(ctx, catObjID)
	if err != nil {
		return nil, err
	}

	// Update fields if provided
	if req.Name != nil {
		category.Name = *req.Name
	}
	if req.Description != nil {
		category.Description = *req.Description
	}
	if req.MaxParticipants != nil {
		category.MaxParticipants = *req.MaxParticipants
	}
	if req.MinParticipants != nil {
		category.MinParticipants = *req.MinParticipants
	}
	if req.StartTime != nil {
		category.StartTime = req.StartTime
	}
	if req.EndTime != nil {
		category.EndTime = req.EndTime
	}
	if req.Status != nil {
		category.Status = *req.Status
	}
	if req.Order != nil {
		category.Order = *req.Order
	}
	if req.ScoringCriteria != nil {
		scoringCriteria := req.ScoringCriteria.ToScoringCriteriaEntity()
		category.ScoringCriteria = &scoringCriteria
	}

	// Save updates
	if err := uc.categoryRepo.Update(ctx, category); err != nil {
		return nil, err
	}

	return category, nil
}
