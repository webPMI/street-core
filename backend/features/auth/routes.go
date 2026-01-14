package auth

import (
	"backend/middlewares"

	"github.com/gin-gonic/gin"
)

// RegisterRoutes configures auth routes
func RegisterRoutes(version *gin.RouterGroup, handler *Handler) {
	authGroup := version.Group("/auth")
	authGroup.Use(middlewares.AuthRateLimitMiddleware())
	{
		// Registration and Login
		authGroup.POST("/register", handler.Register)
		authGroup.POST("/login", handler.Login)

		// Token management
		authGroup.POST("/refresh", middlewares.TokenRefreshRateLimitMiddleware(), handler.RefreshToken)
		authGroup.POST("/logout", handler.Logout)

		// Password reset
		authGroup.POST("/password/forgot", middlewares.PasswordResetRateLimitMiddleware(), handler.ForgotPassword)
		authGroup.POST("/password/reset", handler.ResetPassword)
		authGroup.GET("/validate-token", handler.ValidateToken)

		// OAuth routes
		authGroup.GET("/oauth/google", handler.InitiateGoogleOAuth)
		authGroup.GET("/oauth/google/callback", handler.HandleGoogleCallback)
		authGroup.GET("/oauth/facebook", handler.InitiateFacebookOAuth)
		authGroup.GET("/oauth/facebook/callback", handler.HandleFacebookCallback)
	}
}
