package social

import (
	"fmt"
	"time"

	"go.mongodb.org/mongo-driver/bson/primitive"
)

// Like represents a user's like on a post
type Like struct {
	ID         primitive.ObjectID `bson:"_id,omitempty" json:"id"`
	PostID     primitive.ObjectID `bson:"postId" json:"postId" binding:"required"`
	UserID     primitive.ObjectID `bson:"userId" json:"userId" binding:"required"`
	UserName   string             `bson:"userName" json:"userName"`
	UserAvatar string             `bson:"userAvatar,omitempty" json:"userAvatar,omitempty"`
	CreatedAt  time.Time          `bson:"createdAt" json:"createdAt"`
}

// LikeRequest represents the request to like/unlike a post
type LikeRequest struct {
	PostID primitive.ObjectID `json:"postId" binding:"required"`
}

// LikeResponse represents the response after liking a post
type LikeResponse struct {
	IsLiked    bool   `json:"isLiked"`
	LikesCount int    `json:"likesCount"`
	LikeID     string `json:"likeId,omitempty"`
}

// Validate validates like fields
func (l *Like) Validate() error {
	if l.PostID.IsZero() {
		return fmt.Errorf("postId is required")
	}
	if l.UserID.IsZero() {
		return fmt.Errorf("userId is required")
	}
	return nil
}

// SetDefaults sets default values for a new like
func (l *Like) SetDefaults() {
	l.CreatedAt = time.Now()
}
