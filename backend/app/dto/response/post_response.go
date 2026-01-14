package response

import "time"

// PostResponse represents a post response
// Excludes internal fields like deleted status, media paths, etc.
type PostResponse struct {
	ID         string `json:"id"`
	UserID     string `json:"userId"`
	UserName   string `json:"userName"`
	UserAvatar string `json:"userAvatar,omitempty"`

	// Content
	Caption      string   `json:"caption,omitempty"`
	MediaType    string   `json:"mediaType"`
	MediaURLs    []string `json:"mediaUrls"`
	ThumbnailURL string   `json:"thumbnailUrl,omitempty"`

	// Engagement metrics
	LikesCount    int `json:"likesCount"`
	CommentsCount int `json:"commentsCount"`
	SharesCount   int `json:"sharesCount"`
	ViewsCount    int `json:"viewsCount"`
	SavesCount    int `json:"savesCount"`

	// Metadata
	Location   string   `json:"location,omitempty"`
	Tags       []string `json:"tags,omitempty"`
	Mentions   []string `json:"mentions,omitempty"`
	Visibility string   `json:"visibility"`

	// User interaction tracking
	IsLikedByCurrentUser bool `json:"isLikedByCurrentUser,omitempty"`
	IsSavedByCurrentUser bool `json:"isSavedByCurrentUser,omitempty"`

	// Status
	IsActive   bool `json:"isActive"`
	IsArchived bool `json:"isArchived"`

	// Timestamps
	CreatedAt time.Time `json:"createdAt"`
	UpdatedAt time.Time `json:"updatedAt"`
}

// PostListResponse represents a simplified post response for lists/feeds
type PostListResponse struct {
	ID                   string    `json:"id"`
	UserID               string    `json:"userId"`
	UserName             string    `json:"userName"`
	UserAvatar           string    `json:"userAvatar,omitempty"`
	MediaType            string    `json:"mediaType"`
	MediaURLs            []string  `json:"mediaUrls"`
	ThumbnailURL         string    `json:"thumbnailUrl,omitempty"`
	LikesCount           int       `json:"likesCount"`
	CommentsCount        int       `json:"commentsCount"`
	IsLikedByCurrentUser bool      `json:"isLikedByCurrentUser,omitempty"`
	CreatedAt            time.Time `json:"createdAt"`
}

// CommentResponse represents a comment response
type CommentResponse struct {
	ID                   string    `json:"id"`
	PostID               string    `json:"postId"`
	UserID               string    `json:"userId"`
	UserName             string    `json:"userName"`
	UserAvatar           string    `json:"userAvatar,omitempty"`
	Content              string    `json:"content"`
	LikesCount           int       `json:"likesCount"`
	RepliesCount         int       `json:"repliesCount"`
	ParentID             string    `json:"parentId,omitempty"` // For nested comments
	IsLikedByCurrentUser bool      `json:"isLikedByCurrentUser,omitempty"`
	CreatedAt            time.Time `json:"createdAt"`
	UpdatedAt            time.Time `json:"updatedAt"`
}

// LikeResponse represents a like response
type LikeResponse struct {
	ID         string    `json:"id"`
	UserID     string    `json:"userId"`
	TargetType string    `json:"targetType"` // "post" or "comment"
	TargetID   string    `json:"targetId"`
	CreatedAt  time.Time `json:"createdAt"`
}

// PostStatsResponse represents post statistics
type PostStatsResponse struct {
	TotalPosts      int     `json:"totalPosts"`
	TotalLikes      int     `json:"totalLikes"`
	TotalComments   int     `json:"totalComments"`
	TotalViews      int     `json:"totalViews"`
	TotalShares     int     `json:"totalShares"`
	AverageLikes    float64 `json:"averageLikes"`
	AverageComments float64 `json:"averageComments"`
	MostLikedPostID string  `json:"mostLikedPostId,omitempty"`
}
