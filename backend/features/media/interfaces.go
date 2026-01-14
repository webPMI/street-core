package media

import (
	"context"
	"mime/multipart"
	"time"

	"backend/models"

	"go.mongodb.org/mongo-driver/bson/primitive"
	"go.mongodb.org/mongo-driver/mongo"
)

// IMediaRepository defines the interface for media file storage operations
type IMediaRepository interface {
	// Create saves a new media file record
	Create(ctx context.Context, media *models.MediaFile) error

	// GetByID retrieves a media file by its ID
	GetByID(ctx context.Context, id string) (*models.MediaFile, error)

	// GetByUserID retrieves all media files for a user
	GetByUserID(ctx context.Context, userID string, limit, offset int) ([]*models.MediaFile, error)

	// GetByPostID retrieves all media files associated with a post
	GetByPostID(ctx context.Context, postID string) ([]*models.MediaFile, error)

	// GetByHash finds a media file by its SHA256 hash (for deduplication)
	GetByHash(ctx context.Context, hash string) (*models.MediaFile, error)

	// Update updates an existing media file record
	Update(ctx context.Context, media *models.MediaFile) error

	// UpdateStatus updates the processing status of a media file
	UpdateStatus(ctx context.Context, id string, status models.MediaFileStatus, errorMsg string) error

	// Delete removes a media file record
	Delete(ctx context.Context, id string) error

	// DeleteByUserID removes all media files for a user
	DeleteByUserID(ctx context.Context, userID string) error

	// CountByUserID counts total media files for a user
	CountByUserID(ctx context.Context, userID string) (int64, error)

	// GetPendingFiles retrieves files with pending status for processing
	GetPendingFiles(ctx context.Context, limit int) ([]*models.MediaFile, error)

	// AssociateWithPost links a media file to a post
	AssociateWithPost(ctx context.Context, mediaID string, postID primitive.ObjectID) error

	// GetOrphanedFiles retrieves files without postId older than specified time
	GetOrphanedFiles(ctx context.Context, olderThan time.Time, limit int) ([]*models.MediaFile, error)

	// CountOrphanedFiles counts files without postId older than specified time
	CountOrphanedFiles(ctx context.Context, olderThan time.Time) (int64, error)

	// IncrementRefCount atomically increments the reference count for a media file
	IncrementRefCount(ctx context.Context, id string) error

	// DecrementRefCount atomically decrements the reference count for a media file
	// Returns the new refCount value
	DecrementRefCount(ctx context.Context, id string) (int, error)

	// CountByHash counts the number of files with the same hash
	CountByHash(ctx context.Context, hash string) (int64, error)

	// GetByIDs retrieves multiple media files by their IDs in a single query
	GetByIDs(ctx context.Context, ids []string) ([]*models.MediaFile, error)

	// GetClient returns the MongoDB client for advanced operations (e.g., transactions)
	GetClient() *mongo.Client
}

// IMediaService defines the interface for media business logic
type IMediaService interface {
	// UploadFile handles a single file upload (backward compatible)
	UploadFile(ctx context.Context, file *multipart.FileHeader, fileType models.MediaFileType, userID string) (*models.MediaFile, error)

	// UploadFileWithContext handles a file upload with context-based organization
	UploadFileWithContext(ctx context.Context, file *multipart.FileHeader, fileType models.MediaFileType, userID string, mediaContext string) (*models.MediaFile, error)

	// UploadMultipleFiles handles multiple file uploads (carousel)
	UploadMultipleFiles(ctx context.Context, files []*multipart.FileHeader, fileType models.MediaFileType, userID string) ([]*models.MediaFile, error)

	// GetFile retrieves a media file by ID
	GetFile(ctx context.Context, id string) (*models.MediaFile, error)

	// GetUserFiles retrieves all files for a user with pagination
	GetUserFiles(ctx context.Context, userID string, limit, offset int) ([]*models.MediaFile, int64, error)

	// GetPostMedia retrieves all media files for a specific post
	GetPostMedia(ctx context.Context, postID string) ([]*models.MediaFile, error)

	// DeleteFile deletes a media file (both record and physical file)
	DeleteFile(ctx context.Context, id string, userID string) error

	// ProcessPendingFiles processes files in pending status (thumbnails, etc.)
	// Returns the number of files processed
	ProcessPendingFiles(ctx context.Context) (int, error)

	// Shutdown gracefully shuts down the media service
	Shutdown(ctx context.Context) error

	// AssociateWithPost links media files to a post
	AssociateWithPost(ctx context.Context, mediaIDs []string, postID string) error

	// ValidateOwnership checks if user owns the media file
	ValidateOwnership(ctx context.Context, mediaID, userID string) error

	// GetFilesByIDs retrieves multiple files by their IDs
	GetFilesByIDs(ctx context.Context, ids []string) ([]*models.MediaFile, error)

	// CleanupOrphanedFiles removes files not associated with any post after 24 hours
	CleanupOrphanedFiles(ctx context.Context) error
}

// IMediaProcessor defines the interface for media processing operations
type IMediaProcessor interface {
	// ProcessImage processes an image (resize, optimize, create thumbnail)
	ProcessImage(ctx context.Context, media *models.MediaFile) error

	// ProcessVideo processes a video (extract thumbnail, get duration)
	ProcessVideo(ctx context.Context, media *models.MediaFile) error

	// CreateThumbnail creates a thumbnail for an image
	CreateThumbnail(sourcePath, destPath string, width, height int) error

	// ResizeImage resizes an image to specified dimensions
	ResizeImage(sourcePath, destPath string, maxWidth, maxHeight int) error

	// GetImageDimensions returns the width and height of an image
	GetImageDimensions(filePath string) (width, height int, err error)

	// GetVideoDuration returns the duration of a video in seconds
	GetVideoDuration(filePath string) (int, error)

	// ExtractVideoThumbnail extracts a thumbnail from a video
	ExtractVideoThumbnail(videoPath, thumbnailPath string) error
}
