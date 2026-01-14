// Package adapters provides implementations of the ports interfaces
// that connect to the main application services.
//
// These adapters act as bridges between the competitions module and
// the rest of the application, maintaining the module's independence.
package adapters

import (
	"backend/features/competitions/ports"
	"context"

	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/bson/primitive"
	"go.mongodb.org/mongo-driver/mongo"
)

// MongoUserAdapter adapts the MongoDB users collection to the UserProvider interface.
// This allows the competitions module to access user data without depending on
// the user service implementation.
type MongoUserAdapter struct {
	collection *mongo.Collection
}

// NewMongoUserAdapter creates a new MongoDB user adapter.
func NewMongoUserAdapter(db *mongo.Database) *MongoUserAdapter {
	return &MongoUserAdapter{
		collection: db.Collection("users"),
	}
}

// GetUserByID retrieves a user by their ID.
func (a *MongoUserAdapter) GetUserByID(ctx context.Context, userID primitive.ObjectID) (*ports.UserInfo, error) {
	var result struct {
		ID        primitive.ObjectID `bson:"_id"`
		Email     string             `bson:"email"`
		FirstName string             `bson:"firstName"`
		LastName  string             `bson:"lastName"`
		UserName  string             `bson:"userName"`
		Avatar    string             `bson:"avatar"`
		Role      string             `bson:"role"`
	}

	err := a.collection.FindOne(ctx, bson.M{"_id": userID}).Decode(&result)
	if err != nil {
		if err == mongo.ErrNoDocuments {
			return nil, nil
		}
		return nil, err
	}

	return &ports.UserInfo{
		ID:        result.ID,
		Email:     result.Email,
		FirstName: result.FirstName,
		LastName:  result.LastName,
		UserName:  result.UserName,
		Avatar:    result.Avatar,
		Role:      result.Role,
	}, nil
}

// GetUsersByIDs retrieves multiple users by their IDs.
func (a *MongoUserAdapter) GetUsersByIDs(ctx context.Context, userIDs []primitive.ObjectID) ([]*ports.UserInfo, error) {
	if len(userIDs) == 0 {
		return []*ports.UserInfo{}, nil
	}

	cursor, err := a.collection.Find(ctx, bson.M{"_id": bson.M{"$in": userIDs}})
	if err != nil {
		return nil, err
	}
	defer cursor.Close(ctx)

	var users []*ports.UserInfo
	for cursor.Next(ctx) {
		var result struct {
			ID        primitive.ObjectID `bson:"_id"`
			Email     string             `bson:"email"`
			FirstName string             `bson:"firstName"`
			LastName  string             `bson:"lastName"`
			UserName  string             `bson:"userName"`
			Avatar    string             `bson:"avatar"`
			Role      string             `bson:"role"`
		}

		if err := cursor.Decode(&result); err != nil {
			continue
		}

		users = append(users, &ports.UserInfo{
			ID:        result.ID,
			Email:     result.Email,
			FirstName: result.FirstName,
			LastName:  result.LastName,
			UserName:  result.UserName,
			Avatar:    result.Avatar,
			Role:      result.Role,
		})
	}

	return users, nil
}

// SearchUsers searches for users by query string.
func (a *MongoUserAdapter) SearchUsers(ctx context.Context, query string, limit int) ([]*ports.UserInfo, error) {
	if limit <= 0 {
		limit = 10
	}

	filter := bson.M{
		"$or": []bson.M{
			{"email": bson.M{"$regex": query, "$options": "i"}},
			{"firstName": bson.M{"$regex": query, "$options": "i"}},
			{"lastName": bson.M{"$regex": query, "$options": "i"}},
			{"userName": bson.M{"$regex": query, "$options": "i"}},
		},
	}

	cursor, err := a.collection.Find(ctx, filter)
	if err != nil {
		return nil, err
	}
	defer cursor.Close(ctx)

	var users []*ports.UserInfo
	count := 0
	for cursor.Next(ctx) && count < limit {
		var result struct {
			ID        primitive.ObjectID `bson:"_id"`
			Email     string             `bson:"email"`
			FirstName string             `bson:"firstName"`
			LastName  string             `bson:"lastName"`
			UserName  string             `bson:"userName"`
			Avatar    string             `bson:"avatar"`
			Role      string             `bson:"role"`
		}

		if err := cursor.Decode(&result); err != nil {
			continue
		}

		users = append(users, &ports.UserInfo{
			ID:        result.ID,
			Email:     result.Email,
			FirstName: result.FirstName,
			LastName:  result.LastName,
			UserName:  result.UserName,
			Avatar:    result.Avatar,
			Role:      result.Role,
		})
		count++
	}

	return users, nil
}

// AuthServiceAdapter adapts the auth service to the AuthTokenVerifier interface.
type AuthServiceAdapter struct {
	verifier ports.AuthTokenVerifier
}

// NewAuthServiceAdapter creates a new auth service adapter.
func NewAuthServiceAdapter(verifier ports.AuthTokenVerifier) *AuthServiceAdapter {
	return &AuthServiceAdapter{verifier: verifier}
}

// VerifyAuthToken verifies a JWT token.
func (a *AuthServiceAdapter) VerifyAuthToken(tokenString string) (map[string]interface{}, error) {
	return a.verifier.VerifyAuthToken(tokenString)
}

// TokenRevocationAdapter adapts the token revocation service.
type TokenRevocationAdapter struct {
	checker ports.TokenRevocationChecker
}

// NewTokenRevocationAdapter creates a new token revocation adapter.
func NewTokenRevocationAdapter(checker ports.TokenRevocationChecker) *TokenRevocationAdapter {
	return &TokenRevocationAdapter{checker: checker}
}

// IsTokenRevoked checks if a token is revoked.
func (a *TokenRevocationAdapter) IsTokenRevoked(ctx context.Context, token string) (bool, error) {
	return a.checker.IsTokenRevoked(ctx, token)
}
