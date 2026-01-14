package usecases

import (
	"context"

	"backend/features/competitions/domain/entities"
	"backend/features/competitions/domain/repositories"

	"go.mongodb.org/mongo-driver/bson/primitive"
)

// AssignCategoryJudgeUseCase handles assigning judges to a category
type AssignCategoryJudgeUseCase struct {
	categoryRepo repositories.CategoryRepository
}

// NewAssignCategoryJudgeUseCase creates a new AssignCategoryJudgeUseCase
func NewAssignCategoryJudgeUseCase(categoryRepo repositories.CategoryRepository) *AssignCategoryJudgeUseCase {
	return &AssignCategoryJudgeUseCase{
		categoryRepo: categoryRepo,
	}
}

// AddJudge adds a judge to a category
func (uc *AssignCategoryJudgeUseCase) AddJudge(ctx context.Context, categoryID, judgeID string) error {
	// Parse IDs
	catObjID, err := primitive.ObjectIDFromHex(categoryID)
	if err != nil {
		return err
	}
	judgeObjID, err := primitive.ObjectIDFromHex(judgeID)
	if err != nil {
		return err
	}

	// Check if category exists
	category, err := uc.categoryRepo.FindByID(ctx, catObjID)
	if err != nil {
		return err
	}

	// Check if already a judge
	if category.IsJudge(judgeObjID) {
		return entities.ErrAlreadyJudge
	}

	return uc.categoryRepo.AddJudge(ctx, catObjID, judgeObjID)
}

// RemoveJudge removes a judge from a category
func (uc *AssignCategoryJudgeUseCase) RemoveJudge(ctx context.Context, categoryID, judgeID string) error {
	// Parse IDs
	catObjID, err := primitive.ObjectIDFromHex(categoryID)
	if err != nil {
		return err
	}
	judgeObjID, err := primitive.ObjectIDFromHex(judgeID)
	if err != nil {
		return err
	}

	// Check if category exists
	category, err := uc.categoryRepo.FindByID(ctx, catObjID)
	if err != nil {
		return err
	}

	// Check if judge exists in category
	if !category.IsJudge(judgeObjID) {
		return entities.ErrNotJudgeInCategory
	}

	return uc.categoryRepo.RemoveJudge(ctx, catObjID, judgeObjID)
}
