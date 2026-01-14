package models

import (
	"time"

	"go.mongodb.org/mongo-driver/bson/primitive"
)

// FailedLoginAttempt tracks failed login attempts per email/IP
type FailedLoginAttempt struct {
	ID           primitive.ObjectID `bson:"_id,omitempty" json:"id"`
	Email        string             `bson:"email" json:"email"`
	IPAddress    string             `bson:"ip_address" json:"ip_address"`
	AttemptCount int                `bson:"attempt_count" json:"attempt_count"`
	LockedUntil  *time.Time         `bson:"locked_until,omitempty" json:"locked_until,omitempty"`
	LastAttempt  time.Time          `bson:"last_attempt" json:"last_attempt"`
	CreatedAt    time.Time          `bson:"created_at" json:"created_at"`
}

// IsLocked returns true if the account is currently locked
func (f *FailedLoginAttempt) IsLocked() bool {
	if f.LockedUntil == nil {
		return false
	}
	return time.Now().Before(*f.LockedUntil)
}

// Constants for lockout policy
const (
	MaxFailedAttempts = 5
	LockoutDuration   = 15 * time.Minute
)
