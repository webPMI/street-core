package profile

import (
	"net/http"

	"backend/utils"

	"github.com/gin-gonic/gin"
	"go.mongodb.org/mongo-driver/bson/primitive"
)

type savedPostHandler struct {
	savedPostService ISavedPostService
}

func NewSavedPostHandler(savedPostService ISavedPostService) *savedPostHandler {
	return &savedPostHandler{
		savedPostService: savedPostService,
	}
}

// SavePost saves a post for later viewing
// POST /posts/:id/save
func (h *savedPostHandler) SavePost(c *gin.Context) {
	postID := c.Param("id")
	userID, exists := c.Get("userID")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"status": "error", "message": "unauthorized"})
		return
	}

	postObjID, err := primitive.ObjectIDFromHex(postID)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"status": "error", "message": "invalid_post_id"})
		return
	}

	userObjID, err := primitive.ObjectIDFromHex(userID.(string))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"status": "error", "message": "invalid_user_id"})
		return
	}

	// Create saved post
	savedPost := &SavedPost{
		PostID: postObjID,
		UserID: userObjID,
	}

	if err := h.savedPostService.SavePost(savedPost); err != nil {
		utils.Error("Error saving post", map[string]interface{}{"postId": postID, "userId": userID.(string), "error": err.Error()})

		// Check for specific error messages
		if err.Error() == "post_already_saved" {
			c.JSON(http.StatusConflict, gin.H{"status": "error", "message": "post_already_saved"})
			return
		}

		c.JSON(http.StatusBadRequest, gin.H{"status": "error", "message": err.Error()})
		return
	}

	c.JSON(http.StatusCreated, gin.H{
		"status":  "success",
		"message": "post_saved",
		"data": SavedPostResponse{
			IsSaved: true,
			SaveID:  savedPost.ID.Hex(),
		},
	})
}

// UnsavePost removes a saved post
// DELETE /posts/:id/save
func (h *savedPostHandler) UnsavePost(c *gin.Context) {
	postID := c.Param("id")
	userID, exists := c.Get("userID")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"status": "error", "message": "unauthorized"})
		return
	}

	if err := h.savedPostService.UnsavePost(postID, userID.(string)); err != nil {
		utils.Error("Error unsaving post", map[string]interface{}{"postId": postID, "userId": userID.(string), "error": err.Error()})
		c.JSON(http.StatusBadRequest, gin.H{"status": "error", "message": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"status":  "success",
		"message": "post_unsaved",
		"data": SavedPostResponse{
			IsSaved: false,
		},
	})
}

// GetMySavedPosts gets all posts saved by the authenticated user
// GET /posts/saved
func (h *savedPostHandler) GetMySavedPosts(c *gin.Context) {
	userID, exists := c.Get("userID")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"status": "error", "message": "unauthorized"})
		return
	}

	savedPosts, err := h.savedPostService.GetUserSavedPosts(userID.(string))
	if err != nil {
		utils.Error("Error getting saved posts", map[string]interface{}{"userId": userID, "error": err.Error()})
		c.JSON(http.StatusInternalServerError, gin.H{"status": "error", "message": "server_error"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"status": "success", "data": savedPosts})
}

// CheckSaveStatus verifies if the user has saved a post
// GET /posts/:id/save/status
func (h *savedPostHandler) CheckSaveStatus(c *gin.Context) {
	postID := c.Param("id")

	userID, exists := c.Get("userID")
	if !exists {
		c.JSON(http.StatusOK, gin.H{"status": "success", "data": gin.H{"isSaved": false}})
		return
	}

	isSaved, err := h.savedPostService.CheckSavedStatus(postID, userID.(string))
	if err != nil {
		c.JSON(http.StatusOK, gin.H{"status": "success", "data": gin.H{"isSaved": false}})
		return
	}

	c.JSON(http.StatusOK, gin.H{"status": "success", "data": gin.H{"isSaved": isSaved}})
}
