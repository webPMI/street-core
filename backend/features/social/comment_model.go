package social

import (
	"fmt"
	"time"

	"go.mongodb.org/mongo-driver/bson/primitive"
)

// EntityType constants for commentable entities
const (
	EntityTypePost        = "post"
	EntityTypeCompetition = "competition"
	EntityTypeEvent       = "event"
	EntityTypeClub        = "club"
	EntityTypeProduct     = "product"
)

// Comment represents a user's comment on any entity (post, competition, event, etc.)
type Comment struct {
	ID primitive.ObjectID `bson:"_id,omitempty" json:"id"`

	// Generic entity reference (NEW - supports any commentable entity)
	EntityID   primitive.ObjectID `bson:"entityId,omitempty" json:"entityId,omitempty"`
	EntityType string             `bson:"entityType,omitempty" json:"entityType,omitempty"` // "post", "competition", "event", etc.

	// Legacy post reference (DEPRECATED - kept for backward compatibility)
	PostID primitive.ObjectID `bson:"postId,omitempty" json:"postId,omitempty"`

	// User information
	UserID     primitive.ObjectID `bson:"userId" json:"userId" binding:"required"`
	UserName   string             `bson:"userName" json:"userName"`
	UserAvatar string             `bson:"userAvatar,omitempty" json:"userAvatar,omitempty"`

	// Content
	Text string `bson:"text" json:"text" binding:"required,max=2200"`

	// Reply system (nested comments)
	ParentCommentID *primitive.ObjectID `bson:"parentCommentId,omitempty" json:"parentCommentId,omitempty"`
	RepliesCount    int                 `bson:"repliesCount" json:"repliesCount"`

	// Engagement
	LikesCount int `bson:"likesCount" json:"likesCount"`

	// Status
	IsEdited  bool `bson:"isEdited" json:"isEdited"`
	IsDeleted bool `bson:"isDeleted" json:"-"` // Soft delete

	// User interaction (for current user)
	IsLikedByCurrentUser bool `bson:"-" json:"isLikedByCurrentUser"`

	// Timestamps
	CreatedAt time.Time  `bson:"createdAt" json:"createdAt"`
	UpdatedAt time.Time  `bson:"updatedAt" json:"updatedAt"`
	DeletedAt *time.Time `bson:"deletedAt,omitempty" json:"-"`
}

// CreateCommentRequest represents the request to create a new comment
type CreateCommentRequest struct {
	PostID          primitive.ObjectID  `json:"postId,omitempty"` // Optional - taken from URL param
	Text            string              `json:"text" binding:"required,max=2200"`
	ParentCommentID *primitive.ObjectID `json:"parentCommentId,omitempty"`
}

// UpdateCommentRequest represents the request to update a comment
type UpdateCommentRequest struct {
	Text string `json:"text" binding:"required,max=2200"`
}

// CommentResponse represents a comment with replies
type CommentResponse struct {
	Comment
	Replies []Comment `json:"replies,omitempty"`
}

// Validate validates comment fields (supports both legacy PostID and new EntityID/EntityType)
func (c *Comment) Validate() error {
	// Check if either PostID (legacy) or EntityID (new) is set
	if c.EntityID.IsZero() && c.PostID.IsZero() {
		return fmt.Errorf("either entityId or postId is required")
	}

	// If EntityID is set, EntityType must be specified
	if !c.EntityID.IsZero() && c.EntityType == "" {
		return fmt.Errorf("entityType is required when entityId is set")
	}

	if c.UserID.IsZero() {
		return fmt.Errorf("userId is required")
	}
	if c.Text == "" {
		return fmt.Errorf("text is required")
	}
	if len(c.Text) > 2200 {
		return fmt.Errorf("text must be 2200 characters or less")
	}
	return nil
}

// NormalizeEntityReference ensures that if PostID is set but EntityID is not,
// it migrates PostID to EntityID with EntityType "post" (for backward compatibility)
func (c *Comment) NormalizeEntityReference() {
	// If legacy PostID is set but new EntityID is not, migrate to new format
	if !c.PostID.IsZero() && c.EntityID.IsZero() {
		c.EntityID = c.PostID
		c.EntityType = EntityTypePost
	}
}

// GetEntityID returns the entity ID (prioritizes EntityID over PostID)
func (c *Comment) GetEntityID() primitive.ObjectID {
	if !c.EntityID.IsZero() {
		return c.EntityID
	}
	return c.PostID
}

// GetEntityType returns the entity type (defaults to "post" if not set)
func (c *Comment) GetEntityType() string {
	if c.EntityType != "" {
		return c.EntityType
	}
	if !c.PostID.IsZero() {
		return EntityTypePost
	}
	return ""
}

// SetDefaults sets default values for a new comment
func (c *Comment) SetDefaults() {
	now := time.Now()
	c.CreatedAt = now
	c.UpdatedAt = now
	c.IsEdited = false
	c.IsDeleted = false
	c.LikesCount = 0
	c.RepliesCount = 0
}

// IncrementLikes increments the likes count
func (c *Comment) IncrementLikes() {
	c.LikesCount++
	c.UpdatedAt = time.Now()
}

// DecrementLikes decrements the likes count
func (c *Comment) DecrementLikes() {
	if c.LikesCount > 0 {
		c.LikesCount--
	}
	c.UpdatedAt = time.Now()
}

// IncrementReplies increments the replies count
func (c *Comment) IncrementReplies() {
	c.RepliesCount++
	c.UpdatedAt = time.Now()
}

// DecrementReplies decrements the replies count
func (c *Comment) DecrementReplies() {
	if c.RepliesCount > 0 {
		c.RepliesCount--
	}
	c.UpdatedAt = time.Now()
}

// MarkAsEdited marks the comment as edited
func (c *Comment) MarkAsEdited(newText string) {
	c.Text = newText
	c.IsEdited = true
	c.UpdatedAt = time.Now()
}

// SoftDelete marks the comment as deleted
func (c *Comment) SoftDelete() {
	now := time.Now()
	c.IsDeleted = true
	c.DeletedAt = &now
	c.UpdatedAt = now
	// Keep text for moderation but mark as deleted
	// Frontend should show "[deleted]" or similar
}
