package entities

import (
	"time"

	"go.mongodb.org/mongo-driver/bson/primitive"
)

// Round status constants
const (
	RoundStatusPending   = "pending"
	RoundStatusActive    = "active"
	RoundStatusCompleted = "completed"
)

// Round represents a competition round entity
type Round struct {
	ID            primitive.ObjectID `json:"id" bson:"_id,omitempty"`
	CompetitionID primitive.ObjectID `json:"competitionId" bson:"competitionId" validate:"required"`
	Name          string             `json:"name" bson:"name" validate:"required"`
	Order         int                `json:"order" bson:"order" validate:"required"`
	StartTime     time.Time          `json:"startTime" bson:"startTime" validate:"required"`
	EndTime       *time.Time         `json:"endTime,omitempty" bson:"endTime,omitempty"`
	Status        string             `json:"status" bson:"status" validate:"required,oneof=pending active completed"`
	Description   string             `json:"description,omitempty" bson:"description,omitempty"`
	MaxAthletes   int                `json:"maxAthletes,omitempty" bson:"maxAthletes,omitempty"`

	// Heat configuration
	HasHeats    bool     `json:"hasHeats" bson:"hasHeats"`
	HeatIDs     []string `json:"heatIds,omitempty" bson:"heatIds,omitempty"`
	CurrentHeat int      `json:"currentHeat" bson:"currentHeat"`
	TotalHeats  int      `json:"totalHeats" bson:"totalHeats"`

	CreatedAt     time.Time          `json:"createdAt" bson:"createdAt"`
	UpdatedAt     time.Time          `json:"updatedAt" bson:"updatedAt"`
}

// NewRound creates a new Round
func NewRound(competitionID primitive.ObjectID, name string, order int, startTime time.Time) *Round {
	now := time.Now()
	return &Round{
		ID:            primitive.NewObjectID(),
		CompetitionID: competitionID,
		Name:          name,
		Order:         order,
		StartTime:     startTime,
		Status:        RoundStatusPending,
		CreatedAt:     now,
		UpdatedAt:     now,
	}
}

// CanStart checks if the round can start
func (r *Round) CanStart() bool {
	return r.Status == RoundStatusPending && time.Now().After(r.StartTime)
}

// IsActive checks if the round is currently active
func (r *Round) IsActive() bool {
	return r.Status == RoundStatusActive
}

// IsCompleted checks if the round is completed
func (r *Round) IsCompleted() bool {
	return r.Status == RoundStatusCompleted
}

// Start starts the round
func (r *Round) Start() error {
	if !r.CanStart() {
		return ErrInvalidStatus
	}
	r.Status = RoundStatusActive
	r.UpdatedAt = time.Now()
	return nil
}

// Complete completes the round
func (r *Round) Complete() error {
	if r.Status != RoundStatusActive {
		return ErrInvalidStatus
	}
	now := time.Now()
	r.Status = RoundStatusCompleted
	r.EndTime = &now
	r.UpdatedAt = now
	return nil
}

// PrepareForUpdate updates the timestamp
func (r *Round) PrepareForUpdate() {
	r.UpdatedAt = time.Now()
}

// EnableHeats enables heat configuration for this round
func (r *Round) EnableHeats() {
	r.HasHeats = true
	r.UpdatedAt = time.Now()
}

// DisableHeats disables heat configuration for this round
func (r *Round) DisableHeats() {
	r.HasHeats = false
	r.HeatIDs = []string{}
	r.CurrentHeat = 0
	r.TotalHeats = 0
	r.UpdatedAt = time.Now()
}

// AddHeat adds a heat ID to the round
func (r *Round) AddHeat(heatID string) {
	r.HeatIDs = append(r.HeatIDs, heatID)
	r.TotalHeats = len(r.HeatIDs)
	r.UpdatedAt = time.Now()
}

// RemoveHeat removes a heat ID from the round
func (r *Round) RemoveHeat(heatID string) {
	for i, id := range r.HeatIDs {
		if id == heatID {
			r.HeatIDs = append(r.HeatIDs[:i], r.HeatIDs[i+1:]...)
			break
		}
	}
	r.TotalHeats = len(r.HeatIDs)
	r.UpdatedAt = time.Now()
}

// UsesHeats returns true if this round uses heats
func (r *Round) UsesHeats() bool {
	return r.HasHeats
}
