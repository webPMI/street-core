package handlers

import (
	"log"
	"net/http"

	"backend/features/competitions/application/dto"
	"backend/features/competitions/application/usecases"
	"backend/features/competitions/domain/entities"
	domainerrors "backend/features/competitions/domain/errors"
	"backend/middlewares"

	"github.com/gin-gonic/gin"
)

// CompetitionHandler handles HTTP requests for competitions
type CompetitionHandler struct {
	createCompetition            *usecases.CreateCompetitionUseCase
	listCompetitions             *usecases.ListCompetitionsUseCase
	getCompetition               *usecases.GetCompetitionUseCase
	updateCompetition            *usecases.UpdateCompetitionUseCase
	deleteCompetition            *usecases.DeleteCompetitionUseCase
	registerAthlete              *usecases.RegisterAthleteUseCase
	submitScores                 *usecases.SubmitScoresUseCase
	getScores                    *usecases.GetScoresUseCase
	getLeaderboard               *usecases.GetLeaderboardUseCase
	updateLeaderboard            *usecases.UpdateLeaderboardUseCase
	getMyCompetitions            *usecases.GetMyCompetitionsUseCase
	getParticipants              *usecases.GetParticipantsUseCase
	searchCompetitions           *usecases.SearchCompetitionsUseCase
	startCompetition             *usecases.StartCompetitionUseCase
	endCompetition               *usecases.EndCompetitionUseCase
	postponeCompetition          *usecases.PostponeCompetitionUseCase
	publishResults               *usecases.PublishResultsUseCase
	validateStartRequirements    *usecases.ValidateStartRequirementsUseCase
}

// NewCompetitionHandler creates a new competition handler
func NewCompetitionHandler(
	createCompetition *usecases.CreateCompetitionUseCase,
	listCompetitions *usecases.ListCompetitionsUseCase,
	getCompetition *usecases.GetCompetitionUseCase,
	updateCompetition *usecases.UpdateCompetitionUseCase,
	deleteCompetition *usecases.DeleteCompetitionUseCase,
	registerAthlete *usecases.RegisterAthleteUseCase,
	submitScores *usecases.SubmitScoresUseCase,
	getScores *usecases.GetScoresUseCase,
	getLeaderboard *usecases.GetLeaderboardUseCase,
	updateLeaderboard *usecases.UpdateLeaderboardUseCase,
	getMyCompetitions *usecases.GetMyCompetitionsUseCase,
	getParticipants *usecases.GetParticipantsUseCase,
	searchCompetitions *usecases.SearchCompetitionsUseCase,
	startCompetition *usecases.StartCompetitionUseCase,
	endCompetition *usecases.EndCompetitionUseCase,
	postponeCompetition *usecases.PostponeCompetitionUseCase,
	publishResults *usecases.PublishResultsUseCase,
	validateStartRequirements *usecases.ValidateStartRequirementsUseCase,
) *CompetitionHandler {
	return &CompetitionHandler{
		createCompetition:         createCompetition,
		listCompetitions:          listCompetitions,
		getCompetition:            getCompetition,
		updateCompetition:         updateCompetition,
		deleteCompetition:         deleteCompetition,
		registerAthlete:           registerAthlete,
		submitScores:              submitScores,
		getScores:                 getScores,
		getLeaderboard:            getLeaderboard,
		updateLeaderboard:         updateLeaderboard,
		getMyCompetitions:         getMyCompetitions,
		getParticipants:           getParticipants,
		searchCompetitions:        searchCompetitions,
		startCompetition:          startCompetition,
		endCompetition:            endCompetition,
		postponeCompetition:       postponeCompetition,
		publishResults:            publishResults,
		validateStartRequirements: validateStartRequirements,
	}
}

// List handles listing all competitions with pagination
// GET /competitions
func (h *CompetitionHandler) List(c *gin.Context) {
	// Parse and validate pagination params
	pagination, err := middlewares.ParsePagination(c)
	if err != nil {
		return // Response already sent
	}

	// Parse filters from query params
	filters := make(map[string]interface{})
	if search := c.Query("search"); search != "" {
		filters["search"] = search
	}
	if discipline := c.Query("discipline"); discipline != "" {
		filters["discipline"] = discipline
	}
	if category := c.Query("category"); category != "" {
		filters["category"] = category
	}
	if status := c.Query("status"); status != "" {
		filters["status"] = status
	}
	if clubID := c.Query("clubId"); clubID != "" {
		filters["clubId"] = clubID
	}

	// Execute use case
	competitions, total, err := h.listCompetitions.Execute(c.Request.Context(), pagination.Page, pagination.Limit, filters)
	if err != nil {
		handleError(c, err)
		return
	}

	log.Printf("Listed %d competitions (page %d, limit %d)", len(competitions), pagination.Page, pagination.Limit)
	c.JSON(http.StatusOK, gin.H{
		"status": "success",
		"data": dto.CompetitionListResponse{
			Competitions: competitions,
			Total:        total,
			Page:         pagination.Page,
			Limit:        pagination.Limit,
		},
	})
}

// ListUpcoming handles listing upcoming competitions
// GET /competitions/upcoming
func (h *CompetitionHandler) ListUpcoming(c *gin.Context) {
	pagination, err := middlewares.ParsePagination(c)
	if err != nil {
		return // Response already sent
	}

	filters := make(map[string]interface{})
	if discipline := c.Query("discipline"); discipline != "" {
		filters["discipline"] = discipline
	}

	competitions, total, err := h.listCompetitions.ExecuteUpcoming(c.Request.Context(), pagination.Page, pagination.Limit, filters)
	if err != nil {
		handleError(c, err)
		return
	}

	log.Printf("Listed %d upcoming competitions", len(competitions))
	c.JSON(http.StatusOK, gin.H{
		"status": "success",
		"data": dto.CompetitionListResponse{
			Competitions: competitions,
			Total:        total,
			Page:         pagination.Page,
			Limit:        pagination.Limit,
		},
	})
}

// ListLive handles listing live competitions
// GET /competitions/live
func (h *CompetitionHandler) ListLive(c *gin.Context) {
	pagination, err := middlewares.ParsePagination(c)
	if err != nil {
		return // Response already sent
	}

	filters := make(map[string]interface{})

	competitions, total, err := h.listCompetitions.ExecuteLive(c.Request.Context(), pagination.Page, pagination.Limit, filters)
	if err != nil {
		handleError(c, err)
		return
	}

	log.Printf("Listed %d live competitions", len(competitions))
	c.JSON(http.StatusOK, gin.H{
		"status": "success",
		"data": dto.CompetitionListResponse{
			Competitions: competitions,
			Total:        total,
			Page:         pagination.Page,
			Limit:        pagination.Limit,
		},
	})
}

// Get handles getting a single competition by ID
// GET /competitions/:id
func (h *CompetitionHandler) Get(c *gin.Context) {
	competitionID := c.Param("id")

	competition, err := h.getCompetition.Execute(c.Request.Context(), competitionID)
	if err != nil {
		handleError(c, err)
		return
	}

	log.Printf("Retrieved competition %s", competitionID)
	c.JSON(http.StatusOK, gin.H{
		"status": "success",
		"data":   competition,
	})
}

// Create handles creating a new competition
// POST /competitions
func (h *CompetitionHandler) Create(c *gin.Context) {
	// Get authenticated user from context
	userIDObj, err := middlewares.GetUserIDFromContext(c)
	if err != nil {
		log.Printf("[Handler] Unauthorized: %v", err)
		c.JSON(http.StatusUnauthorized, gin.H{
			"status":  "error",
			"message": "Unauthorized",
		})
		return
	}
	userRole, _ := middlewares.GetUserRoleFromContext(c)

	// Parse request body
	var req dto.CreateCompetitionRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		log.Printf("[Handler] Invalid request: %v", err)
		c.JSON(http.StatusBadRequest, gin.H{
			"status":  "error",
			"message": "Invalid request body: " + err.Error(),
		})
		return
	}

	// Execute use case
	competition, err := h.createCompetition.Execute(c.Request.Context(), req, userIDObj, userRole)
	if err != nil {
		handleError(c, err)
		return
	}

	log.Printf("Created competition %s", competition.ID)
	c.JSON(http.StatusCreated, gin.H{
		"status":  "success",
		"message": "Competition created successfully",
		"data":    competition,
	})
}

// Update handles updating a competition
// PUT /competitions/:id
func (h *CompetitionHandler) Update(c *gin.Context) {
	competitionID := c.Param("id")

	// Get authenticated user from context
	userIDObj, err := middlewares.GetUserIDFromContext(c)
	if err != nil {
		log.Printf("[Handler] Unauthorized: %v", err)
		c.JSON(http.StatusUnauthorized, gin.H{
			"status":  "error",
			"message": "Unauthorized",
		})
		return
	}
	userRole, _ := middlewares.GetUserRoleFromContext(c)

	// Parse request body
	var req dto.UpdateCompetitionRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		log.Printf("[Handler] Invalid request: %v", err)
		c.JSON(http.StatusBadRequest, gin.H{
			"status":  "error",
			"message": "Invalid request body: " + err.Error(),
		})
		return
	}

	// Execute use case
	competition, err := h.updateCompetition.Execute(c.Request.Context(), competitionID, req, userIDObj, userRole)
	if err != nil {
		handleError(c, err)
		return
	}

	log.Printf("Updated competition %s", competitionID)
	c.JSON(http.StatusOK, gin.H{
		"status":  "success",
		"message": "Competition updated successfully",
		"data":    competition,
	})
}

// Delete handles deleting a competition
// DELETE /competitions/:id
func (h *CompetitionHandler) Delete(c *gin.Context) {
	competitionID := c.Param("id")

	// Get authenticated user from context
	userIDObj, err := middlewares.GetUserIDFromContext(c)
	if err != nil {
		log.Printf("[Handler] Unauthorized: %v", err)
		c.JSON(http.StatusUnauthorized, gin.H{
			"status":  "error",
			"message": "Unauthorized",
		})
		return
	}
	userRole, _ := middlewares.GetUserRoleFromContext(c)

	// Execute use case
	err = h.deleteCompetition.Execute(c.Request.Context(), competitionID, userIDObj, userRole)
	if err != nil {
		handleError(c, err)
		return
	}

	log.Printf("Deleted competition %s", competitionID)
	c.JSON(http.StatusOK, gin.H{
		"status":  "success",
		"message": "Competition deleted successfully",
	})
}

// Register handles athlete registration for a competition
// POST /competitions/:id/register
func (h *CompetitionHandler) Register(c *gin.Context) {
	competitionID := c.Param("id")

	// Get authenticated user from context
	userIDObj, err := middlewares.GetUserIDFromContext(c)
	if err != nil {
		log.Printf("[Handler] Unauthorized: %v", err)
		c.JSON(http.StatusUnauthorized, gin.H{
			"status":  "error",
			"message": "Unauthorized",
		})
		return
	}
	userRole, _ := middlewares.GetUserRoleFromContext(c)

	// Parse request body (optional - if not provided, register the current user)
	var req dto.RegisterAthleteRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		// If no body, use current user's ID
		req.AthleteID = userIDObj.Hex()
	}

	// Execute use case
	err = h.registerAthlete.Execute(c.Request.Context(), competitionID, req.AthleteID, userIDObj, userRole)
	if err != nil {
		handleError(c, err)
		return
	}

	log.Printf("Athlete %s registered for competition %s", req.AthleteID, competitionID)
	c.JSON(http.StatusOK, gin.H{
		"status":  "success",
		"message": "Successfully registered for competition",
	})
}

// Unregister handles athlete unregistration from a competition
// DELETE /competitions/:id/register
func (h *CompetitionHandler) Unregister(c *gin.Context) {
	competitionID := c.Param("id")

	// Get authenticated user from context
	userIDObj, err := middlewares.GetUserIDFromContext(c)
	if err != nil {
		log.Printf("[Handler] Unauthorized: %v", err)
		c.JSON(http.StatusUnauthorized, gin.H{
			"status":  "error",
			"message": "Unauthorized",
		})
		return
	}
	userRole, _ := middlewares.GetUserRoleFromContext(c)

	// Use current user's ID for unregistration
	athleteID := userIDObj.Hex()

	// Execute use case
	err = h.registerAthlete.Unregister(c.Request.Context(), competitionID, athleteID, userIDObj, userRole)
	if err != nil {
		handleError(c, err)
		return
	}

	log.Printf("Athlete %s unregistered from competition %s", athleteID, competitionID)
	c.JSON(http.StatusOK, gin.H{
		"status":  "success",
		"message": "Successfully unregistered from competition",
	})
}

// SubmitScore handles score submission for a competition
// POST /competitions/:id/scores
func (h *CompetitionHandler) SubmitScore(c *gin.Context) {
	competitionID := c.Param("id")

	// Get authenticated user from context
	userIDObj, err := middlewares.GetUserIDFromContext(c)
	if err != nil {
		log.Printf("[Handler] Unauthorized: %v", err)
		c.JSON(http.StatusUnauthorized, gin.H{
			"status":  "error",
			"message": "Unauthorized",
		})
		return
	}
	userRole, _ := middlewares.GetUserRoleFromContext(c)

	// Parse request body
	var req struct {
		AthleteID string  `json:"athleteId" binding:"required"`
		RoundID   string  `json:"roundId"`
		HeatID    string  `json:"heatId"`
		Score     float64 `json:"score" binding:"required"`
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		log.Printf("[Handler] Invalid request: %v", err)
		c.JSON(http.StatusBadRequest, gin.H{
			"status":  "error",
			"message": "Invalid request body",
		})
		return
	}

	// Execute use case
	err = h.submitScores.Execute(
		c.Request.Context(),
		competitionID,
		req.AthleteID,
		req.RoundID,
		req.HeatID,
		req.Score,
		userIDObj,
		userRole,
	)

	if err != nil {
		handleError(c, err)
		return
	}

	log.Printf("Score submitted successfully")
	c.JSON(http.StatusCreated, gin.H{
		"status":  "success",
		"message": "Score submitted successfully",
	})
}

// GetScores retrieves all scores for a competition
// GET /competitions/:id/scores
func (h *CompetitionHandler) GetScores(c *gin.Context) {
	competitionID := c.Param("id")

	scores, err := h.getScores.Execute(c.Request.Context(), competitionID)
	if err != nil {
		handleError(c, err)
		return
	}

	log.Printf("Retrieved %d scores", len(scores))
	c.JSON(http.StatusOK, gin.H{
		"status": "success",
		"data":   scores,
	})
}

// GetScoresByAthlete retrieves scores for a specific athlete
// GET /competitions/:id/scores/athlete/:athleteId
func (h *CompetitionHandler) GetScoresByAthlete(c *gin.Context) {
	competitionID := c.Param("id")
	athleteID := c.Param("athleteId")

	scores, err := h.getScores.ExecuteByAthlete(c.Request.Context(), competitionID, athleteID)
	if err != nil {
		handleError(c, err)
		return
	}

	log.Printf("Retrieved %d scores for athlete %s", len(scores), athleteID)
	c.JSON(http.StatusOK, gin.H{
		"status": "success",
		"data":   scores,
	})
}

// GetScoresByRound retrieves scores for a specific round
// GET /competitions/:id/scores/round/:roundId
func (h *CompetitionHandler) GetScoresByRound(c *gin.Context) {
	competitionID := c.Param("id")
	roundID := c.Param("roundId")

	scores, err := h.getScores.ExecuteByRound(c.Request.Context(), competitionID, roundID)
	if err != nil {
		handleError(c, err)
		return
	}

	log.Printf("Retrieved %d scores for round %s", len(scores), roundID)
	c.JSON(http.StatusOK, gin.H{
		"status": "success",
		"data":   scores,
	})
}

// GetLeaderboard retrieves the leaderboard for a competition
// GET /competitions/:id/leaderboard
func (h *CompetitionHandler) GetLeaderboard(c *gin.Context) {
	competitionID := c.Param("id")

	// Try to get user context for authorization check
	userIDObj, err := middlewares.GetUserIDFromContext(c)
	var userRole string
	if err == nil {
		userRole, _ = middlewares.GetUserRoleFromContext(c)
	}

	var leaderboard interface{}

	if err == nil {
		// User is authenticated, use permission check
		leaderboard, err = h.getLeaderboard.ExecuteWithCheck(
			c.Request.Context(),
			competitionID,
			userIDObj,
			userRole,
		)
	} else {
		// Public access, only published results
		leaderboard, err = h.getLeaderboard.Execute(c.Request.Context(), competitionID)
	}

	if err != nil {
		handleError(c, err)
		return
	}

	log.Printf("Retrieved leaderboard for competition %s", competitionID)
	c.JSON(http.StatusOK, gin.H{
		"status": "success",
		"data":   leaderboard,
	})
}

// UpdateLeaderboard forces a leaderboard recalculation
// POST /competitions/:id/leaderboard/update
// Admin/Organizer only
func (h *CompetitionHandler) UpdateLeaderboard(c *gin.Context) {
	competitionID := c.Param("id")

	// Get authenticated user
	_, err := middlewares.GetUserIDFromContext(c)
	if err != nil {
		log.Printf("[Handler] Unauthorized: %v", err)
		c.JSON(http.StatusUnauthorized, gin.H{
			"status":  "error",
			"message": "Unauthorized",
		})
		return
	}
	userRole, _ := middlewares.GetUserRoleFromContext(c)

	// Only admin can manually trigger leaderboard update
	if userRole != "admin" && userRole != "organizer" {
		log.Printf("[Handler] Forbidden: user role %s cannot update leaderboard", userRole)
		c.JSON(http.StatusForbidden, gin.H{
			"status":  "error",
			"message": "Insufficient permissions",
		})
		return
	}

	leaderboard, err := h.updateLeaderboard.Execute(c.Request.Context(), competitionID)
	if err != nil {
		handleError(c, err)
		return
	}

	log.Printf("Leaderboard updated successfully")
	c.JSON(http.StatusOK, gin.H{
		"status":  "success",
		"message": "Leaderboard updated successfully",
		"data":    leaderboard,
	})
}

// GetMyCompetitions retrieves competitions where the user is registered
// GET /competitions/my
func (h *CompetitionHandler) GetMyCompetitions(c *gin.Context) {
	// Get authenticated user from context
	userIDObj, err := middlewares.GetUserIDFromContext(c)
	if err != nil {
		log.Printf("[Handler] Unauthorized: %v", err)
		c.JSON(http.StatusUnauthorized, gin.H{
			"status":  "error",
			"message": "Unauthorized",
		})
		return
	}

	// Parse and validate pagination params
	pagination, err := middlewares.ParsePagination(c)
	if err != nil {
		return // Response already sent
	}

	// Parse role filter (as_athlete, as_organizer, as_judge)
	role := c.DefaultQuery("role", "athlete")

	var competitions []*entities.Competition
	var total int64

	switch role {
	case "organizer":
		competitions, total, err = h.getMyCompetitions.ExecuteAsOrganizer(c.Request.Context(), userIDObj, pagination.Page, pagination.Limit)
	case "judge":
		competitions, total, err = h.getMyCompetitions.ExecuteAsJudge(c.Request.Context(), userIDObj, pagination.Page, pagination.Limit)
	default: // "athlete"
		competitions, total, err = h.getMyCompetitions.Execute(c.Request.Context(), userIDObj, pagination.Page, pagination.Limit)
	}

	if err != nil {
		handleError(c, err)
		return
	}

	// Convert to response DTOs
	competitionResponses := make([]dto.CompetitionResponse, len(competitions))
	for i, comp := range competitions {
		competitionResponses[i] = dto.ToCompetitionResponse(comp)
	}

	log.Printf("Retrieved my competitions for user %s (role: %s)", userIDObj.Hex(), role)
	c.JSON(http.StatusOK, gin.H{
		"status": "success",
		"data": dto.CompetitionListResponse{
			Competitions: competitionResponses,
			Total:        total,
			Page:         pagination.Page,
			Limit:        pagination.Limit,
		},
	})
}

// ListParticipants retrieves participants for a competition
// GET /competitions/:id/participants
func (h *CompetitionHandler) ListParticipants(c *gin.Context) {
	competitionID := c.Param("id")

	// Parse and validate pagination params (default limit 50 for participants)
	pagination, err := middlewares.ParsePaginationWithDefaults(c, 1, 50, 100)
	if err != nil {
		return // Response already sent
	}

	participants, total, err := h.getParticipants.Execute(c.Request.Context(), competitionID, pagination.Page, pagination.Limit)
	if err != nil {
		handleError(c, err)
		return
	}

	log.Printf("Listed %d participants for competition %s", len(participants), competitionID)
	c.JSON(http.StatusOK, gin.H{
		"status": "success",
		"data": gin.H{
			"participants": participants,
			"total":        total,
			"page":         pagination.Page,
			"limit":        pagination.Limit,
		},
	})
}

// GetParticipantCount returns the count of participants for a competition
// GET /competitions/:id/participants/count
func (h *CompetitionHandler) GetParticipantCount(c *gin.Context) {
	competitionID := c.Param("id")

	count, err := h.getParticipants.ExecuteCount(c.Request.Context(), competitionID)
	if err != nil {
		handleError(c, err)
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"status": "success",
		"data": gin.H{
			"count": count,
		},
	})
}

// GetParticipantCounts returns counts of participants grouped by status
// GET /competitions/:id/participants/counts
func (h *CompetitionHandler) GetParticipantCounts(c *gin.Context) {
	competitionID := c.Param("id")

	counts, err := h.getParticipants.ExecuteCounts(c.Request.Context(), competitionID)
	if err != nil {
		handleError(c, err)
		return
	}

	log.Printf("Retrieved participant counts for competition %s: total=%d, approved=%d, pending=%d",
		competitionID, counts.Total, counts.Approved, counts.Pending)
	c.JSON(http.StatusOK, gin.H{
		"status": "success",
		"data":   counts,
	})
}

// ListPendingParticipants retrieves pending participants for a competition
// GET /competitions/:id/participants/pending
func (h *CompetitionHandler) ListPendingParticipants(c *gin.Context) {
	competitionID := c.Param("id")

	// Parse and validate pagination params (default limit 50)
	pagination, err := middlewares.ParsePaginationWithDefaults(c, 1, 50, 100)
	if err != nil {
		return // Response already sent
	}

	participants, total, err := h.getParticipants.ExecutePending(c.Request.Context(), competitionID, pagination.Page, pagination.Limit)
	if err != nil {
		handleError(c, err)
		return
	}

	log.Printf("Listed %d pending participants for competition %s", len(participants), competitionID)
	c.JSON(http.StatusOK, gin.H{
		"status": "success",
		"data": gin.H{
			"participants": participants,
			"total":        total,
			"page":         pagination.Page,
			"limit":        pagination.Limit,
		},
	})
}

// Search handles advanced search for competitions
// GET /competitions/search
func (h *CompetitionHandler) Search(c *gin.Context) {
	// Parse and validate pagination params
	pagination, err := middlewares.ParsePagination(c)
	if err != nil {
		return // Response already sent
	}

	// Build search filters
	filters := usecases.SearchFilters{
		Query:           c.Query("q"),
		Discipline:      c.Query("discipline"),
		CompetitionType: c.Query("competitionType"),
		Status:          c.Query("status"),
		ClubID:          c.Query("clubId"),
		City:            c.Query("city"),
		Country:         c.Query("country"),
		IsFeatured:      c.Query("featured") == "true",
	}

	// Parse tags
	if tags := c.QueryArray("tags"); len(tags) > 0 {
		filters.Tags = tags
	}

	// Execute search
	competitions, total, err := h.searchCompetitions.Execute(c.Request.Context(), filters, pagination.Page, pagination.Limit)
	if err != nil {
		handleError(c, err)
		return
	}

	log.Printf("Search returned %d competitions", len(competitions))
	c.JSON(http.StatusOK, gin.H{
		"status": "success",
		"data": dto.CompetitionListResponse{
			Competitions: competitions,
			Total:        total,
			Page:         pagination.Page,
			Limit:        pagination.Limit,
		},
	})
}

// Featured returns featured competitions
// GET /competitions/featured
func (h *CompetitionHandler) Featured(c *gin.Context) {
	// Parse and validate pagination (default limit 10 for featured)
	pagination, err := middlewares.ParsePaginationWithDefaults(c, 1, 10, 50)
	if err != nil {
		return // Response already sent
	}

	competitions, err := h.searchCompetitions.ExecuteFeatured(c.Request.Context(), pagination.Limit)
	if err != nil {
		handleError(c, err)
		return
	}

	log.Printf("Listed %d featured competitions", len(competitions))
	c.JSON(http.StatusOK, gin.H{
		"status": "success",
		"data":   competitions,
	})
}

// Nearby returns competitions near a location
// GET /competitions/nearby
func (h *CompetitionHandler) Nearby(c *gin.Context) {
	// Parse and validate pagination params
	pagination, err := middlewares.ParsePagination(c)
	if err != nil {
		return // Response already sent
	}

	country := c.Query("country")
	city := c.Query("city")

	if country == "" && city == "" {
		c.JSON(http.StatusBadRequest, gin.H{
			"status":  "error",
			"message": "Either country or city is required",
		})
		return
	}

	competitions, total, err := h.searchCompetitions.ExecuteNearby(c.Request.Context(), country, city, pagination.Page, pagination.Limit)
	if err != nil {
		handleError(c, err)
		return
	}

	log.Printf("Found %d nearby competitions", len(competitions))
	c.JSON(http.StatusOK, gin.H{
		"status": "success",
		"data": dto.CompetitionListResponse{
			Competitions: competitions,
			Total:        total,
			Page:         pagination.Page,
			Limit:        pagination.Limit,
		},
	})
}

// Start handles starting a competition
// POST /competitions/:id/start
func (h *CompetitionHandler) Start(c *gin.Context) {
	competitionID := c.Param("id")

	// Get authenticated user from context
	userIDObj, err := middlewares.GetUserIDFromContext(c)
	if err != nil {
		log.Printf("[Handler] Unauthorized: %v", err)
		c.JSON(http.StatusUnauthorized, gin.H{
			"status":  "error",
			"message": "Unauthorized",
		})
		return
	}
	userRole, _ := middlewares.GetUserRoleFromContext(c)

	// Execute use case
	competition, err := h.startCompetition.Execute(c.Request.Context(), competitionID, userIDObj, userRole)
	if err != nil {
		handleError(c, err)
		return
	}

	log.Printf("Competition %s started", competitionID)
	c.JSON(http.StatusOK, gin.H{
		"status":  "success",
		"message": "Competition started successfully",
		"data":    competition,
	})
}

// ValidateStart validates if a competition can be started
// GET /competitions/:id/validate-start
func (h *CompetitionHandler) ValidateStart(c *gin.Context) {
	competitionID := c.Param("id")

	// Execute validation use case
	validationResult, err := h.validateStartRequirements.Execute(c.Request.Context(), competitionID)
	if err != nil {
		handleError(c, err)
		return
	}

	log.Printf("Competition %s validation: canStart=%v", competitionID, validationResult.CanStart)
	c.JSON(http.StatusOK, gin.H{
		"status":  "success",
		"message": "Validation complete",
		"data":    validationResult,
	})
}

// End handles ending a competition
// POST /competitions/:id/end
func (h *CompetitionHandler) End(c *gin.Context) {
	competitionID := c.Param("id")

	// Get authenticated user from context
	userIDObj, err := middlewares.GetUserIDFromContext(c)
	if err != nil {
		log.Printf("[Handler] Unauthorized: %v", err)
		c.JSON(http.StatusUnauthorized, gin.H{
			"status":  "error",
			"message": "Unauthorized",
		})
		return
	}
	userRole, _ := middlewares.GetUserRoleFromContext(c)

	// Execute use case
	competition, err := h.endCompetition.Execute(c.Request.Context(), competitionID, userIDObj, userRole)
	if err != nil {
		handleError(c, err)
		return
	}

	log.Printf("Competition %s ended", competitionID)
	c.JSON(http.StatusOK, gin.H{
		"status":  "success",
		"message": "Competition ended successfully",
		"data":    competition,
	})
}

// Postpone handles postponing a competition
// POST /competitions/:id/postpone
func (h *CompetitionHandler) Postpone(c *gin.Context) {
	competitionID := c.Param("id")

	// Get authenticated user from context
	userIDObj, err := middlewares.GetUserIDFromContext(c)
	if err != nil {
		log.Printf("[Handler] Unauthorized: %v", err)
		c.JSON(http.StatusUnauthorized, gin.H{
			"status":  "error",
			"message": "Unauthorized",
		})
		return
	}
	userRole, _ := middlewares.GetUserRoleFromContext(c)

	// Execute use case
	competition, err := h.postponeCompetition.Execute(c.Request.Context(), competitionID, userIDObj, userRole)
	if err != nil {
		handleError(c, err)
		return
	}

	log.Printf("Competition %s postponed", competitionID)
	c.JSON(http.StatusOK, gin.H{
		"status":  "success",
		"message": "Competition postponed successfully",
		"data":    competition,
	})
}

// PublishResults handles publishing competition results
// POST /competitions/:id/publish-results
func (h *CompetitionHandler) PublishResults(c *gin.Context) {
	competitionID := c.Param("id")

	// Get authenticated user from context
	userIDObj, err := middlewares.GetUserIDFromContext(c)
	if err != nil {
		log.Printf("[Handler] Unauthorized: %v", err)
		c.JSON(http.StatusUnauthorized, gin.H{
			"status":  "error",
			"message": "Unauthorized",
		})
		return
	}
	userRole, _ := middlewares.GetUserRoleFromContext(c)

	// Execute use case
	competition, err := h.publishResults.Execute(c.Request.Context(), competitionID, userIDObj, userRole)
	if err != nil {
		handleError(c, err)
		return
	}

	log.Printf("Results published for competition %s", competitionID)
	c.JSON(http.StatusOK, gin.H{
		"status":  "success",
		"message": "Results published successfully",
		"data":    competition,
	})
}

// handleError maps domain errors to HTTP responses
func handleError(c *gin.Context, err error) {
	log.Printf("[Handler] Error: %v", err)

	switch err {
	// ==========================================================================
	// CONCURRENCY ERRORS (HTTP 409 Conflict)
	// ==========================================================================
	case domainerrors.ErrHeatAlreadyClosed:
		c.JSON(http.StatusConflict, gin.H{
			"status":     "error",
			"code":       "heat.already.closed",
			"message":    "Heat is already closed for scoring",
			"statusCode": http.StatusConflict,
		})
	case domainerrors.ErrHeatNotActive:
		c.JSON(http.StatusConflict, gin.H{
			"status":     "error",
			"code":       "heat.not.active",
			"message":    "Heat is not active for scoring",
			"statusCode": http.StatusConflict,
		})
	case domainerrors.ErrScoreAlreadyReset:
		c.JSON(http.StatusConflict, gin.H{
			"status":     "error",
			"code":       "score.already.reset",
			"message":    "Score was already reset by organizer",
			"statusCode": http.StatusConflict,
		})
	case domainerrors.ErrScoreAlreadySubmitted:
		c.JSON(http.StatusConflict, gin.H{
			"status":     "error",
			"code":       "score.already.submitted",
			"message":    "Score was already submitted",
			"statusCode": http.StatusConflict,
		})
	case domainerrors.ErrConcurrentModification:
		c.JSON(http.StatusConflict, gin.H{
			"status":     "error",
			"code":       "concurrent.modification",
			"message":    "Resource was modified by another user",
			"statusCode": http.StatusConflict,
		})
	case domainerrors.ErrHeatModified:
		c.JSON(http.StatusConflict, gin.H{
			"status":     "error",
			"code":       "heat.modified",
			"message":    "Heat was modified during operation",
			"statusCode": http.StatusConflict,
		})
	case domainerrors.ErrAthleteNotInHeat:
		c.JSON(http.StatusBadRequest, gin.H{
			"status":     "error",
			"code":       "athlete.not.in.heat",
			"message":    "Athlete is not assigned to this heat",
			"statusCode": http.StatusBadRequest,
		})

	// ==========================================================================
	// RESOURCE GONE ERRORS (HTTP 410 Gone)
	// ==========================================================================
	case domainerrors.ErrHeatDeleted:
		c.JSON(http.StatusGone, gin.H{
			"status":     "error",
			"code":       "heat.deleted",
			"message":    "Heat has been deleted",
			"statusCode": http.StatusGone,
		})
	case domainerrors.ErrScoreDeleted:
		c.JSON(http.StatusGone, gin.H{
			"status":     "error",
			"code":       "score.deleted",
			"message":    "Score has been deleted",
			"statusCode": http.StatusGone,
		})

	// ==========================================================================
	// EXISTING ERRORS
	// ==========================================================================
	case domainerrors.ErrCompetitionNotFound:
		c.JSON(http.StatusNotFound, gin.H{
			"status":  "error",
			"message": "Competition not found",
		})
	case domainerrors.ErrNotJudge:
		c.JSON(http.StatusForbidden, gin.H{
			"status":  "error",
			"message": "Only assigned judges can submit scores",
		})
	case domainerrors.ErrCannotSubmitScore:
		c.JSON(http.StatusForbidden, gin.H{
			"status":  "error",
			"message": "Scores cannot be submitted for this competition",
		})
	case domainerrors.ErrNotRegistered:
		c.JSON(http.StatusBadRequest, gin.H{
			"status":  "error",
			"message": "Athlete is not registered for this competition",
		})
	case domainerrors.ErrResultsNotPublished:
		c.JSON(http.StatusForbidden, gin.H{
			"status":  "error",
			"message": "Results have not been published yet",
		})
	case domainerrors.ErrLeaderboardNotFound:
		c.JSON(http.StatusNotFound, gin.H{
			"status":  "error",
			"message": "Leaderboard not found",
		})
	case domainerrors.ErrInvalidInput:
		c.JSON(http.StatusBadRequest, gin.H{
			"status":  "error",
			"message": "Invalid input",
		})
	case domainerrors.ErrUnauthorized:
		c.JSON(http.StatusUnauthorized, gin.H{
			"status":  "error",
			"message": "Unauthorized",
		})
	case domainerrors.ErrDatabaseOperation:
		c.JSON(http.StatusInternalServerError, gin.H{
			"status":  "error",
			"message": "Database operation failed",
		})
	case domainerrors.ErrAlreadyRegistered:
		c.JSON(http.StatusConflict, gin.H{
			"status":  "error",
			"message": "Athlete already registered for this competition",
		})
	case domainerrors.ErrRegistrationClosed:
		c.JSON(http.StatusBadRequest, gin.H{
			"status":  "error",
			"message": "Registration is closed for this competition",
		})
	case domainerrors.ErrMaxParticipantsReached:
		c.JSON(http.StatusBadRequest, gin.H{
			"status":  "error",
			"message": "Maximum participants reached",
		})
	case domainerrors.ErrCompetitionStarted:
		c.JSON(http.StatusBadRequest, gin.H{
			"status":  "error",
			"message": "Cannot modify competition after it has started",
		})
	case domainerrors.ErrNotOwner:
		c.JSON(http.StatusForbidden, gin.H{
			"status":  "error",
			"message": "Only the competition owner can perform this action",
		})

	// ==========================================================================
	// REGISTRATION TYPE ERRORS (HTTP 400 Bad Request)
	// ==========================================================================
	case domainerrors.ErrInvalidRegistrationType:
		c.JSON(http.StatusBadRequest, gin.H{
			"status":     "error",
			"code":       "registration.invalid.type",
			"message":    "Registration type must be 'internal' or 'external'",
			"statusCode": http.StatusBadRequest,
		})
	case domainerrors.ErrExternalRegistrationURLRequired:
		c.JSON(http.StatusBadRequest, gin.H{
			"status":     "error",
			"code":       "registration.external.url.required",
			"message":    "External registration URL is required when type is 'external'",
			"statusCode": http.StatusBadRequest,
		})
	case domainerrors.ErrInvalidExternalURL:
		c.JSON(http.StatusBadRequest, gin.H{
			"status":     "error",
			"code":       "registration.external.url.invalid",
			"message":    "External registration URL must use HTTPS protocol",
			"statusCode": http.StatusBadRequest,
		})
	case domainerrors.ErrUnsupportedExternalProvider:
		c.JSON(http.StatusBadRequest, gin.H{
			"status":     "error",
			"code":       "registration.external.provider.unsupported",
			"message":    "External registration provider is not supported",
			"statusCode": http.StatusBadRequest,
		})

	default:
		c.JSON(http.StatusInternalServerError, gin.H{
			"status":  "error",
			"message": "Internal server error",
		})
	}
}
