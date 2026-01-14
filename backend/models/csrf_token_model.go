package models

import (
	"time"

	"go.mongodb.org/mongo-driver/bson/primitive"
)

// CSRFToken represents a CSRF token stored in MongoDB
// Uses TTL index on expires_at for automatic cleanup
type CSRFToken struct {
	ID        primitive.ObjectID `bson:"_id,omitempty" json:"id"`
	Token     string             `bson:"token" json:"token"`           // The CSRF token value
	ExpiresAt time.Time          `bson:"expires_at" json:"expires_at"` // TTL index field
	CreatedAt time.Time          `bson:"created_at" json:"created_at"`
}

// IsValid checks if the CSRF token is still valid
func (ct *CSRFToken) IsValid() bool {
	return time.Now().Before(ct.ExpiresAt)
}

// CSRFTokenDuration is the default duration for CSRF tokens
const CSRFTokenDuration = 1 * time.Hour
