package media

import (
	"backend/models"
)

// UploadRequest represents a file upload request
type UploadRequest struct {
	FileType string `form:"fileType" binding:"required,oneof=image video avatar"`
}

// UploadResponse represents the response after uploading a file
type UploadResponse struct {
	ID           string `json:"id"`
	PublicURL    string `json:"publicUrl"`
	ThumbnailURL string `json:"thumbnailUrl,omitempty"`
	FileType     string `json:"fileType"`
	MimeType     string `json:"mimeType"`
	FileSize     int64  `json:"fileSize"`
	Width        int    `json:"width,omitempty"`
	Height       int    `json:"height,omitempty"`
	Duration     int    `json:"duration,omitempty"`
	Status       string `json:"status"`
}

// MultiUploadResponse represents the response after uploading multiple files
type MultiUploadResponse struct {
	Files   []UploadResponse `json:"files"`
	Success int              `json:"success"`
	Failed  int              `json:"failed"`
	Errors  []UploadError    `json:"errors,omitempty"`
}

// UploadError represents an error during file upload
type UploadError struct {
	FileName string `json:"fileName"`
	Error    string `json:"error"`
}

// MediaListResponse represents a paginated list of media files
type MediaListResponse struct {
	Files      []UploadResponse `json:"files"`
	Total      int64            `json:"total"`
	Page       int              `json:"page"`
	Limit      int              `json:"limit"`
	TotalPages int              `json:"totalPages"`
}

// AssociateRequest represents a request to associate media with a post
type AssociateRequest struct {
	MediaIDs []string `json:"mediaIds" binding:"required,min=1,max=10"`
	PostID   string   `json:"postId" binding:"required"`
}

// ToUploadResponse converts a MediaFile to UploadResponse
func ToUploadResponse(media *models.MediaFile) UploadResponse {
	return UploadResponse{
		ID:           media.ID.Hex(),
		PublicURL:    media.PublicURL,
		ThumbnailURL: media.ThumbnailURL,
		FileType:     string(media.FileType),
		MimeType:     media.MimeType,
		FileSize:     media.FileSize,
		Width:        media.Width,
		Height:       media.Height,
		Duration:     media.Duration,
		Status:       string(media.Status),
	}
}

// ToUploadResponses converts a slice of MediaFile to UploadResponse slice
func ToUploadResponses(mediaFiles []*models.MediaFile) []UploadResponse {
	responses := make([]UploadResponse, len(mediaFiles))
	for i, media := range mediaFiles {
		responses[i] = ToUploadResponse(media)
	}
	return responses
}
