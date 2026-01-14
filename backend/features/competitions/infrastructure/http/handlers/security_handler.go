package handlers

import (
	"net/http"

	"backend/app/dto/response"
	"backend/features/competitions/application/usecases"
	"backend/features/competitions/domain/models"
	globalMiddlewares "backend/middlewares"

	"github.com/gin-gonic/gin"
)

// SecurityHandler handles all security-related endpoints for competitions
// (Check-in, Role Management, Pause/Resume, Score Unlock)
type SecurityHandler struct {
	checkInUseCase        *usecases.CheckInToHeatUseCase
	replaceRoleUseCase    *usecases.ReplaceHeatRoleUseCase
	bypassJudgeUseCase    *usecases.BypassJudgeRequirementUseCase
	speakerDashboardUseCase *usecases.GetSpeakerDashboardUseCase
	requestUnlockUseCase  *usecases.RequestScoreUnlockUseCase
	authorizeUnlockUseCase *usecases.AuthorizeScoreUnlockUseCase
	pauseHeatUseCase      *usecases.PauseHeatUseCase
	resumeHeatUseCase     *usecases.ResumeHeatUseCase
}

// NewSecurityHandler creates a new SecurityHandler
func NewSecurityHandler(
	checkInUseCase *usecases.CheckInToHeatUseCase,
	replaceRoleUseCase *usecases.ReplaceHeatRoleUseCase,
	bypassJudgeUseCase *usecases.BypassJudgeRequirementUseCase,
	speakerDashboardUseCase *usecases.GetSpeakerDashboardUseCase,
	requestUnlockUseCase *usecases.RequestScoreUnlockUseCase,
	authorizeUnlockUseCase *usecases.AuthorizeScoreUnlockUseCase,
	pauseHeatUseCase *usecases.PauseHeatUseCase,
	resumeHeatUseCase *usecases.ResumeHeatUseCase,
) *SecurityHandler {
	return &SecurityHandler{
		checkInUseCase:        checkInUseCase,
		replaceRoleUseCase:    replaceRoleUseCase,
		bypassJudgeUseCase:    bypassJudgeUseCase,
		speakerDashboardUseCase: speakerDashboardUseCase,
		requestUnlockUseCase:  requestUnlockUseCase,
		authorizeUnlockUseCase: authorizeUnlockUseCase,
		pauseHeatUseCase:      pauseHeatUseCase,
		resumeHeatUseCase:     resumeHeatUseCase,
	}
}

// =============================================================================
// CHECK-IN SYSTEM (Ready Protocol)
// =============================================================================

// AssignRole assigns a user to a role (judge, speaker, marshall) for a heat
// POST /competitions/:id/heats/:heatId/roles/assign
func (h *SecurityHandler) AssignRole(c *gin.Context) {
	heatID := c.Param("heatId")

	var req struct {
		Role   string `json:"role" binding:"required"`
		UserID string `json:"userId" binding:"required"`
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		response.Error(c, http.StatusBadRequest, "invalid heat ID")
		return
	}

	if err := h.checkInUseCase.AssignRole(c.Request.Context(), heatID, req.Role, req.UserID); err != nil {
		handleSecurityError(c, err)
		return
	}

	response.Success(c, http.StatusOK, "role assigned successfully", nil)
}

// CheckIn marks a user as checked-in for their assigned role
// POST /competitions/:id/heats/:heatId/checkin
func (h *SecurityHandler) CheckIn(c *gin.Context) {
	heatID := c.Param("heatId")

	// Get authenticated user ID from context
	userIDObj, _ := c.Get(globalMiddlewares.UserIDKey)
	userID, _ := userIDObj.(string)

	var req struct {
		Role string `json:"role" binding:"required"`
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		response.Error(c, http.StatusBadRequest, "invalid role")
		return
	}

	if err := h.checkInUseCase.CheckIn(c.Request.Context(), heatID, req.Role, userID); err != nil {
		handleSecurityError(c, err)
		return
	}

	response.Success(c, http.StatusOK, "checked in successfully", nil)
}

// CheckOut marks a user as checked-out (for role replacement)
// POST /competitions/:id/heats/:heatId/checkout
func (h *SecurityHandler) CheckOut(c *gin.Context) {
	heatID := c.Param("heatId")

	// Get authenticated user ID from context
	userIDObj, _ := c.Get(globalMiddlewares.UserIDKey)
	userID, _ := userIDObj.(string)

	var req struct {
		Role string `json:"role" binding:"required"`
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		response.Error(c, http.StatusBadRequest, "invalid role")
		return
	}

	if err := h.checkInUseCase.CheckOut(c.Request.Context(), heatID, req.Role, userID); err != nil {
		handleSecurityError(c, err)
		return
	}

	response.Success(c, http.StatusOK, "checked out successfully", nil)
}

// UnassignRole removes a user from a role
// DELETE /competitions/:id/heats/:heatId/roles/unassign
func (h *SecurityHandler) UnassignRole(c *gin.Context) {
	heatID := c.Param("heatId")

	var req struct {
		Role   string `json:"role" binding:"required"`
		UserID string `json:"userId" binding:"required"`
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		response.Error(c, http.StatusBadRequest, "invalid heat ID")
		return
	}

	if err := h.checkInUseCase.UnassignRole(c.Request.Context(), heatID, req.Role, req.UserID); err != nil {
		handleSecurityError(c, err)
		return
	}

	response.Success(c, http.StatusOK, "role unassigned successfully", nil)
}

// =============================================================================
// CONTINGENCY MANAGEMENT (Crisis Control)
// =============================================================================

// ReplaceRole replaces a user in a role with another user (contingency)
// POST /competitions/:id/heats/:heatId/roles/replace
func (h *SecurityHandler) ReplaceRole(c *gin.Context) {
	heatID := c.Param("heatId")

	var req struct {
		Role      string `json:"role" binding:"required"`
		OldUserID string `json:"oldUserId" binding:"required"`
		NewUserID string `json:"newUserId" binding:"required"`
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		response.Error(c, http.StatusBadRequest, "invalid heat ID")
		return
	}

	if err := h.replaceRoleUseCase.Execute(c.Request.Context(), heatID, req.Role, req.OldUserID, req.NewUserID); err != nil {
		handleSecurityError(c, err)
		return
	}

	response.Success(c, http.StatusOK, "role replaced successfully", nil)
}

// BypassJudge allows reducing the minimum judge requirement
// POST /competitions/:id/heats/:heatId/bypass-judge
func (h *SecurityHandler) BypassJudge(c *gin.Context) {
	heatID := c.Param("heatId")

	var req struct {
		NewMinJudges  int    `json:"newMinJudges" binding:"required,min=1"`
		BypassReason  string `json:"bypassReason" binding:"required"`
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		response.Error(c, http.StatusBadRequest, "bypass not allowed")
		return
	}

	if err := h.bypassJudgeUseCase.Execute(c.Request.Context(), heatID, req.NewMinJudges, req.BypassReason); err != nil {
		handleSecurityError(c, err)
		return
	}

	response.Success(c, http.StatusOK, "heat.bypass.success", nil)
}

// =============================================================================
// MASTER PAUSE SYSTEM
// =============================================================================

// PauseHeat pauses a heat, blocking all score submissions
// POST /competitions/:id/heats/:heatId/pause
func (h *SecurityHandler) PauseHeat(c *gin.Context) {
	heatID := c.Param("heatId")

	// Get authenticated user ID from context
	userIDObj, _ := c.Get(globalMiddlewares.UserIDKey)
	userID, _ := userIDObj.(string)

	var req struct {
		Reason string `json:"reason" binding:"required"`
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		response.Error(c, http.StatusBadRequest, "cannot pause heat")
		return
	}

	if err := h.pauseHeatUseCase.Execute(c.Request.Context(), heatID, userID, req.Reason); err != nil {
		handleSecurityError(c, err)
		return
	}

	response.Success(c, http.StatusOK, "heat paused successfully", nil)
}

// ResumeHeat resumes a paused heat
// POST /competitions/:id/heats/:heatId/resume
func (h *SecurityHandler) ResumeHeat(c *gin.Context) {
	heatID := c.Param("heatId")

	if err := h.resumeHeatUseCase.Execute(c.Request.Context(), heatID); err != nil {
		handleSecurityError(c, err)
		return
	}

	response.Success(c, http.StatusOK, "heat resumed successfully", nil)
}

// =============================================================================
// SCORE UNLOCK SYSTEM (Grace Period)
// =============================================================================

// RequestScoreUnlock allows a judge to request permission to edit a score
// POST /competitions/:id/scores/:scoreId/unlock/request
func (h *SecurityHandler) RequestScoreUnlock(c *gin.Context) {
	scoreID := c.Param("scoreId")

	// Get authenticated user ID from context
	userIDObj, _ := c.Get(globalMiddlewares.UserIDKey)
	judgeID, _ := userIDObj.(string)

	if err := h.requestUnlockUseCase.Execute(c.Request.Context(), scoreID, judgeID); err != nil {
		handleSecurityError(c, err)
		return
	}

	response.Success(c, http.StatusOK, "score unlock requested", nil)
}

// AuthorizeScoreUnlock allows an organizer to authorize a score unlock
// POST /competitions/:id/scores/:scoreId/unlock/authorize
func (h *SecurityHandler) AuthorizeScoreUnlock(c *gin.Context) {
	scoreID := c.Param("scoreId")

	// Get authenticated user ID from context
	userIDObj, _ := c.Get(globalMiddlewares.UserIDKey)
	organizerID, _ := userIDObj.(string)

	var req struct {
		GracePeriodMinutes int `json:"gracePeriodMinutes"` // Optional, 0 = use competition default
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		// If body is empty, use default (0)
		req.GracePeriodMinutes = 0
	}

	if err := h.authorizeUnlockUseCase.Execute(c.Request.Context(), scoreID, organizerID, req.GracePeriodMinutes); err != nil {
		handleSecurityError(c, err)
		return
	}

	response.Success(c, http.StatusOK, "score unlock authorized", nil)
}

// DenyScoreUnlock allows an organizer to deny a score unlock request
// POST /competitions/:id/scores/:scoreId/unlock/deny
func (h *SecurityHandler) DenyScoreUnlock(c *gin.Context) {
	scoreID := c.Param("scoreId")

	// Get authenticated user ID from context
	userIDObj, _ := c.Get(globalMiddlewares.UserIDKey)
	organizerID, _ := userIDObj.(string)

	var req struct {
		DenyReason string `json:"denyReason" binding:"required"`
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		response.Error(c, http.StatusBadRequest, "invalid input")
		return
	}

	if err := h.authorizeUnlockUseCase.Deny(c.Request.Context(), scoreID, organizerID, req.DenyReason); err != nil {
		handleSecurityError(c, err)
		return
	}

	response.Success(c, http.StatusOK, "score.unlock.denied", nil)
}

// =============================================================================
// SPEAKER DASHBOARD (Real-time Panel)
// =============================================================================

// GetSpeakerDashboard returns real-time data for speaker panel
// GET /competitions/:id/heats/:heatId/speaker-dashboard
func (h *SecurityHandler) GetSpeakerDashboard(c *gin.Context) {
	heatID := c.Param("heatId")

	dashboardData, err := h.speakerDashboardUseCase.Execute(c.Request.Context(), heatID)
	if err != nil {
		handleSecurityError(c, err)
		return
	}

	response.Success(c, http.StatusOK, "speaker.dashboard.retrieved", dashboardData)
}

// =============================================================================
// ERROR HANDLING
// =============================================================================

// handleSecurityError maps security use case errors to HTTP responses
func handleSecurityError(c *gin.Context, err error) {
	// Check if error is a HeatError with details
	if heatErr, ok := err.(*models.HeatError); ok {
		response.Error(c, http.StatusBadRequest, heatErr.Message)
		return
	}

	// Generic error - use error message directly
	response.Error(c, http.StatusBadRequest, err.Error())
}
