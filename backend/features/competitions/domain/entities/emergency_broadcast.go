package entities

import (
	"errors"
	"time"

	"go.mongodb.org/mongo-driver/bson/primitive"
)

// Broadcast priority constants
const (
	BroadcastPriorityInfo      = "INFO"
	BroadcastPriorityWarning   = "WARNING"
	BroadcastPriorityCritical  = "CRITICAL"
	BroadcastPriorityEmergency = "EMERGENCY"
)

// Target role constants
const (
	TargetAllJudges    = "ALL_JUDGES"
	TargetAllSpeakers  = "ALL_SPEAKERS"
	TargetAllMarshalls = "ALL_MARSHALLS"
	TargetAllStaff     = "ALL_STAFF"
	TargetEveryone     = "EVERYONE"
	TargetSpecific     = "SPECIFIC_USERS"
)

// EmergencyBroadcast represents a real-time broadcast message during emergencies
type EmergencyBroadcast struct {
	ID            primitive.ObjectID `json:"id" bson:"_id,omitempty"`
	CompetitionID primitive.ObjectID `json:"competitionId" bson:"competitionId" validate:"required"`
	HeatID        *primitive.ObjectID `json:"heatId,omitempty" bson:"heatId,omitempty"`
	ActionID      *primitive.ObjectID `json:"actionId,omitempty" bson:"actionId,omitempty"` // Link to EmergencyAction

	// Message details
	Priority     string `json:"priority" bson:"priority" validate:"required"`
	Subject      string `json:"subject" bson:"subject" validate:"required,min=5"`
	Message      string `json:"message" bson:"message" validate:"required,min=10"`
	ActionNeeded string `json:"actionNeeded,omitempty" bson:"actionNeeded,omitempty"`

	// Target audience
	TargetRole    string               `json:"targetRole" bson:"targetRole" validate:"required"`
	TargetUserIDs []primitive.ObjectID `json:"targetUserIds,omitempty" bson:"targetUserIds,omitempty"`

	// Sender info
	SentBy     primitive.ObjectID `json:"sentBy" bson:"sentBy" validate:"required"`
	SentByName string             `json:"sentByName,omitempty" bson:"sentByName,omitempty"`
	SentAt     time.Time          `json:"sentAt" bson:"sentAt"`

	// Acknowledgment tracking
	RequiresAcknowledgment bool                 `json:"requiresAcknowledgment" bson:"requiresAcknowledgment"`
	AcknowledgedBy         []primitive.ObjectID `json:"acknowledgedBy,omitempty" bson:"acknowledgedBy,omitempty"`
	AcknowledgedAt         map[string]time.Time `json:"acknowledgedAt,omitempty" bson:"acknowledgedAt,omitempty"`

	// Expiration (for TTL index)
	ExpiresAt *time.Time `json:"expiresAt,omitempty" bson:"expiresAt,omitempty"`

	// Timestamps
	CreatedAt time.Time `json:"createdAt" bson:"createdAt"`
	UpdatedAt time.Time `json:"updatedAt" bson:"updatedAt"`
}

// NewEmergencyBroadcast creates a new EmergencyBroadcast
func NewEmergencyBroadcast(
	competitionID primitive.ObjectID,
	priority string,
	subject string,
	message string,
	targetRole string,
	sentBy primitive.ObjectID,
	sentByName string,
) *EmergencyBroadcast {
	now := time.Now()
	return &EmergencyBroadcast{
		ID:                     primitive.NewObjectID(),
		CompetitionID:          competitionID,
		Priority:               priority,
		Subject:                subject,
		Message:                message,
		TargetRole:             targetRole,
		SentBy:                 sentBy,
		SentByName:             sentByName,
		SentAt:                 now,
		AcknowledgedBy:         []primitive.ObjectID{},
		AcknowledgedAt:         make(map[string]time.Time),
		RequiresAcknowledgment: false,
		CreatedAt:              now,
		UpdatedAt:              now,
	}
}

// SetHeat links this broadcast to a specific heat
func (eb *EmergencyBroadcast) SetHeat(heatID primitive.ObjectID) {
	eb.HeatID = &heatID
	eb.UpdatedAt = time.Now()
}

// SetAction links this broadcast to an emergency action
func (eb *EmergencyBroadcast) SetAction(actionID primitive.ObjectID) {
	eb.ActionID = &actionID
	eb.UpdatedAt = time.Now()
}

// SetTargetUsers sets specific target users
func (eb *EmergencyBroadcast) SetTargetUsers(userIDs []primitive.ObjectID) {
	eb.TargetRole = TargetSpecific
	eb.TargetUserIDs = userIDs
	eb.UpdatedAt = time.Now()
}

// SetExpiration sets when this broadcast expires
func (eb *EmergencyBroadcast) SetExpiration(duration time.Duration) {
	expiresAt := time.Now().Add(duration)
	eb.ExpiresAt = &expiresAt
	eb.UpdatedAt = time.Now()
}

// RequireAcknowledgment marks that this broadcast requires acknowledgment
func (eb *EmergencyBroadcast) RequireAcknowledgment() {
	eb.RequiresAcknowledgment = true
	eb.UpdatedAt = time.Now()
}

// Acknowledge marks that a user has acknowledged this broadcast
func (eb *EmergencyBroadcast) Acknowledge(userID primitive.ObjectID) error {
	// Check if already acknowledged
	for _, id := range eb.AcknowledgedBy {
		if id == userID {
			return errors.New("user has already acknowledged this broadcast")
		}
	}

	now := time.Now()
	eb.AcknowledgedBy = append(eb.AcknowledgedBy, userID)
	if eb.AcknowledgedAt == nil {
		eb.AcknowledgedAt = make(map[string]time.Time)
	}
	eb.AcknowledgedAt[userID.Hex()] = now
	eb.UpdatedAt = now
	return nil
}

// IsAcknowledgedBy checks if a user has acknowledged this broadcast
func (eb *EmergencyBroadcast) IsAcknowledgedBy(userID primitive.ObjectID) bool {
	for _, id := range eb.AcknowledgedBy {
		if id == userID {
			return true
		}
	}
	return false
}

// IsExpired checks if the broadcast has expired
func (eb *EmergencyBroadcast) IsExpired() bool {
	if eb.ExpiresAt == nil {
		return false
	}
	return time.Now().After(*eb.ExpiresAt)
}

// IsCritical returns true if priority is CRITICAL or EMERGENCY
func (eb *EmergencyBroadcast) IsCritical() bool {
	return eb.Priority == BroadcastPriorityCritical || eb.Priority == BroadcastPriorityEmergency
}

// GetAcknowledgmentRate returns the acknowledgment rate as a percentage
func (eb *EmergencyBroadcast) GetAcknowledgmentRate(totalTargets int) float64 {
	if totalTargets == 0 {
		return 0
	}
	return (float64(len(eb.AcknowledgedBy)) / float64(totalTargets)) * 100
}

// Validate validates the emergency broadcast
func (eb *EmergencyBroadcast) Validate() error {
	// Validate competition ID
	if eb.CompetitionID.IsZero() {
		return errors.New("competition ID is required for emergency broadcast")
	}

	// Validate priority
	if eb.Priority == "" {
		return errors.New("broadcast priority is required")
	}

	// Validate subject
	if eb.Subject == "" {
		return errors.New("broadcast subject is required")
	}
	if len(eb.Subject) < 5 {
		return errors.New("broadcast subject must be at least 5 characters")
	}

	// Validate message
	if eb.Message == "" {
		return errors.New("broadcast message is required")
	}
	if len(eb.Message) < 10 {
		return errors.New("broadcast message must be at least 10 characters")
	}

	// Validate target role
	if eb.TargetRole == "" {
		return errors.New("broadcast target role is required")
	}

	// Validate specific targets
	if eb.TargetRole == TargetSpecific && len(eb.TargetUserIDs) == 0 {
		return errors.New("target users required when target role is SPECIFIC_USERS")
	}

	// Validate sender
	if eb.SentBy.IsZero() {
		return errors.New("broadcast sender is required")
	}

	return nil
}

// PrepareForUpdate updates the timestamp
func (eb *EmergencyBroadcast) PrepareForUpdate() {
	eb.UpdatedAt = time.Now()
}
