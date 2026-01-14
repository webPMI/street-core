package dto

import (
	"time"

	"backend/features/competitions/domain/entities"
)

// CreateCategoryRequest represents the request to create a category
type CreateCategoryRequest struct {
	Name            string             `json:"name" binding:"required,min=2,max=100"`
	Description     string             `json:"description,omitempty"`
	MaxParticipants int                `json:"maxParticipants"`
	MinParticipants int                `json:"minParticipants"`
	ScoringCriteria *ScoringCriteriaDTO `json:"scoringCriteria,omitempty"`
	StartTime       *time.Time         `json:"startTime,omitempty"`
	EndTime         *time.Time         `json:"endTime,omitempty"`
	Order           int                `json:"order"`
}

// UpdateCategoryRequest represents the request to update a category
type UpdateCategoryRequest struct {
	Name            *string            `json:"name,omitempty" binding:"omitempty,min=2,max=100"`
	Description     *string            `json:"description,omitempty"`
	MaxParticipants *int               `json:"maxParticipants,omitempty"`
	MinParticipants *int               `json:"minParticipants,omitempty"`
	ScoringCriteria *ScoringCriteriaDTO `json:"scoringCriteria,omitempty"`
	StartTime       *time.Time         `json:"startTime,omitempty"`
	EndTime         *time.Time         `json:"endTime,omitempty"`
	Status          *string            `json:"status,omitempty" binding:"omitempty,oneof=active inactive closed"`
	Order           *int               `json:"order,omitempty"`
}

// AssignParticipantRequest represents the request to assign a participant to a category
type AssignParticipantRequest struct {
	ParticipantID string `json:"participantId" binding:"required"`
}

// AssignJudgeRequest represents the request to assign a judge to a category
type AssignJudgeRequest struct {
	JudgeID string `json:"judgeId" binding:"required"`
}

// CategoryResponse represents the response for a category
type CategoryResponse struct {
	ID                  string              `json:"id"`
	CompetitionID       string              `json:"competitionId"`
	Name                string              `json:"name"`
	Description         string              `json:"description,omitempty"`
	MaxParticipants     int                 `json:"maxParticipants"`
	MinParticipants     int                 `json:"minParticipants"`
	CurrentParticipants int                 `json:"currentParticipants"`
	ParticipantIDs      []string            `json:"participantIds,omitempty"`
	JudgeIDs            []string            `json:"judgeIds,omitempty"`
	ScoringCriteria     *ScoringCriteriaDTO `json:"scoringCriteria,omitempty"`
	StartTime           *time.Time          `json:"startTime,omitempty"`
	EndTime             *time.Time          `json:"endTime,omitempty"`
	Status              string              `json:"status"`
	Order               int                 `json:"order"`
	CreatedAt           time.Time           `json:"createdAt"`
	UpdatedAt           time.Time           `json:"updatedAt"`
}

// ToCategoryResponse converts a Category entity to CategoryResponse DTO
func ToCategoryResponse(category *entities.Category) CategoryResponse {
	participantIDs := make([]string, len(category.ParticipantIDs))
	for i, id := range category.ParticipantIDs {
		participantIDs[i] = id.Hex()
	}

	judgeIDs := make([]string, len(category.JudgeIDs))
	for i, id := range category.JudgeIDs {
		judgeIDs[i] = id.Hex()
	}

	response := CategoryResponse{
		ID:                  category.ID.Hex(),
		CompetitionID:       category.CompetitionID.Hex(),
		Name:                category.Name,
		Description:         category.Description,
		MaxParticipants:     category.MaxParticipants,
		MinParticipants:     category.MinParticipants,
		CurrentParticipants: category.CurrentParticipants,
		ParticipantIDs:      participantIDs,
		JudgeIDs:            judgeIDs,
		StartTime:           category.StartTime,
		EndTime:             category.EndTime,
		Status:              category.Status,
		Order:               category.Order,
		CreatedAt:           category.CreatedAt,
		UpdatedAt:           category.UpdatedAt,
	}

	if category.ScoringCriteria != nil {
		criteriaDTO := FromScoringCriteriaEntity(*category.ScoringCriteria)
		response.ScoringCriteria = &criteriaDTO
	}

	return response
}

// ToCategoryResponseList converts a list of Category entities to CategoryResponse DTOs
func ToCategoryResponseList(categories []*entities.Category) []CategoryResponse {
	responses := make([]CategoryResponse, len(categories))
	for i, category := range categories {
		responses[i] = ToCategoryResponse(category)
	}
	return responses
}
