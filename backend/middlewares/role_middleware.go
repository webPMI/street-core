package middlewares

import (
	"net/http"

	"backend/app/dto/response"
	"backend/models"

	"github.com/gin-gonic/gin"
)

// RequireRole creates a middleware that checks if the authenticated user has one of the required roles.
// This middleware must be used AFTER JWTAuthMiddleware since it depends on the user role being set in context.
//
// Usage:
//
//	protectedGroup.Use(middlewares.JWTAuthMiddleware(authService))
//	adminGroup := protectedGroup.Group("/admin")
//	adminGroup.Use(middlewares.RequireRole("admin"))
//
// Parameters:
//
//	allowedRoles - Variable number of role strings that are allowed to access the endpoint
func RequireRole(allowedRoles ...string) gin.HandlerFunc {
	return func(c *gin.Context) {
		// 1. Get the user role from context (set by JWTAuthMiddleware)
		userRoleAny, exists := c.Get(UserRoleKey)
		if !exists {
			response.Error(c, http.StatusForbidden, models.PermissionDenied)
			c.Abort()
			return
		}

		// 2. Convert role to string
		userRole, ok := userRoleAny.(string)
		if !ok || userRole == "" {
			response.Error(c, http.StatusInternalServerError, models.ServerError)
			c.Abort()
			return
		}

		// 3. Check if user's role is in the list of allowed roles
		hasPermission := false
		for _, allowedRole := range allowedRoles {
			if userRole == allowedRole {
				hasPermission = true
				break
			}
		}

		if !hasPermission {
			response.Error(c, http.StatusForbidden, models.PermissionDenied)
			c.Abort()
			return
		}

		// 4. User has permission, continue to next handler
		c.Next()
	}
}

// RequireAdminOrEditor is a convenience function for requiring admin or editor role
func RequireAdminOrEditor() gin.HandlerFunc {
	return RequireRole("admin", "editor")
}
