package repositories

import (
	"context"

	"backend/features/competitions/domain/entities"

	"go.mongodb.org/mongo-driver/bson/primitive"
)

// NotificationBroadcaster defines the interface for real-time notifications
// Used to send emergency alerts to Speaker, judges, and staff
type NotificationBroadcaster interface {
	// BroadcastEmergency sends an emergency broadcast to all connected clients
	BroadcastEmergency(ctx context.Context, broadcast *entities.EmergencyBroadcast) error

	// BroadcastToCompetition sends a message to all users in a competition
	BroadcastToCompetition(ctx context.Context, competitionID primitive.ObjectID, messageType, message string) error

	// NotifyReview sends a review notification to Speaker and organizer
	NotifyReview(ctx context.Context, competitionID, scoreID primitive.ObjectID, message string) error

	// NotifyScoreReset notifies about score reset
	NotifyScoreReset(ctx context.Context, competitionID, heatID, athleteID primitive.ObjectID) error

	// NotifyHeatOrderChange notifies about heat order change
	NotifyHeatOrderChange(ctx context.Context, competitionID, heatID primitive.ObjectID, newOrder []primitive.ObjectID) error

	// NotifyAthleteRemoved notifies about athlete removal from heat
	NotifyAthleteRemoved(ctx context.Context, competitionID, heatID, athleteID primitive.ObjectID, reason string) error
}
