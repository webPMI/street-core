package middlewares

import (
	"context"
	"net/http"
	"time"

	"backend/app/dto/response"
	"backend/features/competitions/domain/entities"
	"backend/features/competitions/domain/repositories"

	"github.com/gin-gonic/gin"
	"go.mongodb.org/mongo-driver/bson/primitive"
)

// ValidateHeatState verifica que el Heat NO esté pausado o completado
// antes de permitir SubmitScore
//
// SECURITY: State-Validation Middleware
// Rechaza con 409 Conflict si el Heat está en estado Paused o Completed
func ValidateHeatState(heatRepo repositories.HeatRepository) gin.HandlerFunc {
	return func(c *gin.Context) {
		// Extract heatID from request body or params
		// For SubmitScore, it's typically in the request body
		var requestBody struct {
			HeatID string `json:"heatId"`
		}

		if err := c.ShouldBindJSON(&requestBody); err != nil {
			// If binding fails, let the handler deal with validation
			c.Next()
			return
		}

		// Re-bind the body so the handler can read it again
		c.Request.Body = http.MaxBytesReader(c.Writer, c.Request.Body, 1<<20) // 1MB limit

		// Validate heatID format
		if requestBody.HeatID == "" {
			// No heatID in body, skip validation (might be optional)
			c.Next()
			return
		}

		heatObjID, err := primitive.ObjectIDFromHex(requestBody.HeatID)
		if err != nil {
			// Invalid format, let handler deal with it
			c.Next()
			return
		}

		// Get heat from database
		ctx, cancel := context.WithTimeout(c.Request.Context(), 5*time.Second)
		defer cancel()

		heat, err := heatRepo.FindByID(ctx, heatObjID)
		if err != nil {
			// Heat not found, let handler deal with it
			c.Next()
			return
		}

		// SECURITY CHECK: Reject if Heat is PAUSED
		if heat.Status == entities.HeatStatusPaused {
			response.Error(c, http.StatusConflict, "cannot submit score: heat is paused")
			c.Abort()
			return
		}

		// SECURITY CHECK: Reject if Heat is COMPLETED
		if heat.Status == entities.HeatStatusCompleted {
			response.Error(c, http.StatusConflict, "cannot submit score: heat is already completed")
			c.Abort()
			return
		}

		// Heat state is valid, continue to handler
		c.Next()
	}
}
