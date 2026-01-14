package profile

import (
	"fmt"
	"regexp"
	"strings"
	"time"

	"go.mongodb.org/mongo-driver/bson/primitive"
)

var (
	// hashtagRegex matches #hashtag patterns
	hashtagRegex = regexp.MustCompile(`#(\w+)`)
	// mentionRegex matches @username patterns
	mentionRegex = regexp.MustCompile(`@(\w+)`)
)

// MediaType represents the type of media in a post
type MediaType string

const (
	MediaTypeImage    MediaType = "image"
	MediaTypeVideo    MediaType = "video"
	MediaTypeCarousel MediaType = "carousel"
)

// PostVisibility represents who can see the post
type PostVisibility string

const (
	VisibilityPublic    PostVisibility = "public"
	VisibilityFollowers PostVisibility = "followers"
	VisibilityPrivate   PostVisibility = "private"
)

// Post represents a user post with media (Instagram-style)
type Post struct {
	ID         primitive.ObjectID `bson:"_id,omitempty" json:"id"`
	UserID     primitive.ObjectID `bson:"userId" json:"userId" binding:"required"`
	UserName   string             `bson:"userName" json:"userName"`
	UserAvatar string             `bson:"userAvatar,omitempty" json:"userAvatar,omitempty"`

	// Content
	Caption      string    `bson:"caption" json:"caption" binding:"max=2200"` // Instagram limit
	MediaType    MediaType `bson:"mediaType" json:"mediaType" binding:"required,oneof=image video carousel"`
	MediaURLs    []string  `bson:"mediaUrls" json:"mediaUrls" binding:"required,min=1,max=10"`
	MediaPaths   []string  `bson:"mediaPaths" json:"-"`                                  // Server paths (not exposed in API)
	ThumbnailURL string    `bson:"thumbnailUrl,omitempty" json:"thumbnailUrl,omitempty"` // For videos

	// Engagement metrics
	LikesCount    int `bson:"likesCount" json:"likesCount"`
	CommentsCount int `bson:"commentsCount" json:"commentsCount"`
	SharesCount   int `bson:"sharesCount" json:"sharesCount"`
	ViewsCount    int `bson:"viewsCount" json:"viewsCount"` // For videos
	SavesCount    int `bson:"savesCount" json:"savesCount"` // Saved by users

	// Metadata
	Location string   `bson:"location,omitempty" json:"location,omitempty"`
	Tags     []string `bson:"tags,omitempty" json:"tags,omitempty"`         // #hashtags
	Mentions []string `bson:"mentions,omitempty" json:"mentions,omitempty"` // @mentions

	// Status
	IsActive   bool           `bson:"isActive" json:"isActive"`
	IsArchived bool           `bson:"isArchived" json:"isArchived"`
	IsDeleted  bool           `bson:"isDeleted" json:"-"` // Soft delete
	Visibility PostVisibility `bson:"visibility" json:"visibility" binding:"required,oneof=public followers private"`

	// User interaction tracking (for current user)
	IsLikedByCurrentUser bool `bson:"-" json:"isLikedByCurrentUser"`
	IsSavedByCurrentUser bool `bson:"-" json:"isSavedByCurrentUser"`

	// Timestamps
	CreatedAt time.Time  `bson:"createdAt" json:"createdAt"`
	UpdatedAt time.Time  `bson:"updatedAt" json:"updatedAt"`
	DeletedAt *time.Time `bson:"deletedAt,omitempty" json:"-"`
}

// PostResponse is used for API responses with user engagement data
type PostResponse struct {
	Post
	IsLiked bool `json:"isLiked"`
	IsSaved bool `json:"isSaved"`
}

// CreatePostRequest represents the request to create a new post
type CreatePostRequest struct {
	Caption    string         `json:"caption" binding:"max=2200"`
	MediaType  MediaType      `json:"mediaType" binding:"required,oneof=image video carousel"`
	MediaURLs  []string       `json:"mediaUrls" binding:"required,min=1,max=10"`
	Location   string         `json:"location,omitempty"`
	Tags       []string       `json:"tags,omitempty"`
	Mentions   []string       `json:"mentions,omitempty"`
	Visibility PostVisibility `json:"visibility" binding:"required,oneof=public followers private"`
}

// UpdatePostRequest represents the request to update a post
type UpdatePostRequest struct {
	Caption    *string         `json:"caption,omitempty" binding:"omitempty,max=2200"`
	Location   *string         `json:"location,omitempty"`
	Tags       []string        `json:"tags,omitempty"`
	Mentions   []string        `json:"mentions,omitempty"`
	Visibility *PostVisibility `json:"visibility,omitempty" binding:"omitempty,oneof=public followers private"`
}

// PostStats represents aggregate statistics for a user's posts
type PostStats struct {
	TotalPosts      int     `json:"totalPosts"`
	TotalLikes      int     `json:"totalLikes"`
	TotalComments   int     `json:"totalComments"`
	TotalViews      int     `json:"totalViews"`
	AverageLikes    float64 `json:"averageLikes"`
	AverageComments float64 `json:"averageComments"`
}

// Validate validates post fields
func (p *Post) Validate() error {
	if p.UserID.IsZero() {
		return fmt.Errorf("userId is required")
	}
	if len(p.MediaURLs) == 0 {
		return fmt.Errorf("at least one media URL is required")
	}
	if len(p.MediaURLs) > 10 {
		return fmt.Errorf("maximum 10 media files per post")
	}
	if len(p.Caption) > 2200 {
		return fmt.Errorf("caption must be 2200 characters or less")
	}
	return nil
}

// SetDefaults sets default values for a new post
func (p *Post) SetDefaults() {
	now := time.Now()
	p.CreatedAt = now
	p.UpdatedAt = now
	p.IsActive = true
	p.IsArchived = false
	p.IsDeleted = false
	p.LikesCount = 0
	p.CommentsCount = 0
	p.SharesCount = 0
	p.ViewsCount = 0
	p.SavesCount = 0

	if p.Visibility == "" {
		p.Visibility = VisibilityPublic
	}
	if p.Tags == nil {
		p.Tags = []string{}
	}
	if p.Mentions == nil {
		p.Mentions = []string{}
	}
}

// IncrementLikes increments the likes count
func (p *Post) IncrementLikes() {
	p.LikesCount++
	p.UpdatedAt = time.Now()
}

// DecrementLikes decrements the likes count
func (p *Post) DecrementLikes() {
	if p.LikesCount > 0 {
		p.LikesCount--
	}
	p.UpdatedAt = time.Now()
}

// IncrementComments increments the comments count
func (p *Post) IncrementComments() {
	p.CommentsCount++
	p.UpdatedAt = time.Now()
}

// DecrementComments decrements the comments count
func (p *Post) DecrementComments() {
	if p.CommentsCount > 0 {
		p.CommentsCount--
	}
	p.UpdatedAt = time.Now()
}

// IncrementViews increments the views count
func (p *Post) IncrementViews() {
	p.ViewsCount++
}

// SoftDelete marks the post as deleted
func (p *Post) SoftDelete() {
	now := time.Now()
	p.IsDeleted = true
	p.IsActive = false
	p.DeletedAt = &now
	p.UpdatedAt = now
}

// ExtractHashtags extracts unique hashtags from text (without the # symbol)
func ExtractHashtags(text string) []string {
	matches := hashtagRegex.FindAllStringSubmatch(text, -1)
	seen := make(map[string]bool)
	var hashtags []string

	for _, match := range matches {
		if len(match) > 1 {
			tag := strings.ToLower(match[1])
			if !seen[tag] {
				seen[tag] = true
				hashtags = append(hashtags, tag)
			}
		}
	}
	return hashtags
}

// ExtractMentions extracts unique mentions from text (without the @ symbol)
func ExtractMentions(text string) []string {
	matches := mentionRegex.FindAllStringSubmatch(text, -1)
	seen := make(map[string]bool)
	var mentions []string

	for _, match := range matches {
		if len(match) > 1 {
			mention := strings.ToLower(match[1])
			if !seen[mention] {
				seen[mention] = true
				mentions = append(mentions, mention)
			}
		}
	}
	return mentions
}

// ExtractAndSetTagsFromCaption parses the caption and sets Tags field
func (p *Post) ExtractAndSetTagsFromCaption() {
	if p.Caption != "" {
		extracted := ExtractHashtags(p.Caption)
		// Merge with existing tags (avoid duplicates)
		seen := make(map[string]bool)
		for _, tag := range p.Tags {
			seen[strings.ToLower(tag)] = true
		}
		for _, tag := range extracted {
			if !seen[tag] {
				p.Tags = append(p.Tags, tag)
				seen[tag] = true
			}
		}
	}
}

// ExtractAndSetMentionsFromCaption parses the caption and sets Mentions field
func (p *Post) ExtractAndSetMentionsFromCaption() {
	if p.Caption != "" {
		extracted := ExtractMentions(p.Caption)
		// Merge with existing mentions (avoid duplicates)
		seen := make(map[string]bool)
		for _, mention := range p.Mentions {
			seen[strings.ToLower(mention)] = true
		}
		for _, mention := range extracted {
			if !seen[mention] {
				p.Mentions = append(p.Mentions, mention)
				seen[mention] = true
			}
		}
	}
}
