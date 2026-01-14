package usecases

import (
	"context"

	"backend/features/competitions/domain/entities"
	"backend/features/competitions/domain/repositories"

	"go.mongodb.org/mongo-driver/bson/primitive"
)

// ListCategoriesUseCase handles listing categories for a competition
type ListCategoriesUseCase struct {
	categoryRepo repositories.CategoryRepository
}

// NewListCategoriesUseCase creates a new ListCategoriesUseCase
func NewListCategoriesUseCase(categoryRepo repositories.CategoryRepository) *ListCategoriesUseCase {
	return &ListCategoriesUseCase{
		categoryRepo: categoryRepo,
	}
}

// Execute lists all categories for a competition
func (uc *ListCategoriesUseCase) Execute(ctx context.Context, competitionID string, page, limit int) ([]*entities.Category, int64, error) {
	// Parse competition ID
	compObjID, err := primitive.ObjectIDFromHex(competitionID)
	if err != nil {
		return nil, 0, err
	}

	// Apply defaults
	if page < 1 {
		page = 1
	}
	if limit < 1 {
		limit = 20
	}

	return uc.categoryRepo.FindByCompetitionID(ctx, compObjID, page, limit)
}
