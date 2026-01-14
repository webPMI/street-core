package profile

import (
	"fmt"
	"time"

	"go.mongodb.org/mongo-driver/bson/primitive"
)

// FollowStatus represents the status of a follow request
type FollowStatus string

const (
	FollowStatusPending  FollowStatus = "pending"  // For private accounts
	FollowStatusAccepted FollowStatus = "accepted" // Follow is active
	FollowStatusRejected FollowStatus = "rejected" // Follow request rejected
)

// Follow represents a follow relationship between users
type Follow struct {
	ID          primitive.ObjectID `bson:"_id,omitempty" json:"id"`
	FollowerID  primitive.ObjectID `bson:"followerId" json:"followerId" binding:"required"`   // User who follows
	FollowingID primitive.ObjectID `bson:"followingId" json:"followingId" binding:"required"` // User being followed

	// User info for quick access
	FollowerName    string `bson:"followerName" json:"followerName"`
	FollowerAvatar  string `bson:"followerAvatar,omitempty" json:"followerAvatar,omitempty"`
	FollowingName   string `bson:"followingName" json:"followingName"`
	FollowingAvatar string `bson:"followingAvatar,omitempty" json:"followingAvatar,omitempty"`

	// Status
	Status FollowStatus `bson:"status" json:"status"`

	// Timestamps
	CreatedAt  time.Time  `bson:"createdAt" json:"createdAt"`
	AcceptedAt *time.Time `bson:"acceptedAt,omitempty" json:"acceptedAt,omitempty"`
}

// Block represents a blocked user relationship
type Block struct {
	ID        primitive.ObjectID `bson:"_id,omitempty" json:"id"`
	BlockerID primitive.ObjectID `bson:"blockerId" json:"blockerId" binding:"required"` // User who blocks
	BlockedID primitive.ObjectID `bson:"blockedId" json:"blockedId" binding:"required"` // User being blocked

	BlockedName   string `bson:"blockedName" json:"blockedName"`
	BlockedAvatar string `bson:"blockedAvatar,omitempty" json:"blockedAvatar,omitempty"`

	Reason    string    `bson:"reason,omitempty" json:"reason,omitempty"`
	CreatedAt time.Time `bson:"createdAt" json:"createdAt"`
}

// FollowRequest represents a request to follow
type FollowRequest struct {
	UserID primitive.ObjectID `json:"userId" binding:"required"`
}

// FollowResponse represents the response after follow action
type FollowResponse struct {
	IsFollowing    bool   `json:"isFollowing"`
	FollowStatus   string `json:"followStatus"` // "accepted" or "pending"
	FollowersCount int    `json:"followersCount"`
	FollowingCount int    `json:"followingCount"`
}

// FollowStats represents follow statistics for a user
type FollowStats struct {
	FollowersCount       int `json:"followersCount"`
	FollowingCount       int `json:"followingCount"`
	PendingRequestsCount int `json:"pendingRequestsCount"` // Requests to follow this user
}

// UserFollowInfo represents user info with follow status
type UserFollowInfo struct {
	UserID       string `json:"userId"`
	UserName     string `json:"userName"`
	UserAvatar   string `json:"userAvatar,omitempty"`
	IsFollowing  bool   `json:"isFollowing"`
	FollowsYou   bool   `json:"followsYou"`
	FollowStatus string `json:"followStatus,omitempty"` // "pending", "accepted", null
}

// Validate validates follow fields
func (f *Follow) Validate() error {
	if f.FollowerID.IsZero() {
		return fmt.Errorf("followerId is required")
	}
	if f.FollowingID.IsZero() {
		return fmt.Errorf("followingId is required")
	}
	if f.FollowerID == f.FollowingID {
		return fmt.Errorf("cannot follow yourself")
	}
	return nil
}

// SetDefaults sets default values for a new follow
func (f *Follow) SetDefaults() {
	f.CreatedAt = time.Now()
	if f.Status == "" {
		f.Status = FollowStatusAccepted // Default to accepted (for public accounts)
	}
}

// Accept accepts a follow request
func (f *Follow) Accept() {
	now := time.Now()
	f.Status = FollowStatusAccepted
	f.AcceptedAt = &now
}

// Reject rejects a follow request
func (f *Follow) Reject() {
	f.Status = FollowStatusRejected
}

// Validate validates block fields
func (b *Block) Validate() error {
	if b.BlockerID.IsZero() {
		return fmt.Errorf("blockerId is required")
	}
	if b.BlockedID.IsZero() {
		return fmt.Errorf("blockedId is required")
	}
	if b.BlockerID == b.BlockedID {
		return fmt.Errorf("cannot block yourself")
	}
	return nil
}

// SetDefaults sets default values for a new block
func (b *Block) SetDefaults() {
	b.CreatedAt = time.Now()
}
