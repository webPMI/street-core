package models

import (
	"fmt"
	"time"

	"go.mongodb.org/mongo-driver/bson/primitive"
)

// NotificationType represents the type of notification
type NotificationType string

const (
	NotificationTypeFollow       NotificationType = "follow"        // Someone followed you
	NotificationTypeFollowAccept NotificationType = "follow_accept" // Follow request accepted
	NotificationTypeLike         NotificationType = "like"          // Someone liked your post
	NotificationTypeComment      NotificationType = "comment"       // Someone commented on your post
	NotificationTypeCommentReply NotificationType = "comment_reply" // Someone replied to your comment
	NotificationTypeStoryView    NotificationType = "story_view"    // Someone viewed your story
	NotificationTypeMention      NotificationType = "mention"       // Someone mentioned you
)

// Notification represents a user notification
type Notification struct {
	ID     primitive.ObjectID `bson:"_id,omitempty" json:"id"`
	UserID primitive.ObjectID `bson:"userId" json:"userId" binding:"required"` // Recipient

	// Actor (who triggered the notification)
	ActorID     primitive.ObjectID `bson:"actorId" json:"actorId" binding:"required"`
	ActorName   string             `bson:"actorName" json:"actorName"`
	ActorAvatar string             `bson:"actorAvatar,omitempty" json:"actorAvatar,omitempty"`

	// Notification details
	Type    NotificationType `bson:"type" json:"type" binding:"required"`
	Message string           `bson:"message" json:"message"`

	// Related entities (optional - depending on type)
	PostID    *primitive.ObjectID `bson:"postId,omitempty" json:"postId,omitempty"`
	CommentID *primitive.ObjectID `bson:"commentId,omitempty" json:"commentId,omitempty"`
	StoryID   *primitive.ObjectID `bson:"storyId,omitempty" json:"storyId,omitempty"`

	// Status
	IsRead    bool `bson:"isRead" json:"isRead"`
	IsDeleted bool `bson:"isDeleted" json:"-"`

	// Timestamps
	CreatedAt time.Time  `bson:"createdAt" json:"createdAt"`
	ReadAt    *time.Time `bson:"readAt,omitempty" json:"readAt,omitempty"`
	ExpiresAt time.Time  `bson:"expiresAt" json:"expiresAt"` // Auto-delete after 30 days
}

// NotificationSettings represents user notification preferences
type NotificationSettings struct {
	ID     primitive.ObjectID `bson:"_id,omitempty" json:"id"`
	UserID primitive.ObjectID `bson:"userId" json:"userId" binding:"required"`

	// Email notifications
	EmailEnabled        bool `bson:"emailEnabled" json:"emailEnabled"`
	EmailOnFollow       bool `bson:"emailOnFollow" json:"emailOnFollow"`
	EmailOnLike         bool `bson:"emailOnLike" json:"emailOnLike"`
	EmailOnComment      bool `bson:"emailOnComment" json:"emailOnComment"`
	EmailOnCommentReply bool `bson:"emailOnCommentReply" json:"emailOnCommentReply"`
	EmailOnMention      bool `bson:"emailOnMention" json:"emailOnMention"`

	// Push notifications
	PushEnabled        bool `bson:"pushEnabled" json:"pushEnabled"`
	PushOnFollow       bool `bson:"pushOnFollow" json:"pushOnFollow"`
	PushOnLike         bool `bson:"pushOnLike" json:"pushOnLike"`
	PushOnComment      bool `bson:"pushOnComment" json:"pushOnComment"`
	PushOnCommentReply bool `bson:"pushOnCommentReply" json:"pushOnCommentReply"`
	PushOnMention      bool `bson:"pushOnMention" json:"pushOnMention"`
	PushOnStoryView    bool `bson:"pushOnStoryView" json:"pushOnStoryView"`

	// Timestamps
	CreatedAt time.Time `bson:"createdAt" json:"createdAt"`
	UpdatedAt time.Time `bson:"updatedAt" json:"updatedAt"`
}

// NotificationStats represents notification statistics for a user
type NotificationStats struct {
	TotalCount  int `json:"totalCount"`
	UnreadCount int `json:"unreadCount"`
}

// Validate validates notification fields
func (n *Notification) Validate() error {
	if n.UserID.IsZero() {
		return fmt.Errorf("userId is required")
	}
	if n.ActorID.IsZero() {
		return fmt.Errorf("actorId is required")
	}
	if n.Type == "" {
		return fmt.Errorf("type is required")
	}
	return nil
}

// SetDefaults sets default values for a new notification
func (n *Notification) SetDefaults() {
	now := time.Now()
	n.CreatedAt = now
	n.ExpiresAt = now.AddDate(0, 0, 30) // Expires in 30 days
	n.IsRead = false
	n.IsDeleted = false
}

// MarkAsRead marks the notification as read
func (n *Notification) MarkAsRead() {
	now := time.Now()
	n.IsRead = true
	n.ReadAt = &now
}

// Validate validates notification settings fields
func (ns *NotificationSettings) Validate() error {
	if ns.UserID.IsZero() {
		return fmt.Errorf("userId is required")
	}
	return nil
}

// SetDefaults sets default values for new notification settings
func (ns *NotificationSettings) SetDefaults() {
	now := time.Now()
	ns.CreatedAt = now
	ns.UpdatedAt = now

	// Default all notifications to enabled
	ns.EmailEnabled = true
	ns.EmailOnFollow = true
	ns.EmailOnLike = true
	ns.EmailOnComment = true
	ns.EmailOnCommentReply = true
	ns.EmailOnMention = true

	ns.PushEnabled = true
	ns.PushOnFollow = true
	ns.PushOnLike = true
	ns.PushOnComment = true
	ns.PushOnCommentReply = true
	ns.PushOnMention = true
	ns.PushOnStoryView = false // Story views disabled by default (can be noisy)
}
