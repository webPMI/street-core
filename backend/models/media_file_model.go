package models

import (
	"fmt"
	"time"

	"go.mongodb.org/mongo-driver/bson/primitive"
)

// MediaFileType represents the type of media file
type MediaFileType string

const (
	MediaFileTypeImage     MediaFileType = "image"
	MediaFileTypeVideo     MediaFileType = "video"
	MediaFileTypeThumbnail MediaFileType = "thumbnail"
	MediaFileTypeAvatar    MediaFileType = "avatar"
)

// MediaFileStatus represents the processing status of a media file
type MediaFileStatus string

const (
	MediaFileStatusPending    MediaFileStatus = "pending"
	MediaFileStatusProcessing MediaFileStatus = "processing"
	MediaFileStatusReady      MediaFileStatus = "ready"
	MediaFileStatusFailed     MediaFileStatus = "failed"
)

// MediaFile represents an uploaded media file with metadata
type MediaFile struct {
	ID     primitive.ObjectID  `bson:"_id,omitempty" json:"id"`
	UserID primitive.ObjectID  `bson:"userId" json:"userId" binding:"required"`
	PostID *primitive.ObjectID `bson:"postId,omitempty" json:"postId,omitempty"`

	// File information
	FileName     string        `bson:"fileName" json:"fileName"`
	OriginalName string        `bson:"originalName" json:"originalName"`
	FileType     MediaFileType `bson:"fileType" json:"fileType" binding:"required,oneof=image video thumbnail avatar"`
	MimeType     string        `bson:"mimeType" json:"mimeType"`
	FileSize     int64         `bson:"fileSize" json:"fileSize"` // in bytes

	// Storage paths
	FilePath     string `bson:"filePath" json:"-"`                                    // Server file path (not exposed)
	PublicURL    string `bson:"publicUrl" json:"publicUrl"`                           // Public accessible URL
	ThumbnailURL string `bson:"thumbnailUrl,omitempty" json:"thumbnailUrl,omitempty"` // For videos

	// Media metadata
	Width       int    `bson:"width,omitempty" json:"width,omitempty"`
	Height      int    `bson:"height,omitempty" json:"height,omitempty"`
	Duration    int    `bson:"duration,omitempty" json:"duration,omitempty"` // Video duration in seconds
	AspectRatio string `bson:"aspectRatio,omitempty" json:"aspectRatio,omitempty"`

	// Processing status
	Status          MediaFileStatus `bson:"status" json:"status"`
	ProcessingError string          `bson:"processingError,omitempty" json:"-"` // Not exposed

	// Security
	HashSHA256      string `bson:"hashSha256" json:"-"`                // File hash for deduplication
	VirusScanStatus string `bson:"virusScanStatus,omitempty" json:"-"` // clean/infected/pending

	// Reference counting for deduplication
	// Tracks how many times this file is referenced (shared across multiple uploads)
	RefCount int `bson:"refCount" json:"-"` // Number of references to this file

	// Timestamps
	CreatedAt time.Time `bson:"createdAt" json:"createdAt"`
	UpdatedAt time.Time `bson:"updatedAt" json:"updatedAt"`
}

// Validate validates media file fields
func (m *MediaFile) Validate() error {
	if m.UserID.IsZero() {
		return fmt.Errorf("userId is required")
	}
	if m.FileName == "" {
		return fmt.Errorf("fileName is required")
	}
	if m.FileSize <= 0 {
		return fmt.Errorf("fileSize must be greater than 0")
	}
	// Max file size: 100MB for images, 500MB for videos
	maxSize := int64(100 * 1024 * 1024) // 100MB default
	if m.FileType == MediaFileTypeVideo {
		maxSize = int64(500 * 1024 * 1024) // 500MB for videos
	}
	if m.FileSize > maxSize {
		return fmt.Errorf("file size exceeds maximum allowed")
	}
	return nil
}

// SetDefaults sets default values for a new media file
func (m *MediaFile) SetDefaults() {
	now := time.Now()
	m.CreatedAt = now
	m.UpdatedAt = now
	m.Status = MediaFileStatusPending
	m.VirusScanStatus = "pending"
	// Initialize reference count to 1 (first upload)
	if m.RefCount == 0 {
		m.RefCount = 1
	}
}

// MarkAsProcessing marks the file as being processed
func (m *MediaFile) MarkAsProcessing() {
	m.Status = MediaFileStatusProcessing
	m.UpdatedAt = time.Now()
}

// MarkAsReady marks the file as ready to use
func (m *MediaFile) MarkAsReady() {
	m.Status = MediaFileStatusReady
	m.VirusScanStatus = "clean"
	m.UpdatedAt = time.Now()
}

// MarkAsFailed marks the file processing as failed
func (m *MediaFile) MarkAsFailed(errorMsg string) {
	m.Status = MediaFileStatusFailed
	m.ProcessingError = errorMsg
	m.UpdatedAt = time.Now()
}

// IsImage returns true if the file is an image
func (m *MediaFile) IsImage() bool {
	return m.FileType == MediaFileTypeImage || m.FileType == MediaFileTypeThumbnail || m.FileType == MediaFileTypeAvatar
}

// IsVideo returns true if the file is a video
func (m *MediaFile) IsVideo() bool {
	return m.FileType == MediaFileTypeVideo
}
