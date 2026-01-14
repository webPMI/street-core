package models

import (
	"time"

	"go.mongodb.org/mongo-driver/bson/primitive"
)

// RateLimit represents a rate limit entry stored in MongoDB
// Uses TTL index on expires_at for automatic cleanup
type RateLimit struct {
	ID        primitive.ObjectID `bson:"_id,omitempty" json:"id"`
	Key       string             `bson:"key" json:"key"`               // IP address or user ID
	Tokens    int                `bson:"tokens" json:"tokens"`         // Remaining tokens
	Window    time.Duration      `bson:"window" json:"window"`         // Time window duration
	ExpiresAt time.Time          `bson:"expires_at" json:"expires_at"` // TTL index field
	UpdatedAt time.Time          `bson:"updated_at" json:"updated_at"`
}

// RateLimitConfig defines the configuration for a rate limiter
type RateLimitConfig struct {
	Name   string        // Identifier for the limiter
	Rate   int           // Max requests per window
	Window time.Duration // Time window
}

// Predefined rate limit configurations
var (
	AuthRateLimitConfig = RateLimitConfig{
		Name:   "auth",
		Rate:   10,
		Window: 1 * time.Minute,
	}

	PasswordChangeRateLimitConfig = RateLimitConfig{
		Name:   "password_change",
		Rate:   5,
		Window: 1 * time.Hour,
	}

	TokenRefreshRateLimitConfig = RateLimitConfig{
		Name:   "token_refresh",
		Rate:   3,
		Window: 5 * time.Minute,
	}

	UploadRateLimitConfig = RateLimitConfig{
		Name:   "upload",
		Rate:   10,
		Window: 1 * time.Minute,
	}

	PostCreationRateLimitConfig = RateLimitConfig{
		Name:   "post_creation",
		Rate:   20,
		Window: 1 * time.Hour,
	}

	CommentRateLimitConfig = RateLimitConfig{
		Name:   "comment",
		Rate:   50,
		Window: 1 * time.Hour,
	}

	LikeRateLimitConfig = RateLimitConfig{
		Name:   "like",
		Rate:   100,
		Window: 1 * time.Minute,
	}

	APIRateLimitConfig = RateLimitConfig{
		Name:   "api",
		Rate:   1000,
		Window: 1 * time.Hour,
	}

	TwoFactorVerifyRateLimitConfig = RateLimitConfig{
		Name:   "two_factor_verify",
		Rate:   3,
		Window: 1 * time.Minute,
	}

	ContactMessageRateLimitConfig = RateLimitConfig{
		Name:   "contact_message",
		Rate:   5,
		Window: 1 * time.Hour,
	}

	ConfigUpdateRateLimitConfig = RateLimitConfig{
		Name:   "config_update",
		Rate:   10,
		Window: 1 * time.Hour,
	}

	AdminImageUploadRateLimitConfig = RateLimitConfig{
		Name:   "admin_image_upload",
		Rate:   20,
		Window: 1 * time.Hour,
	}

	PasswordResetRateLimitConfig = RateLimitConfig{
		Name:   "password_reset",
		Rate:   3,
		Window: 5 * time.Minute,
	}
)
