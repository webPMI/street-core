package livestreams

import (
	"time"

	"go.mongodb.org/mongo-driver/bson/primitive"
)

// LiveStreamStatus represents the current state of a livestream
type LiveStreamStatus string

const (
	LiveStreamStatusScheduled LiveStreamStatus = "scheduled"
	LiveStreamStatusLive      LiveStreamStatus = "live"
	LiveStreamStatusEnded     LiveStreamStatus = "ended"
	LiveStreamStatusCancelled LiveStreamStatus = "cancelled"
)

// LiveStream represents a live streaming session
type LiveStream struct {
	ID primitive.ObjectID `bson:"_id,omitempty" json:"id"`

	// Stream info
	Title       string `bson:"title" json:"title"`
	Description string `bson:"description" json:"description"`
	ThumbnailURL string `bson:"thumbnailUrl,omitempty" json:"thumbnail_url,omitempty"`

	// Host info
	HostID   primitive.ObjectID `bson:"hostId" json:"host_id"`
	HostName string            `bson:"hostName" json:"host_name"` // Denormalized for performance

	// Agora configuration
	ChannelName string `bson:"channelName" json:"channel_name"` // Agora channel name
	AppID       string `bson:"appId" json:"app_id"`
	Token       string `bson:"token,omitempty" json:"token,omitempty"` // Agora RTC token
	UID         uint   `bson:"uid" json:"uid"`                        // Agora user ID

	// Stream status
	Status        LiveStreamStatus `bson:"status" json:"status"`
	ScheduledTime *time.Time      `bson:"scheduledTime,omitempty" json:"scheduled_time,omitempty"`
	StartedAt     *time.Time      `bson:"startedAt,omitempty" json:"started_at,omitempty"`
	EndedAt       *time.Time      `bson:"endedAt,omitempty" json:"ended_at,omitempty"`

	// Statistics
	ViewerCount    int `bson:"viewerCount" json:"viewer_count"`         // Current viewers
	PeakViewers    int `bson:"peakViewers" json:"peak_viewers"`         // Max concurrent viewers
	TotalViews     int `bson:"totalViews" json:"total_views"`           // Total unique views
	ReactionCount  int `bson:"reactionCount" json:"reaction_count"`     // Total reactions
	MessageCount   int `bson:"messageCount" json:"message_count"`       // Total chat messages

	// Recording
	RecordingEnabled bool   `bson:"recordingEnabled" json:"recording_enabled"`
	RecordingURL     string `bson:"recordingUrl,omitempty" json:"recording_url,omitempty"`
	RecordingID      string `bson:"recordingId,omitempty" json:"recording_id,omitempty"` // Agora cloud recording ID

	// Metadata
	Tags      []string  `bson:"tags,omitempty" json:"tags,omitempty"`
	CreatedAt time.Time `bson:"createdAt" json:"created_at"`
	UpdatedAt time.Time `bson:"updatedAt" json:"updated_at"`
}

// LiveStreamViewer represents a viewer in a livestream
type LiveStreamViewer struct {
	ID primitive.ObjectID `bson:"_id,omitempty" json:"id"`

	StreamID primitive.ObjectID `bson:"streamId" json:"stream_id"`
	UserID   primitive.ObjectID `bson:"userId" json:"user_id"`
	Username string            `bson:"username" json:"username"` // Denormalized

	// Viewer session
	JoinedAt *time.Time `bson:"joinedAt" json:"joined_at"`
	LeftAt   *time.Time `bson:"leftAt,omitempty" json:"left_at,omitempty"`
	Duration int        `bson:"duration" json:"duration"` // Watch duration in seconds

	// Agora token for this viewer
	Token string `bson:"token,omitempty" json:"token,omitempty"`
	UID   uint   `bson:"uid" json:"uid"`
}

// ChatMessage represents a chat message in a livestream
type ChatMessage struct {
	ID primitive.ObjectID `bson:"_id,omitempty" json:"id"`

	StreamID primitive.ObjectID `bson:"streamId" json:"stream_id"`
	UserID   primitive.ObjectID `bson:"userId" json:"user_id"`
	Username string            `bson:"username" json:"username"` // Denormalized
	AvatarURL string           `bson:"avatarUrl,omitempty" json:"avatar_url,omitempty"`

	// Message content
	Message   string    `bson:"message" json:"message"`
	CreatedAt time.Time `bson:"createdAt" json:"created_at"`

	// Moderation
	IsDeleted bool `bson:"isDeleted" json:"is_deleted"`
	IsPinned  bool `bson:"isPinned" json:"is_pinned"`
}

// StreamReaction represents a reaction (emoji, like, etc.) in a livestream
type StreamReaction struct {
	ID primitive.ObjectID `bson:"_id,omitempty" json:"id"`

	StreamID primitive.ObjectID `bson:"streamId" json:"stream_id"`
	UserID   primitive.ObjectID `bson:"userId" json:"user_id"`

	// Reaction type
	Type      string    `bson:"type" json:"type"` // heart, fire, thumbsup, etc.
	CreatedAt time.Time `bson:"createdAt" json:"created_at"`
}

// Collection names
const (
	LiveStreamsCollection = "livestreams"
	ViewersCollection    = "livestream_viewers"
	ChatMessagesCollection = "livestream_messages"
	ReactionsCollection   = "livestream_reactions"
)
