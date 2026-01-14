package profile

import (
	"fmt"
	"time"

	"go.mongodb.org/mongo-driver/bson/primitive"
)

// StoryMediaType represents the type of media in a story
type StoryMediaType string

const (
	StoryMediaTypeImage StoryMediaType = "image"
	StoryMediaTypeVideo StoryMediaType = "video"
)

// StoryVisibility represents who can view the story
type StoryVisibility string

const (
	StoryVisibilityPublic       StoryVisibility = "public"        // All followers
	StoryVisibilityFollowers    StoryVisibility = "followers"     // Only followers
	StoryVisibilityCloseFriends StoryVisibility = "close_friends" // Only close friends list
)

// Story represents a user's story (24h expiration)
type Story struct {
	ID     primitive.ObjectID `bson:"_id,omitempty" json:"id"`
	UserID primitive.ObjectID `bson:"userId" json:"userId" binding:"required"`

	// User info for quick access
	UserName   string `bson:"userName" json:"userName"`
	UserAvatar string `bson:"userAvatar,omitempty" json:"userAvatar,omitempty"`

	// Content
	MediaType    StoryMediaType `bson:"mediaType" json:"mediaType" binding:"required,oneof=image video"`
	MediaURL     string         `bson:"mediaUrl" json:"mediaUrl" binding:"required"`
	ThumbnailURL string         `bson:"thumbnailUrl,omitempty" json:"thumbnailUrl,omitempty"` // For videos
	Caption      string         `bson:"caption,omitempty" json:"caption,omitempty" binding:"max=200"`

	// Engagement
	ViewsCount int         `bson:"viewsCount" json:"viewsCount"`
	Viewers    []StoryView `bson:"viewers" json:"viewers"` // Embedded viewers

	// Visibility
	Visibility StoryVisibility `bson:"visibility" json:"visibility"`

	// Status
	IsActive  bool `bson:"isActive" json:"isActive"`
	IsDeleted bool `bson:"isDeleted" json:"-"`

	// Timestamps
	CreatedAt time.Time `bson:"createdAt" json:"createdAt"`
	ExpiresAt time.Time `bson:"expiresAt" json:"expiresAt"` // 24 hours from creation
}

// StoryView represents a view on a story
type StoryView struct {
	ID      primitive.ObjectID `bson:"_id,omitempty" json:"id"`
	StoryID primitive.ObjectID `bson:"storyId" json:"storyId" binding:"required"`
	UserID  primitive.ObjectID `bson:"userId" json:"userId" binding:"required"`

	// User info for quick access
	UserName   string `bson:"userName" json:"userName"`
	UserAvatar string `bson:"userAvatar,omitempty" json:"userAvatar,omitempty"`

	ViewedAt time.Time `bson:"viewedAt" json:"viewedAt"`
}

// StoryHighlight represents a saved story collection
type StoryHighlight struct {
	ID       primitive.ObjectID   `bson:"_id,omitempty" json:"id"`
	UserID   primitive.ObjectID   `bson:"userId" json:"userId" binding:"required"`
	Title    string               `bson:"title" json:"title" binding:"required,min=1,max=50"`
	CoverURL string               `bson:"coverUrl,omitempty" json:"coverUrl,omitempty"`
	StoryIDs []primitive.ObjectID `bson:"storyIds" json:"storyIds"`

	// Timestamps
	CreatedAt time.Time `bson:"createdAt" json:"createdAt"`
	UpdatedAt time.Time `bson:"updatedAt" json:"updatedAt"`
}

// StoryStats represents story statistics for a user
type StoryStats struct {
	ActiveStoriesCount int `json:"activeStoriesCount"`
	TotalViews         int `json:"totalViews"`
	HighlightsCount    int `json:"highlightsCount"`
}

// Validate validates story fields
func (s *Story) Validate() error {
	if s.UserID.IsZero() {
		return fmt.Errorf("userId is required")
	}
	if s.MediaURL == "" {
		return fmt.Errorf("mediaUrl is required")
	}
	if s.MediaType != StoryMediaTypeImage && s.MediaType != StoryMediaTypeVideo {
		return fmt.Errorf("invalid media type")
	}
	if len(s.Caption) > 200 {
		return fmt.Errorf("caption too long")
	}
	return nil
}

// SetDefaults sets default values for a new story
func (s *Story) SetDefaults() {
	now := time.Now()
	s.CreatedAt = now
	s.ExpiresAt = now.Add(24 * time.Hour) // Expires in 24 hours
	s.IsActive = true
	s.IsDeleted = false
	s.ViewsCount = 0

	if s.Visibility == "" {
		s.Visibility = StoryVisibilityFollowers // Default to followers only
	}
}

// IsExpired checks if the story has expired
func (s *Story) IsExpired() bool {
	return time.Now().After(s.ExpiresAt)
}

// IncrementViews increments the views count
func (s *Story) IncrementViews() {
	s.ViewsCount++
}

// Validate validates story view fields
func (sv *StoryView) Validate() error {
	if sv.StoryID.IsZero() {
		return fmt.Errorf("storyId is required")
	}
	if sv.UserID.IsZero() {
		return fmt.Errorf("userId is required")
	}
	return nil
}

// SetDefaults sets default values for a new story view
func (sv *StoryView) SetDefaults() {
	sv.ViewedAt = time.Now()
}

// Validate validates story highlight fields
func (sh *StoryHighlight) Validate() error {
	if sh.UserID.IsZero() {
		return fmt.Errorf("userId is required")
	}
	if sh.Title == "" {
		return fmt.Errorf("title is required")
	}
	if len(sh.Title) > 50 {
		return fmt.Errorf("title too long")
	}
	return nil
}

// SetDefaults sets default values for a new story highlight
func (sh *StoryHighlight) SetDefaults() {
	now := time.Now()
	sh.CreatedAt = now
	sh.UpdatedAt = now

	if sh.StoryIDs == nil {
		sh.StoryIDs = []primitive.ObjectID{}
	}
}

// AddStory adds a story to the highlight
func (sh *StoryHighlight) AddStory(storyID primitive.ObjectID) {
	sh.StoryIDs = append(sh.StoryIDs, storyID)
	sh.UpdatedAt = time.Now()
}

// RemoveStory removes a story from the highlight
func (sh *StoryHighlight) RemoveStory(storyID primitive.ObjectID) {
	for i, id := range sh.StoryIDs {
		if id == storyID {
			sh.StoryIDs = append(sh.StoryIDs[:i], sh.StoryIDs[i+1:]...)
			sh.UpdatedAt = time.Now()
			break
		}
	}
}
