package handlers

import (
	"net/http"

	"backend/app/dto/response"
	"backend/features/competitions/application/usecases/emergency"
	globalMiddlewares "backend/middlewares"

	"github.com/gin-gonic/gin"
	"go.mongodb.org/mongo-driver/bson/primitive"
)

// EmergencyHandler handles all emergency crisis management endpoints
// Critical features for X-Games, UCI BMX, skateboarding competitions
type EmergencyHandler struct {
	resolveTieBreakUseCase        *emergency.ResolveTieBreakUseCase
	setScoreUnderReviewUseCase    *emergency.SetScoreUnderReviewUseCase
	freezeHeatStateUseCase        *emergency.FreezeHeatStateUseCase
	swapAthleteScoresUseCase      *emergency.SwapAthleteScoresUseCase
	rollbackHeatStateUseCase      *emergency.RollbackHeatStateUseCase
	resetSingleAthleteScoreUseCase *emergency.ResetSingleAthleteScoreUseCase
	adminOverrideScoreUseCase     *emergency.AdminOverrideScoreUseCase
}

// NewEmergencyHandler creates a new EmergencyHandler
func NewEmergencyHandler(
	resolveTieBreakUseCase *emergency.ResolveTieBreakUseCase,
	setScoreUnderReviewUseCase *emergency.SetScoreUnderReviewUseCase,
	freezeHeatStateUseCase *emergency.FreezeHeatStateUseCase,
	swapAthleteScoresUseCase *emergency.SwapAthleteScoresUseCase,
	rollbackHeatStateUseCase *emergency.RollbackHeatStateUseCase,
	resetSingleAthleteScoreUseCase *emergency.ResetSingleAthleteScoreUseCase,
	adminOverrideScoreUseCase *emergency.AdminOverrideScoreUseCase,
) *EmergencyHandler {
	return &EmergencyHandler{
		resolveTieBreakUseCase:        resolveTieBreakUseCase,
		setScoreUnderReviewUseCase:    setScoreUnderReviewUseCase,
		freezeHeatStateUseCase:        freezeHeatStateUseCase,
		swapAthleteScoresUseCase:      swapAthleteScoresUseCase,
		rollbackHeatStateUseCase:      rollbackHeatStateUseCase,
		resetSingleAthleteScoreUseCase: resetSingleAthleteScoreUseCase,
		adminOverrideScoreUseCase:     adminOverrideScoreUseCase,
	}
}

// =============================================================================
// TIE-BREAK RESOLUTION
// =============================================================================

// ResolveTieBreak resolves a tie-break between two identical scores
// POST /competitions/:id/heats/:heatId/emergency/resolve-tie
// Request: { "score1Id": "...", "score2Id": "...", "tieBreakRule": "highest_run" }
func (h *EmergencyHandler) ResolveTieBreak(c *gin.Context) {
	var req struct {
		Score1ID     string `json:"score1Id" binding:"required"`
		Score2ID     string `json:"score2Id" binding:"required"`
		TieBreakRule string `json:"tieBreakRule" binding:"required"`
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		response.Error(c, http.StatusBadRequest, "invalid score input")
		return
	}

	if err := h.resolveTieBreakUseCase.Execute(c.Request.Context(), req.Score1ID, req.Score2ID, req.TieBreakRule); err != nil {
		handleHeatError(c, err)
		return
	}

	response.Success(c, http.StatusOK, "tie break resolved successfully", nil)
}

// =============================================================================
// SCORE UNDER REVIEW (Protest Management)
// =============================================================================

// SetScoreUnderReview marks a score as under review (hidden from public)
// POST /competitions/:id/scores/:scoreId/emergency/under-review
// Request: { "reason": "Coach protest - possible equipment violation" }
func (h *EmergencyHandler) SetScoreUnderReview(c *gin.Context) {
	scoreID := c.Param("scoreId")

	var req struct {
		Reason string `json:"reason" binding:"required"`
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		response.Error(c, http.StatusBadRequest, "invalid score input")
		return
	}

	if err := h.setScoreUnderReviewUseCase.SetUnderReview(c.Request.Context(), scoreID, req.Reason); err != nil {
		handleHeatError(c, err)
		return
	}

	response.Success(c, http.StatusOK, "score marked as under review", nil)
}

// ResolveScoreReview resolves a score review (approve or update score)
// POST /competitions/:id/scores/:scoreId/emergency/resolve-review
// Request: { "approved": true, "newScore": 85.5 }
func (h *EmergencyHandler) ResolveScoreReview(c *gin.Context) {
	scoreID := c.Param("scoreId")

	var req struct {
		Approved bool     `json:"approved"`
		NewScore *float64 `json:"newScore,omitempty"`
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		response.Error(c, http.StatusBadRequest, "invalid score input")
		return
	}

	if err := h.setScoreUnderReviewUseCase.ResolveReview(c.Request.Context(), scoreID, req.Approved, req.NewScore); err != nil {
		handleHeatError(c, err)
		return
	}

	response.Success(c, http.StatusOK, "score review resolved successfully", nil)
}

// =============================================================================
// FREEZE HEAT STATE (Weather/Safety Interruptions)
// =============================================================================

// FreezeHeat creates a snapshot of heat state for later resumption
// POST /competitions/:id/heats/:heatId/emergency/freeze
// Request: { "reason": "Rain delay - 3 athletes completed, 5 pending" }
func (h *EmergencyHandler) FreezeHeat(c *gin.Context) {
	heatID := c.Param("heatId")

	// Get authenticated user ID from context
	userIDObj, _ := c.Get(globalMiddlewares.UserIDKey)
	userID, _ := userIDObj.(string)

	var req struct {
		Reason string `json:"reason" binding:"required"`
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		response.Error(c, http.StatusBadRequest, "heat freeze reason is required")
		return
	}

	snapshot, err := h.freezeHeatStateUseCase.Freeze(c.Request.Context(), heatID, req.Reason, userID)
	if err != nil {
		handleHeatError(c, err)
		return
	}

	response.Success(c, http.StatusOK, "heat frozen successfully", gin.H{
		"snapshotId": snapshot.ID.Hex(),
		"reason":     snapshot.Reason,
		"createdAt":  snapshot.CreatedAt,
	})
}

// ResumeHeat restores heat state from a freeze snapshot
// POST /competitions/:id/heats/:heatId/emergency/resume
// Request: { "snapshotId": "..." }
func (h *EmergencyHandler) ResumeHeat(c *gin.Context) {
	// Get authenticated user ID from context
	userIDObj, _ := c.Get(globalMiddlewares.UserIDKey)
	userID, _ := userIDObj.(string)

	var req struct {
		SnapshotID string `json:"snapshotId" binding:"required"`
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		response.Error(c, http.StatusBadRequest, "snapshot ID is required")
		return
	}

	if err := h.freezeHeatStateUseCase.Resume(c.Request.Context(), req.SnapshotID, userID); err != nil {
		handleHeatError(c, err)
		return
	}

	response.Success(c, http.StatusOK, "heat resumed from freeze", nil)
}

// =============================================================================
// SWAP ATHLETE SCORES (Identity Confusion)
// =============================================================================

// SwapAthleteScores swaps scores between two athletes (identity mix-up)
// POST /competitions/:id/heats/:heatId/emergency/swap-scores
// Request: { "athlete1Id": "...", "athlete2Id": "...", "reason": "Speaker announced Juan but Pedro competed" }
func (h *EmergencyHandler) SwapAthleteScores(c *gin.Context) {
	competitionID := c.Param("id")
	heatID := c.Param("heatId")

	// Get authenticated user from context
	userIDObj, exists := c.Get(globalMiddlewares.UserIDKey)
	if !exists {
		response.Error(c, http.StatusUnauthorized, "unauthorized")
		return
	}

	userID, err := primitive.ObjectIDFromHex(userIDObj.(string))
	if err != nil {
		response.Error(c, http.StatusBadRequest, "invalid ID")
		return
	}

	// Get user name from context (for audit trail)
	userNameObj, _ := c.Get(globalMiddlewares.UserNameKey)
	userNameStr := "Unknown"
	if userName, ok := userNameObj.(string); ok {
		userNameStr = userName
	}

	var req struct {
		Athlete1ID string `json:"athlete1Id" binding:"required"`
		Athlete2ID string `json:"athlete2Id" binding:"required"`
		Reason     string `json:"reason" binding:"required,min=10"`
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		response.Error(c, http.StatusBadRequest, "invalid input")
		return
	}

	// Parse ObjectIDs
	compID, err := primitive.ObjectIDFromHex(competitionID)
	if err != nil {
		response.Error(c, http.StatusBadRequest, "invalid ID")
		return
	}

	heatObjID, err := primitive.ObjectIDFromHex(heatID)
	if err != nil {
		response.Error(c, http.StatusBadRequest, "invalid ID")
		return
	}

	athlete1ID, err := primitive.ObjectIDFromHex(req.Athlete1ID)
	if err != nil {
		response.Error(c, http.StatusBadRequest, "invalid ID")
		return
	}

	athlete2ID, err := primitive.ObjectIDFromHex(req.Athlete2ID)
	if err != nil {
		response.Error(c, http.StatusBadRequest, "invalid ID")
		return
	}

	// Create swap request
	swapReq := emergency.SwapRequest{
		CompetitionID:   compID,
		HeatID:          heatObjID,
		AthleteID1:      athlete1ID,
		AthleteID2:      athlete2ID,
		Reason:          req.Reason,
		InitiatedBy:     userID,
		InitiatedByName: userNameStr,
	}

	if err := h.swapAthleteScoresUseCase.Execute(c.Request.Context(), swapReq); err != nil {
		handleHeatError(c, err)
		return
	}

	response.Success(c, http.StatusOK, "scores swapped successfully", gin.H{
		"athlete1Id": req.Athlete1ID,
		"athlete2Id": req.Athlete2ID,
		"status":     "scores_swapped",
	})
}

// =============================================================================
// ROLLBACK HEAT STATE (Undo Mistakes)
// =============================================================================

// RollbackHeat rolls back heat to previous snapshot state
// POST /competitions/:id/heats/:heatId/emergency/rollback
func (h *EmergencyHandler) RollbackHeat(c *gin.Context) {
	heatID := c.Param("heatId")

	// Get authenticated user ID from context
	userIDObj, _ := c.Get(globalMiddlewares.UserIDKey)
	userID, _ := userIDObj.(string)

	if err := h.rollbackHeatStateUseCase.Execute(c.Request.Context(), heatID, userID); err != nil {
		handleHeatError(c, err)
		return
	}

	response.Success(c, http.StatusOK, "heat rolled back successfully", nil)
}

// =============================================================================
// RESET SINGLE ATHLETE SCORE (Re-run Scenarios)
// =============================================================================

// ResetSingleAthleteScore archives existing scores and creates new empty ones
// POST /competitions/:id/heats/:heatId/emergency/reset-athlete
// Request: { "athleteId": "...", "reason": "Equipment failure during run" }
func (h *EmergencyHandler) ResetSingleAthleteScore(c *gin.Context) {
	competitionID := c.Param("id")
	heatID := c.Param("heatId")

	// Get authenticated user from context
	userIDObj, exists := c.Get(globalMiddlewares.UserIDKey)
	if !exists {
		response.Error(c, http.StatusUnauthorized, "unauthorized")
		return
	}

	userID, err := primitive.ObjectIDFromHex(userIDObj.(string))
	if err != nil {
		response.Error(c, http.StatusBadRequest, "invalid ID")
		return
	}

	// Get user name from context (optional)
	userName, _ := c.Get(globalMiddlewares.UserNameKey)
	userNameStr, _ := userName.(string)

	var req struct {
		AthleteID string `json:"athleteId" binding:"required"`
		Reason    string `json:"reason" binding:"required,min=10"`
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		response.Error(c, http.StatusBadRequest, "invalid input")
		return
	}

	// Parse IDs
	compID, err := primitive.ObjectIDFromHex(competitionID)
	if err != nil {
		response.Error(c, http.StatusBadRequest, "invalid ID")
		return
	}

	heatObjID, err := primitive.ObjectIDFromHex(heatID)
	if err != nil {
		response.Error(c, http.StatusBadRequest, "invalid ID")
		return
	}

	athleteID, err := primitive.ObjectIDFromHex(req.AthleteID)
	if err != nil {
		response.Error(c, http.StatusBadRequest, "invalid ID")
		return
	}

	// Execute use case
	resetReq := emergency.ResetRequest{
		CompetitionID:   compID,
		HeatID:          heatObjID,
		AthleteID:       athleteID,
		Reason:          req.Reason,
		InitiatedBy:     userID,
		InitiatedByName: userNameStr,
	}

	if err := h.resetSingleAthleteScoreUseCase.Execute(c.Request.Context(), resetReq); err != nil {
		handleHeatError(c, err)
		return
	}

	response.Success(c, http.StatusOK, "score reset successfully", gin.H{
		"athleteId": req.AthleteID,
		"status":    "scores_archived_and_reset",
	})
}

// =============================================================================
// ADMIN OVERRIDE SCORE (Manual Entry / Tablet Failure)
// =============================================================================

// AdminOverrideScore manually overrides a score (preserves original for protests)
// POST /competitions/:id/scores/:scoreId/emergency/admin-override
// Request: { "newScore": 85.5, "criteriaScores": {...}, "reason": "Judge tablet failure" }
func (h *EmergencyHandler) AdminOverrideScore(c *gin.Context) {
	competitionID := c.Param("id")
	scoreID := c.Param("scoreId")

	// Get authenticated user from context
	userIDObj, exists := c.Get(globalMiddlewares.UserIDKey)
	if !exists {
		response.Error(c, http.StatusUnauthorized, "unauthorized")
		return
	}

	userID, err := primitive.ObjectIDFromHex(userIDObj.(string))
	if err != nil {
		response.Error(c, http.StatusBadRequest, "invalid ID")
		return
	}

	// Get user name from context (optional)
	userName, _ := c.Get(globalMiddlewares.UserNameKey)
	userNameStr, _ := userName.(string)

	var req struct {
		NewScore       float64            `json:"newScore" binding:"required,gte=0"`
		CriteriaScores map[string]float64 `json:"criteriaScores,omitempty"`
		Reason         string             `json:"reason" binding:"required,min=10"`
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		response.Error(c, http.StatusBadRequest, "invalid input")
		return
	}

	// Parse IDs
	compID, err := primitive.ObjectIDFromHex(competitionID)
	if err != nil {
		response.Error(c, http.StatusBadRequest, "invalid ID")
		return
	}

	scoreObjID, err := primitive.ObjectIDFromHex(scoreID)
	if err != nil {
		response.Error(c, http.StatusBadRequest, "invalid ID")
		return
	}

	// Execute use case
	overrideReq := emergency.OverrideRequest{
		CompetitionID:     compID,
		ScoreID:           scoreObjID,
		NewTotalScore:     req.NewScore,
		NewCriteriaScores: req.CriteriaScores,
		Reason:            req.Reason,
		InitiatedBy:       userID,
		InitiatedByName:   userNameStr,
	}

	if err := h.adminOverrideScoreUseCase.Execute(c.Request.Context(), overrideReq); err != nil {
		handleHeatError(c, err)
		return
	}

	response.Success(c, http.StatusOK, "score overridden successfully", gin.H{
		"scoreId":      scoreID,
		"newScore":     req.NewScore,
		"isOverridden": true,
	})
}

