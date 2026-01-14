package usecases

import (
	"context"

	"backend/features/competitions/domain/entities"
	"backend/features/competitions/domain/repositories"

	"go.mongodb.org/mongo-driver/bson/primitive"
)

// GetCategoryUseCase handles getting a single category
type GetCategoryUseCase struct {
	categoryRepo repositories.CategoryRepository
}

// NewGetCategoryUseCase creates a new GetCategoryUseCase
func NewGetCategoryUseCase(categoryRepo repositories.CategoryRepository) *GetCategoryUseCase {
	return &GetCategoryUseCase{
		categoryRepo: categoryRepo,
	}
}

// Execute retrieves a category by ID
func (uc *GetCategoryUseCase) Execute(ctx context.Context, categoryID string) (*entities.Category, error) {
	// Parse category ID
	catObjID, err := primitive.ObjectIDFromHex(categoryID)
	if err != nil {
		return nil, err
	}

	return uc.categoryRepo.FindByID(ctx, catObjID)
}
