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

// ValidateScoreOwnership verifica que el UserID del JWT sea el Judge que creó el Score
//
// SECURITY: Ownership Validation
// Solo el juez original puede solicitar unlock de su propio score
func ValidateScoreOwnership(scoreRepo repositories.ScoreRepository) gin.HandlerFunc {
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

		// Parse user ID to ObjectID
		userObjID, err := primitive.ObjectIDFromHex(userIDStr)
		if err != nil {
			response.Error(c, http.StatusUnauthorized, "invalid user ID")
			c.Abort()
			return
		}

		// Get scoreID from URL params
		scoreID := c.Param("scoreId")
		if scoreID == "" {
			response.Error(c, http.StatusBadRequest, "invalid score ID")
			c.Abort()
			return
		}

		// Parse scoreID
		scoreObjID, err := primitive.ObjectIDFromHex(scoreID)
		if err != nil {
			response.Error(c, http.StatusBadRequest, "invalid score ID")
			c.Abort()
			return
		}

		// Get score from database
		ctx, cancel := context.WithTimeout(c.Request.Context(), 5*time.Second)
		defer cancel()

		score, err := scoreRepo.FindByID(ctx, scoreObjID)
		if err != nil {
			response.Error(c, http.StatusNotFound, "score not found")
			c.Abort()
			return
		}

		// SECURITY CHECK: Verify that the authenticated user is the judge who created this score
		if score.JudgeID != userObjID {
			response.Error(c, http.StatusForbidden, "only the original judge can unlock their own score")
			c.Abort()
			return
		}

		// User owns this score, continue
		c.Next()
	}
}
