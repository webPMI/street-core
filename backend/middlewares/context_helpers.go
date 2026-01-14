package middlewares

import (
	"backend/pkg/errors"
	"backend/pkg/helpers"
	"backend/pkg/response"

	"github.com/gin-gonic/gin"
	"go.mongodb.org/mongo-driver/bson/primitive"
)

// GetUserIDFromContext extracts and validates user ID from Gin context
// Returns ObjectID and error. If error occurs, response is already sent to client.
func GetUserIDFromContext(c *gin.Context) (primitive.ObjectID, error) {
	userIDAny, exists := c.Get(UserIDKey)
	if !exists {
		err := errors.ErrUnauthorized()
		response.HandleError(c, err)
		return primitive.NilObjectID, err
	}

	userIDStr, ok := userIDAny.(string)
	if !ok || userIDStr == "" {
		err := errors.ErrInternalServer("Invalid user ID format in context", nil)
		response.HandleError(c, err)
		return primitive.NilObjectID, err
	}

	objectID, err := helpers.StringToObjectID(userIDStr)
	if err != nil {
		response.HandleError(c, err)
		return primitive.NilObjectID, err
	}

	return objectID, nil
}

// GetUserRoleFromContext extracts user role from Gin context
func GetUserRoleFromContext(c *gin.Context) (string, bool) {
	roleAny, exists := c.Get(UserRoleKey)
	if !exists {
		return "", false
	}

	role, ok := roleAny.(string)
	return role, ok
}

// Context keys for additional user data
const (
	UserNameKey   = "userName"
	UserAvatarKey = "userAvatar"
)

// GetUserNameFromContext extracts user name from Gin context safely.
// Returns empty string if not set or invalid type.
func GetUserNameFromContext(c *gin.Context) string {
	nameAny, exists := c.Get(UserNameKey)
	if !exists {
		return ""
	}
	name, ok := nameAny.(string)
	if !ok {
		return ""
	}
	return name
}

// GetUserAvatarFromContext extracts user avatar URL from Gin context safely.
// Returns empty string if not set or invalid type.
func GetUserAvatarFromContext(c *gin.Context) string {
	avatarAny, exists := c.Get(UserAvatarKey)
	if !exists {
		return ""
	}
	avatar, ok := avatarAny.(string)
	if !ok {
		return ""
	}
	return avatar
}

// UserContextData holds all user-related data extracted from context
type UserContextData struct {
	UserID   primitive.ObjectID
	UserName string
	Avatar   string
	Role     string
}

// GetUserContextData extracts all user-related data from context in one call.
// Returns error if user is not authenticated. If error is returned, response is already sent.
func GetUserContextData(c *gin.Context) (*UserContextData, error) {
	userID, err := GetUserIDFromContext(c)
	if err != nil {
		return nil, err // Response already sent
	}

	role, _ := GetUserRoleFromContext(c)

	return &UserContextData{
		UserID:   userID,
		UserName: GetUserNameFromContext(c),
		Avatar:   GetUserAvatarFromContext(c),
		Role:     role,
	}, nil
}
