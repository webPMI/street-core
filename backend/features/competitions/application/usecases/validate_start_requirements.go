package usecases

import (
	"context"
	"log"

	"backend/features/competitions/domain/entities"
	domainerrors "backend/features/competitions/domain/errors"
	"backend/features/competitions/domain/repositories"

	"go.mongodb.org/mongo-driver/bson/primitive"
)

// StartValidationResult contains validation results for starting a competition
type StartValidationResult struct {
	CanStart               bool     `json:"canStart"`
	Errors                 []string `json:"errors"`
	Warnings               []string `json:"warnings"`
	HasCategories          bool     `json:"hasCategories"`
	CategoriesCount        int64    `json:"categoriesCount"`
	CategoriesWithCriteria int64    `json:"categoriesWithCriteria"`
	MinParticipants        int      `json:"minParticipants"`
	CurrentParticipants    int      `json:"currentParticipants"`
	RequiredJudges         int      `json:"requiredJudges"`
	CurrentJudges          int      `json:"currentJudges"`
	Status                 string   `json:"status"`
}

// ValidateStartRequirementsUseCase handles validation of competition start requirements
type ValidateStartRequirementsUseCase struct {
	competitionRepo repositories.CompetitionRepository
	categoryRepo    repositories.CategoryRepository
}

// NewValidateStartRequirementsUseCase creates a new validation use case
func NewValidateStartRequirementsUseCase(
	competitionRepo repositories.CompetitionRepository,
	categoryRepo repositories.CategoryRepository,
) *ValidateStartRequirementsUseCase {
	return &ValidateStartRequirementsUseCase{
		competitionRepo: competitionRepo,
		categoryRepo:    categoryRepo,
	}
}

// Execute validates if a competition can be started
func (uc *ValidateStartRequirementsUseCase) Execute(
	ctx context.Context,
	competitionID string,
) (*StartValidationResult, error) {
	// Convert ID
	competitionOID, err := primitive.ObjectIDFromHex(competitionID)
	if err != nil {
		log.Printf("[ValidateStartRequirements] Invalid competition ID: %v", err)
		return nil, domainerrors.ErrInvalidInput
	}

	// Fetch competition
	competition, err := uc.competitionRepo.FindByID(ctx, competitionOID)
	if err != nil {
		log.Printf("[ValidateStartRequirements] Competition not found: %v", err)
		return nil, domainerrors.ErrCompetitionNotFound
	}

	result := &StartValidationResult{
		CanStart:            true, // Start optimistic
		Errors:              []string{},
		Warnings:            []string{},
		MinParticipants:     competition.Registration.MinParticipants,
		CurrentParticipants: competition.Registration.CurrentParticipants,
		RequiredJudges:      competition.RequiredJudges,
		CurrentJudges:       len(competition.JudgeIDs),
		Status:              competition.Status,
	}

	// Validation 1: Status must be "upcoming"
	if competition.Status != entities.StatusUpcoming {
		result.Errors = append(result.Errors, "error.competition.not.upcoming")
		result.CanStart = false
	}

	// Validation 2: Minimum participants check
	if competition.Registration.MinParticipants > 0 &&
		competition.Registration.CurrentParticipants < competition.Registration.MinParticipants {
		result.Errors = append(result.Errors, "error.insufficient.participants")
		result.CanStart = false
	}

	// Validation 3: Categories must be configured
	categories, categoriesCount, err := uc.categoryRepo.FindByCompetitionID(ctx, competitionOID, 1, 100)
	if err != nil {
		log.Printf("[ValidateStartRequirements] Failed to fetch categories: %v", err)
		// Non-blocking error - continue with validation
		result.Warnings = append(result.Warnings, "warning.could.not.check.categories")
	} else {
		result.CategoriesCount = categoriesCount
		result.HasCategories = categoriesCount > 0

		if categoriesCount == 0 {
			result.Errors = append(result.Errors, "error.no.categories.configured")
			result.CanStart = false
		} else {
			// Validation 4: At least one category must have scoring criteria configured
			categoriesWithCriteria := int64(0)
			for _, category := range categories {
				if category.ScoringCriteria != nil && len(category.ScoringCriteria.Criteria) > 0 {
					categoriesWithCriteria++
				}
			}

			result.CategoriesWithCriteria = categoriesWithCriteria

			if categoriesWithCriteria == 0 {
				result.Errors = append(result.Errors, "error.no.criteria.configured")
				result.CanStart = false
			} else if categoriesWithCriteria < categoriesCount {
				// Some categories have criteria, but not all
				result.Warnings = append(result.Warnings, "warning.some.categories.without.criteria")
			}
		}
	}

	// Warning: Judges check (non-blocking)
	if competition.RequiredJudges > 0 && len(competition.JudgeIDs) < competition.RequiredJudges {
		result.Warnings = append(result.Warnings, "warning.insufficient.judges")
	}

	log.Printf("[ValidateStartRequirements] Validation complete: canStart=%v, errors=%d, warnings=%d",
		result.CanStart, len(result.Errors), len(result.Warnings))

	return result, nil
}
