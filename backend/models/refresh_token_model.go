package models

import (
	"time"

	"go.mongodb.org/mongo-driver/bson/primitive"
)

// RefreshToken represents a refresh token stored in the database
type RefreshToken struct {
	ID           primitive.ObjectID `bson:"_id,omitempty" json:"id"`
	Token        string             `bson:"token" json:"token"`
	UserID       primitive.ObjectID `bson:"user_id" json:"user_id"`
	FamilyID     string             `bson:"family_id" json:"family_id"`                 // NEW: Token family for rotation detection
	Used         bool               `bson:"used" json:"used"`                           // NEW: Mark as used (not revoked yet)
	UsedAt       *time.Time         `bson:"used_at,omitempty" json:"used_at,omitempty"` // NEW: When it was used
	ExpiresAt    time.Time          `bson:"expires_at" json:"expires_at"`
	CreatedAt    time.Time          `bson:"created_at" json:"created_at"`
	Revoked      bool               `bson:"revoked" json:"revoked"`
	RevokedAt    *time.Time         `bson:"revoked_at,omitempty" json:"revoked_at,omitempty"`
	RevokeReason string             `bson:"revoke_reason,omitempty" json:"revoke_reason,omitempty"` // NEW: Why was it revoked
}

// IsValid checks if the refresh token is still valid
func (rt *RefreshToken) IsValid() bool {
	return !rt.Revoked && time.Now().Before(rt.ExpiresAt)
}
