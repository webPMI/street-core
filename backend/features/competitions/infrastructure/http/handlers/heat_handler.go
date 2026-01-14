package handlers

import (
	"log"
	"net/http"

	"backend/features/competitions/application/usecases"
	"backend/features/competitions/domain/entities"
	"backend/features/competitions/domain/models"
	"backend/middlewares"

	"github.com/gin-gonic/gin"
)

// HeatHandler handles HTTP requests for heats
type HeatHandler struct {
	createHeats  *usecases.CreateHeatsUseCase
	getHeats     *usecases.GetHeatsUseCase
	completeHeat *usecases.CompleteHeatUseCase
	resetHeats   *usecases.ResetHeatsUseCase
}

// NewHeatHandler creates a new heat handler
func NewHeatHandler(
	createHeats *usecases.CreateHeatsUseCase,
	getHeats *usecases.GetHeatsUseCase,
	completeHeat *usecases.CompleteHeatUseCase,
	resetHeats *usecases.ResetHeatsUseCase,
) *HeatHandler {
	return &HeatHandler{
		createHeats:  createHeats,
		getHeats:     getHeats,
		completeHeat: completeHeat,
		resetHeats:   resetHeats,
	}
}

// GenerateHeats handles automatic heat generation for a round
// POST /api/v1/competitions/:competitionId/rounds/:roundId/heats/generate
// Auth: Organizer or Admin only
func (h *HeatHandler) GenerateHeats(c *gin.Context) {
	// Get authenticated user
	userIDObj, err := middlewares.GetUserIDFromContext(c)
	if err != nil {
		log.Printf("[HeatHandler] Unauthorized: %v", err)
		c.JSON(http.StatusUnauthorized, gin.H{
			"status":  "error",
			"message": "Unauthorized",
		})
		return
	}
	_ = userIDObj // Will be used for authorization check

	roundID := c.Param("roundId")

	// Parse request body
	var req struct {
		CategoryID      string         `json:"categoryId"`       // Optional
		HeatSize        int            `json:"heatSize"`         // Target size per heat
		Mode            string         `json:"mode"`             // "sequential" or "simultaneous"
		EnableSeeding   bool           `json:"enableSeeding"`    // Optional
		SeedingSource   string         `json:"seedingSource"`    // "manual", "tournament_standing", etc
		SeedingType     string         `json:"seedingType"`      // "snake" or "linear"
		AthleteRankings map[string]int `json:"athleteRankings"`  // Manual rankings
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		log.Printf("[HeatHandler] Invalid request: %v", err)
		c.JSON(http.StatusBadRequest, gin.H{
			"status":  "error",
			"message": "Invalid request body: " + err.Error(),
		})
		return
	}

	// Build use case request
	createReq := usecases.CreateHeatsRequest{
		RoundID:         roundID,
		CategoryID:      req.CategoryID,
		HeatSize:        req.HeatSize,
		Mode:            req.Mode,
		EnableSeeding:   req.EnableSeeding,
		SeedingSource:   req.SeedingSource,
		SeedingType:     req.SeedingType,
		AthleteRankings: req.AthleteRankings,
	}

	// Execute use case
	heats, err := h.createHeats.Execute(c.Request.Context(), createReq)
	if err != nil {
		handleHeatError(c, err)
		return
	}

	log.Printf("[HeatHandler] ✅ Generated %d heats for round %s (sizes: %v)",
		len(heats), roundID, getHeatSizes(heats))

	c.JSON(http.StatusCreated, gin.H{
		"status":  "success",
		"message": "Heats generated successfully",
		"data":    heats,
	})
}

// GetHeat handles retrieving a single heat by ID
// GET /api/v1/competitions/:competitionId/heats/:heatId
// Auth: Public (judges, organizers, spectators)
func (h *HeatHandler) GetHeat(c *gin.Context) {
	heatID := c.Param("heatId")

	heat, err := h.getHeats.ExecuteByID(c.Request.Context(), heatID)
	if err != nil {
		handleHeatError(c, err)
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"status": "success",
		"data":   heat,
	})
}

// GetRoundHeats handles retrieving all heats for a round
// GET /api/v1/competitions/:competitionId/rounds/:roundId/heats
// Auth: Public (judges, organizers, spectators)
func (h *HeatHandler) GetRoundHeats(c *gin.Context) {
	roundID := c.Param("roundId")

	heats, err := h.getHeats.ExecuteByRound(c.Request.Context(), roundID)
	if err != nil {
		handleHeatError(c, err)
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"status": "success",
		"data":   heats,
		"count":  len(heats),
	})
}

// GetCategoryHeats handles retrieving heats for a specific category and round
// GET /api/v1/competitions/:competitionId/rounds/:roundId/categories/:categoryId/heats
// Auth: Public
func (h *HeatHandler) GetCategoryHeats(c *gin.Context) {
	roundID := c.Param("roundId")
	categoryID := c.Param("categoryId")

	heats, err := h.getHeats.ExecuteByCategoryAndRound(c.Request.Context(), categoryID, roundID)
	if err != nil {
		handleHeatError(c, err)
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"status": "success",
		"data":   heats,
		"count":  len(heats),
	})
}

// GetCompetitionHeats handles retrieving all heats for a competition
// GET /api/v1/competitions/:competitionId/heats
// Auth: Public
func (h *HeatHandler) GetCompetitionHeats(c *gin.Context) {
	competitionID := c.Param("id")

	heats, err := h.getHeats.ExecuteByCompetition(c.Request.Context(), competitionID)
	if err != nil {
		handleHeatError(c, err)
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"status": "success",
		"data":   heats,
		"count":  len(heats),
	})
}

// CompleteHeat handles marking a heat as completed
// POST /api/v1/competitions/:competitionId/heats/:heatId/complete
// Auth: Organizer or Admin only
func (h *HeatHandler) CompleteHeat(c *gin.Context) {
	// Get authenticated user
	userIDObj, err := middlewares.GetUserIDFromContext(c)
	if err != nil {
		log.Printf("[HeatHandler] Unauthorized: %v", err)
		c.JSON(http.StatusUnauthorized, gin.H{
			"status":  "error",
			"message": "Unauthorized",
		})
		return
	}
	_ = userIDObj // Will be used for authorization check

	heatID := c.Param("heatId")
	competitionID := c.Param("id")

	// Execute use case
	err = h.completeHeat.Execute(c.Request.Context(), heatID)
	if err != nil {
		handleHeatError(c, err)
		return
	}

	// CRITICAL OPERATION LOG
	log.Printf("[HeatHandler] 🏁 HEAT COMPLETED: Heat %s in competition %s completed by user %s",
		heatID, competitionID, userIDObj.Hex())

	c.JSON(http.StatusOK, gin.H{
		"status":  "success",
		"message": "Heat completed successfully",
	})
}

// ResetHeats handles resetting all heats for a round (DESTRUCTIVE)
// POST /api/v1/competitions/:competitionId/rounds/:roundId/heats/reset
// Auth: Organizer or Admin only
func (h *HeatHandler) ResetHeats(c *gin.Context) {
	// Get authenticated user
	userIDObj, err := middlewares.GetUserIDFromContext(c)
	if err != nil {
		log.Printf("[HeatHandler] Unauthorized: %v", err)
		c.JSON(http.StatusUnauthorized, gin.H{
			"status":  "error",
			"message": "Unauthorized",
		})
		return
	}

	roundID := c.Param("roundId")
	competitionID := c.Param("id")

	// Parse request body (requires confirmation)
	var req struct {
		ConfirmationText string `json:"confirmationText" binding:"required"`
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		log.Printf("[HeatHandler] Invalid request: %v", err)
		c.JSON(http.StatusBadRequest, gin.H{
			"status":  "error",
			"message": "Confirmation text is required",
		})
		return
	}

	// Build use case request
	resetReq := usecases.ResetHeatsRequest{
		RoundID:          roundID,
		ConfirmationText: req.ConfirmationText,
	}

	// CRITICAL OPERATION LOG - BEFORE execution
	log.Printf("[HeatHandler] ⚠️  RESET HEATS REQUESTED: Round %s in competition %s by user %s (confirmation: '%s')",
		roundID, competitionID, userIDObj.Hex(), req.ConfirmationText)

	// Execute use case
	err = h.resetHeats.Execute(c.Request.Context(), resetReq)
	if err != nil {
		handleHeatError(c, err)
		return
	}

	// CRITICAL OPERATION LOG - AFTER execution
	log.Printf("[HeatHandler] 🔥 RESET HEATS COMPLETED: Round %s in competition %s - all heats and scores deleted by user %s",
		roundID, competitionID, userIDObj.Hex())

	c.JSON(http.StatusOK, gin.H{
		"status":  "success",
		"message": "Heats reset successfully",
	})
}

// handleHeatError maps HeatError to HTTP responses with semantic status codes
func handleHeatError(c *gin.Context, err error) {
	log.Printf("[HeatHandler] Error: %v", err)

	// Check if it's a HeatError with details
	if heatErr, ok := err.(*models.HeatError); ok {
		response := gin.H{
			"status":  "error",
			"message": heatErr.Message,
		}

		// Include details if present
		if len(heatErr.Details) > 0 {
			response["details"] = heatErr.Details
		}

		c.JSON(http.StatusBadRequest, response)
		return
	}

	// Fallback for standard errors
	c.JSON(http.StatusBadRequest, gin.H{
		"status":  "error",
		"message": err.Error(),
	})
}


// Helper function to get heat sizes for logging
func getHeatSizes(heats []*entities.Heat) []int {
	sizes := make([]int, len(heats))
	for i, heat := range heats {
		sizes[i] = heat.GetAthleteCount()
	}
	return sizes
}
