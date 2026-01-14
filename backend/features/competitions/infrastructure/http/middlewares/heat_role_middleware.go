package middlewares

import (
	"context"
	"net/http"
	"time"

	"backend/app/dto/response"
	"backend/features/competitions/domain/repositories"
	globalMiddlewares "backend/middlewares"

	"github.com/gin-gonic/gin"
	"go.mongodb.org/mongo-driver/bson/primitive"
)

// ValidateHeatRoleMembership verifica que el UserID del JWT esté asignado al Heat
// en alguno de los roles (judge, speaker, marshall)
//
// SECURITY: Ownership Validation
// Previene que usuarios no asignados hagan check-in
func ValidateHeatRoleMembership(heatRepo repositories.HeatRepository) gin.HandlerFunc {
	return func(c *gin.Context) {
		// Get authenticated user ID from context (set by JWTAuthMiddleware)
		userIDObj, exists := c.Get(globalMiddlewares.UserIDKey)
		if !exists {
			response.Error(c, http.StatusUnauthorized, "invalid user ID")
			c.Abort()
			return
		}

		userIDStr, ok := userIDObj.(string)
		if !ok || userIDStr == "" {
			response.Error(c, http.StatusUnauthorized, "invalid user ID")
			c.Abort()
			return
		}

		// Get heatID from URL params
		heatID := c.Param("heatId")
		if heatID == "" {
			response.Error(c, http.StatusBadRequest, "invalid heat ID")
			c.Abort()
			return
		}

		// Parse heatID
		heatObjID, err := primitive.ObjectIDFromHex(heatID)
		if err != nil {
			response.Error(c, http.StatusBadRequest, "invalid heat ID")
			c.Abort()
			return
		}

		// Get heat from database
		ctx, cancel := context.WithTimeout(c.Request.Context(), 5*time.Second)
		defer cancel()

		heat, err := heatRepo.FindByID(ctx, heatObjID)
		if err != nil {
			response.Error(c, http.StatusNotFound, "heat not found")
			c.Abort()
			return
		}

		// Check if user is assigned to ANY role in this heat
		isAssigned := false
		if heat.CheckInEnabled && heat.AssignedRoles != nil {
			for _, userIDs := range heat.AssignedRoles {
				for _, assignedUserID := range userIDs {
					if assignedUserID == userIDStr {
						isAssigned = true
						break
					}
				}
				if isAssigned {
					break
				}
			}
		}

		if !isAssigned {
			response.Error(c, http.StatusForbidden, "user not assigned to this heat")
			c.Abort()
			return
		}

		// User is assigned to this heat, continue
		c.Next()
	}
}
