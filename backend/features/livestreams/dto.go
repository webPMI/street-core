package livestreams

import "time"

// CreateLiveStreamRequest - Request to create a new livestream
type CreateLiveStreamRequest struct {
	Title            string     `json:"title" binding:"required,min=3,max=100"`
	Description      string     `json:"description" binding:"max=500"`
	ThumbnailURL     string     `json:"thumbnail_url"`
	ScheduledTime    *time.Time `json:"scheduled_time"` // Optional: schedule for later
	RecordingEnabled bool       `json:"recording_enabled"`
	Tags             []string   `json:"tags"`
}

// UpdateLiveStreamRequest - Request to update livestream details
type UpdateLiveStreamRequest struct {
	Title        *string   `json:"title" binding:"omitempty,min=3,max=100"`
	Description  *string   `json:"description" binding:"omitempty,max=500"`
	ThumbnailURL *string   `json:"thumbnail_url"`
	Tags         *[]string `json:"tags"`
}

// StartLiveStreamRequest - Request to start a scheduled livestream
type StartLiveStreamRequest struct {
	// Empty for now, may add options later
}

// EndLiveStreamRequest - Request to end a livestream
type EndLiveStreamRequest struct {
	SaveRecording bool `json:"save_recording"`
}

// JoinLiveStreamRequest - Request to join as a viewer
type JoinLiveStreamRequest struct {
	// StreamID comes from URL parameter
}

// SendChatMessageRequest - Request to send a chat message
type SendChatMessageRequest struct {
	Message string `json:"message" binding:"required,min=1,max=500"`
}

// SendReactionRequest - Request to send a reaction
type SendReactionRequest struct {
	Type string `json:"type" binding:"required,oneof=heart fire thumbsup clap star"` // Allowed reaction types
}

// LiveStreamResponse - Response with livestream data
type LiveStreamResponse struct {
	ID            string    `json:"id"`
	Title         string    `json:"title"`
	Description   string    `json:"description"`
	ThumbnailURL  string    `json:"thumbnail_url,omitempty"`
	HostID        string    `json:"host_id"`
	HostName      string    `json:"host_name"`
	Status        string    `json:"status"`
	ScheduledTime *string   `json:"scheduled_time,omitempty"` // ISO 8601 format
	StartedAt     *string   `json:"started_at,omitempty"`
	EndedAt       *string   `json:"ended_at,omitempty"`
	ViewerCount   int       `json:"viewer_count"`
	PeakViewers   int       `json:"peak_viewers"`
	TotalViews    int       `json:"total_views"`
	ReactionCount int       `json:"reaction_count"`
	MessageCount  int       `json:"message_count"`
	Tags          []string  `json:"tags,omitempty"`
	CreatedAt     string    `json:"created_at"`
}

// JoinStreamResponse - Response when joining a livestream
type JoinStreamResponse struct {
	Stream      LiveStreamResponse `json:"stream"`
	ChannelName string            `json:"channel_name"`
	Token       string            `json:"token"`      // Agora RTC token
	UID         uint              `json:"uid"`        // Agora user ID
	AppID       string            `json:"app_id"`     // Agora App ID
	RecordingURL string           `json:"recording_url,omitempty"` // If VOD available
}

// ChatMessageResponse - Response with chat message
type ChatMessageResponse struct {
	ID        string `json:"id"`
	StreamID  string `json:"stream_id"`
	UserID    string `json:"user_id"`
	Username  string `json:"username"`
	AvatarURL string `json:"avatar_url,omitempty"`
	Message   string `json:"message"`
	CreatedAt string `json:"created_at"`
	IsPinned  bool   `json:"is_pinned"`
}

// ReactionResponse - Response with reaction
type ReactionResponse struct {
	ID        string `json:"id"`
	StreamID  string `json:"stream_id"`
	UserID    string `json:"user_id"`
	Type      string `json:"type"`
	CreatedAt string `json:"created_at"`
}

// StreamListResponse - Response with list of livestreams
type StreamListResponse struct {
	Streams    []LiveStreamResponse `json:"streams"`
	Total      int64               `json:"total"`
	Page       int                 `json:"page"`
	Limit      int                 `json:"limit"`
	TotalPages int                 `json:"total_pages"`
}

// ViewerListResponse - Response with list of viewers
type ViewerListResponse struct {
	Viewers []ViewerResponse `json:"viewers"`
	Total   int             `json:"total"`
}

// ViewerResponse - Response with viewer data
type ViewerResponse struct {
	UserID    string  `json:"user_id"`
	Username  string  `json:"username"`
	AvatarURL string  `json:"avatar_url,omitempty"`
	JoinedAt  string  `json:"joined_at"`
	Duration  int     `json:"duration"` // seconds
}

// StreamStatsResponse - Response with stream statistics
type StreamStatsResponse struct {
	StreamID       string `json:"stream_id"`
	CurrentViewers int    `json:"current_viewers"`
	PeakViewers    int    `json:"peak_viewers"`
	TotalViews     int    `json:"total_views"`
	ReactionCount  int    `json:"reaction_count"`
	MessageCount   int    `json:"message_count"`
	Duration       int    `json:"duration"` // seconds
}
