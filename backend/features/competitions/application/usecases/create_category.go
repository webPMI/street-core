package usecases

import (
	"context"

	"backend/features/competitions/application/dto"
	"backend/features/competitions/domain/entities"
	"backend/features/competitions/domain/repositories"

	"go.mongodb.org/mongo-driver/bson/primitive"
)

// CreateCategoryUseCase handles creating a new category
type CreateCategoryUseCase struct {
	categoryRepo    repositories.CategoryRepository
	competitionRepo repositories.CompetitionRepository
}

// NewCreateCategoryUseCase creates a new CreateCategoryUseCase
func NewCreateCategoryUseCase(categoryRepo repositories.CategoryRepository, competitionRepo repositories.CompetitionRepository) *CreateCategoryUseCase {
	return &CreateCategoryUseCase{
		categoryRepo:    categoryRepo,
		competitionRepo: competitionRepo,
	}
}

// Execute creates a new category for a competition
func (uc *CreateCategoryUseCase) Execute(ctx context.Context, competitionID string, req dto.CreateCategoryRequest) (*entities.Category, error) {
	// Parse competition ID
	compObjID, err := primitive.ObjectIDFromHex(competitionID)
	if err != nil {
		return nil, err
	}

	// Verify competition exists
	_, err = uc.competitionRepo.FindByID(ctx, compObjID)
	if err != nil {
		return nil, err
	}

	// Create new category entity
	category := entities.NewCategory(compObjID, req.Name)
	category.Description = req.Description
	category.StartTime = req.StartTime
	category.EndTime = req.EndTime
	category.Order = req.Order

	if req.MaxParticipants > 0 {
		category.MaxParticipants = req.MaxParticipants
	}
	if req.MinParticipants > 0 {
		category.MinParticipants = req.MinParticipants
	}

	// Convert scoring criteria if provided
	if req.ScoringCriteria != nil {
		scoringCriteria := req.ScoringCriteria.ToScoringCriteriaEntity()
		category.ScoringCriteria = &scoringCriteria
	}

	// Save category
	if err := uc.categoryRepo.Save(ctx, category); err != nil {
		return nil, err
	}

	return category, nil
}
