package profile

import (
	"context"
	"backend/models"
	"backend/utils"
	"time"

	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/bson/primitive"
	"go.mongodb.org/mongo-driver/mongo"
)

// NotificationService handles notification operations for the profile module
type NotificationService struct {
	collection     *mongo.Collection
	userCollection *mongo.Collection
}

// NewNotificationService creates a new notification service
func NewNotificationService(db *mongo.Database) *NotificationService {
	return &NotificationService{
		collection:     db.Collection("notifications"),
		userCollection: db.Collection("users"),
	}
}

// CreateMentionNotification creates a notification when a user is mentioned in a post
func (s *NotificationService) CreateMentionNotification(
	ctx context.Context,
	mentionedUserID primitive.ObjectID,
	actorID primitive.ObjectID,
	actorName string,
	actorAvatar string,
	postID primitive.ObjectID,
) error {
	notification := &models.Notification{
		UserID:      mentionedUserID,
		ActorID:     actorID,
		ActorName:   actorName,
		ActorAvatar: actorAvatar,
		Type:        models.NotificationTypeMention,
		Message:     actorName + " te mencionó en una publicación",
		PostID:      &postID,
		IsRead:      false,
		IsDeleted:   false,
		CreatedAt:   time.Now(),
		ExpiresAt:   time.Now().AddDate(0, 0, 30), // 30 days
	}

	_, err := s.collection.InsertOne(ctx, notification)
	return err
}

// CreateMentionNotificationsFromUsernames creates notifications for mentioned users
// It looks up users by username and creates notifications for valid mentions
func (s *NotificationService) CreateMentionNotificationsFromUsernames(
	ctx context.Context,
	mentionUsernames []string,
	actorID primitive.ObjectID,
	actorName string,
	actorAvatar string,
	postID primitive.ObjectID,
) {
	if len(mentionUsernames) == 0 {
		return
	}

	for _, username := range mentionUsernames {
		// Look up user by username
		var user struct {
			ID primitive.ObjectID `bson:"_id"`
		}
		err := s.userCollection.FindOne(ctx, bson.M{
			"userName": bson.M{"$regex": "^" + username + "$", "$options": "i"},
		}).Decode(&user)

		if err != nil {
			// User not found, skip
			utils.Warn("User not found for mention notification", map[string]interface{}{"username": username})
			continue
		}

		// Don't notify yourself
		if user.ID == actorID {
			continue
		}

		// Create notification
		err = s.CreateMentionNotification(
			ctx,
			user.ID,
			actorID,
			actorName,
			actorAvatar,
			postID,
		)
		if err != nil {
			utils.Error("Error creating mention notification", map[string]interface{}{"username": username, "error": err.Error()})
			continue
		}

		utils.Info("Created mention notification", map[string]interface{}{"username": username})
	}
}
