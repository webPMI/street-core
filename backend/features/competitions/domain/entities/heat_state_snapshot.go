package entities

import (
	"errors"
	"time"

	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/bson/primitive"
)

// Snapshot type constants
const (
	SnapshotTypeFreeze   = "freeze"   // Manual freeze for crisis (weather, safety)
	SnapshotTypeRollback = "rollback" // Rollback to undo changes (organizer error)
)

// HeatStateSnapshot represents a frozen state of a heat that can be restored
// Use cases:
// - Weather interruption (rain, lightning) - freeze state, resume later
// - Safety incident - freeze state, investigate, resume
// - Organizer error - rollback to previous state
// - Score dispute - rollback to pre-dispute state
type HeatStateSnapshot struct {
	ID            primitive.ObjectID `json:"id" bson:"_id,omitempty"`
	HeatID        primitive.ObjectID `json:"heatId" bson:"heatId" validate:"required"`
	CompetitionID primitive.ObjectID `json:"competitionId" bson:"competitionId" validate:"required"`
	RoundID       primitive.ObjectID `json:"roundId" bson:"roundId"`

	// Snapshot type determines usage
	SnapshotType string `json:"snapshotType" bson:"snapshotType" validate:"required,oneof=freeze rollback"`

	// Captured state data (stored as raw BSON for flexibility)
	HeatData        bson.Raw   `json:"heatData" bson:"heatData" validate:"required"`                  // Complete Heat entity
	ScoreData       []bson.Raw `json:"scoreData" bson:"scoreData"`                                    // All Score entities at snapshot time
	ParticipantData []bson.Raw `json:"participantData,omitempty" bson:"participantData,omitempty"`    // Athlete info (optional)

	// Snapshot metadata
	CreatedBy primitive.ObjectID `json:"createdBy" bson:"createdBy" validate:"required"` // Organizer who created snapshot
	CreatedAt time.Time          `json:"createdAt" bson:"createdAt"`
	Reason    string             `json:"reason" bson:"reason" validate:"required"` // Why snapshot was created

	// Restore tracking
	IsRestored bool                `json:"isRestored" bson:"isRestored"`                       // Whether snapshot has been restored
	RestoredAt *time.Time          `json:"restoredAt,omitempty" bson:"restoredAt,omitempty"`   // When snapshot was restored
	RestoredBy *primitive.ObjectID `json:"restoredBy,omitempty" bson:"restoredBy,omitempty"`   // Who restored snapshot
}

// NewHeatStateSnapshot creates a new heat state snapshot
func NewHeatStateSnapshot(
	heatID, competitionID, roundID primitive.ObjectID,
	snapshotType string,
	heatData bson.Raw,
	scoreData []bson.Raw,
	createdBy primitive.ObjectID,
	reason string,
) *HeatStateSnapshot {
	return &HeatStateSnapshot{
		ID:              primitive.NewObjectID(),
		HeatID:          heatID,
		CompetitionID:   competitionID,
		RoundID:         roundID,
		SnapshotType:    snapshotType,
		HeatData:        heatData,
		ScoreData:       scoreData,
		ParticipantData: []bson.Raw{},
		CreatedBy:       createdBy,
		CreatedAt:       time.Now(),
		Reason:          reason,
		IsRestored:      false,
	}
}

// MarkAsRestored marks the snapshot as restored
func (s *HeatStateSnapshot) MarkAsRestored(restoredBy primitive.ObjectID) {
	now := time.Now()
	s.IsRestored = true
	s.RestoredAt = &now
	s.RestoredBy = &restoredBy
}

// IsFreeze returns true if this is a freeze snapshot
func (s *HeatStateSnapshot) IsFreeze() bool {
	return s.SnapshotType == SnapshotTypeFreeze
}

// IsRollback returns true if this is a rollback snapshot
func (s *HeatStateSnapshot) IsRollback() bool {
	return s.SnapshotType == SnapshotTypeRollback
}

// HasBeenRestored returns true if snapshot has been restored
func (s *HeatStateSnapshot) HasBeenRestored() bool {
	return s.IsRestored
}

// Validate validates the snapshot entity
func (s *HeatStateSnapshot) Validate() error {
	// Validate snapshot type
	if s.SnapshotType != SnapshotTypeFreeze && s.SnapshotType != SnapshotTypeRollback {
		return errors.New("invalid snapshot type, must be 'freeze' or 'rollback'")
	}

	// Validate required ObjectIDs
	if s.HeatID.IsZero() {
		return errors.New("heatId is required")
	}
	if s.CompetitionID.IsZero() {
		return errors.New("competitionId is required")
	}
	if s.CreatedBy.IsZero() {
		return errors.New("createdBy is required")
	}

	// Validate reason
	if s.Reason == "" {
		return errors.New("reason is required")
	}

	// Validate heat data
	if len(s.HeatData) == 0 {
		return errors.New("heatData is required")
	}

	// Validate BSON structure
	var testHeat map[string]interface{}
	if err := bson.Unmarshal(s.HeatData, &testHeat); err != nil {
		return errors.New("invalid BSON data in heatData")
	}

	return nil
}

// GetHeat unmarshals the heat data into a Heat entity
func (s *HeatStateSnapshot) GetHeat() (*Heat, error) {
	var heat Heat
	if err := bson.Unmarshal(s.HeatData, &heat); err != nil {
		return nil, err
	}
	return &heat, nil
}

// GetScores unmarshals the score data into Score entities
func (s *HeatStateSnapshot) GetScores() ([]*Score, error) {
	scores := make([]*Score, len(s.ScoreData))
	for i, rawScore := range s.ScoreData {
		var score Score
		if err := bson.Unmarshal(rawScore, &score); err != nil {
			return nil, err
		}
		scores[i] = &score
	}
	return scores, nil
}

// GetSnapshotSummary returns a human-readable summary
func (s *HeatStateSnapshot) GetSnapshotSummary() string {
	summary := "Snapshot: "
	if s.IsFreeze() {
		summary += "FREEZE"
	} else {
		summary += "ROLLBACK"
	}
	summary += " | Reason: " + s.Reason
	if s.IsRestored {
		summary += " | RESTORED"
	}
	return summary
}
