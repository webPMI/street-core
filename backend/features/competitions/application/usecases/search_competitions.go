package usecases

import (
	"context"
	"time"

	"backend/features/competitions/application/dto"
	"backend/features/competitions/domain/entities"
	"backend/features/competitions/domain/repositories"

	"go.mongodb.org/mongo-driver/bson/primitive"
)

// SearchFilters represents advanced search filters
type SearchFilters struct {
	Query         string
	Discipline    string
	CompetitionType string
	Status        string
	ClubID        string
	City          string
	Country       string
	DateFrom      *time.Time
	DateTo        *time.Time
	IsFeatured    bool
	Tags          []string
}

// SearchCompetitionsUseCase handles advanced search and featured competitions
type SearchCompetitionsUseCase struct {
	repo repositories.CompetitionRepository
}

// NewSearchCompetitionsUseCase creates a new SearchCompetitionsUseCase
func NewSearchCompetitionsUseCase(repo repositories.CompetitionRepository) *SearchCompetitionsUseCase {
	return &SearchCompetitionsUseCase{
		repo: repo,
	}
}

// Execute performs an advanced search
func (uc *SearchCompetitionsUseCase) Execute(ctx context.Context, filters SearchFilters, page, limit int) ([]dto.CompetitionResponse, int64, error) {
	// Apply defaults
	if page < 1 {
		page = 1
	}
	if limit < 1 {
		limit = 20
	}
	if limit > 100 {
		limit = 100
	}

	// Build filter map
	filterMap := make(map[string]interface{})

	if filters.Query != "" {
		filterMap["search"] = filters.Query
	}
	if filters.Discipline != "" {
		filterMap["discipline"] = filters.Discipline
	}
	if filters.CompetitionType != "" {
		filterMap["competitionType"] = filters.CompetitionType
	}
	if filters.Status != "" {
		filterMap["status"] = filters.Status
	}
	if filters.ClubID != "" {
		if oid, err := primitive.ObjectIDFromHex(filters.ClubID); err == nil {
			filterMap["clubId"] = oid
		}
	}
	if filters.City != "" {
		filterMap["schedule.city"] = filters.City
	}
	if filters.Country != "" {
		filterMap["schedule.country"] = filters.Country
	}
	if filters.IsFeatured {
		filterMap["isFeatured"] = true
	}
	if len(filters.Tags) > 0 {
		filterMap["tags"] = filters.Tags
	}

	// Date range filters
	if filters.DateFrom != nil || filters.DateTo != nil {
		dateFilter := make(map[string]interface{})
		if filters.DateFrom != nil {
			dateFilter["$gte"] = *filters.DateFrom
		}
		if filters.DateTo != nil {
			dateFilter["$lte"] = *filters.DateTo
		}
		filterMap["schedule.startDate"] = dateFilter
	}

	// Execute search
	competitions, total, err := uc.repo.FindAll(ctx, page, limit, filterMap)
	if err != nil {
		return nil, 0, err
	}

	// Convert to response DTOs
	responses := make([]dto.CompetitionResponse, len(competitions))
	for i, comp := range competitions {
		responses[i] = dto.ToCompetitionResponse(comp)
	}

	return responses, total, nil
}

// ExecuteFeatured retrieves featured competitions
func (uc *SearchCompetitionsUseCase) ExecuteFeatured(ctx context.Context, limit int) ([]dto.CompetitionResponse, error) {
	if limit < 1 {
		limit = 10
	}
	if limit > 50 {
		limit = 50
	}

	// Only get active/upcoming featured competitions
	filters := map[string]interface{}{
		"isFeatured": true,
		"status": map[string]interface{}{
			"$in": []string{entities.StatusUpcoming, entities.StatusLive},
		},
	}

	competitions, _, err := uc.repo.FindAll(ctx, 1, limit, filters)
	if err != nil {
		return nil, err
	}

	// Convert to response DTOs
	responses := make([]dto.CompetitionResponse, len(competitions))
	for i, comp := range competitions {
		responses[i] = dto.ToCompetitionResponse(comp)
	}

	return responses, nil
}

// ExecuteNearby finds competitions near a location (simplified - uses country/city)
func (uc *SearchCompetitionsUseCase) ExecuteNearby(ctx context.Context, country, city string, page, limit int) ([]dto.CompetitionResponse, int64, error) {
	if page < 1 {
		page = 1
	}
	if limit < 1 {
		limit = 20
	}

	filters := map[string]interface{}{
		"status": map[string]interface{}{
			"$in": []string{entities.StatusUpcoming, entities.StatusLive},
		},
	}

	if country != "" {
		filters["schedule.country"] = country
	}
	if city != "" {
		filters["schedule.city"] = city
	}

	competitions, total, err := uc.repo.FindAll(ctx, page, limit, filters)
	if err != nil {
		return nil, 0, err
	}

	// Convert to response DTOs
	responses := make([]dto.CompetitionResponse, len(competitions))
	for i, comp := range competitions {
		responses[i] = dto.ToCompetitionResponse(comp)
	}

	return responses, total, nil
}
