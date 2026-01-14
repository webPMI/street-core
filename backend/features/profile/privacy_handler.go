package profile

import (
	"backend/middlewares"
	"backend/models"
	"backend/pkg/response"
	"backend/utils"
	"net/http"

	"github.com/gin-gonic/gin"
	"go.mongodb.org/mongo-driver/bson/primitive"
)

// PrivacyHandler maneja las solicitudes de privacidad
type PrivacyHandler struct {
	privacyService IPrivacyService
}

// NewPrivacyHandler crea una nueva instancia de PrivacyHandler
func NewPrivacyHandler(privacyService IPrivacyService) *PrivacyHandler {
	return &PrivacyHandler{
		privacyService: privacyService,
	}
}

// PrivacyHandlerDependencies holds dependencies for privacy handlers
type PrivacyHandlerDependencies struct {
	PrivacyService IPrivacyService
}

// ===================================
// 1. GET PRIVACY SETTINGS (GET /api/v1/users/me/privacy)
// ===================================

// GetPrivacySettings retrieves the current user's privacy settings
// Creates default settings if they don't exist
func GetPrivacySettings(deps PrivacyHandlerDependencies) gin.HandlerFunc {
	return func(c *gin.Context) {
		// 1. Get authenticated user ID from context
		userIDAny, exists := c.Get(middlewares.UserIDKey)
		if !exists {
			response.Error(c, http.StatusUnauthorized, models.Unauthorized)
			return
		}

		userIDStr, ok := userIDAny.(string)
		if !ok || userIDStr == "" {
			response.Error(c, http.StatusInternalServerError, models.ServerError)
			return
		}

		// 2. Convert to ObjectID
		userID, err := primitive.ObjectIDFromHex(userIDStr)
		if err != nil {
			response.Error(c, http.StatusBadRequest, models.InvalidToken)
			return
		}

		// 3. Get or create privacy settings
		settings, err := deps.PrivacyService.GetOrCreatePrivacySettings(userID)
		if err != nil {
			utils.Error("Error getting privacy settings", map[string]interface{}{"userId": userIDStr, "error": err.Error()})
			response.Error(c, http.StatusInternalServerError, models.ServerError)
			return
		}

		// 4. Return privacy settings
		response.Success(c, http.StatusOK, models.PrivacySettingsRetrieved, settings)
	}
}

// ===================================
// 2. UPDATE PRIVACY SETTINGS (PUT /api/v1/users/me/privacy)
// ===================================

// UpdatePrivacySettings updates the current user's privacy settings
func UpdatePrivacySettings(deps PrivacyHandlerDependencies) gin.HandlerFunc {
	return func(c *gin.Context) {
		// 1. Get authenticated user ID from context
		userIDAny, exists := c.Get(middlewares.UserIDKey)
		if !exists {
			response.Error(c, http.StatusUnauthorized, models.Unauthorized)
			return
		}

		userIDStr, ok := userIDAny.(string)
		if !ok || userIDStr == "" {
			response.Error(c, http.StatusInternalServerError, models.ServerError)
			return
		}

		// 2. Convert to ObjectID
		userID, err := primitive.ObjectIDFromHex(userIDStr)
		if err != nil {
			response.Error(c, http.StatusBadRequest, models.InvalidToken)
			return
		}

		// 3. Parse request body
		var req UpdatePrivacySettingsRequest
		if err := c.ShouldBindJSON(&req); err != nil {
			response.Error(c, http.StatusBadRequest, models.RequiredField)
			return
		}

		// 4. Update privacy settings
		updatedSettings, err := deps.PrivacyService.UpdatePrivacySettings(userID, req)
		if err != nil {
			if err.Error() == "privacy settings not found" {
				response.Error(c, http.StatusNotFound, models.PrivacySettingsNotFound)
				return
			}
			utils.Error("Error updating privacy settings", map[string]interface{}{"userId": userIDStr, "error": err.Error()})
			response.Error(c, http.StatusInternalServerError, models.ServerError)
			return
		}

		// 5. Return updated settings
		response.Success(c, http.StatusOK, models.PrivacySettingsUpdated, updatedSettings)
	}
}

// ===================================
// 3. BLOCK USER (POST /api/v1/users/me/privacy/block)
// ===================================

// BlockUser adds a user to the blocked list
func BlockUser(deps PrivacyHandlerDependencies) gin.HandlerFunc {
	return func(c *gin.Context) {
		// 1. Get authenticated user ID from context
		userIDAny, exists := c.Get(middlewares.UserIDKey)
		if !exists {
			response.Error(c, http.StatusUnauthorized, models.Unauthorized)
			return
		}

		userIDStr, ok := userIDAny.(string)
		if !ok || userIDStr == "" {
			response.Error(c, http.StatusInternalServerError, models.ServerError)
			return
		}

		// 2. Convert to ObjectID
		userID, err := primitive.ObjectIDFromHex(userIDStr)
		if err != nil {
			response.Error(c, http.StatusBadRequest, models.InvalidToken)
			return
		}

		// 3. Parse request body
		var req BlockUserRequest
		if err := c.ShouldBindJSON(&req); err != nil {
			response.Error(c, http.StatusBadRequest, models.RequiredField)
			return
		}

		// 4. Sanitize input
		req.UserIDToBlock = middlewares.SanitizeInput(req.UserIDToBlock)

		// 5. Convert target user ID
		userToBlockID, err := primitive.ObjectIDFromHex(req.UserIDToBlock)
		if err != nil {
			response.Error(c, http.StatusBadRequest, "invalid_user_id")
			return
		}

		// 6. Block the user
		err = deps.PrivacyService.BlockUser(userID, userToBlockID)
		if err != nil {
			if err.Error() == "cannot block yourself" {
				response.Error(c, http.StatusBadRequest, models.CannotBlockYourself)
				return
			}
			utils.Error("Error blocking user", map[string]interface{}{"userId": userIDStr, "userToBlock": req.UserIDToBlock, "error": err.Error()})
			response.Error(c, http.StatusInternalServerError, models.ServerError)
			return
		}

		// 7. Return success
		response.Success(c, http.StatusOK, models.UserBlocked, gin.H{
			"blockedUserId": req.UserIDToBlock,
		})
	}
}

// ===================================
// 4. UNBLOCK USER (DELETE /api/v1/users/me/privacy/block/:userId)
// ===================================

// UnblockUser removes a user from the blocked list
func UnblockUser(deps PrivacyHandlerDependencies) gin.HandlerFunc {
	return func(c *gin.Context) {
		// 1. Get authenticated user ID from context
		userIDAny, exists := c.Get(middlewares.UserIDKey)
		if !exists {
			response.Error(c, http.StatusUnauthorized, models.Unauthorized)
			return
		}

		userIDStr, ok := userIDAny.(string)
		if !ok || userIDStr == "" {
			response.Error(c, http.StatusInternalServerError, models.ServerError)
			return
		}

		// 2. Convert to ObjectID
		userID, err := primitive.ObjectIDFromHex(userIDStr)
		if err != nil {
			response.Error(c, http.StatusBadRequest, models.InvalidToken)
			return
		}

		// 3. Get target user ID from URL parameter
		userToUnblockIDStr := c.Param("userId")
		if userToUnblockIDStr == "" {
			response.Error(c, http.StatusBadRequest, models.RequiredField)
			return
		}

		// 4. Sanitize and convert target user ID
		userToUnblockIDStr = middlewares.SanitizeInput(userToUnblockIDStr)
		userToUnblockID, err := primitive.ObjectIDFromHex(userToUnblockIDStr)
		if err != nil {
			response.Error(c, http.StatusBadRequest, "invalid_user_id")
			return
		}

		// 5. Unblock the user
		err = deps.PrivacyService.UnblockUser(userID, userToUnblockID)
		if err != nil {
			if err.Error() == "privacy settings not found" {
				response.Error(c, http.StatusNotFound, models.PrivacySettingsNotFound)
				return
			}
			utils.Error("Error unblocking user", map[string]interface{}{"userId": userIDStr, "userToUnblock": userToUnblockIDStr, "error": err.Error()})
			response.Error(c, http.StatusInternalServerError, models.ServerError)
			return
		}

		// 6. Return success
		response.Success(c, http.StatusOK, models.UserUnblocked, gin.H{
			"unblockedUserId": userToUnblockIDStr,
		})
	}
}

// ===================================
// 5. GET BLOCKED USERS (GET /api/v1/users/me/privacy/blocked)
// ===================================

// GetBlockedUsers retrieves the list of blocked user IDs
func GetBlockedUsers(deps PrivacyHandlerDependencies) gin.HandlerFunc {
	return func(c *gin.Context) {
		// 1. Get authenticated user ID from context
		userIDAny, exists := c.Get(middlewares.UserIDKey)
		if !exists {
			response.Error(c, http.StatusUnauthorized, models.Unauthorized)
			return
		}

		userIDStr, ok := userIDAny.(string)
		if !ok || userIDStr == "" {
			response.Error(c, http.StatusInternalServerError, models.ServerError)
			return
		}

		// 2. Convert to ObjectID
		userID, err := primitive.ObjectIDFromHex(userIDStr)
		if err != nil {
			response.Error(c, http.StatusBadRequest, models.InvalidToken)
			return
		}

		// 3. Get blocked users list
		blockedUserIDs, err := deps.PrivacyService.GetBlockedUsers(userID)
		if err != nil {
			utils.Error("Error getting blocked users", map[string]interface{}{"userId": userIDStr, "error": err.Error()})
			response.Error(c, http.StatusInternalServerError, models.ServerError)
			return
		}

		// 4. Return blocked users list
		response.Success(c, http.StatusOK, models.BlockedUsersRetrieved, gin.H{
			"blockedUserIds": blockedUserIDs,
			"count":          len(blockedUserIDs),
		})
	}
}
