package entities

import (
	"time"

	"go.mongodb.org/mongo-driver/bson/primitive"
)

// Category status constants
const (
	CategoryStatusActive   = "active"
	CategoryStatusInactive = "inactive"
	CategoryStatusClosed   = "closed"
)

// Category represents a competition category (e.g., "Men's Pro", "Women's Amateur")
type Category struct {
	ID            primitive.ObjectID   `json:"id" bson:"_id,omitempty"`
	CompetitionID primitive.ObjectID   `json:"competitionId" bson:"competitionId" validate:"required"`
	Name          string               `json:"name" bson:"name" validate:"required,min=2,max=100"`
	Description   string               `json:"description,omitempty" bson:"description,omitempty"`

	// Participant limits
	MaxParticipants     int `json:"maxParticipants" bson:"maxParticipants"`
	MinParticipants     int `json:"minParticipants" bson:"minParticipants"`
	CurrentParticipants int `json:"currentParticipants" bson:"currentParticipants"`

	// Participant and Judge assignments
	ParticipantIDs []primitive.ObjectID `json:"participantIds,omitempty" bson:"participantIds,omitempty"`
	JudgeIDs       []primitive.ObjectID `json:"judgeIds,omitempty" bson:"judgeIds,omitempty"`

	// Scoring configuration (can override competition defaults)
	ScoringCriteria *ScoringCriteria `json:"scoringCriteria,omitempty" bson:"scoringCriteria,omitempty"`

	// Schedule (can have different times within competition)
	StartTime *time.Time `json:"startTime,omitempty" bson:"startTime,omitempty"`
	EndTime   *time.Time `json:"endTime,omitempty" bson:"endTime,omitempty"`

	// Status and ordering
	Status   string `json:"status" bson:"status" validate:"required,oneof=active inactive closed"`
	Order    int    `json:"order" bson:"order"` // For display ordering

	// Metadata
	CreatedAt time.Time `json:"createdAt" bson:"createdAt"`
	UpdatedAt time.Time `json:"updatedAt" bson:"updatedAt"`
}

// NewCategory creates a new Category with defaults
func NewCategory(competitionID primitive.ObjectID, name string) *Category {
	now := time.Now()
	return &Category{
		ID:            primitive.NewObjectID(),
		CompetitionID: competitionID,
		Name:          name,
		MaxParticipants: 50,
		MinParticipants: 1,
		Status:        CategoryStatusActive,
		Order:         0,
		CreatedAt:     now,
		UpdatedAt:     now,
	}
}

// AddParticipant adds a participant to the category
func (c *Category) AddParticipant(participantID primitive.ObjectID) error {
	// Check if already in category
	for _, id := range c.ParticipantIDs {
		if id == participantID {
			return ErrAlreadyInCategory
		}
	}

	// Check if category is full
	if c.MaxParticipants > 0 && c.CurrentParticipants >= c.MaxParticipants {
		return ErrCategoryFull
	}

	c.ParticipantIDs = append(c.ParticipantIDs, participantID)
	c.CurrentParticipants++
	c.UpdatedAt = time.Now()
	return nil
}

// RemoveParticipant removes a participant from the category
func (c *Category) RemoveParticipant(participantID primitive.ObjectID) error {
	for i, id := range c.ParticipantIDs {
		if id == participantID {
			c.ParticipantIDs = append(c.ParticipantIDs[:i], c.ParticipantIDs[i+1:]...)
			c.CurrentParticipants--
			c.UpdatedAt = time.Now()
			return nil
		}
	}
	return ErrNotInCategory
}

// AddJudge adds a judge to the category
func (c *Category) AddJudge(judgeID primitive.ObjectID) error {
	for _, id := range c.JudgeIDs {
		if id == judgeID {
			return ErrAlreadyJudge
		}
	}

	c.JudgeIDs = append(c.JudgeIDs, judgeID)
	c.UpdatedAt = time.Now()
	return nil
}

// RemoveJudge removes a judge from the category
func (c *Category) RemoveJudge(judgeID primitive.ObjectID) error {
	for i, id := range c.JudgeIDs {
		if id == judgeID {
			c.JudgeIDs = append(c.JudgeIDs[:i], c.JudgeIDs[i+1:]...)
			c.UpdatedAt = time.Now()
			return nil
		}
	}
	return ErrNotJudgeInCategory
}

// IsParticipant checks if user is a participant in this category
func (c *Category) IsParticipant(userID primitive.ObjectID) bool {
	for _, id := range c.ParticipantIDs {
		if id == userID {
			return true
		}
	}
	return false
}

// IsJudge checks if user is a judge in this category
func (c *Category) IsJudge(userID primitive.ObjectID) bool {
	for _, id := range c.JudgeIDs {
		if id == userID {
			return true
		}
	}
	return false
}

// PrepareForUpdate updates the timestamp
func (c *Category) PrepareForUpdate() {
	c.UpdatedAt = time.Now()
}

// Category domain errors
var (
	ErrCategoryNotFound    = newDomainError("category not found")
	ErrAlreadyInCategory   = newDomainError("participant already in category")
	ErrNotInCategory       = newDomainError("participant not in category")
	ErrCategoryFull        = newDomainError("category is full")
	ErrNotJudgeInCategory  = newDomainError("user is not a judge in this category")
)
