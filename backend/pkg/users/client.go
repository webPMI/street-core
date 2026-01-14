// Package users provides cross-module user lookup functionality.
// This package allows other modules to fetch basic user information
// without directly depending on the users module.
package users

import (
	"context"

	"go.mongodb.org/mongo-driver/bson/primitive"
)

// UserBasicInfo contains basic user information for cross-module lookups.
// This is a lightweight struct that doesn't expose sensitive user data.
type UserBasicInfo struct {
	ID        primitive.ObjectID `json:"id" bson:"_id"`
	FirstName string             `json:"firstName" bson:"firstName"`
	LastName  string             `json:"lastName" bson:"lastName"`
	AvatarURL string             `json:"avatarUrl" bson:"avatarUrl"`
	UserName  string             `json:"userName" bson:"userName"`
}

// FullName returns the user's full name (FirstName + LastName)
func (u *UserBasicInfo) FullName() string {
	if u.LastName == "" {
		return u.FirstName
	}
	return u.FirstName + " " + u.LastName
}

// UserClient defines the interface for cross-module user lookups.
// Other modules should depend on this interface, not on the concrete implementation.
type UserClient interface {
	// GetUserBasicInfo retrieves basic information for a single user.
	// Returns nil if user not found (no error).
	GetUserBasicInfo(ctx context.Context, userID primitive.ObjectID) (*UserBasicInfo, error)

	// GetUsersBasicInfo retrieves basic information for multiple users.
	// Returns a map of userID (hex string) -> UserBasicInfo.
	// Users not found are simply not included in the result map.
	GetUsersBasicInfo(ctx context.Context, userIDs []primitive.ObjectID) (map[string]*UserBasicInfo, error)
}
