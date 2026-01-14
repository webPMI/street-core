package handlers

import (
	"backend/features/auth"
	"backend/features/profile"
	"backend/middlewares"
	"backend/models"
	"backend/pkg/errors"
	"backend/pkg/response"
	"net/http"

	"github.com/gin-gonic/gin"
)

// UserHandler handles user-related HTTP requests
type UserHandler struct {
	userService profile.UserService
	authService auth.AuthService
}

// NewUserHandler creates a new user handler
func NewUserHandler(userService profile.UserService, authService auth.AuthService) *UserHandler {
	return &UserHandler{
		userService: userService,
		authService: authService,
	}
}

// GetCurrentUser returns the current authenticated user
func (h *UserHandler) GetCurrentUser(c *gin.Context) {
	userObjID, err := middlewares.GetUserIDFromContext(c)
	if err != nil {
		return // Error already handled by GetUserIDFromContext
	}

	user, err := h.userService.GetCurrentUser(userObjID.Hex())
	if err != nil {
		response.HandleError(c, errors.ErrUserNotFound())
		return
	}

	response.OK(c, models.UserRetrieved, gin.H{"user": user})
}

// GetUserByIDPublic returns a user by ID (public profile)
func (h *UserHandler) GetUserByIDPublic(c *gin.Context) {
	userID := c.Param("id")
	if userID == "" {
		response.HandleError(c, errors.ErrRequiredField("id"))
		return
	}

	user, err := h.userService.GetUser(userID)
	if err != nil {
		response.HandleError(c, errors.ErrUserNotFound())
		return
	}

	// Return public profile (hide sensitive data)
	publicUser := gin.H{
		"id":             user.ID,
		"firstName":      user.FirstName,
		"lastName":       user.LastName,
		"userName":       user.UserName,
		"bio":            user.Bio,
		"avatarUrl":      user.AvatarURL,
		"isPrivate":      user.IsPrivate,
		"followersCount": user.FollowersCount,
		"followingCount": user.FollowingCount,
	}

	response.OK(c, models.UserRetrieved, gin.H{"user": publicUser})
}

// UpdateUserProfile updates the current user's profile
func (h *UserHandler) UpdateUserProfile(c *gin.Context) {
	userObjID, err := middlewares.GetUserIDFromContext(c)
	if err != nil {
		return // Error already handled
	}
	userID := userObjID.Hex()

	var updates map[string]interface{}
	if err := c.ShouldBindJSON(&updates); err != nil {
		response.HandleError(c, errors.ErrJSONParsingFailed(err))
		return
	}

	// Remove fields that shouldn't be updated directly
	delete(updates, "id")
	delete(updates, "_id")
	delete(updates, "email")
	delete(updates, "password")
	delete(updates, "role")
	delete(updates, "tokenVersion")
	delete(updates, "createdAt")
	delete(updates, "updatedAt")

	// Protect calculated/system fields
	delete(updates, "followersCount")
	delete(updates, "followingCount")
	delete(updates, "emailVerified")
	delete(updates, "isActive")
	delete(updates, "isPremium")

	// Protect 2FA fields (should be managed through dedicated endpoints)
	delete(updates, "twoFactorSecret")
	delete(updates, "twoFactorVerifiedAt")
	delete(updates, "backupCodes")

	// Protect OAuth fields (managed through OAuth flow)
	delete(updates, "oauthProviders")

	if err := h.userService.UpdateUser(userID, updates); err != nil {
		response.HandleError(c, errors.ErrDatabaseError("update user", err))
		return
	}

	user, _ := h.userService.GetUser(userID)
	response.OK(c, models.ProfileUpdated, gin.H{"user": user})
}

// ChangePassword changes the user's password
func (h *UserHandler) ChangePassword(c *gin.Context) {
	userObjID, err := middlewares.GetUserIDFromContext(c)
	if err != nil {
		return // Error already handled
	}
	userID := userObjID.Hex()

	var req struct {
		OldPassword string `json:"oldPassword" binding:"required,min=8"`
		NewPassword string `json:"newPassword" binding:"required,min=8"`
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		response.HandleError(c, errors.ErrJSONParsingFailed(err))
		return
	}

	// Validate password strength
	if passwordErrors := middlewares.ValidatePasswordStrength(req.NewPassword); len(passwordErrors) > 0 {
		response.HandleError(c, errors.ErrWeakPassword(passwordErrors))
		return
	}

	if err := h.userService.ChangePassword(userID, req.OldPassword, req.NewPassword); err != nil {
		response.HandleError(c, errors.ErrInvalidInput(err.Error()))
		return
	}

	response.OK(c, models.PasswordChanged, nil)
}

// CreateUser creates a new user (admin only)
func (h *UserHandler) CreateUser(c *gin.Context) {
	var user models.User
	if err := c.ShouldBindJSON(&user); err != nil {
		response.HandleError(c, errors.ErrJSONParsingFailed(err))
		return
	}

	if err := h.userService.CreateUser(&user); err != nil {
		response.HandleError(c, errors.ErrDatabaseError("create user", err))
		return
	}

	response.Created(c, models.UserCreated, gin.H{"user": user})
}

// DeleteUser deletes a user (admin only or self)
func (h *UserHandler) DeleteUser(c *gin.Context) {
	userID := c.Param("id")
	currentUserObjID, err := middlewares.GetUserIDFromContext(c)
	if err != nil {
		return // Error already handled
	}
	currentUserID := currentUserObjID.Hex()
	currentUserRole, _ := middlewares.GetUserRoleFromContext(c)

	// Only admin or the user themselves can delete
	if currentUserRole != models.RoleAdmin && currentUserID != userID {
		response.Error(c, http.StatusForbidden, models.PermissionDenied)
		return
	}

	if err := h.userService.DeleteUser(userID); err != nil {
		response.HandleError(c, errors.ErrDatabaseError("delete user", err))
		return
	}

	response.OK(c, models.UserDeleted, nil)
}
