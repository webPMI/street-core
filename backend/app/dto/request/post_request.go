package request

// CreatePostRequest represents the post creation request payload
type CreatePostRequest struct {
	Caption    string   `json:"caption,omitempty" binding:"omitempty,max=2200"`
	MediaType  string   `json:"mediaType" binding:"required,oneof=image video carousel"`
	MediaURLs  []string `json:"mediaUrls" binding:"required,min=1,max=10"`
	Location   string   `json:"location,omitempty"`
	Tags       []string `json:"tags,omitempty"`
	Mentions   []string `json:"mentions,omitempty"`
	Visibility string   `json:"visibility" binding:"required,oneof=public followers private"`
}

// UpdatePostRequest represents the post update request payload
type UpdatePostRequest struct {
	Caption    *string  `json:"caption,omitempty" binding:"omitempty,max=2200"`
	Location   *string  `json:"location,omitempty"`
	Tags       []string `json:"tags,omitempty"`
	Mentions   []string `json:"mentions,omitempty"`
	Visibility *string  `json:"visibility,omitempty" binding:"omitempty,oneof=public followers private"`
}

// CreateCommentRequest represents the comment creation request payload
type CreateCommentRequest struct {
	Content  string `json:"content" binding:"required,min=1,max=500"`
	ParentID string `json:"parentId,omitempty"` // For nested comments/replies
}

// UpdateCommentRequest represents the comment update request payload
type UpdateCommentRequest struct {
	Content string `json:"content" binding:"required,min=1,max=500"`
}

// CreateLikeRequest represents the like creation request payload
type CreateLikeRequest struct {
	TargetType string `json:"targetType" binding:"required,oneof=post comment"`
	TargetID   string `json:"targetId" binding:"required"`
}
