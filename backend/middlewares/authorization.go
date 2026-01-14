package middlewares

import (
	"backend/pkg/errors"
	"backend/pkg/response"

	"github.com/gin-gonic/gin"
)

// OwnershipValidator defines the interface for resource ownership validation
type OwnershipValidator interface {
	CheckOwnership(resourceID string, userID string) error
}

// RequireOwnershipOrRole checks if the user is the owner of the resource OR has the specified role
func RequireOwnershipOrRole(validator OwnershipValidator, idParam string, role string) gin.HandlerFunc {
	return func(c *gin.Context) {
		// Get User ID from context
		userIDObj, err := GetUserIDFromContext(c)
		if err != nil {
			return
		}
		userID := userIDObj.Hex()

		// Get User Role
		userRole, _ := GetUserRoleFromContext(c)

		// 1. Check Role Permission (Admin always allowed)
		if userRole == role || userRole == "admin" {
			c.Next()
			return
		}

		// 2. Check Ownership
		resourceID := c.Param(idParam)
		if resourceID == "" {
			response.Error(c, 400, "Missing resource ID")
			c.Abort()
			return
		}

		if err := validator.CheckOwnership(resourceID, userID); err != nil {
			// If validation fails (not owner) AND role check failed (not admin) -> Forbidden
			// Note: The validator typically returns an error if not owner.
			// We should check if the error is "forbidden" or actual DB error?
			// For simplicity: if valitator fails, we deny access unless role check passed (handled above)

			// If it's a "forbidden" error from validator, we return Forbidden.
			// If it's a DB error (not found), we might extend this logic.
			// For now, assume validator failure = forbidden.
			response.HandleError(c, errors.ErrPermissionDenied())
			c.Abort()
			return
		}

		c.Next()
	}
}
