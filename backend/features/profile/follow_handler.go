package profile

import (
	"net/http"

	"backend/pkg/pagination"
	"backend/utils"

	"github.com/gin-gonic/gin"
	"github.com/microcosm-cc/bluemonday"
)

type followHandler struct {
	followService IFollowService
	userService   IProfileUserService
}

func NewFollowHandler(followService IFollowService, userService IProfileUserService) *followHandler {
	return &followHandler{
		followService: followService,
		userService:   userService,
	}
}

// FollowUser sigue a un usuario
// POST /api/users/:id/follow
func (h *followHandler) FollowUser(c *gin.Context) {
	targetUserID := c.Param("id")
	currentUserID, exists := c.Get("userID")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"status": "error", "message": "unauthorized"})
		return
	}

	followerID := currentUserID.(string)

	// No puedes seguirte a ti mismo
	if followerID == targetUserID {
		c.JSON(http.StatusBadRequest, gin.H{"status": "error", "message": "cannot_follow_yourself"})
		return
	}

	// Obtener info del usuario objetivo
	targetUser, err := h.userService.GetUser(targetUserID)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"status": "error", "message": "user_not_found"})
		return
	}
	// Si targetUser es nil (no error pero no encontrado)
	if targetUser == nil {
		c.JSON(http.StatusNotFound, gin.H{"status": "error", "message": "user_not_found"})
		return
	}

	// Obtener info del seguidor
	followerUser, err := h.userService.GetUser(followerID)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"status": "error", "message": "follower_not_found"})
		return
	}
	if followerUser == nil {
		c.JSON(http.StatusNotFound, gin.H{"status": "error", "message": "follower_not_found"})
		return
	}

	// Crear seguimiento
	follow, err := h.followService.FollowUser(
		followerID,
		targetUserID,
		followerUser.UserName,
		followerUser.AvatarURL,
		targetUser.UserName,
		targetUser.AvatarURL,
		targetUser.IsPrivate,
	)

	if err != nil {
		// Mapeo básico de errores comunes
		if err.Error() == "already following or request pending" || err.Error() == "ya está siguiendo o solicitud pendiente" {
			c.JSON(http.StatusConflict, gin.H{"status": "error", "message": "already_following"})
			return
		}
		utils.Error("Error following user", map[string]interface{}{"error": err.Error()})
		c.JSON(http.StatusInternalServerError, gin.H{"status": "error", "message": "failed_to_follow_user"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"status":  "success",
		"message": "follow_request_sent",
		"data":    follow,
	})
}

// UnfollowUser deja de seguir a un usuario
// DELETE /api/users/:id/follow
func (h *followHandler) UnfollowUser(c *gin.Context) {
	targetUserID := c.Param("id")
	currentUserID, exists := c.Get("userID")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"status": "error", "message": "unauthorized"})
		return
	}

	followerID := currentUserID.(string)

	err := h.followService.UnfollowUser(followerID, targetUserID)
	if err != nil {
		if err.Error() == "relación de seguimiento no encontrada" {
			c.JSON(http.StatusNotFound, gin.H{"status": "error", "message": "follow_not_found"})
			return
		}
		c.JSON(http.StatusInternalServerError, gin.H{"status": "error", "message": "failed_to_unfollow_user"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"status":  "success",
		"message": "unfollowed_successfully",
	})
}

// GetFollowers obtiene los seguidores de un usuario
// GET /api/users/:id/followers
func (h *followHandler) GetFollowers(c *gin.Context) {
	userID := c.Param("id")

	params := pagination.ParseParams(c)

	followers, total, err := h.followService.GetFollowers(userID, params)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"status": "error", "message": "failed_to_get_followers"})
		return
	}

	response := pagination.CreateResponse(params.Page, params.Limit, total, followers)
	c.JSON(http.StatusOK, gin.H{
		"status":     "success",
		"message":    "followers_retrieved_successfully",
		"data":       response.Data,
		"pagination": response.Pagination,
	})
}

// GetFollowing obtiene a quién sigue un usuario
// GET /api/users/:id/following
func (h *followHandler) GetFollowing(c *gin.Context) {
	userID := c.Param("id")

	params := pagination.ParseParams(c)

	following, total, err := h.followService.GetFollowing(userID, params)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"status": "error", "message": "failed_to_get_following"})
		return
	}

	response := pagination.CreateResponse(params.Page, params.Limit, total, following)
	c.JSON(http.StatusOK, gin.H{
		"status":     "success",
		"message":    "following_retrieved_successfully",
		"data":       response.Data,
		"pagination": response.Pagination,
	})
}

// GetFollowStatus verifica el estado de seguimiento
// GET /api/users/:id/follow/status
func (h *followHandler) GetFollowStatus(c *gin.Context) {
	targetUserID := c.Param("id")
	currentUserID, exists := c.Get("userID")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"status": "error", "message": "unauthorized"})
		return
	}

	followerID := currentUserID.(string)

	isFollowing, status, err := h.followService.IsFollowing(followerID, targetUserID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"status": "error", "message": "failed_to_check_status"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"status": "success",
		"data": gin.H{
			"isFollowing":  isFollowing,
			"followStatus": status,
		},
	})
}

// GetPendingRequests obtiene solicitudes pendientes
// GET /api/follow/requests
func (h *followHandler) GetPendingRequests(c *gin.Context) {
	currentUserID, exists := c.Get("userID")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"status": "error", "message": "unauthorized"})
		return
	}

	userID := currentUserID.(string)

	requests, err := h.followService.GetPendingRequests(userID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"status": "error", "message": "failed_to_get_requests"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"status": "success",
		"data":   requests,
	})
}

// AcceptFollowRequest acepta una solicitud de seguimiento
// PUT /api/follow/requests/{id}/accept
func (h *followHandler) AcceptFollowRequest(c *gin.Context) {
	followID := c.Param("id")
	_, exists := c.Get("userID")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"status": "error", "message": "unauthorized"})
		return
	}

	err := h.followService.AcceptFollowRequest(followID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"status": "error", "message": "failed_to_accept_request"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"status":  "success",
		"message": "follow_request_accepted",
	})
}

// RejectFollowRequest rechaza una solicitud de seguimiento
// PUT /api/follow/requests/{id}/reject
func (h *followHandler) RejectFollowRequest(c *gin.Context) {
	followID := c.Param("id")
	_, exists := c.Get("userID")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"status": "error", "message": "unauthorized"})
		return
	}

	err := h.followService.RejectFollowRequest(followID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"status": "error", "message": "failed_to_reject_request"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"status":  "success",
		"message": "follow_request_rejected",
	})
}

// BlockUser bloquea a un usuario
// POST /api/users/:id/block
func (h *followHandler) BlockUser(c *gin.Context) {
	targetUserID := c.Param("id")
	currentUserID, exists := c.Get("userID")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"status": "error", "message": "unauthorized"})
		return
	}

	blockerID := currentUserID.(string)

	if blockerID == targetUserID {
		c.JSON(http.StatusBadRequest, gin.H{"status": "error", "message": "cannot_block_yourself"})
		return
	}

	var body struct {
		Reason string `json:"reason"`
	}
	c.ShouldBindJSON(&body)

	p := bluemonday.StrictPolicy()
	reason := p.Sanitize(body.Reason)

	// Obtener usuario objetivo
	targetUser, err := h.userService.GetUser(targetUserID)
	if err != nil || targetUser == nil {
		c.JSON(http.StatusNotFound, gin.H{"status": "error", "message": "user_not_found"})
		return
	}

	// Obtener usuario bloqueador
	blockerUser, err := h.userService.GetUser(blockerID)
	if err != nil || blockerUser == nil {
		c.JSON(http.StatusNotFound, gin.H{"status": "error", "message": "blocker_not_found"})
		return
	}

	err = h.followService.BlockUser(
		blockerID,
		targetUserID,
		blockerUser.UserName,
		targetUser.UserName,
		targetUser.AvatarURL,
		reason,
	)

	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"status": "error", "message": "failed_to_block_user"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"status":  "success",
		"message": "user_blocked_successfully",
	})
}

// UnblockUser desbloquea a un usuario
// DELETE /api/users/:id/block
func (h *followHandler) UnblockUser(c *gin.Context) {
	targetUserID := c.Param("id")
	currentUserID, exists := c.Get("userID")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"status": "error", "message": "unauthorized"})
		return
	}

	blockerID := currentUserID.(string)

	err := h.followService.UnblockUser(blockerID, targetUserID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"status": "error", "message": "failed_to_unblock_user"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"status":  "success",
		"message": "user_unblocked_successfully",
	})
}

// GetBlockedUsers obtiene usuarios bloqueados
// GET /api/blocks
func (h *followHandler) GetBlockedUsers(c *gin.Context) {
	currentUserID, exists := c.Get("userID")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"status": "error", "message": "unauthorized"})
		return
	}

	blockerID := currentUserID.(string)

	blocks, err := h.followService.GetBlockedUsers(blockerID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"status": "error", "message": "failed_to_get_blocked_users"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"status": "success",
		"data":   blocks,
	})
}

// GetFollowStats obtiene estadísticas de seguimiento
// GET /api/users/:id/stats
func (h *followHandler) GetFollowStats(c *gin.Context) {
	userID := c.Param("id")

	stats, err := h.followService.GetFollowStats(userID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"status": "error", "message": "failed_to_get_stats"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"status": "success",
		"data":   stats,
	})
}

// BlockRequest represents the block request body
type BlockRequest struct {
	Reason string `json:"reason" binding:"max=500"`
}
