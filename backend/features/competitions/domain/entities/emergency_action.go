package entities

import (
	"encoding/json"
	"errors"
	"time"

	"go.mongodb.org/mongo-driver/bson/primitive"
)

// Emergency action type constants
const (
	ActionResetAthleteScore     = "RESET_ATHLETE_SCORE"
	ActionUpdateHeatOrder       = "UPDATE_HEAT_ORDER"
	ActionRemoveAthleteFromHeat = "REMOVE_ATHLETE_FROM_HEAT"
	ActionAdminOverrideScore    = "ADMIN_OVERRIDE_SCORE"
	ActionSwapAthleteScores     = "SWAP_ATHLETE_SCORES"
	ActionEmergencyBroadcast    = "EMERGENCY_BROADCAST"
)

// Emergency action status constants
const (
	ActionStatusPending  = "pending"
	ActionStatusApplied  = "applied"
	ActionStatusReverted = "reverted"
	ActionStatusFailed   = "failed"
)

// EmergencyAction represents an emergency action taken during a competition
// with full audit trail including before/after state for UNDO capability
type EmergencyAction struct {
	ID            primitive.ObjectID `json:"id" bson:"_id,omitempty"`
	CompetitionID primitive.ObjectID `json:"competitionId" bson:"competitionId" validate:"required"`
	HeatID        primitive.ObjectID `json:"heatId,omitempty" bson:"heatId,omitempty"`
	RoundID       primitive.ObjectID `json:"roundId,omitempty" bson:"roundId,omitempty"`

	// Action identification
	ActionType string `json:"actionType" bson:"actionType" validate:"required"`

	// SECURITY: Reason is MANDATORY (min 10 characters)
	Reason      string `json:"reason" bson:"reason" validate:"required,min=10"`
	Description string `json:"description,omitempty" bson:"description,omitempty"`

	// AUDIT: State capture for UNDO capability (stored as JSON)
	StateBefore map[string]interface{} `json:"stateBefore,omitempty" bson:"stateBefore,omitempty"`
	StateAfter  map[string]interface{} `json:"stateAfter,omitempty" bson:"stateAfter,omitempty"`

	// Affected entities (optional, depends on action type)
	AthleteID *primitive.ObjectID `json:"athleteId,omitempty" bson:"athleteId,omitempty"`
	JudgeID   *primitive.ObjectID `json:"judgeId,omitempty" bson:"judgeId,omitempty"`
	ScoreID   *primitive.ObjectID `json:"scoreId,omitempty" bson:"scoreId,omitempty"`

	// Additional metadata (flexible JSON storage)
	Metadata map[string]interface{} `json:"metadata,omitempty" bson:"metadata,omitempty"`

	// Audit trail
	InitiatedBy     primitive.ObjectID `json:"initiatedBy" bson:"initiatedBy" validate:"required"`
	InitiatedByName string             `json:"initiatedByName,omitempty" bson:"initiatedByName,omitempty"`
	InitiatedAt     time.Time          `json:"initiatedAt" bson:"initiatedAt"`

	// Status tracking
	Status        string     `json:"status" bson:"status" validate:"required"`
	AppliedAt     *time.Time `json:"appliedAt,omitempty" bson:"appliedAt,omitempty"`
	FailureReason string     `json:"failureReason,omitempty" bson:"failureReason,omitempty"`

	// Rollback support
	SnapshotID *primitive.ObjectID `json:"snapshotId,omitempty" bson:"snapshotId,omitempty"`
	RevertedAt *time.Time          `json:"revertedAt,omitempty" bson:"revertedAt,omitempty"`
	RevertedBy *primitive.ObjectID `json:"revertedBy,omitempty" bson:"revertedBy,omitempty"`

	// Timestamps
	CreatedAt time.Time `json:"createdAt" bson:"createdAt"`
	UpdatedAt time.Time `json:"updatedAt" bson:"updatedAt"`
}

// NewEmergencyAction creates a new EmergencyAction entity
func NewEmergencyAction(
	competitionID primitive.ObjectID,
	actionType string,
	reason string,
	initiatedBy primitive.ObjectID,
	initiatedByName string,
) *EmergencyAction {
	now := time.Now()
	return &EmergencyAction{
		ID:              primitive.NewObjectID(),
		CompetitionID:   competitionID,
		ActionType:      actionType,
		Reason:          reason,
		InitiatedBy:     initiatedBy,
		InitiatedByName: initiatedByName,
		InitiatedAt:     now,
		Status:          ActionStatusPending,
		StateBefore:     make(map[string]interface{}),
		StateAfter:      make(map[string]interface{}),
		Metadata:        make(map[string]interface{}),
		CreatedAt:       now,
		UpdatedAt:       now,
	}
}

// SetHeat sets the heat ID for this action
func (ea *EmergencyAction) SetHeat(heatID primitive.ObjectID) {
	ea.HeatID = heatID
	ea.UpdatedAt = time.Now()
}

// SetRound sets the round ID for this action
func (ea *EmergencyAction) SetRound(roundID primitive.ObjectID) {
	ea.RoundID = roundID
	ea.UpdatedAt = time.Now()
}

// SetAthlete sets the athlete ID for this action
func (ea *EmergencyAction) SetAthlete(athleteID primitive.ObjectID) {
	ea.AthleteID = &athleteID
	ea.UpdatedAt = time.Now()
}

// SetScore sets the score ID for this action
func (ea *EmergencyAction) SetScore(scoreID primitive.ObjectID) {
	ea.ScoreID = &scoreID
	ea.UpdatedAt = time.Now()
}

// SetSnapshot links this action to a heat snapshot for rollback
func (ea *EmergencyAction) SetSnapshot(snapshotID primitive.ObjectID) {
	ea.SnapshotID = &snapshotID
	ea.UpdatedAt = time.Now()
}

// CaptureStateBefore serializes an entity to JSON and stores it in StateBefore
// This enables UNDO functionality by preserving the exact state before the action
func (ea *EmergencyAction) CaptureStateBefore(entity interface{}) error {
	jsonData, err := json.Marshal(entity)
	if err != nil {
		return err
	}

	var stateMap map[string]interface{}
	if err := json.Unmarshal(jsonData, &stateMap); err != nil {
		return err
	}

	ea.StateBefore = stateMap
	ea.UpdatedAt = time.Now()
	return nil
}

// CaptureStateAfter serializes an entity to JSON and stores it in StateAfter
func (ea *EmergencyAction) CaptureStateAfter(entity interface{}) error {
	jsonData, err := json.Marshal(entity)
	if err != nil {
		return err
	}

	var stateMap map[string]interface{}
	if err := json.Unmarshal(jsonData, &stateMap); err != nil {
		return err
	}

	ea.StateAfter = stateMap
	ea.UpdatedAt = time.Now()
	return nil
}

// AddMetadata adds a metadata key-value pair
func (ea *EmergencyAction) AddMetadata(key string, value interface{}) {
	if ea.Metadata == nil {
		ea.Metadata = make(map[string]interface{})
	}
	ea.Metadata[key] = value
	ea.UpdatedAt = time.Now()
}

// MarkAsApplied marks the action as successfully applied
func (ea *EmergencyAction) MarkAsApplied() error {
	if ea.Status == ActionStatusApplied {
		return errors.New("emergency action has already been applied")
	}

	now := time.Now()
	ea.Status = ActionStatusApplied
	ea.AppliedAt = &now
	ea.UpdatedAt = now
	return nil
}

// MarkAsFailed marks the action as failed with a reason
func (ea *EmergencyAction) MarkAsFailed(reason string) error {
	if ea.Status == ActionStatusApplied {
		return errors.New("cannot mark an applied action as failed")
	}

	now := time.Now()
	ea.Status = ActionStatusFailed
	ea.FailureReason = reason
	ea.UpdatedAt = now
	return nil
}

// Revert reverts this action using the captured StateBefore
func (ea *EmergencyAction) Revert(revertedBy primitive.ObjectID) error {
	if ea.Status != ActionStatusApplied {
		return errors.New("can only revert applied actions")
	}

	if len(ea.StateBefore) == 0 {
		return errors.New("no state before data available for rollback")
	}

	now := time.Now()
	ea.Status = ActionStatusReverted
	ea.RevertedAt = &now
	ea.RevertedBy = &revertedBy
	ea.UpdatedAt = now
	return nil
}

// IsApplied returns true if the action has been applied
func (ea *EmergencyAction) IsApplied() bool {
	return ea.Status == ActionStatusApplied
}

// IsFailed returns true if the action failed
func (ea *EmergencyAction) IsFailed() bool {
	return ea.Status == ActionStatusFailed
}

// IsReverted returns true if the action was reverted
func (ea *EmergencyAction) IsReverted() bool {
	return ea.Status == ActionStatusReverted
}

// CanBeReverted checks if this action can be reverted
func (ea *EmergencyAction) CanBeReverted() bool {
	return ea.Status == ActionStatusApplied && len(ea.StateBefore) > 0
}

// Validate validates the emergency action using centralized error codes
func (ea *EmergencyAction) Validate() error {
	// Validate competition ID
	if ea.CompetitionID.IsZero() {
		return errors.New("competition ID is required for emergency action")
	}

	// Validate action type
	if ea.ActionType == "" {
		return errors.New("action type is required for emergency action")
	}

	// SECURITY: Reason is MANDATORY and minimum 10 characters
	if ea.Reason == "" {
		return errors.New("emergency action reason is required")
	}
	if len(ea.Reason) < 10 {
		return errors.New("emergency action reason must be at least 10 characters")
	}

	// Validate initiator
	if ea.InitiatedBy.IsZero() {
		return errors.New("emergency action initiator is required")
	}

	// Validate action-specific requirements
	switch ea.ActionType {
	case ActionResetAthleteScore, ActionRemoveAthleteFromHeat:
		if ea.AthleteID == nil || ea.AthleteID.IsZero() {
			return errors.New("athlete ID is required for this action type")
		}

	case ActionAdminOverrideScore:
		if ea.ScoreID == nil || ea.ScoreID.IsZero() {
			return errors.New("score ID is required for admin override action")
		}

	case ActionSwapAthleteScores:
		if ea.Metadata == nil || ea.Metadata["athleteId1"] == nil || ea.Metadata["athleteId2"] == nil {
			return errors.New("both athlete IDs required in metadata for swap action")
		}
	}

	return nil
}

// PrepareForUpdate updates the timestamp
func (ea *EmergencyAction) PrepareForUpdate() {
	ea.UpdatedAt = time.Now()
}
