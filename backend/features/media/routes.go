package media

import (
	"backend/middlewares"

	"github.com/gin-gonic/gin"
)

// RegisterRoutes registers all media routes
//
// Security Layers:
// - Authentication: All routes require valid JWT token
// - CSRF Protection: All state-changing operations (POST, DELETE) validate CSRF token
// - Rate Limiting: Upload endpoints limited to 10 uploads per minute per user
//
// Rate Limit Configuration:
// - Upload endpoints: 10 requests/minute (UploadRateLimitConfig)
// - Applies to: /upload, /upload/avatar, /upload/image, /upload/video, /upload/multiple
// - Exceeded limit returns: 429 Too Many Requests with retry-after header
func RegisterRoutes(router *gin.RouterGroup, handler *mediaHandler, authMiddleware gin.HandlerFunc) {
	media := router.Group("/media")
	{
		// Public routes (none for media - all require auth)

		// Protected routes - require authentication and CSRF protection
		protected := media.Group("")
		protected.Use(authMiddleware)
		protected.Use(middlewares.CSRFProtection())
		{
			// Upload endpoints with rate limiting (10 uploads per minute)
			upload := protected.Group("/upload")
			upload.Use(middlewares.UploadRateLimitMiddleware())
			{
				// Single file upload (generic)
				// POST /api/v2/media/upload
				upload.POST("", handler.Upload)

				// Avatar upload (convenience endpoint)
				// POST /api/v2/media/upload/avatar
				upload.POST("/avatar", handler.UploadAvatar)

				// Image upload (convenience endpoint)
				// POST /api/v2/media/upload/image
				upload.POST("/image", handler.UploadImage)

				// Video upload (convenience endpoint)
				// POST /api/v2/media/upload/video
				upload.POST("/video", handler.UploadVideo)

				// Multiple file upload (carousel)
				// POST /api/v2/media/upload/multiple
				upload.POST("/multiple", handler.UploadMultiple)
			}

			// Get authenticated user's files
			// GET /api/v2/media/me
			protected.GET("/me", handler.GetMyFiles)

			// Get single file by ID
			// GET /api/v2/media/:id
			protected.GET("/:id", handler.GetFile)

			// Delete file
			// DELETE /api/v2/media/:id
			protected.DELETE("/:id", handler.DeleteFile)

			// Associate media with post
			// POST /api/v2/media/associate
			protected.POST("/associate", handler.AssociateWithPost)

			// Get all media for a post
			// GET /api/v2/media/post/:postId
			protected.GET("/post/:postId", handler.GetPostMedia)
		}
	}
}
