package social

import (
	"backend/middlewares"
	"backend/models"
	"backend/pkg/pagination"
	"backend/utils"
	"log"
	"net/http"

	"github.com/gin-gonic/gin"
	"go.mongodb.org/mongo-driver/bson/primitive"
)

type commentHandler struct {
	commentService     ICommentService
	commentLikeService ICommentLikeService
}

func NewCommentHandler(service ICommentService, likeService ICommentLikeService) *commentHandler {
	return &commentHandler{
		commentService:     service,
		commentLikeService: likeService,
	}
}

// CreateComment crea un nuevo comentario
// POST /posts/:id/comments
func (h *commentHandler) CreateComment(c *gin.Context) {
	postID := c.Param("id")
	utils.InfoWithTag("Social", "Creating comment on post", map[string]interface{}{
		"post_id": postID,
	})

	// Extract user data from context safely
	userData, err := middlewares.GetUserContextData(c)
	if err != nil {
		return // Response already sent
	}

	var req CreateCommentRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.ErrorWithTag("Social", "Failed to parse comment request", map[string]interface{}{
			"error": err.Error(),
		})
		c.JSON(http.StatusBadRequest, gin.H{"status": "error", "message": models.RequiredField})
		return
	}

	postObjID, err := primitive.ObjectIDFromHex(postID)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"status": "error", "message": "invalid_post_id"})
		return
	}

	comment := &Comment{
		PostID:          postObjID,
		UserID:          userData.UserID,
		UserName:        userData.UserName,
		UserAvatar:      userData.Avatar,
		Text:            middlewares.SanitizeHTML(req.Text),
		ParentCommentID: req.ParentCommentID,
	}

	if err := h.commentService.CreateComment(comment); err != nil {
		utils.ErrorWithTag("Social", "Failed to create comment", map[string]interface{}{
			"error":   err.Error(),
			"post_id": postID,
		})
		c.JSON(http.StatusInternalServerError, gin.H{"status": "error", "message": models.ServerError})
		return
	}

	// Establecer isLikedByCurrentUser como false para comentarios nuevos
	comment.IsLikedByCurrentUser = false

	utils.InfoWithTag("Social", "Comment created successfully", map[string]interface{}{
		"comment_id": comment.ID.Hex(),
		"post_id":    postID,
	})
	c.JSON(http.StatusCreated, gin.H{"status": "success", "message": "social.comment.created", "data": comment})
}

// GetPostComments obtiene todos los comentarios de una publicación
// GET /posts/:id/comments
func (h *commentHandler) GetPostComments(c *gin.Context) {
	postID := c.Param("id")
	utils.DebugWithTag("Social", "Fetching post comments", map[string]interface{}{
		"post_id": postID,
	})

	paginationParams, err := middlewares.ParsePagination(c)
	if err != nil {
		return // Response already sent
	}

	// Convert to service params format
	params := &pagination.Params{
		Page:  paginationParams.Page,
		Limit: paginationParams.Limit,
		Skip:  paginationParams.Offset,
	}

	if c.Query("page") != "" || c.Query("limit") != "" {
		comments, total, err := h.commentService.GetPostCommentsPaginated(postID, params)
		if err != nil {
			utils.ErrorWithTag("Social", "Failed to fetch comments", map[string]interface{}{
				"error":   err.Error(),
				"post_id": postID,
			})
			c.JSON(http.StatusInternalServerError, gin.H{"status": "error", "message": models.ServerError})
			return
		}

		// Populate isLikedByCurrentUser for each comment if user is authenticated
		if userID, exists := c.Get("userID"); exists {
			for i := range comments {
				like, _ := h.commentLikeService.GetLike(comments[i].ID.Hex(), userID.(string))
				comments[i].IsLikedByCurrentUser = (like != nil)
			}
		}

		paginatedResp := pagination.CreateResponse(params.Page, params.Limit, total, comments)
		utils.DebugWithTag("Social", "Returning paginated comments", map[string]interface{}{
			"page":  params.Page,
			"total": total,
		})
		c.JSON(http.StatusOK, gin.H{"status": "success", "message": "social.comments.retrieved", "data": paginatedResp})
		return
	}

	comments, err := h.commentService.GetPostComments(postID)
	if err != nil {
		utils.ErrorWithTag("Social", "Failed to fetch comments", map[string]interface{}{
			"error":   err.Error(),
			"post_id": postID,
		})
		c.JSON(http.StatusInternalServerError, gin.H{"status": "error", "message": models.ServerError})
		return
	}

	// Populate isLikedByCurrentUser for each comment if user is authenticated
	if userID, exists := c.Get("userID"); exists {
		for i := range comments {
			like, _ := h.commentLikeService.GetLike(comments[i].ID.Hex(), userID.(string))
			comments[i].IsLikedByCurrentUser = (like != nil)
		}
	}

	utils.DebugWithTag("Social", "Returning comments", map[string]interface{}{
		"count": len(comments),
	})
	c.JSON(http.StatusOK, gin.H{"status": "success", "data": comments})
}

// GetCommentReplies obtiene todas las respuestas de un comentario
// GET /comments/:commentId/replies
func (h *commentHandler) GetCommentReplies(c *gin.Context) {
	commentID := c.Param("commentId")
	utils.DebugWithTag("Social", "Fetching comment replies", map[string]interface{}{
		"comment_id": commentID,
	})

	replies, err := h.commentService.GetCommentReplies(commentID)
	if err != nil {
		utils.ErrorWithTag("Social", "Failed to fetch replies", map[string]interface{}{
			"error":      err.Error(),
			"comment_id": commentID,
		})
		c.JSON(http.StatusInternalServerError, gin.H{"status": "error", "message": models.ServerError})
		return
	}

	// Populate isLikedByCurrentUser for each reply if user is authenticated
	if userID, exists := c.Get("userID"); exists {
		for i := range replies {
			like, _ := h.commentLikeService.GetLike(replies[i].ID.Hex(), userID.(string))
			replies[i].IsLikedByCurrentUser = (like != nil)
		}
	}

	utils.DebugWithTag("Social", "Returning replies", map[string]interface{}{
		"count": len(replies),
	})
	c.JSON(http.StatusOK, gin.H{"status": "success", "data": replies})
}

// UpdateComment actualiza un comentario
// PUT /comments/:commentId
func (h *commentHandler) UpdateComment(c *gin.Context) {
	commentID := c.Param("commentId")
	utils.InfoWithTag("Social", "Updating comment", map[string]interface{}{
		"comment_id": commentID,
	})

	var req UpdateCommentRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.ErrorWithTag("Social", "Failed to parse update request", map[string]interface{}{
			"error": err.Error(),
		})
		c.JSON(http.StatusBadRequest, gin.H{"status": "error", "message": models.RequiredField})
		return
	}

	// Verificar propiedad
	comment, err := h.commentService.GetCommentByID(commentID)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"status": "error", "message": "comment_not_found"})
		return
	}

	userID, _ := c.Get("userID")
	if comment.UserID.Hex() != userID.(string) {
		c.JSON(http.StatusForbidden, gin.H{"status": "error", "message": "forbidden"})
		return
	}

	// Sanitizar texto
	req.Text = middlewares.SanitizeHTML(req.Text)

	if err := h.commentService.UpdateComment(commentID, &req); err != nil {
		utils.ErrorWithTag("Social", "Failed to update comment", map[string]interface{}{
			"error":      err.Error(),
			"comment_id": commentID,
		})
		c.JSON(http.StatusInternalServerError, gin.H{"status": "error", "message": models.ServerError})
		return
	}

	utils.InfoWithTag("Social", "Comment updated successfully", map[string]interface{}{
		"comment_id": commentID,
	})
	c.JSON(http.StatusOK, gin.H{"status": "success", "message": "social.comment.updated"})
}

// DeleteComment elimina un comentario
// DELETE /comments/:commentId
func (h *commentHandler) DeleteComment(c *gin.Context) {
	commentID := c.Param("commentId")
	utils.InfoWithTag("Social", "Deleting comment", map[string]interface{}{
		"comment_id": commentID,
	})

	// Verificar propiedad
	comment, err := h.commentService.GetCommentByID(commentID)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"status": "error", "message": "comment_not_found"})
		return
	}

	userID, _ := c.Get("userID")
	if comment.UserID.Hex() != userID.(string) {
		c.JSON(http.StatusForbidden, gin.H{"status": "error", "message": "forbidden"})
		return
	}

	if err := h.commentService.DeleteComment(commentID); err != nil {
		utils.ErrorWithTag("Social", "Failed to delete comment", map[string]interface{}{
			"error":      err.Error(),
			"comment_id": commentID,
		})
		c.JSON(http.StatusInternalServerError, gin.H{"status": "error", "message": models.ServerError})
		return
	}

	utils.InfoWithTag("Social", "Comment deleted successfully", map[string]interface{}{
		"comment_id": commentID,
	})
	c.JSON(http.StatusOK, gin.H{"status": "success", "message": "social.comment.deleted"})
}

// GetMyComments obtiene todos los comentarios del usuario autenticado
// GET /comments/me
func (h *commentHandler) GetMyComments(c *gin.Context) {
	utils.DebugWithTag("Social", "Fetching user comments", nil)

	userID, exists := c.Get("userID")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"status": "error", "message": "unauthorized"})
		return
	}

	comments, err := h.commentService.GetUserComments(userID.(string))
	if err != nil {
		log.Printf("🛑 [Service Error] Error obteniendo comentarios del usuario: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{"status": "error", "message": "server_error"})
		return
	}

	// Populate isLikedByCurrentUser for each comment (user's own comments)
	for i := range comments {
		like, _ := h.commentLikeService.GetLike(comments[i].ID.Hex(), userID.(string))
		comments[i].IsLikedByCurrentUser = (like != nil)
	}

	log.Printf("📦 [Controller] Retornando %d comentarios", len(comments))
	c.JSON(http.StatusOK, gin.H{"status": "success", "data": comments})
}
