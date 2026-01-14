package profile

import (
	"fmt"
	"time"

	"go.mongodb.org/mongo-driver/bson/primitive"
)

// SavedPost represents a user's saved post for later viewing
type SavedPost struct {
	ID        primitive.ObjectID `bson:"_id,omitempty" json:"id"`
	PostID    primitive.ObjectID `bson:"postId" json:"postId" binding:"required"`
	UserID    primitive.ObjectID `bson:"userId" json:"userId" binding:"required"`
	CreatedAt time.Time          `bson:"createdAt" json:"createdAt"`
}

// SavedPostResponse represents the response after saving/unsaving a post
type SavedPostResponse struct {
	IsSaved bool   `json:"isSaved"`
	SaveID  string `json:"saveId,omitempty"`
}

// Validate validates saved post fields
func (s *SavedPost) Validate() error {
	if s.PostID.IsZero() {
		return fmt.Errorf("postId is required")
	}
	if s.UserID.IsZero() {
		return fmt.Errorf("userId is required")
	}
	return nil
}

// SetDefaults sets default values for a new saved post
func (s *SavedPost) SetDefaults() {
	s.CreatedAt = time.Now()
}
