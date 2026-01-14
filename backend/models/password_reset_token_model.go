package models

import (
	"time"

	"go.mongodb.org/mongo-driver/bson/primitive"
)

// PasswordResetToken represents a password reset token stored in the database
// Tokens expire after 1 hour for security
type PasswordResetToken struct {
	ID        primitive.ObjectID `bson:"_id,omitempty" json:"id"`
	Token     string             `bson:"token" json:"token"`           // Hashed token
	UserID    primitive.ObjectID `bson:"user_id" json:"user_id"`       // User requesting reset
	Email     string             `bson:"email" json:"email"`           // User's email (for quick lookup)
	Used      bool               `bson:"used" json:"used"`             // Mark as used after password reset
	UsedAt    *time.Time         `bson:"used_at,omitempty" json:"used_at,omitempty"`
	ExpiresAt time.Time          `bson:"expires_at" json:"expires_at"` // Automatically deleted by TTL index
	CreatedAt time.Time          `bson:"created_at" json:"created_at"`
}

// IsValid checks if the password reset token is still valid
func (prt *PasswordResetToken) IsValid() bool {
	return !prt.Used && time.Now().Before(prt.ExpiresAt)
}
