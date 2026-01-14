package entities

import (
	"time"

	"go.mongodb.org/mongo-driver/bson/primitive"
)

// JudgeInvitation status constants
const (
	InvitationStatusPending  = "pending"
	InvitationStatusAccepted = "accepted"
	InvitationStatusDeclined = "declined"
	InvitationStatusExpired  = "expired"
)

// JudgeInvitation represents an invitation for a user to judge a competition
type JudgeInvitation struct {
	ID            primitive.ObjectID `json:"id" bson:"_id,omitempty"`
	CompetitionID primitive.ObjectID `json:"competitionId" bson:"competitionId" validate:"required"`
	CategoryID    primitive.ObjectID `json:"categoryId,omitempty" bson:"categoryId,omitempty"` // Optional: for category-specific judging
	InvitedUserID primitive.ObjectID `json:"invitedUserId" bson:"invitedUserId" validate:"required"`
	InvitedByID   primitive.ObjectID `json:"invitedById" bson:"invitedById" validate:"required"`

	// User details (denormalized for display)
	InvitedUserName string `json:"invitedUserName" bson:"invitedUserName"`
	InvitedByName   string `json:"invitedByName" bson:"invitedByName"`

	// Invitation details
	Message   string     `json:"message,omitempty" bson:"message,omitempty"`
	Status    string     `json:"status" bson:"status" validate:"required,oneof=pending accepted declined expired"`
	ExpiresAt *time.Time `json:"expiresAt,omitempty" bson:"expiresAt,omitempty"`

	// Response details
	RespondedAt *time.Time `json:"respondedAt,omitempty" bson:"respondedAt,omitempty"`
	Response    string     `json:"response,omitempty" bson:"response,omitempty"` // Optional message from invitee

	// Metadata
	CreatedAt time.Time `json:"createdAt" bson:"createdAt"`
	UpdatedAt time.Time `json:"updatedAt" bson:"updatedAt"`
}

// NewJudgeInvitation creates a new JudgeInvitation
func NewJudgeInvitation(competitionID, invitedUserID, invitedByID primitive.ObjectID, invitedUserName, invitedByName string) *JudgeInvitation {
	now := time.Now()
	expiresAt := now.AddDate(0, 0, 7) // 7 days default expiry

	return &JudgeInvitation{
		ID:              primitive.NewObjectID(),
		CompetitionID:   competitionID,
		InvitedUserID:   invitedUserID,
		InvitedByID:     invitedByID,
		InvitedUserName: invitedUserName,
		InvitedByName:   invitedByName,
		Status:          InvitationStatusPending,
		ExpiresAt:       &expiresAt,
		CreatedAt:       now,
		UpdatedAt:       now,
	}
}

// Accept accepts the invitation
func (i *JudgeInvitation) Accept(response string) error {
	if i.Status != InvitationStatusPending {
		return ErrInvitationNotPending
	}
	if i.IsExpired() {
		return ErrInvitationExpired
	}

	now := time.Now()
	i.Status = InvitationStatusAccepted
	i.RespondedAt = &now
	i.Response = response
	i.UpdatedAt = now
	return nil
}

// Decline declines the invitation
func (i *JudgeInvitation) Decline(response string) error {
	if i.Status != InvitationStatusPending {
		return ErrInvitationNotPending
	}

	now := time.Now()
	i.Status = InvitationStatusDeclined
	i.RespondedAt = &now
	i.Response = response
	i.UpdatedAt = now
	return nil
}

// IsExpired checks if the invitation is expired
func (i *JudgeInvitation) IsExpired() bool {
	if i.ExpiresAt == nil {
		return false
	}
	return time.Now().After(*i.ExpiresAt)
}

// MarkExpired marks the invitation as expired
func (i *JudgeInvitation) MarkExpired() {
	i.Status = InvitationStatusExpired
	i.UpdatedAt = time.Now()
}

// PrepareForUpdate updates the timestamp
func (i *JudgeInvitation) PrepareForUpdate() {
	i.UpdatedAt = time.Now()
}

// JudgeInvitation domain errors
var (
	ErrInvitationNotFound   = newDomainError("judge invitation not found")
	ErrInvitationNotPending = newDomainError("invitation is not pending")
	ErrInvitationExpired    = newDomainError("invitation has expired")
	ErrAlreadyInvited       = newDomainError("user already has pending invitation")
)
