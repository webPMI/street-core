package mongodb

import (
	"context"
	"time"

	"backend/features/competitions/domain/entities"
	"backend/features/competitions/domain/repositories"

	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/bson/primitive"
	"go.mongodb.org/mongo-driver/mongo"
	"go.mongodb.org/mongo-driver/mongo/options"
)

// JudgeInvitationRepositoryImpl implements the JudgeInvitationRepository interface
type JudgeInvitationRepositoryImpl struct {
	collection *mongo.Collection
}

// NewJudgeInvitationRepository creates a new judge invitation repository
func NewJudgeInvitationRepository(db *mongo.Database) repositories.JudgeInvitationRepository {
	return &JudgeInvitationRepositoryImpl{
		collection: db.Collection("judge_invitations"),
	}
}

// Save creates a new judge invitation
func (r *JudgeInvitationRepositoryImpl) Save(ctx context.Context, invitation *entities.JudgeInvitation) error {
	_, err := r.collection.InsertOne(ctx, invitation)
	if err != nil {
		if mongo.IsDuplicateKeyError(err) {
			return entities.ErrAlreadyInvited
		}
		return err
	}
	return nil
}

// Update updates an existing judge invitation
func (r *JudgeInvitationRepositoryImpl) Update(ctx context.Context, invitation *entities.JudgeInvitation) error {
	invitation.PrepareForUpdate()

	filter := bson.M{"_id": invitation.ID}
	update := bson.M{"$set": invitation}

	result, err := r.collection.UpdateOne(ctx, filter, update)
	if err != nil {
		return err
	}

	if result.MatchedCount == 0 {
		return entities.ErrInvitationNotFound
	}

	return nil
}

// FindByID finds a judge invitation by ID
func (r *JudgeInvitationRepositoryImpl) FindByID(ctx context.Context, id primitive.ObjectID) (*entities.JudgeInvitation, error) {
	var invitation entities.JudgeInvitation
	filter := bson.M{"_id": id}

	err := r.collection.FindOne(ctx, filter).Decode(&invitation)
	if err != nil {
		if err == mongo.ErrNoDocuments {
			return nil, entities.ErrInvitationNotFound
		}
		return nil, err
	}

	return &invitation, nil
}

// Delete deletes a judge invitation by ID
func (r *JudgeInvitationRepositoryImpl) Delete(ctx context.Context, id primitive.ObjectID) error {
	filter := bson.M{"_id": id}

	result, err := r.collection.DeleteOne(ctx, filter)
	if err != nil {
		return err
	}

	if result.DeletedCount == 0 {
		return entities.ErrInvitationNotFound
	}

	return nil
}

// FindByCompetitionID finds all invitations for a competition
func (r *JudgeInvitationRepositoryImpl) FindByCompetitionID(ctx context.Context, competitionID primitive.ObjectID, status string, page, limit int) ([]*entities.JudgeInvitation, int64, error) {
	filter := bson.M{"competitionId": competitionID}
	if status != "" {
		filter["status"] = status
	}

	return r.findWithPagination(ctx, filter, page, limit)
}

// FindByUserID finds all invitations for a user
func (r *JudgeInvitationRepositoryImpl) FindByUserID(ctx context.Context, userID primitive.ObjectID, status string, page, limit int) ([]*entities.JudgeInvitation, int64, error) {
	filter := bson.M{"invitedUserId": userID}
	if status != "" {
		filter["status"] = status
	}

	return r.findWithPagination(ctx, filter, page, limit)
}

// FindPendingByCompetitionAndUser finds a pending invitation for a specific user and competition
func (r *JudgeInvitationRepositoryImpl) FindPendingByCompetitionAndUser(ctx context.Context, competitionID, userID primitive.ObjectID) (*entities.JudgeInvitation, error) {
	filter := bson.M{
		"competitionId": competitionID,
		"invitedUserId": userID,
		"status":        entities.InvitationStatusPending,
	}

	var invitation entities.JudgeInvitation
	err := r.collection.FindOne(ctx, filter).Decode(&invitation)
	if err != nil {
		if err == mongo.ErrNoDocuments {
			return nil, entities.ErrInvitationNotFound
		}
		return nil, err
	}

	return &invitation, nil
}

// ExpireOldInvitations marks all expired invitations
func (r *JudgeInvitationRepositoryImpl) ExpireOldInvitations(ctx context.Context) (int64, error) {
	filter := bson.M{
		"status":    entities.InvitationStatusPending,
		"expiresAt": bson.M{"$lt": time.Now()},
	}
	update := bson.M{
		"$set": bson.M{
			"status":    entities.InvitationStatusExpired,
			"updatedAt": time.Now(),
		},
	}

	result, err := r.collection.UpdateMany(ctx, filter, update)
	if err != nil {
		return 0, err
	}

	return result.ModifiedCount, nil
}

// findWithPagination is a helper for paginated queries
func (r *JudgeInvitationRepositoryImpl) findWithPagination(ctx context.Context, filter bson.M, page, limit int) ([]*entities.JudgeInvitation, int64, error) {
	// Count total documents
	total, err := r.collection.CountDocuments(ctx, filter)
	if err != nil {
		return nil, 0, err
	}

	// Find with pagination
	skip := (page - 1) * limit
	findOptions := options.Find().
		SetSkip(int64(skip)).
		SetLimit(int64(limit)).
		SetSort(bson.M{"createdAt": -1})

	cursor, err := r.collection.Find(ctx, filter, findOptions)
	if err != nil {
		return nil, 0, err
	}
	defer cursor.Close(ctx)

	var invitations []*entities.JudgeInvitation
	if err := cursor.All(ctx, &invitations); err != nil {
		return nil, 0, err
	}

	return invitations, total, nil
}
