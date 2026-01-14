package dto

import (
	"time"

	"backend/features/competitions/domain/entities"
)

// CreateJudgeInvitationRequest represents the request to create a judge invitation
type CreateJudgeInvitationRequest struct {
	UserID     string     `json:"userId" binding:"required"`
	CategoryID string     `json:"categoryId,omitempty"` // Optional
	Message    string     `json:"message,omitempty"`
	ExpiresAt  *time.Time `json:"expiresAt,omitempty"`
}

// RespondToInvitationRequest represents the request to respond to an invitation
type RespondToInvitationRequest struct {
	Accept   bool   `json:"accept" binding:"required"`
	Response string `json:"response,omitempty"`
}

// JudgeInvitationResponse represents a judge invitation response
type JudgeInvitationResponse struct {
	ID              string     `json:"id"`
	CompetitionID   string     `json:"competitionId"`
	CategoryID      string     `json:"categoryId,omitempty"`
	InvitedUserID   string     `json:"invitedUserId"`
	InvitedByID     string     `json:"invitedById"`
	InvitedUserName string     `json:"invitedUserName"`
	InvitedByName   string     `json:"invitedByName"`
	Message         string     `json:"message,omitempty"`
	Status          string     `json:"status"`
	ExpiresAt       *time.Time `json:"expiresAt,omitempty"`
	RespondedAt     *time.Time `json:"respondedAt,omitempty"`
	Response        string     `json:"response,omitempty"`
	CreatedAt       time.Time  `json:"createdAt"`
	UpdatedAt       time.Time  `json:"updatedAt"`
}

// ToJudgeInvitationResponse converts a JudgeInvitation entity to JudgeInvitationResponse DTO
func ToJudgeInvitationResponse(invitation *entities.JudgeInvitation) JudgeInvitationResponse {
	response := JudgeInvitationResponse{
		ID:              invitation.ID.Hex(),
		CompetitionID:   invitation.CompetitionID.Hex(),
		InvitedUserID:   invitation.InvitedUserID.Hex(),
		InvitedByID:     invitation.InvitedByID.Hex(),
		InvitedUserName: invitation.InvitedUserName,
		InvitedByName:   invitation.InvitedByName,
		Message:         invitation.Message,
		Status:          invitation.Status,
		ExpiresAt:       invitation.ExpiresAt,
		RespondedAt:     invitation.RespondedAt,
		Response:        invitation.Response,
		CreatedAt:       invitation.CreatedAt,
		UpdatedAt:       invitation.UpdatedAt,
	}

	if !invitation.CategoryID.IsZero() {
		response.CategoryID = invitation.CategoryID.Hex()
	}

	return response
}

// ToJudgeInvitationResponseList converts a list of JudgeInvitation entities to responses
func ToJudgeInvitationResponseList(invitations []*entities.JudgeInvitation) []JudgeInvitationResponse {
	responses := make([]JudgeInvitationResponse, len(invitations))
	for i, invitation := range invitations {
		responses[i] = ToJudgeInvitationResponse(invitation)
	}
	return responses
}
