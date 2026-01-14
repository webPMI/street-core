package media

import (
	"context"
	"fmt"
	"mime/multipart"
	"sync"
	"time"

	"backend/config"
	"backend/models"
	"backend/pkg/retry"
	"backend/pkg/worker"
	"backend/utils"

	"go.mongodb.org/mongo-driver/bson/primitive"
	"go.mongodb.org/mongo-driver/mongo"
)

type mediaService struct {
	repo           IMediaRepository
	processor      IMediaProcessor
	processingPool *worker.WorkerPool // Worker pool for async processing
	mu             sync.RWMutex
}

// NewMediaService creates a new media service instance
func NewMediaService(repo IMediaRepository, processor IMediaProcessor) IMediaService {
	// Initialize worker pool with configurable workers
	numWorkers := 10 // Default
	if config.Media != nil && config.Media.ProcessingWorkers > 0 {
		numWorkers = config.Media.ProcessingWorkers
	}

	utils.Info("Initializing media service", map[string]interface{}{
		"processing_workers": numWorkers,
	})

	return &mediaService{
		repo:           repo,
		processor:      processor,
		processingPool: worker.NewWorkerPool(numWorkers),
	}
}

// Shutdown gracefully shuts down the media service
// Should be called during application shutdown
func (s *mediaService) Shutdown(ctx context.Context) error {
	utils.Info("Shutting down media service", nil)
	return s.processingPool.Shutdown(ctx)
}

// UploadFile handles a single file upload (backward compatible)
func (s *mediaService) UploadFile(ctx context.Context, file *multipart.FileHeader, fileType models.MediaFileType, userID string) (*models.MediaFile, error) {
	return s.UploadFileWithContext(ctx, file, fileType, userID, "")
}

// UploadFileWithContext handles a file upload with context-based organization
func (s *mediaService) UploadFileWithContext(ctx context.Context, file *multipart.FileHeader, fileType models.MediaFileType, userID string, mediaContext string) (*models.MediaFile, error) {
	// Validate user ID
	userObjID, err := primitive.ObjectIDFromHex(userID)
	if err != nil {
		return nil, fmt.Errorf("invalid user ID")
	}

	// Check max files limit per user (optional: can be removed or configured)
	count, err := s.repo.CountByUserID(ctx, userID)
	if err != nil {
		utils.Warn("Failed to count user media", map[string]interface{}{
			"user_id": userID,
			"error":   err.Error(),
		})
	}

	// Limit files per user (configurable)
	maxFilesPerUser := int64(1000)
	if count >= maxFilesPerUser {
		return nil, fmt.Errorf("maximum file limit reached")
	}

	// Convert context string to MediaContext type
	var ctxType config.MediaContext
	switch mediaContext {
	case "competitions":
		ctxType = config.MediaContextCompetitions
	case "posts":
		ctxType = config.MediaContextPosts
	case "clubs":
		ctxType = config.MediaContextClubs
	case "events":
		ctxType = config.MediaContextEvents
	case "profiles":
		ctxType = config.MediaContextProfiles
	default:
		ctxType = config.MediaContextGeneral
	}

	// Save file to disk using existing pkg/media logic with context
	result, err := SaveUploadedFileWithContext(file, fileType, userID, ctxType)
	if err != nil {
		return nil, fmt.Errorf("failed to save file: %w", err)
	}

	// Check for duplicate by hash (deduplication with reference counting)
	existingMedia, _ := s.repo.GetByHash(ctx, result.Hash)
	if existingMedia != nil {
		// File already exists, increment reference count
		if err := s.repo.IncrementRefCount(ctx, existingMedia.ID.Hex()); err != nil {
			utils.Warn("Failed to increment refCount for duplicate file", map[string]interface{}{
				"file_id": existingMedia.ID.Hex(),
				"error":   err.Error(),
			})
		}

		utils.Debug("Duplicate file detected, refCount incremented", map[string]interface{}{
			"user_id":          userID,
			"hash":             result.Hash,
			"existing_file_id": existingMedia.ID.Hex(),
			"new_refCount":     existingMedia.RefCount + 1,
		})

		// Delete the newly uploaded file since we already have it
		DeleteFile(result.FilePath)

		return existingMedia, nil
	}

	// Create media record
	media := &models.MediaFile{
		ID:           primitive.NewObjectID(),
		UserID:       userObjID,
		FileName:     result.FileName,
		OriginalName: file.Filename,
		FileType:     fileType,
		MimeType:     result.MimeType,
		FileSize:     result.FileSize,
		FilePath:     result.FilePath,
		PublicURL:    result.PublicURL,
		HashSHA256:   result.Hash,
		Status:       models.MediaFileStatusPending,
	}
	media.SetDefaults()

	// Save to database
	if err := s.repo.Create(ctx, media); err != nil {
		// Cleanup file if database save fails
		DeleteFile(result.FilePath)
		return nil, fmt.Errorf("failed to create media record: %w", err)
	}

	// Process file asynchronously using worker pool (instead of raw goroutine)
	mediaID := media.ID.Hex()
	if err := s.processingPool.Submit(func() {
		s.processFileAsync(ctx, mediaID)
	}); err != nil {
		utils.Warn("Failed to submit processing job to worker pool", map[string]interface{}{
			"file_id": mediaID,
			"error":   err.Error(),
		})
		// Fallback: process synchronously if pool is unavailable
		go s.processFileAsync(ctx, mediaID)
	}

	utils.Info("File uploaded successfully", map[string]interface{}{
		"file_id":   media.ID.Hex(),
		"user_id":   userID,
		"file_type": string(fileType),
		"file_size": result.FileSize,
		"context":   mediaContext,
	})

	return media, nil
}

// UploadMultipleFiles handles multiple file uploads (carousel)
func (s *mediaService) UploadMultipleFiles(ctx context.Context, files []*multipart.FileHeader, fileType models.MediaFileType, userID string) ([]*models.MediaFile, error) {
	if len(files) > config.Media.MaxFilesPerUpload {
		return nil, fmt.Errorf("too many files (max %d)", config.Media.MaxFilesPerUpload)
	}

	var mediaFiles []*models.MediaFile
	var errors []error

	for _, file := range files {
		media, err := s.UploadFile(ctx, file, fileType, userID)
		if err != nil {
			errors = append(errors, fmt.Errorf("%s: %w", file.Filename, err))
			continue
		}
		mediaFiles = append(mediaFiles, media)
	}

	if len(errors) > 0 && len(mediaFiles) == 0 {
		return nil, fmt.Errorf("all uploads failed: %v", errors)
	}

	return mediaFiles, nil
}

// GetFile retrieves a media file by ID
func (s *mediaService) GetFile(ctx context.Context, id string) (*models.MediaFile, error) {
	return s.repo.GetByID(ctx, id)
}

// GetUserFiles retrieves all files for a user with pagination
func (s *mediaService) GetUserFiles(ctx context.Context, userID string, limit, offset int) ([]*models.MediaFile, int64, error) {
	files, err := s.repo.GetByUserID(ctx, userID, limit, offset)
	if err != nil {
		return nil, 0, err
	}

	total, err := s.repo.CountByUserID(ctx, userID)
	if err != nil {
		return nil, 0, err
	}

	return files, total, nil
}

// GetPostMedia retrieves all media files for a specific post
func (s *mediaService) GetPostMedia(ctx context.Context, postID string) ([]*models.MediaFile, error) {
	// Validate post ID format
	_, err := primitive.ObjectIDFromHex(postID)
	if err != nil {
		return nil, fmt.Errorf("invalid post ID format")
	}

	// Get all media files for the post
	files, err := s.repo.GetByPostID(ctx, postID)
	if err != nil {
		return nil, fmt.Errorf("failed to get post media: %w", err)
	}

	return files, nil
}

// DeleteFile deletes a media file with reference counting
// Physical file is only deleted when refCount reaches 0
func (s *mediaService) DeleteFile(ctx context.Context, id string, userID string) error {
	// Get file to verify ownership and get file path
	media, err := s.repo.GetByID(ctx, id)
	if err != nil {
		return err
	}

	// Verify ownership
	if media.UserID.Hex() != userID {
		return ErrUnauthorized
	}

	// Decrement reference count atomically
	newRefCount, err := s.repo.DecrementRefCount(ctx, id)
	if err != nil {
		utils.Warn("Failed to decrement refCount", map[string]interface{}{
			"file_id": id,
			"error":   err.Error(),
		})
		// Continue with deletion even if refCount update fails
		newRefCount = 0
	}

	utils.Debug("Reference count decremented", map[string]interface{}{
		"file_id":     id,
		"refCount":    newRefCount,
		"will_delete": newRefCount <= 0,
	})

	// Only delete physical file if refCount is 0 or below
	if newRefCount <= 0 {
		// Delete physical file
		if err := DeleteFile(media.FilePath); err != nil {
			utils.Warn("Failed to delete physical file", map[string]interface{}{
				"file_id":   id,
				"file_path": media.FilePath,
				"error":     err.Error(),
			})
		}

		// Delete thumbnail if exists
		if media.ThumbnailURL != "" {
			thumbnailPath := s.urlToPath(media.ThumbnailURL)
			if err := DeleteFile(thumbnailPath); err != nil {
				utils.Debug("Failed to delete thumbnail", map[string]interface{}{
					"file_id":        id,
					"thumbnail_path": thumbnailPath,
					"error":          err.Error(),
				})
			}
		}

		// Delete database record
		if err := s.repo.Delete(ctx, id); err != nil {
			return err
		}

		utils.Info("File deleted (refCount reached 0)", map[string]interface{}{
			"file_id": id,
			"user_id": userID,
		})
	} else {
		utils.Info("File reference removed (still referenced by others)", map[string]interface{}{
			"file_id":        id,
			"user_id":        userID,
			"remaining_refs": newRefCount,
		})
	}

	return nil
}

// ProcessPendingFiles processes files in pending status
// Returns the number of files processed
func (s *mediaService) ProcessPendingFiles(ctx context.Context) (int, error) {
	files, err := s.repo.GetPendingFiles(ctx, 100)
	if err != nil {
		return 0, err
	}

	count := len(files)
	for _, file := range files {
		if err := s.processFile(ctx, file); err != nil {
			utils.Error("Failed to process file", map[string]interface{}{
				"file_id": file.ID.Hex(),
				"error":   err.Error(),
			})
			s.repo.UpdateStatus(ctx, file.ID.Hex(), models.MediaFileStatusFailed, err.Error())
		}
	}

	return count, nil
}

// AssociateWithPost links media files to a post using MongoDB transactions
// Ensures atomicity - either all associations succeed or none do
func (s *mediaService) AssociateWithPost(ctx context.Context, mediaIDs []string, postID string) error {
	postObjID, err := primitive.ObjectIDFromHex(postID)
	if err != nil {
		return fmt.Errorf("invalid post ID")
	}

	// Validate that we have media IDs to associate
	if len(mediaIDs) == 0 {
		return nil // Nothing to do
	}

	// Get MongoDB client for transaction support
	client := s.repo.GetClient()

	// Start MongoDB session for transaction
	session, err := client.StartSession()
	if err != nil {
		utils.Error("Failed to start transaction session", map[string]interface{}{
			"post_id": postID,
			"error":   err.Error(),
		})
		return fmt.Errorf("failed to start session: %w", err)
	}
	defer session.EndSession(ctx)

	// Execute all associations within a transaction
	_, err = session.WithTransaction(ctx, func(sessCtx mongo.SessionContext) (interface{}, error) {
		// Associate all media files with the post
		for _, mediaID := range mediaIDs {
			if err := s.repo.AssociateWithPost(sessCtx, mediaID, postObjID); err != nil {
				utils.Warn("Failed to associate media in transaction", map[string]interface{}{
					"media_id": mediaID,
					"post_id":  postID,
					"error":    err.Error(),
				})
				return nil, fmt.Errorf("failed to associate media %s: %w", mediaID, err)
			}
		}
		return nil, nil
	})

	if err != nil {
		utils.Error("Transaction failed for media association", map[string]interface{}{
			"post_id":    postID,
			"media_count": len(mediaIDs),
			"error":      err.Error(),
		})
		return fmt.Errorf("failed to associate media with post: %w", err)
	}

	utils.Info("Media associated with post successfully", map[string]interface{}{
		"post_id":    postID,
		"media_count": len(mediaIDs),
	})

	return nil
}

// ValidateOwnership checks if user owns the media file
func (s *mediaService) ValidateOwnership(ctx context.Context, mediaID, userID string) error {
	media, err := s.repo.GetByID(ctx, mediaID)
	if err != nil {
		return ErrNotFound
	}

	if media.UserID.Hex() != userID {
		return ErrUnauthorized
	}

	return nil
}

// GetFilesByIDs retrieves multiple files by their IDs using a single bulk query
// This eliminates N+1 query problems
func (s *mediaService) GetFilesByIDs(ctx context.Context, ids []string) ([]*models.MediaFile, error) {
	// Use the new bulk query method from repository
	return s.repo.GetByIDs(ctx, ids)
}

// CleanupOrphanedFiles removes files not associated with any post after 24 hours
func (s *mediaService) CleanupOrphanedFiles(ctx context.Context) error {
	utils.Info("Starting orphaned files cleanup", nil)

	// Files must be at least 24 hours old before cleanup
	olderThan := time.Now().Add(-24 * time.Hour)

	// Count orphaned files first
	count, err := s.repo.CountOrphanedFiles(ctx, olderThan)
	if err != nil {
		utils.Warn("Failed to count orphaned files", map[string]interface{}{
			"error": err.Error(),
		})
	} else {
		utils.Info("Found orphaned files", map[string]interface{}{
			"count": count,
		})
	}

	// Process in batches of 100
	batchSize := 100
	totalDeleted := 0

	for {
		files, err := s.repo.GetOrphanedFiles(ctx, olderThan, batchSize)
		if err != nil {
			utils.Error("Failed to get orphaned files", map[string]interface{}{
				"error": err.Error(),
			})
			break
		}

		if len(files) == 0 {
			break
		}

		for _, file := range files {
			// Delete physical file
			if err := DeleteFile(file.FilePath); err != nil {
				utils.Warn("Failed to delete orphaned file", map[string]interface{}{
					"file_id":   file.ID.Hex(),
					"file_path": file.FilePath,
					"error":     err.Error(),
				})
			}

			// Delete thumbnail if exists
			if file.ThumbnailURL != "" {
				thumbnailPath := s.urlToPath(file.ThumbnailURL)
				if thumbnailPath != "" {
					DeleteFile(thumbnailPath)
				}
			}

			// Delete database record
			if err := s.repo.Delete(ctx, file.ID.Hex()); err != nil {
				utils.Warn("Failed to delete orphaned file record", map[string]interface{}{
					"file_id": file.ID.Hex(),
					"error":   err.Error(),
				})
			} else {
				totalDeleted++
			}
		}
	}

	utils.Info("Orphaned files cleanup completed", map[string]interface{}{
		"deleted": totalDeleted,
	})

	// Also cleanup temp files
	if err := CleanupTempFiles(); err != nil {
		utils.Warn("Failed to cleanup temp files", map[string]interface{}{
			"error": err.Error(),
		})
	}

	return nil
}

// processFileAsync processes a file asynchronously
// Uses parent context for proper cancellation propagation
func (s *mediaService) processFileAsync(parentCtx context.Context, mediaID string) {
	// Get timeout from config
	timeout := 5 * time.Minute // Default
	if config.Media != nil && config.Media.ProcessingTimeout > 0 {
		timeout = config.Media.ProcessingTimeout
	}

	// Create a new context from parent with timeout for this specific processing
	ctx, cancel := context.WithTimeout(parentCtx, timeout)
	defer cancel()

	media, err := s.repo.GetByID(ctx, mediaID)
	if err != nil {
		utils.Error("Failed to get media for processing", map[string]interface{}{
			"file_id": mediaID,
			"error":   err.Error(),
		})
		return
	}

	// Get max retries from config
	maxRetries := 3 // Default
	if config.Media != nil && config.Media.MaxRetries > 0 {
		maxRetries = config.Media.MaxRetries
	}

	// Process file with retry logic (exponential backoff)
	err = retry.WithRetry(ctx, maxRetries, func() error {
		return s.processFile(ctx, media)
	})

	if err != nil {
		utils.Error("Failed to process file after retries", map[string]interface{}{
			"file_id": mediaID,
			"error":   err.Error(),
		})
		s.repo.UpdateStatus(ctx, mediaID, models.MediaFileStatusFailed, err.Error())
		return
	}

	// Update the media record with processed data
	if err := s.repo.Update(ctx, media); err != nil {
		utils.Error("Failed to update media after processing", map[string]interface{}{
			"file_id": mediaID,
			"error":   err.Error(),
		})
	}
}

// processFile processes a single file based on its type
func (s *mediaService) processFile(ctx context.Context, media *models.MediaFile) error {
	// Update status to processing
	s.repo.UpdateStatus(ctx, media.ID.Hex(), models.MediaFileStatusProcessing, "")

	switch media.FileType {
	case models.MediaFileTypeImage, models.MediaFileTypeAvatar, models.MediaFileTypeThumbnail:
		return s.processor.ProcessImage(ctx, media)
	case models.MediaFileTypeVideo:
		return s.processor.ProcessVideo(ctx, media)
	default:
		media.MarkAsReady()
		return nil
	}
}

// urlToPath converts a public URL to a file path
func (s *mediaService) urlToPath(url string) string {
	// Remove /uploads/ prefix and join with upload directory
	if len(url) > 9 && url[:9] == "/uploads/" {
		return config.Media.UploadDir + url[8:]
	}
	return ""
}
