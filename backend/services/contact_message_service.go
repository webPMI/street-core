package services

import (
	"backend/models"
	"context"
	"time"

	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/bson/primitive"
	"go.mongodb.org/mongo-driver/mongo"
	"go.mongodb.org/mongo-driver/mongo/options"
)

// ContactMessageService handles contact message operations
type ContactMessageService struct {
	db         *mongo.Database
	collection *mongo.Collection
}

// NewContactMessageService creates a new contact message service
func NewContactMessageService(db *mongo.Database) *ContactMessageService {
	return &ContactMessageService{
		db:         db,
		collection: db.Collection("contact_messages"),
	}
}

// SubmitMessage submits a new contact message
func (s *ContactMessageService) SubmitMessage(ctx context.Context, message *models.ContactMessage) error {
	message.ID = primitive.NewObjectID()
	message.CreatedAt = time.Now()
	message.Status = "pending"

	_, err := s.collection.InsertOne(ctx, message)
	return err
}

// GetMessages retrieves contact messages with pagination
func (s *ContactMessageService) GetMessages(ctx context.Context, page, limit int64, status string) ([]models.ContactMessage, int64, error) {
	filter := bson.M{}
	if status != "" {
		filter["status"] = status
	}

	// Count total
	total, err := s.collection.CountDocuments(ctx, filter)
	if err != nil {
		return nil, 0, err
	}

	// Find with pagination
	opts := options.Find().
		SetSort(bson.M{"createdAt": -1}).
		SetSkip((page - 1) * limit).
		SetLimit(limit)

	cursor, err := s.collection.Find(ctx, filter, opts)
	if err != nil {
		return nil, 0, err
	}
	defer cursor.Close(ctx)

	var messages []models.ContactMessage
	if err := cursor.All(ctx, &messages); err != nil {
		return nil, 0, err
	}

	return messages, total, nil
}

// GetMessageByID retrieves a contact message by ID
func (s *ContactMessageService) GetMessageByID(ctx context.Context, id string) (*models.ContactMessage, error) {
	objectID, err := primitive.ObjectIDFromHex(id)
	if err != nil {
		return nil, err
	}

	var message models.ContactMessage
	err = s.collection.FindOne(ctx, bson.M{"_id": objectID}).Decode(&message)
	if err != nil {
		return nil, err
	}

	return &message, nil
}

// UpdateMessageStatus updates the status of a contact message
func (s *ContactMessageService) UpdateMessageStatus(ctx context.Context, id, status string, response string) error {
	objectID, err := primitive.ObjectIDFromHex(id)
	if err != nil {
		return err
	}

	update := bson.M{
		"$set": bson.M{
			"status":    status,
			"updatedAt": time.Now(),
		},
	}

	if response != "" {
		update["$set"].(bson.M)["response"] = response
		update["$set"].(bson.M)["respondedAt"] = time.Now()
	}

	_, err = s.collection.UpdateOne(ctx, bson.M{"_id": objectID}, update)
	return err
}

// DeleteMessage deletes a contact message
func (s *ContactMessageService) DeleteMessage(ctx context.Context, id string) error {
	objectID, err := primitive.ObjectIDFromHex(id)
	if err != nil {
		return err
	}

	_, err = s.collection.DeleteOne(ctx, bson.M{"_id": objectID})
	return err
}
