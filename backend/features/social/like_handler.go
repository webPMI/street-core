package social

import (
	"net/http"

	"backend/middlewares"
	"backend/utils"

	"github.com/gin-gonic/gin"
	"go.mongodb.org/mongo-driver/bson/primitive"
)

type likeHandler struct {
	likeService ILikeService
	postService IPostService
}

func NewLikeHandler(likeService ILikeService, postService IPostService) *likeHandler {
	return &likeHandler{
		likeService: likeService,
		postService: postService,
	}
}

// LikePost da "me gusta" a una publicación
// POST /posts/:id/like
func (h *likeHandler) LikePost(c *gin.Context) {
	postID := c.Param("id")

	// Extract user data from context safely
	userData, err := middlewares.GetUserContextData(c)
	if err != nil {
		return // Response already sent
	}

	postObjID, err := primitive.ObjectIDFromHex(postID)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"status": "error", "message": "invalid_post_id"})
		return
	}

	// Crear like
	like := &Like{
		PostID:     postObjID,
		UserID:     userData.UserID,
		UserName:   userData.UserName,
		UserAvatar: userData.Avatar,
	}

	if err := h.likeService.LikePost(like); err != nil {
		utils.Warn("Failed to like post", map[string]interface{}{
			"post_id": postID,
			"user_id": userData.UserID.Hex(),
			"error":   err.Error(),
		})
		c.JSON(http.StatusBadRequest, gin.H{"status": "error", "message": err.Error()})
		return
	}

	// Obtener publicación actualizada para devolver contador de likes
	post, err := h.postService.GetPostByID(postID)
	if err != nil {
		utils.Debug("Could not fetch updated post after like", map[string]interface{}{
			"post_id": postID,
			"error":   err.Error(),
		})
	}
	likesCount := 0
	if post != nil {
		// Type assertion to get LikesCount from the interface{}
		if postData, ok := post.(map[string]interface{}); ok {
			if count, ok := postData["likesCount"].(int); ok {
				likesCount = count
			}
		}
	}

	c.JSON(http.StatusCreated, gin.H{
		"status":  "success",
		"message": "post_liked_successfully",
		"data": LikeResponse{
			IsLiked:    true,
			LikesCount: likesCount,
			LikeID:     like.ID.Hex(),
		},
	})
}

// UnlikePost quita el "me gusta" de una publicación
// DELETE /posts/:id/like
func (h *likeHandler) UnlikePost(c *gin.Context) {
	postID := c.Param("id")
	userID, exists := c.Get("userID")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"status": "error", "message": "unauthorized"})
		return
	}

	if err := h.likeService.UnlikePost(postID, userID.(string)); err != nil {
		utils.Warn("Failed to unlike post", map[string]interface{}{
			"post_id": postID,
			"user_id": userID.(string),
			"error":   err.Error(),
		})
		c.JSON(http.StatusBadRequest, gin.H{"status": "error", "message": err.Error()})
		return
	}

	// Obtener publicación actualizada para devolver contador de likes
	post, err := h.postService.GetPostByID(postID)
	if err != nil {
		utils.Debug("Could not fetch updated post after unlike", map[string]interface{}{
			"post_id": postID,
			"error":   err.Error(),
		})
	}
	likesCount := 0
	if post != nil {
		if postData, ok := post.(map[string]interface{}); ok {
			if count, ok := postData["likesCount"].(int); ok {
				likesCount = count
			}
		}
	}

	c.JSON(http.StatusOK, gin.H{
		"status":  "success",
		"message": "post_unliked_successfully",
		"data": LikeResponse{
			IsLiked:    false,
			LikesCount: likesCount,
		},
	})
}

// GetPostLikes obtiene todos los usuarios que dieron like a una publicación
// GET /posts/:id/likes
func (h *likeHandler) GetPostLikes(c *gin.Context) {
	postID := c.Param("id")

	// Límite por defecto 100
	limit := 100

	likes, err := h.likeService.GetPostLikes(postID, limit)
	if err != nil {
		utils.Error("Failed to get post likes", map[string]interface{}{
			"post_id": postID,
			"error":   err.Error(),
		})
		c.JSON(http.StatusInternalServerError, gin.H{"status": "error", "message": "server_error"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"status": "success", "data": likes})
}

// GetMyLikes obtiene todas las publicaciones que le gustaron al usuario autenticado
// GET /likes/me
func (h *likeHandler) GetMyLikes(c *gin.Context) {
	userID, exists := c.Get("userID")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"status": "error", "message": "unauthorized"})
		return
	}

	likes, err := h.likeService.GetUserLikes(userID.(string))
	if err != nil {
		utils.Error("Failed to get user likes", map[string]interface{}{
			"user_id": userID.(string),
			"error":   err.Error(),
		})
		c.JSON(http.StatusInternalServerError, gin.H{"status": "error", "message": "server_error"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"status": "success", "data": likes})
}

// CheckLikeStatus verifica si el usuario autenticado dio like a una publicación
// GET /posts/:id/like/status
func (h *likeHandler) CheckLikeStatus(c *gin.Context) {
	postID := c.Param("id")

	userID, exists := c.Get("userID")
	if !exists {
		c.JSON(http.StatusOK, gin.H{"status": "success", "data": gin.H{"isLiked": false}})
		return
	}

	like, err := h.likeService.GetLike(postID, userID.(string))
	if err != nil {
		c.JSON(http.StatusOK, gin.H{"status": "success", "data": gin.H{"isLiked": false}})
		return
	}

	isLiked := like != nil
	c.JSON(http.StatusOK, gin.H{"status": "success", "data": gin.H{"isLiked": isLiked}})
}
