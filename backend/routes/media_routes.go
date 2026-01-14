package routes

import (
	application "backend/app"
	"backend/features/media"
	"backend/middlewares"

	"github.com/gin-gonic/gin"
)

// SetupMediaRoutes sets up media upload and management routes
func SetupMediaRoutes(version *gin.RouterGroup, container *application.Container) {
	// Create auth middleware for protected routes
	authMiddleware := middlewares.JWTAuthMiddleware(
		container.Services.Auth,
		container.Services.TokenRevocation,
		container.UserRepo,
	)

	// Register media routes using the module's handler
	media.RegisterRoutes(version, container.Media.Handler, authMiddleware)
}
