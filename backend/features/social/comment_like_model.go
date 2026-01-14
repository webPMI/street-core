package social

import (
	"fmt"
	"time"

	"go.mongodb.org/mongo-driver/bson/primitive"
)

// CommentLike represents a user's like on a comment
type CommentLike struct {
	ID         primitive.ObjectID `bson:"_id,omitempty" json:"id"`
	CommentID  primitive.ObjectID `bson:"commentId" json:"commentId" binding:"required"`
	UserID     primitive.ObjectID `bson:"userId" json:"userId" binding:"required"`
	UserName   string             `bson:"userName" json:"userName"`
	UserAvatar string             `bson:"userAvatar,omitempty" json:"userAvatar,omitempty"`
	CreatedAt  time.Time          `bson:"createdAt" json:"createdAt"`
}

// CommentLikeResponse represents the response after liking a comment
type CommentLikeResponse struct {
	IsLiked    bool   `json:"isLiked"`
	LikesCount int    `json:"likesCount"`
	LikeID     string `json:"likeId,omitempty"`
}

// Validate validates comment like fields
func (cl *CommentLike) Validate() error {
	if cl.CommentID.IsZero() {
		return fmt.Errorf("commentId is required")
	}
	if cl.UserID.IsZero() {
		return fmt.Errorf("userId is required")
	}
	return nil
}

// SetDefaults sets default values for a new comment like
func (cl *CommentLike) SetDefaults() {
	cl.CreatedAt = time.Now()
}
