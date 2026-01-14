package realtime

import (
	"context"
	"encoding/json"
	"fmt"
	"time"

	"backend/features/competitions/domain/entities"
	"backend/features/competitions/domain/repositories"

	"github.com/gin-contrib/sse"
	"go.mongodb.org/mongo-driver/bson/primitive"
)

// SSEBroadcaster implements NotificationBroadcaster using Server-Sent Events
// CRITICAL: Real-time updates for Speaker dashboard during competitions
type SSEBroadcaster struct {
	hub *SSEHub
}

// NewSSEBroadcaster creates a new SSE-based notification broadcaster
func NewSSEBroadcaster(hub *SSEHub) repositories.NotificationBroadcaster {
	return &SSEBroadcaster{
		hub: hub,
	}
}

// ============================================================================
// EMERGENCY BROADCASTS
// ============================================================================

// EmergencyPayload represents the JSON payload for emergency broadcasts
type EmergencyPayload struct {
	Type          string                 `json:"type"`           // "emergency", "score_reset", "score_swap", etc.
	Priority      string                 `json:"priority"`       // "CRITICAL", "EMERGENCY", "WARNING", "INFO"
	CompetitionID string                 `json:"competitionId"`
	HeatID        string                 `json:"heatId,omitempty"`
	Message       string                 `json:"message"`
	Timestamp     time.Time              `json:"timestamp"`
	Data          map[string]interface{} `json:"data,omitempty"` // Flexible payload
}

// BroadcastEmergency sends emergency broadcast entity to all connected clients
func (b *SSEBroadcaster) BroadcastEmergency(
	ctx context.Context,
	broadcast *entities.EmergencyBroadcast,
) error {
	heatIDStr := ""
	if broadcast.HeatID != nil {
		heatIDStr = broadcast.HeatID.Hex()
	}

	payload := EmergencyPayload{
		Type:          "emergency",
		Priority:      broadcast.Priority,
		CompetitionID: broadcast.CompetitionID.Hex(),
		HeatID:        heatIDStr,
		Message:       broadcast.Message,
		Timestamp:     time.Now(),
		Data: map[string]interface{}{
			"subject":      broadcast.Subject,
			"targetRole":   broadcast.TargetRole,
			"actionNeeded": broadcast.ActionNeeded,
		},
	}

	return b.sendEvent(broadcast.CompetitionID, "emergency", payload)
}

// BroadcastToCompetition sends a generic broadcast to all competition subscribers
func (b *SSEBroadcaster) BroadcastToCompetition(
	ctx context.Context,
	competitionID primitive.ObjectID,
	eventType string,
	message string,
) error {
	payload := EmergencyPayload{
		Type:          eventType,
		Priority:      "INFO",
		CompetitionID: competitionID.Hex(),
		Message:       message,
		Timestamp:     time.Now(),
	}

	return b.sendEvent(competitionID, eventType, payload)
}

// ============================================================================
// SCORE MANAGEMENT NOTIFICATIONS
// ============================================================================

// NotifyScoreReset notifies about score reset for re-runs
// PAYLOAD: athleteId, heatId, archivedScores[], newScores[]
func (b *SSEBroadcaster) NotifyScoreReset(
	ctx context.Context,
	competitionID primitive.ObjectID,
	heatID primitive.ObjectID,
	athleteID primitive.ObjectID,
) error {
	payload := EmergencyPayload{
		Type:          "score_reset",
		Priority:      "CRITICAL",
		CompetitionID: competitionID.Hex(),
		HeatID:        heatID.Hex(),
		Message:       "Score reset for athlete - Re-run authorized",
		Timestamp:     time.Now(),
		Data: map[string]interface{}{
			"athleteId": athleteID.Hex(),
			"action":    "SCORE_RESET",
		},
	}

	fmt.Printf("📢 [SSE BROADCAST] Score Reset: Competition=%s, Heat=%s, Athlete=%s\n",
		competitionID.Hex(), heatID.Hex(), athleteID.Hex())

	return b.sendEvent(competitionID, "score_reset", payload)
}

// NotifyScoreSwap notifies about score swap between athletes
// PAYLOAD: athlete1Id, athlete2Id, heatId, reason
func (b *SSEBroadcaster) NotifyScoreSwap(
	ctx context.Context,
	competitionID primitive.ObjectID,
	heatID primitive.ObjectID,
	athlete1ID primitive.ObjectID,
	athlete2ID primitive.ObjectID,
	reason string,
) error {
	payload := EmergencyPayload{
		Type:          "score_swap",
		Priority:      "CRITICAL",
		CompetitionID: competitionID.Hex(),
		HeatID:        heatID.Hex(),
		Message:       fmt.Sprintf("Scores swapped between two athletes"),
		Timestamp:     time.Now(),
		Data: map[string]interface{}{
			"athlete1Id": athlete1ID.Hex(),
			"athlete2Id": athlete2ID.Hex(),
			"reason":     reason,
			"action":     "SCORE_SWAP",
		},
	}

	fmt.Printf("📢 [SSE BROADCAST] Score Swap: Competition=%s, Heat=%s, Athletes=%s<->%s\n",
		competitionID.Hex(), heatID.Hex(), athlete1ID.Hex(), athlete2ID.Hex())

	return b.sendEvent(competitionID, "score_swap", payload)
}

// NotifyScoreOverride notifies about admin score override
// PAYLOAD: scoreId, athleteId, judgeId, originalScore, newScore, reason
func (b *SSEBroadcaster) NotifyScoreOverride(
	ctx context.Context,
	competitionID primitive.ObjectID,
	heatID primitive.ObjectID,
	scoreID primitive.ObjectID,
	athleteID primitive.ObjectID,
	originalScore float64,
	newScore float64,
	reason string,
) error {
	payload := EmergencyPayload{
		Type:          "score_override",
		Priority:      "CRITICAL",
		CompetitionID: competitionID.Hex(),
		HeatID:        heatID.Hex(),
		Message:       fmt.Sprintf("Admin override: Score changed from %.2f to %.2f", originalScore, newScore),
		Timestamp:     time.Now(),
		Data: map[string]interface{}{
			"scoreId":       scoreID.Hex(),
			"athleteId":     athleteID.Hex(),
			"originalScore": originalScore,
			"newScore":      newScore,
			"reason":        reason,
			"action":        "SCORE_OVERRIDE",
		},
	}

	fmt.Printf("📢 [SSE BROADCAST] Score Override: Competition=%s, Score=%s, %.2f -> %.2f\n",
		competitionID.Hex(), scoreID.Hex(), originalScore, newScore)

	return b.sendEvent(competitionID, "score_override", payload)
}

// ============================================================================
// REVIEW & PROTEST NOTIFICATIONS
// ============================================================================

// NotifyReview notifies about score under review (protests)
func (b *SSEBroadcaster) NotifyReview(
	ctx context.Context,
	competitionID primitive.ObjectID,
	scoreID primitive.ObjectID,
	message string,
) error {
	payload := EmergencyPayload{
		Type:          "score_under_review",
		Priority:      "WARNING",
		CompetitionID: competitionID.Hex(),
		Message:       message,
		Timestamp:     time.Now(),
		Data: map[string]interface{}{
			"scoreId": scoreID.Hex(),
			"action":  "UNDER_REVIEW",
		},
	}

	return b.sendEvent(competitionID, "score_under_review", payload)
}

// ============================================================================
// HEAT MANAGEMENT NOTIFICATIONS
// ============================================================================

// NotifyHeatOrderChange notifies about heat order changes
func (b *SSEBroadcaster) NotifyHeatOrderChange(
	ctx context.Context,
	competitionID primitive.ObjectID,
	heatID primitive.ObjectID,
	newOrder []primitive.ObjectID,
) error {
	// Convert ObjectIDs to strings for JSON
	orderStrings := make([]string, len(newOrder))
	for i, id := range newOrder {
		orderStrings[i] = id.Hex()
	}

	payload := EmergencyPayload{
		Type:          "heat_order_change",
		Priority:      "WARNING",
		CompetitionID: competitionID.Hex(),
		HeatID:        heatID.Hex(),
		Message:       "Heat order has been modified",
		Timestamp:     time.Now(),
		Data: map[string]interface{}{
			"newOrder": orderStrings,
			"action":   "HEAT_ORDER_CHANGE",
		},
	}

	return b.sendEvent(competitionID, "heat_order_change", payload)
}

// NotifyAthleteRemoved notifies about athlete removal from heat
func (b *SSEBroadcaster) NotifyAthleteRemoved(
	ctx context.Context,
	competitionID primitive.ObjectID,
	heatID primitive.ObjectID,
	athleteID primitive.ObjectID,
	reason string,
) error {
	payload := EmergencyPayload{
		Type:          "athlete_removed",
		Priority:      "CRITICAL",
		CompetitionID: competitionID.Hex(),
		HeatID:        heatID.Hex(),
		Message:       "Athlete removed from heat",
		Timestamp:     time.Now(),
		Data: map[string]interface{}{
			"athleteId": athleteID.Hex(),
			"reason":    reason,
			"action":    "ATHLETE_REMOVED",
		},
	}

	return b.sendEvent(competitionID, "athlete_removed", payload)
}

// ============================================================================
// HELPER METHODS
// ============================================================================

// sendEvent converts payload to SSE event and broadcasts it
func (b *SSEBroadcaster) sendEvent(competitionID primitive.ObjectID, eventType string, payload interface{}) error {
	// Serialize payload to JSON
	data, err := json.Marshal(payload)
	if err != nil {
		return fmt.Errorf("failed to marshal payload: %w", err)
	}

	// Create SSE event
	event := sse.Event{
		Event: eventType,
		Data:  string(data),
	}

	// Broadcast to all subscribers
	b.hub.Broadcast(competitionID, event)

	return nil
}

// GetSubscriberCount returns number of active SSE connections for a competition
func (b *SSEBroadcaster) GetSubscriberCount(competitionID primitive.ObjectID) int {
	return b.hub.GetSubscriberCount(competitionID)
}
