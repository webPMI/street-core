package entities

import (
	"time"

	"go.mongodb.org/mongo-driver/bson/primitive"
)

// Participant status constants
const (
	ParticipantStatusPending  = "pending"
	ParticipantStatusApproved = "approved"
	ParticipantStatusRejected = "rejected"
)

// Participant represents an athlete participating in a competition
type Participant struct {
	ID            primitive.ObjectID `json:"id" bson:"_id,omitempty"`
	CompetitionID primitive.ObjectID `json:"competitionId" bson:"competitionId" validate:"required"`
	AthleteID     primitive.ObjectID `json:"athleteId" bson:"athleteId" validate:"required"`
	AthleteName   string             `json:"athleteName" bson:"athleteName"`
	AthleteNumber string             `json:"athleteNumber,omitempty" bson:"athleteNumber,omitempty"`
	ClubID        primitive.ObjectID `json:"clubId,omitempty" bson:"clubId,omitempty"`
	ClubName      string             `json:"clubName,omitempty" bson:"clubName,omitempty"`
	Status        string             `json:"status" bson:"status" validate:"required,oneof=pending approved rejected"`
	RegisteredAt  time.Time          `json:"registeredAt" bson:"registeredAt"`
	ApprovedAt    *time.Time         `json:"approvedAt,omitempty" bson:"approvedAt,omitempty"`
	Notes         string             `json:"notes,omitempty" bson:"notes,omitempty"`
	CreatedAt     time.Time          `json:"createdAt" bson:"createdAt"`
	UpdatedAt     time.Time          `json:"updatedAt" bson:"updatedAt"`
}

// NewParticipant creates a new Participant
func NewParticipant(competitionID, athleteID primitive.ObjectID, athleteName string) *Participant {
	now := time.Now()
	return &Participant{
		ID:            primitive.NewObjectID(),
		CompetitionID: competitionID,
		AthleteID:     athleteID,
		AthleteName:   athleteName,
		Status:        ParticipantStatusPending,
		RegisteredAt:  now,
		CreatedAt:     now,
		UpdatedAt:     now,
	}
}

// Approve approves the participant
func (p *Participant) Approve() {
	now := time.Now()
	p.Status = ParticipantStatusApproved
	p.ApprovedAt = &now
	p.UpdatedAt = now
}

// Reject rejects the participant
func (p *Participant) Reject() {
	p.Status = ParticipantStatusRejected
	p.UpdatedAt = time.Now()
}

// IsApproved checks if participant is approved
func (p *Participant) IsApproved() bool {
	return p.Status == ParticipantStatusApproved
}

// IsPending checks if participant is pending
func (p *Participant) IsPending() bool {
	return p.Status == ParticipantStatusPending
}

// PrepareForUpdate updates the timestamp
func (p *Participant) PrepareForUpdate() {
	p.UpdatedAt = time.Now()
}
