package social

import (
	"net/http"

	"backend/middlewares"
	"backend/utils"

	"github.com/gin-gonic/gin"
	"go.mongodb.org/mongo-driver/bson/primitive"
)

type commentLikeHandler struct {
	commentLikeService ICommentLikeService
	commentService     ICommentService
}

func NewCommentLikeHandler(commentLikeService ICommentLikeService, commentService ICommentService) *commentLikeHandler {
	return &commentLikeHandler{
		commentLikeService: commentLikeService,
		commentService:     commentService,
	}
}

// LikeComment da "me gusta" a un comentario
// POST /comments/:commentId/like
func (h *commentLikeHandler) LikeComment(c *gin.Context) {
	commentID := c.Param("commentId")

	// Extract user data from context safely
	userData, err := middlewares.GetUserContextData(c)
	if err != nil {
		return // Response already sent
	}

	commentObjID, err := primitive.ObjectIDFromHex(commentID)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"status": "error", "message": "invalid_comment_id"})
		return
	}

	// Crear like
	like := &CommentLike{
		CommentID:  commentObjID,
		UserID:     userData.UserID,
		UserName:   userData.UserName,
		UserAvatar: userData.Avatar,
	}

	if err := h.commentLikeService.LikeComment(like); err != nil {
		utils.Warn("Failed to like comment", map[string]interface{}{
			"comment_id": commentID,
			"user_id":    userData.UserID.Hex(),
			"error":      err.Error(),
		})
		c.JSON(http.StatusBadRequest, gin.H{"status": "error", "message": err.Error()})
		return
	}

	// Obtener comentario actualizado para devolver contador de likes
	comment, err := h.commentService.GetCommentByID(commentID)
	if err != nil {
		utils.Debug("Could not fetch updated comment after like", map[string]interface{}{
			"comment_id": commentID,
			"error":      err.Error(),
		})
	}
	likesCount := 0
	if comment != nil {
		likesCount = comment.LikesCount
	}

	c.JSON(http.StatusCreated, gin.H{
		"status":  "success",
		"message": "comment_liked_successfully",
		"data": CommentLikeResponse{
			IsLiked:    true,
			LikesCount: likesCount,
			LikeID:     like.ID.Hex(),
		},
	})
}

// UnlikeComment quita el "me gusta" de un comentario
// DELETE /comments/:commentId/like
func (h *commentLikeHandler) UnlikeComment(c *gin.Context) {
	commentID := c.Param("commentId")
	userID, exists := c.Get("userID")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"status": "error", "message": "unauthorized"})
		return
	}

	if err := h.commentLikeService.UnlikeComment(commentID, userID.(string)); err != nil {
		utils.Warn("Failed to unlike comment", map[string]interface{}{
			"comment_id": commentID,
			"user_id":    userID.(string),
			"error":      err.Error(),
		})
		c.JSON(http.StatusBadRequest, gin.H{"status": "error", "message": err.Error()})
		return
	}

	// Obtener comentario actualizado para devolver contador de likes
	comment, err := h.commentService.GetCommentByID(commentID)
	if err != nil {
		utils.Debug("Could not fetch updated comment after unlike", map[string]interface{}{
			"comment_id": commentID,
			"error":      err.Error(),
		})
	}
	likesCount := 0
	if comment != nil {
		likesCount = comment.LikesCount
	}

	c.JSON(http.StatusOK, gin.H{
		"status":  "success",
		"message": "comment_unliked_successfully",
		"data": CommentLikeResponse{
			IsLiked:    false,
			LikesCount: likesCount,
		},
	})
}

// GetCommentLikes obtiene todos los usuarios que dieron like a un comentario
// GET /comments/:commentId/likes
func (h *commentLikeHandler) GetCommentLikes(c *gin.Context) {
	commentID := c.Param("commentId")

	// Límite por defecto 100
	limit := 100

	likes, err := h.commentLikeService.GetCommentLikes(commentID, limit)
	if err != nil {
		utils.Error("Failed to get comment likes", map[string]interface{}{
			"comment_id": commentID,
			"error":      err.Error(),
		})
		c.JSON(http.StatusInternalServerError, gin.H{"status": "error", "message": "server_error"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"status": "success", "data": likes})
}

// CheckLikeStatus verifica si el usuario autenticado dio like a un comentario
// GET /comments/:commentId/like/status
func (h *commentLikeHandler) CheckLikeStatus(c *gin.Context) {
	commentID := c.Param("commentId")

	userID, exists := c.Get("userID")
	if !exists {
		c.JSON(http.StatusOK, gin.H{"status": "success", "data": gin.H{"isLiked": false}})
		return
	}

	like, err := h.commentLikeService.GetLike(commentID, userID.(string))
	if err != nil {
		c.JSON(http.StatusOK, gin.H{"status": "success", "data": gin.H{"isLiked": false}})
		return
	}

	isLiked := like != nil
	c.JSON(http.StatusOK, gin.H{"status": "success", "data": gin.H{"isLiked": isLiked}})
}
