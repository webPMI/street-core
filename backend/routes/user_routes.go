package routes

import (
	application "backend/app"
	"backend/middlewares"

	"github.com/gin-gonic/gin"
)

func SetupUserRoutes(version *gin.RouterGroup, container *application.Container) {
	// Get user handler from container
	userHandler := container.Handlers.User

	// =========================================================
	// PUBLIC ROUTES (No authentication required)

	// POST /api/version/users (Create new user / Register)
	version.POST("/users", userHandler.CreateUser)

	// GET /api/version/users/profile/:id (Get public user profile)
	version.GET("/users/profile/:id", userHandler.GetUserByIDPublic)

	// =========================================================
	// PROTECTED ROUTES (JWT Authentication Required)

	protectedGroup := version.Group("")
	protectedGroup.Use(middlewares.JWTAuthMiddleware(container.Services.Auth, container.Services.TokenRevocation, container.UserRepo))
	//	protectedGroup.Use(middlewares.CSRFProtection()) // 🔒 CSRF protection for state-changing operations
	{
		// ---------------------------------------------------------
		// USER PROFILE MANAGEMENT

		// GET /api/version/users/me (Get current user profile)
		protectedGroup.GET("/users/me", userHandler.GetCurrentUser)

		// PUT /api/version/users/me (Update user profile)
		protectedGroup.PUT("/users/me", userHandler.UpdateUserProfile)

		// PUT /api/version/users/me/change-password (Change password)
		protectedGroup.PUT("/users/me/change-password",
			middlewares.PasswordChangeRateLimitMiddleware(), // Rate limit: 5/hour
			userHandler.ChangePassword,
		)

		// ---------------------------------------------------------
		// PRIVACY SETTINGS & BLOCKING

		/* 		privacyDeps := handlers.PrivacyHandlerDependencies{
		   			PrivacyService: container.Services.Privacy,
		   		}

		   		// GET /api/version/users/me/privacy (Get privacy settings)
		   		protectedGroup.GET("/users/me/privacy",
		   			handlers.GetPrivacySettings(privacyDeps),
		   		)

		   		// PUT /api/version/users/me/privacy (Update privacy settings)
		   		protectedGroup.PUT("/users/me/privacy",
		   			handlers.UpdatePrivacySettings(privacyDeps),
		   		)

		   		// POST /api/version/users/me/privacy/block (Block a user)
		   		protectedGroup.POST("/users/me/privacy/block",
		   			handlers.BlockUser(privacyDeps),
		   		)

		   		// DELETE /api/version/users/me/privacy/block/:userId (Unblock a user)
		   		protectedGroup.DELETE("/users/me/privacy/block/:userId",
		   			handlers.UnblockUser(privacyDeps),
		   		)

		   		// GET /api/version/users/me/privacy/blocked (Get blocked users list)
		   		protectedGroup.GET("/users/me/privacy/blocked",
		   			handlers.GetBlockedUsers(privacyDeps),
		   		) */
	}

}
