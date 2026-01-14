package users

import (
	"backend/utils"
	"context"

	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/bson/primitive"
	"go.mongodb.org/mongo-driver/mongo"
	"go.mongodb.org/mongo-driver/mongo/options"
)

// MongoUserClient implements UserClient using MongoDB.
type MongoUserClient struct {
	collection *mongo.Collection
}

// NewMongoUserClient creates a new MongoDB-backed user client.
func NewMongoUserClient(db *mongo.Database) *MongoUserClient {
	return &MongoUserClient{
		collection: db.Collection("users"),
	}
}

// GetUserBasicInfo retrieves basic information for a single user.
func (c *MongoUserClient) GetUserBasicInfo(ctx context.Context, userID primitive.ObjectID) (*UserBasicInfo, error) {
	// Only fetch the fields we need
	projection := bson.M{
		"_id":       1,
		"firstName": 1,
		"lastName":  1,
		"avatarUrl": 1,
		"userName":  1,
	}

	var user UserBasicInfo
	err := c.collection.FindOne(
		ctx,
		bson.M{"_id": userID},
		options.FindOne().SetProjection(projection),
	).Decode(&user)

	if err != nil {
		if err == mongo.ErrNoDocuments {
			return nil, nil // User not found, return nil without error
		}
		utils.ErrorWithTag("Database", "Failed to fetch user", map[string]interface{}{
			"error":   err.Error(),
			"user_id": userID.Hex(),
		})
		return nil, err
	}

	return &user, nil
}

// GetUsersBasicInfo retrieves basic information for multiple users.
func (c *MongoUserClient) GetUsersBasicInfo(ctx context.Context, userIDs []primitive.ObjectID) (map[string]*UserBasicInfo, error) {
	if len(userIDs) == 0 {
		return make(map[string]*UserBasicInfo), nil
	}

	// Only fetch the fields we need
	projection := bson.M{
		"_id":       1,
		"firstName": 1,
		"lastName":  1,
		"avatarUrl": 1,
		"userName":  1,
	}

	cursor, err := c.collection.Find(
		ctx,
		bson.M{"_id": bson.M{"$in": userIDs}},
		options.Find().SetProjection(projection),
	)
	if err != nil {
		utils.ErrorWithTag("Database", "Failed to fetch users", map[string]interface{}{
			"error": err.Error(),
			"count": len(userIDs),
		})
		return nil, err
	}
	defer cursor.Close(ctx)

	result := make(map[string]*UserBasicInfo)
	for cursor.Next(ctx) {
		var user UserBasicInfo
		if err := cursor.Decode(&user); err != nil {
			utils.WarnWithTag("Database", "Failed to decode user", map[string]interface{}{
				"error": err.Error(),
			})
			continue
		}
		result[user.ID.Hex()] = &user
	}

	if err := cursor.Err(); err != nil {
		utils.ErrorWithTag("Database", "Cursor error", map[string]interface{}{
			"error": err.Error(),
		})
		return result, err
	}

	utils.DebugWithTag("Database", "Fetched users", map[string]interface{}{
		"fetched":   len(result),
		"requested": len(userIDs),
	})
	return result, nil
}
