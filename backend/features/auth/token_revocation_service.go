package auth

import (
	"context"
	"time"

	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/bson/primitive"
	"go.mongodb.org/mongo-driver/mongo"
)

// tokenRevocationServiceImpl implements ITokenRevocationService
type tokenRevocationServiceImpl struct {
	db                *mongo.Database
	revokedTokensColl *mongo.Collection
	refreshTokensColl *mongo.Collection
}

// RevokedToken represents a revoked token in the database
type RevokedToken struct {
	ID        primitive.ObjectID `bson:"_id,omitempty"`
	Token     string             `bson:"token"`
	UserID    primitive.ObjectID `bson:"user_id,omitempty"`
	RevokedAt time.Time          `bson:"revoked_at"`
	ExpiresAt time.Time          `bson:"expires_at"`
}

// NewTokenRevocationService creates a new token revocation service
func NewTokenRevocationService(db *mongo.Database) ITokenRevocationService {
	return &tokenRevocationServiceImpl{
		db:                db,
		revokedTokensColl: db.Collection("revoked_tokens"),
		refreshTokensColl: db.Collection("refresh_tokens"),
	}
}

// RevokeToken adds a token to the revocation list.
// The context allows for request cancellation and tracing.
func (s *tokenRevocationServiceImpl) RevokeToken(ctx context.Context, token string) error {
	revokedToken := RevokedToken{
		ID:        primitive.NewObjectID(),
		Token:     token,
		RevokedAt: time.Now(),
		ExpiresAt: time.Now().Add(24 * time.Hour),
	}

	_, err := s.revokedTokensColl.InsertOne(ctx, revokedToken)
	return err
}

// IsTokenRevoked checks if a token has been revoked.
// The context allows for request cancellation and tracing.
func (s *tokenRevocationServiceImpl) IsTokenRevoked(ctx context.Context, token string) (bool, error) {
	count, err := s.revokedTokensColl.CountDocuments(ctx, bson.M{
		"token":      token,
		"expires_at": bson.M{"$gt": time.Now()},
	})
	if err != nil {
		return false, err
	}

	return count > 0, nil
}

// RevokeAllUserTokens revokes all tokens for a specific user.
// The context allows for request cancellation and tracing.
func (s *tokenRevocationServiceImpl) RevokeAllUserTokens(ctx context.Context, userID string) error {
	objectID, err := primitive.ObjectIDFromHex(userID)
	if err != nil {
		return err
	}

	now := time.Now()

	// Revoke all refresh tokens
	_, err = s.refreshTokensColl.UpdateMany(ctx,
		bson.M{
			"user_id": objectID,
			"revoked": false,
		},
		bson.M{
			"$set": bson.M{
				"revoked":       true,
				"revoked_at":    now,
				"revoke_reason": "user_logout_all",
			},
		},
	)

	return err
}

// CleanupExpiredTokens removes expired tokens from the revocation list.
// The context allows for cancellation of long-running cleanup operations.
func (s *tokenRevocationServiceImpl) CleanupExpiredTokens(ctx context.Context) error {
	_, err := s.revokedTokensColl.DeleteMany(ctx, bson.M{
		"expires_at": bson.M{"$lt": time.Now()},
	})

	return err
}
