package routes

import (
	application "backend/app"
	"backend/config"
	"backend/features/livestreams"
	"backend/middlewares"
	"net/http"

	"github.com/gin-gonic/gin"
)

// SetupRouter registers all application route groups.
// Receives the container with all application dependencies.
func SetupRouter(router *gin.Engine, container *application.Container) {
	// Version endpoint
	router.GET("/", func(c *gin.Context) {
		c.JSON(http.StatusOK, gin.H{
			"version":     config.Cfg.VERSION,
			"api_version": config.Cfg.APIVERSION,
			"build_date":  "2025-12-14",
			"status":      "stable",
		})
	})

	// CSRF token endpoint
	router.GET("/csrf-token", middlewares.GetCSRFToken)

	// API Version group
	apiVersion := config.Cfg.APIVERSION
	version := router.Group("/api/" + apiVersion)
	{
		// =========================================================
		// PUBLIC ROUTES
		// =========================================================

		// Auth routes (login, register, etc.) - using auth module
		container.Auth.RegisterRoutes(version)

		// Site configuration (public GET endpoints)
		SiteConfigRoutes(version, container)

		// Contact messages (public POST endpoint)
		ContactMessageRoutes(version, container)

		// =========================================================
		// PROTECTED ROUTES
		// =========================================================

		// User routes (profile, settings, etc.)
		SetupUserRoutes(version, container)

		// User profile routes (avatar, posts, privacy, follow system)
		SetupUserProfileRoutes(version, container)

		// Media upload routes (images, videos, avatars)
		SetupMediaRoutes(version, container)

		// =========================================================
		// LIVESTREAMING MODULE
		// =========================================================
		// Livestream routes (public + protected)
		authMiddleware := middlewares.JWTAuthMiddleware(
			container.Services.Auth,
			container.Services.TokenRevocation,
			container.UserRepo,
		)
		livestreams.RegisterRoutes(version, container.DB, authMiddleware)

		// =========================================================
		// COMPETITIONS MODULE
		// =========================================================
		// Competitions routes (public + protected)
		container.Competitions.RegisterRoutes(
			version,
			container.Services.Auth,
			container.Services.TokenRevocation,
			container.UserRepo,
		)
	}
}
