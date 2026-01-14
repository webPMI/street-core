package usecases

import (
	"context"

	"backend/features/competitions/domain/repositories"

	"go.mongodb.org/mongo-driver/bson/primitive"
)

// DeleteCategoryUseCase handles deleting a category
type DeleteCategoryUseCase struct {
	categoryRepo repositories.CategoryRepository
}

// NewDeleteCategoryUseCase creates a new DeleteCategoryUseCase
func NewDeleteCategoryUseCase(categoryRepo repositories.CategoryRepository) *DeleteCategoryUseCase {
	return &DeleteCategoryUseCase{
		categoryRepo: categoryRepo,
	}
}

// Execute deletes a category by ID
func (uc *DeleteCategoryUseCase) Execute(ctx context.Context, categoryID string) error {
	// Parse category ID
	catObjID, err := primitive.ObjectIDFromHex(categoryID)
	if err != nil {
		return err
	}

	return uc.categoryRepo.Delete(ctx, catObjID)
}
