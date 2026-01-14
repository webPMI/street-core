package profile

import (
	"backend/pkg/pagination"
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/microcosm-cc/bluemonday"
	"go.mongodb.org/mongo-driver/bson/primitive"
)

type StoryHandler struct {
	StoryService  IStoryService
	UserService   UserService
	FollowService IFollowService
}

func NewStoryHandler(storyService IStoryService, userService UserService, followService IFollowService) *StoryHandler {
	return &StoryHandler{
		StoryService:  storyService,
		UserService:   userService,
		FollowService: followService,
	}
}

// CreateStory godoc
// @Summary Create a new story
// @Description Create a new story (expires in 24 hours)
// @Tags Stories
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param body body CreateStoryRequest true "Story data"
// @Success 201 {object} map[string]interface{} "Story created"
// @Failure 400 {object} map[string]interface{} "Invalid request"
// @Failure 401 {object} map[string]interface{} "Unauthorized"
// @Router /api/stories [post]
func (h *StoryHandler) CreateStory(c *gin.Context) {
	currentUserID, exists := c.Get("userID")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"status": "error", "message": "unauthorized"})
		return
	}

	userID := currentUserID.(string)

	var req CreateStoryRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"status": "error", "message": err.Error()})
		return
	}

	// Get user info
	userObjID, err := primitive.ObjectIDFromHex(userID)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"status": "error", "message": "invalid user ID"})
		return
	}
	user, err := h.UserService.GetUserByObjectID(c.Request.Context(), userObjID)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"status": "error", "message": "user not found"})
		return
	}

	// Sanitize caption
	p := bluemonday.StrictPolicy()
	caption := p.Sanitize(req.Caption)

	// Create story
	story, err := h.StoryService.CreateStory(
		userID,
		user.UserName,
		user.AvatarURL,
		req.MediaType,
		req.MediaURL,
		req.ThumbnailURL,
		caption,
		req.Visibility,
	)

	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"status": "error", "message": "failed to create story"})
		return
	}

	c.JSON(http.StatusCreated, gin.H{
		"status":  "success",
		"message": "story created",
		"data":    story,
	})
}

// GetStory godoc
// @Summary Get a story by ID
// @Description Get a specific story by ID
// @Tags Stories
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param id path string true "Story ID"
// @Success 200 {object} map[string]interface{} "Story data"
// @Failure 401 {object} map[string]interface{} "Unauthorized"
// @Failure 404 {object} map[string]interface{} "Story not found"
// @Router /api/stories/{id} [get]
func (h *StoryHandler) GetStory(c *gin.Context) {
	storyID := c.Param("id")
	_, exists := c.Get("userID")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"status": "error", "message": "unauthorized"})
		return
	}

	story, err := h.StoryService.GetStoryByID(storyID)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"status": "error", "message": "story not found or expired"})
		return
	}

	if story == nil {
		c.JSON(http.StatusNotFound, gin.H{"status": "error", "message": "story not found"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"status": "success",
		"data":   story,
	})
}

// GetUserStories godoc
// @Summary Get user's active stories
// @Description Get all active stories for a specific user
// @Tags Stories
// @Accept json
// @Produce json
// @Param id path string true "User ID"
// @Success 200 {object} map[string]interface{} "User stories"
// @Failure 400 {object} map[string]interface{} "Invalid request"
// @Router /api/users/{id}/stories [get]
func (h *StoryHandler) GetUserStories(c *gin.Context) {
	userID := c.Param("id")

	stories, err := h.StoryService.GetActiveUserStories(userID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"status": "error", "message": "failed to get stories"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"status": "success",
		"data":   stories,
	})
}

// GetFollowingStories godoc
// @Summary Get stories from followed users
// @Description Get active stories from users that the current user follows
// @Tags Stories
// @Accept json
// @Produce json
// @Security BearerAuth
// @Success 200 {object} map[string]interface{} "Following stories"
// @Failure 401 {object} map[string]interface{} "Unauthorized"
// @Router /api/stories/following [get]
func (h *StoryHandler) GetFollowingStories(c *gin.Context) {
	currentUserID, exists := c.Get("userID")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"status": "error", "message": "unauthorized"})
		return
	}

	userID := currentUserID.(string)

	// Get list of users the current user follows
	following, _, err := h.FollowService.GetFollowing(userID, &pagination.Params{Page: 1, Limit: 1000})
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"status": "error", "message": "failed to get following"})
		return
	}

	// Extract following user IDs
	followingIDs := make([]string, 0, len(following))
	for _, f := range following {
		followingIDs = append(followingIDs, f.FollowingID.Hex())
	}

	// Get stories from followed users
	stories, err := h.StoryService.GetFollowingStories(userID, followingIDs)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"status": "error", "message": "failed to get stories"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"status": "success",
		"data":   stories,
	})
}

// DeleteStory godoc
// @Summary Delete a story
// @Description Delete a story (soft delete)
// @Tags Stories
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param id path string true "Story ID"
// @Success 200 {object} map[string]interface{} "Story deleted"
// @Failure 401 {object} map[string]interface{} "Unauthorized"
// @Failure 404 {object} map[string]interface{} "Story not found"
// @Router /api/stories/{id} [delete]
func (h *StoryHandler) DeleteStory(c *gin.Context) {
	storyID := c.Param("id")
	currentUserID, exists := c.Get("userID")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"status": "error", "message": "unauthorized"})
		return
	}

	userID := currentUserID.(string)

	err := h.StoryService.DeleteStory(storyID, userID)
	if err != nil {
		if err.Error() == "story not found or not owned by user" {
			c.JSON(http.StatusNotFound, gin.H{"status": "error", "message": err.Error()})
			return
		}
		c.JSON(http.StatusInternalServerError, gin.H{"status": "error", "message": "failed to delete story"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"status":  "success",
		"message": "story deleted",
	})
}

// ViewStory godoc
// @Summary View a story
// @Description Record a view on a story
// @Tags Stories
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param id path string true "Story ID"
// @Success 200 {object} map[string]interface{} "View recorded"
// @Failure 401 {object} map[string]interface{} "Unauthorized"
// @Router /api/stories/{id}/view [post]
func (h *StoryHandler) ViewStory(c *gin.Context) {
	storyID := c.Param("id")
	currentUserID, exists := c.Get("userID")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"status": "error", "message": "unauthorized"})
		return
	}

	userID := currentUserID.(string)

	// Get user info
	userObjID, err := primitive.ObjectIDFromHex(userID)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"status": "error", "message": "invalid user ID"})
		return
	}
	user, err := h.UserService.GetUserByObjectID(c.Request.Context(), userObjID)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"status": "error", "message": "user not found"})
		return
	}

	err = h.StoryService.ViewStory(storyID, userID, user.UserName, user.AvatarURL)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"status": "error", "message": "failed to record view"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"status":  "success",
		"message": "view recorded",
	})
}

// GetStoryViewers godoc
// @Summary Get story viewers
// @Description Get all users who viewed a story
// @Tags Stories
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param id path string true "Story ID"
// @Success 200 {object} map[string]interface{} "Story viewers"
// @Failure 401 {object} map[string]interface{} "Unauthorized"
// @Failure 403 {object} map[string]interface{} "Not story owner"
// @Router /api/stories/{id}/viewers [get]
func (h *StoryHandler) GetStoryViewers(c *gin.Context) {
	storyID := c.Param("id")
	currentUserID, exists := c.Get("userID")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"status": "error", "message": "unauthorized"})
		return
	}

	userID := currentUserID.(string)

	viewers, err := h.StoryService.GetStoryViewers(storyID, userID)
	if err != nil {
		if err.Error() == "story not found or not owned by user" {
			c.JSON(http.StatusForbidden, gin.H{"status": "error", "message": err.Error()})
			return
		}
		c.JSON(http.StatusInternalServerError, gin.H{"status": "error", "message": "failed to get viewers"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"status": "success",
		"data":   viewers,
	})
}

// CreateHighlight godoc
// @Summary Create a story highlight
// @Description Create a new story highlight collection
// @Tags Stories
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param body body CreateHighlightRequest true "Highlight data"
// @Success 201 {object} map[string]interface{} "Highlight created"
// @Failure 400 {object} map[string]interface{} "Invalid request"
// @Failure 401 {object} map[string]interface{} "Unauthorized"
// @Router /api/highlights [post]
func (h *StoryHandler) CreateHighlight(c *gin.Context) {
	currentUserID, exists := c.Get("userID")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"status": "error", "message": "unauthorized"})
		return
	}

	userID := currentUserID.(string)

	var req CreateHighlightRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"status": "error", "message": err.Error()})
		return
	}

	// Sanitize title
	p := bluemonday.StrictPolicy()
	title := p.Sanitize(req.Title)

	highlight, err := h.StoryService.CreateHighlight(userID, title, req.CoverURL, req.StoryIDs)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"status": "error", "message": "failed to create highlight"})
		return
	}

	c.JSON(http.StatusCreated, gin.H{
		"status":  "success",
		"message": "highlight created",
		"data":    highlight,
	})
}

// GetUserHighlights godoc
// @Summary Get user's highlights
// @Description Get all highlights for a specific user
// @Tags Stories
// @Accept json
// @Produce json
// @Param id path string true "User ID"
// @Success 200 {object} map[string]interface{} "User highlights"
// @Failure 400 {object} map[string]interface{} "Invalid request"
// @Router /api/users/{id}/highlights [get]
func (h *StoryHandler) GetUserHighlights(c *gin.Context) {
	userID := c.Param("id")

	highlights, err := h.StoryService.GetUserHighlights(userID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"status": "error", "message": "failed to get highlights"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"status": "success",
		"data":   highlights,
	})
}

// UpdateHighlight godoc
// @Summary Update a highlight
// @Description Update a story highlight
// @Tags Stories
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param id path string true "Highlight ID"
// @Param body body UpdateHighlightRequest true "Highlight data"
// @Success 200 {object} map[string]interface{} "Highlight updated"
// @Failure 400 {object} map[string]interface{} "Invalid request"
// @Failure 401 {object} map[string]interface{} "Unauthorized"
// @Failure 404 {object} map[string]interface{} "Highlight not found"
// @Router /api/highlights/{id} [put]
func (h *StoryHandler) UpdateHighlight(c *gin.Context) {
	highlightID := c.Param("id")
	currentUserID, exists := c.Get("userID")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"status": "error", "message": "unauthorized"})
		return
	}

	userID := currentUserID.(string)

	var req UpdateHighlightRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"status": "error", "message": err.Error()})
		return
	}

	// Sanitize title
	p := bluemonday.StrictPolicy()
	title := p.Sanitize(req.Title)

	err := h.StoryService.UpdateHighlight(highlightID, userID, title, req.CoverURL, req.StoryIDs)
	if err != nil {
		if err.Error() == "highlight not found or not owned by user" {
			c.JSON(http.StatusNotFound, gin.H{"status": "error", "message": err.Error()})
			return
		}
		c.JSON(http.StatusInternalServerError, gin.H{"status": "error", "message": "failed to update highlight"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"status":  "success",
		"message": "highlight updated",
	})
}

// DeleteHighlight godoc
// @Summary Delete a highlight
// @Description Delete a story highlight
// @Tags Stories
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param id path string true "Highlight ID"
// @Success 200 {object} map[string]interface{} "Highlight deleted"
// @Failure 401 {object} map[string]interface{} "Unauthorized"
// @Failure 404 {object} map[string]interface{} "Highlight not found"
// @Router /api/highlights/{id} [delete]
func (h *StoryHandler) DeleteHighlight(c *gin.Context) {
	highlightID := c.Param("id")
	currentUserID, exists := c.Get("userID")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"status": "error", "message": "unauthorized"})
		return
	}

	userID := currentUserID.(string)

	err := h.StoryService.DeleteHighlight(highlightID, userID)
	if err != nil {
		if err.Error() == "highlight not found or not owned by user" {
			c.JSON(http.StatusNotFound, gin.H{"status": "error", "message": err.Error()})
			return
		}
		c.JSON(http.StatusInternalServerError, gin.H{"status": "error", "message": "failed to delete highlight"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"status":  "success",
		"message": "highlight deleted",
	})
}

// GetStoryStats godoc
// @Summary Get story statistics
// @Description Get story statistics for a user
// @Tags Stories
// @Accept json
// @Produce json
// @Security BearerAuth
// @Success 200 {object} map[string]interface{} "Story stats"
// @Failure 401 {object} map[string]interface{} "Unauthorized"
// @Router /api/stories/stats [get]
func (h *StoryHandler) GetStoryStats(c *gin.Context) {
	currentUserID, exists := c.Get("userID")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"status": "error", "message": "unauthorized"})
		return
	}

	userID := currentUserID.(string)

	stats, err := h.StoryService.GetStoryStats(userID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"status": "error", "message": "failed to get stats"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"status": "success",
		"data":   stats,
	})
}

// Request structs
type CreateStoryRequest struct {
	MediaType    StoryMediaType  `json:"mediaType" binding:"required,oneof=image video"`
	MediaURL     string          `json:"mediaUrl" binding:"required"`
	ThumbnailURL string          `json:"thumbnailUrl,omitempty"`
	Caption      string          `json:"caption,omitempty" binding:"max=200"`
	Visibility   StoryVisibility `json:"visibility" binding:"required,oneof=public followers close_friends"`
}

type CreateHighlightRequest struct {
	Title    string   `json:"title" binding:"required,min=1,max=50"`
	CoverURL string   `json:"coverUrl,omitempty"`
	StoryIDs []string `json:"storyIds" binding:"required,min=1"`
}

type UpdateHighlightRequest struct {
	Title    string   `json:"title" binding:"required,min=1,max=50"`
	CoverURL string   `json:"coverUrl,omitempty"`
	StoryIDs []string `json:"storyIds" binding:"required,min=1"`
}
