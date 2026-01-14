package media

import (
	"errors"
	"net/http"
	"strconv"

	"backend/config"
	"backend/middlewares"
	"backend/models"
	"backend/utils"

	"github.com/gin-gonic/gin"
)

type mediaHandler struct {
	service IMediaService
}

// NewMediaHandler creates a new media handler instance
func NewMediaHandler(service IMediaService) *mediaHandler {
	return &mediaHandler{
		service: service,
	}
}

// Upload handles single file upload
// POST /api/v2/media/upload
func (h *mediaHandler) Upload(c *gin.Context) {
	// Get user ID from context
	userID, exists := c.Get(middlewares.UserIDKey)
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{
			"status":  "error",
			"message": "unauthorized",
		})
		return
	}

	// Get file type from form
	fileTypeStr := c.DefaultPostForm("fileType", "image")
	fileType := models.MediaFileType(fileTypeStr)

	// Validate file type
	if !isValidFileType(fileType) {
		c.JSON(http.StatusBadRequest, gin.H{
			"status":  "error",
			"message": "invalid_file_type",
			"details": "Allowed types: image, video, avatar",
		})
		return
	}

	// Get file from form
	file, err := c.FormFile("file")
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"status":  "error",
			"message": "file_required",
			"details": err.Error(),
		})
		return
	}

	// Upload file
	media, err := h.service.UploadFile(c.Request.Context(), file, fileType, userID.(string))
	if err != nil {
		utils.Warn("Upload failed", map[string]interface{}{
			"user_id": userID.(string),
			"error":   err.Error(),
		})
		c.JSON(http.StatusBadRequest, gin.H{
			"status":  "error",
			"message": "upload_failed",
			"details": err.Error(),
		})
		return
	}

	c.JSON(http.StatusCreated, gin.H{
		"status":  "success",
		"message": "file_uploaded_successfully",
		"data":    ToUploadResponse(media),
	})
}

// UploadAvatar handles avatar upload (convenience endpoint)
// POST /api/v2/media/upload/avatar
func (h *mediaHandler) UploadAvatar(c *gin.Context) {
	// Set fileType to avatar and delegate to Upload
	c.Set("forcedFileType", models.MediaFileTypeAvatar)
	h.uploadWithType(c, models.MediaFileTypeAvatar)
}

// UploadImage handles image upload (convenience endpoint)
// POST /api/v2/media/upload/image
func (h *mediaHandler) UploadImage(c *gin.Context) {
	h.uploadWithType(c, models.MediaFileTypeImage)
}

// UploadVideo handles video upload (convenience endpoint)
// POST /api/v2/media/upload/video
func (h *mediaHandler) UploadVideo(c *gin.Context) {
	h.uploadWithType(c, models.MediaFileTypeVideo)
}

// uploadWithType is a helper that uploads with a specific file type
func (h *mediaHandler) uploadWithType(c *gin.Context, fileType models.MediaFileType) {
	utils.AppLogger.Debug("Subiendo imagen")

	// Get user ID from context
	userID, exists := c.Get(middlewares.UserIDKey)
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{
			"status":  "error",
			"message": "unauthorized",
		})
		return
	}

	// Get file from form
	file, err := c.FormFile("file")
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"status":  "error",
			"message": "file_required",
			"details": err.Error(),
		})
		return
	}

	// Upload file with specified type
	media, err := h.service.UploadFile(c.Request.Context(), file, fileType, userID.(string))
	if err != nil {
		utils.Warn("Upload failed", map[string]interface{}{
			"user_id":   userID.(string),
			"file_type": string(fileType),
			"error":     err.Error(),
		})
		c.JSON(http.StatusBadRequest, gin.H{
			"status":  "error",
			"message": "upload_failed",
			"details": err.Error(),
		})
		return
	}

	c.JSON(http.StatusCreated, gin.H{
		"status":  "success",
		"message": "file_uploaded_successfully",
		"data":    ToUploadResponse(media),
	})
}

// UploadMultiple handles multiple file uploads (carousel)
// POST /api/v2/media/upload/multiple
func (h *mediaHandler) UploadMultiple(c *gin.Context) {
	// Get user ID from context
	userID, exists := c.Get(middlewares.UserIDKey)
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{
			"status":  "error",
			"message": "unauthorized",
		})
		return
	}

	// Get file type from form
	fileTypeStr := c.DefaultPostForm("fileType", "image")
	fileType := models.MediaFileType(fileTypeStr)

	// Validate file type
	if !isValidFileType(fileType) {
		c.JSON(http.StatusBadRequest, gin.H{
			"status":  "error",
			"message": "invalid_file_type",
		})
		return
	}

	// Get files from form
	form, err := c.MultipartForm()
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"status":  "error",
			"message": "invalid_form_data",
		})
		return
	}

	files := form.File["files"]
	if len(files) == 0 {
		c.JSON(http.StatusBadRequest, gin.H{
			"status":  "error",
			"message": "files_required",
		})
		return
	}

	if len(files) > config.Media.MaxFilesPerUpload {
		c.JSON(http.StatusBadRequest, gin.H{
			"status":  "error",
			"message": "too_many_files",
			"details": map[string]int{"max": config.Media.MaxFilesPerUpload},
		})
		return
	}

	// Upload files
	var responses []UploadResponse
	var errors []UploadError

	for _, file := range files {
		media, err := h.service.UploadFile(c.Request.Context(), file, fileType, userID.(string))
		if err != nil {
			errors = append(errors, UploadError{
				FileName: file.Filename,
				Error:    err.Error(),
			})
			continue
		}
		responses = append(responses, ToUploadResponse(media))
	}

	c.JSON(http.StatusOK, gin.H{
		"status":  "success",
		"message": "upload_completed",
		"data": MultiUploadResponse{
			Files:   responses,
			Success: len(responses),
			Failed:  len(errors),
			Errors:  errors,
		},
	})
}

// GetFile retrieves a media file by ID
// GET /api/v2/media/:id
func (h *mediaHandler) GetFile(c *gin.Context) {
	id := c.Param("id")

	media, err := h.service.GetFile(c.Request.Context(), id)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{
			"status":  "error",
			"message": "file_not_found",
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"status": "success",
		"data":   ToUploadResponse(media),
	})
}

// GetMyFiles retrieves all files for the authenticated user
// GET /api/v2/media/me
func (h *mediaHandler) GetMyFiles(c *gin.Context) {
	userID, exists := c.Get(middlewares.UserIDKey)
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{
			"status":  "error",
			"message": "unauthorized",
		})
		return
	}

	// Parse pagination
	page, _ := strconv.Atoi(c.DefaultQuery("page", "1"))
	limit, _ := strconv.Atoi(c.DefaultQuery("limit", "20"))

	if page < 1 {
		page = 1
	}
	if limit < 1 || limit > 100 {
		limit = 20
	}

	offset := (page - 1) * limit

	files, total, err := h.service.GetUserFiles(c.Request.Context(), userID.(string), limit, offset)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"status":  "error",
			"message": "server_error",
		})
		return
	}

	totalPages := int(total) / limit
	if int(total)%limit > 0 {
		totalPages++
	}

	c.JSON(http.StatusOK, gin.H{
		"status": "success",
		"data": MediaListResponse{
			Files:      ToUploadResponses(files),
			Total:      total,
			Page:       page,
			Limit:      limit,
			TotalPages: totalPages,
		},
	})
}

// DeleteFile deletes a media file
// DELETE /api/v2/media/:id
func (h *mediaHandler) DeleteFile(c *gin.Context) {
	userID, exists := c.Get(middlewares.UserIDKey)
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{
			"status":  "error",
			"message": "unauthorized",
		})
		return
	}

	id := c.Param("id")

	err := h.service.DeleteFile(c.Request.Context(), id, userID.(string))
	if err != nil {
		// SECURITY FIX: Use errors.Is for semantic error comparison
		if errors.Is(err, ErrUnauthorized) {
			c.JSON(http.StatusForbidden, gin.H{
				"status":  "error",
				"message": "forbidden",
				"details": "you don't own this file",
			})
			return
		}

		if errors.Is(err, ErrNotFound) {
			c.JSON(http.StatusNotFound, gin.H{
				"status":  "error",
				"message": "file_not_found",
			})
			return
		}

		// Other errors
		c.JSON(http.StatusInternalServerError, gin.H{
			"status":  "error",
			"message": "server_error",
			"details": err.Error(),
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"status":  "success",
		"message": "file_deleted_successfully",
	})
}

// AssociateWithPost links media files to a post
// POST /api/v2/media/associate
func (h *mediaHandler) AssociateWithPost(c *gin.Context) {
	userID, exists := c.Get(middlewares.UserIDKey)
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{
			"status":  "error",
			"message": "unauthorized",
		})
		return
	}

	var req AssociateRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"status":  "error",
			"message": "invalid_request",
			"details": err.Error(),
		})
		return
	}

	// Validate ownership of all media files
	for _, mediaID := range req.MediaIDs {
		if err := h.service.ValidateOwnership(c.Request.Context(), mediaID, userID.(string)); err != nil {
			c.JSON(http.StatusForbidden, gin.H{
				"status":  "error",
				"message": "forbidden",
				"details": "You don't own one or more of the specified files",
			})
			return
		}
	}

	// Associate files with post
	if err := h.service.AssociateWithPost(c.Request.Context(), req.MediaIDs, req.PostID); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"status":  "error",
			"message": "association_failed",
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"status":  "success",
		"message": "files_associated_successfully",
	})
}

// GetPostMedia retrieves all media files for a post
// GET /api/v2/media/post/:postId
func (h *mediaHandler) GetPostMedia(c *gin.Context) {
	postID := c.Param("postId")

	// Get media files from service
	files, err := h.service.GetPostMedia(c.Request.Context(), postID)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"status":  "error",
			"message": "invalid_post_id",
			"details": err.Error(),
		})
		return
	}

	// Convert to response format
	responses := make([]UploadResponse, len(files))
	for i, file := range files {
		responses[i] = UploadResponse{
			ID:           file.ID.Hex(),
			PublicURL:    file.PublicURL,
			ThumbnailURL: file.ThumbnailURL,
			FileType:     string(file.FileType),
			MimeType:     file.MimeType,
			FileSize:     file.FileSize,
			Width:        file.Width,
			Height:       file.Height,
			Duration:     file.Duration,
			Status:       string(file.Status),
		}
	}

	c.JSON(http.StatusOK, gin.H{
		"status":  "success",
		"data":    responses,
		"count":   len(responses),
		"post_id": postID,
	})
}

// isValidFileType checks if the file type is valid
func isValidFileType(fileType models.MediaFileType) bool {
	switch fileType {
	case models.MediaFileTypeImage, models.MediaFileTypeVideo, models.MediaFileTypeAvatar:
		return true
	default:
		return false
	}
}
