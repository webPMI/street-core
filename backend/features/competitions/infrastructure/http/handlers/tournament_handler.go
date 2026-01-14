package handlers

import (
	"log"
	"net/http"
	"strconv"

	"backend/features/competitions/application/dto"
	"backend/features/competitions/application/usecases"
	domainerrors "backend/features/competitions/domain/errors"
	"backend/middlewares"

	"github.com/gin-gonic/gin"
)

// TournamentHandler handles HTTP requests for tournaments
type TournamentHandler struct {
	createTournament            *usecases.CreateTournamentUseCase
	getTournament               *usecases.GetTournamentUseCase
	listTournaments             *usecases.ListTournamentsUseCase
	addCompetitionToTournament  *usecases.AddCompetitionToTournamentUseCase
	updateTournamentStandings   *usecases.UpdateTournamentStandingsUseCase
}

// NewTournamentHandler creates a new tournament handler
func NewTournamentHandler(
	createTournament *usecases.CreateTournamentUseCase,
	getTournament *usecases.GetTournamentUseCase,
	listTournaments *usecases.ListTournamentsUseCase,
	addCompetitionToTournament *usecases.AddCompetitionToTournamentUseCase,
	updateTournamentStandings *usecases.UpdateTournamentStandingsUseCase,
) *TournamentHandler {
	return &TournamentHandler{
		createTournament:           createTournament,
		getTournament:              getTournament,
		listTournaments:            listTournaments,
		addCompetitionToTournament: addCompetitionToTournament,
		updateTournamentStandings:  updateTournamentStandings,
	}
}

// Create handles creating a new tournament
// POST /tournaments
func (h *TournamentHandler) Create(c *gin.Context) {
	// Get authenticated user from context
	userIDObj, err := middlewares.GetUserIDFromContext(c)
	if err != nil {
		log.Printf("[TournamentHandler] Unauthorized: %v", err)
		c.JSON(http.StatusUnauthorized, gin.H{
			"status":  "error",
			"message": "Unauthorized",
		})
		return
	}
	userRole, _ := middlewares.GetUserRoleFromContext(c)

	// Parse request body
	var req dto.CreateTournamentRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		log.Printf("[TournamentHandler] Invalid request: %v", err)
		c.JSON(http.StatusBadRequest, gin.H{
			"status":  "error",
			"message": "Invalid request body: " + err.Error(),
		})
		return
	}

	// Execute use case
	tournament, err := h.createTournament.Execute(c.Request.Context(), req, userIDObj, userRole)
	if err != nil {
		handleTournamentError(c, err)
		return
	}

	log.Printf("Created tournament %s", tournament.ID)
	c.JSON(http.StatusCreated, gin.H{
		"status":  "success",
		"message": "Tournament created successfully",
		"data":    tournament,
	})
}

// Get handles getting a single tournament by ID
// GET /tournaments/:id
func (h *TournamentHandler) Get(c *gin.Context) {
	tournamentID := c.Param("id")

	tournament, err := h.getTournament.Execute(c.Request.Context(), tournamentID)
	if err != nil {
		handleTournamentError(c, err)
		return
	}

	log.Printf("Retrieved tournament %s", tournamentID)
	c.JSON(http.StatusOK, gin.H{
		"status": "success",
		"data":   tournament,
	})
}

// List handles listing all tournaments with pagination
// GET /tournaments
func (h *TournamentHandler) List(c *gin.Context) {
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
	if status := c.Query("status"); status != "" {
		filters["status"] = status
	}
	if sportType := c.Query("sportType"); sportType != "" {
		filters["sportType"] = sportType
	}
	if discipline := c.Query("discipline"); discipline != "" {
		filters["discipline"] = discipline
	}
	if year := c.Query("year"); year != "" {
		filters["year"] = year
	}
	if isPublic := c.Query("isPublic"); isPublic != "" {
		filters["isPublic"] = isPublic == "true"
	}
	if isFeatured := c.Query("isFeatured"); isFeatured != "" {
		filters["isFeatured"] = isFeatured == "true"
	}

	// Execute use case
	tournaments, total, err := h.listTournaments.Execute(c.Request.Context(), pagination.Page, pagination.Limit, filters)
	if err != nil {
		handleTournamentError(c, err)
		return
	}

	log.Printf("Listed %d tournaments (page %d, limit %d)", len(tournaments), pagination.Page, pagination.Limit)
	c.JSON(http.StatusOK, gin.H{
		"status": "success",
		"data": dto.TournamentListResponse{
			Tournaments: tournaments,
			Total:       total,
			Page:        pagination.Page,
			Limit:       pagination.Limit,
		},
	})
}

// ListByStatus handles listing tournaments by status
// GET /tournaments/status/:status
func (h *TournamentHandler) ListByStatus(c *gin.Context) {
	status := c.Param("status")

	pagination, err := middlewares.ParsePagination(c)
	if err != nil {
		return // Response already sent
	}

	tournaments, total, err := h.listTournaments.ExecuteByStatus(c.Request.Context(), status, pagination.Page, pagination.Limit)
	if err != nil {
		handleTournamentError(c, err)
		return
	}

	log.Printf("Listed %d tournaments with status %s", len(tournaments), status)
	c.JSON(http.StatusOK, gin.H{
		"status": "success",
		"data": dto.TournamentListResponse{
			Tournaments: tournaments,
			Total:       total,
			Page:        pagination.Page,
			Limit:       pagination.Limit,
		},
	})
}

// ListUpcoming handles listing upcoming tournaments
// GET /tournaments/upcoming
func (h *TournamentHandler) ListUpcoming(c *gin.Context) {
	pagination, err := middlewares.ParsePagination(c)
	if err != nil {
		return // Response already sent
	}

	filters := make(map[string]interface{})
	if discipline := c.Query("discipline"); discipline != "" {
		filters["discipline"] = discipline
	}
	if sportType := c.Query("sportType"); sportType != "" {
		filters["sportType"] = sportType
	}

	tournaments, total, err := h.listTournaments.ExecuteUpcoming(c.Request.Context(), pagination.Page, pagination.Limit, filters)
	if err != nil {
		handleTournamentError(c, err)
		return
	}

	log.Printf("Listed %d upcoming tournaments", len(tournaments))
	c.JSON(http.StatusOK, gin.H{
		"status": "success",
		"data": dto.TournamentListResponse{
			Tournaments: tournaments,
			Total:       total,
			Page:        pagination.Page,
			Limit:       pagination.Limit,
		},
	})
}

// ListLive handles listing live tournaments
// GET /tournaments/live
func (h *TournamentHandler) ListLive(c *gin.Context) {
	pagination, err := middlewares.ParsePagination(c)
	if err != nil {
		return // Response already sent
	}

	filters := make(map[string]interface{})
	if discipline := c.Query("discipline"); discipline != "" {
		filters["discipline"] = discipline
	}

	tournaments, total, err := h.listTournaments.ExecuteLive(c.Request.Context(), pagination.Page, pagination.Limit, filters)
	if err != nil {
		handleTournamentError(c, err)
		return
	}

	log.Printf("Listed %d live tournaments", len(tournaments))
	c.JSON(http.StatusOK, gin.H{
		"status": "success",
		"data": dto.TournamentListResponse{
			Tournaments: tournaments,
			Total:       total,
			Page:        pagination.Page,
			Limit:       pagination.Limit,
		},
	})
}

// ListByOrganizer handles listing tournaments by organizer
// GET /tournaments/organizer/:organizerId
func (h *TournamentHandler) ListByOrganizer(c *gin.Context) {
	organizerID := c.Param("organizerId")

	pagination, err := middlewares.ParsePagination(c)
	if err != nil {
		return // Response already sent
	}

	tournaments, total, err := h.listTournaments.ExecuteByOrganizerID(c.Request.Context(), organizerID, pagination.Page, pagination.Limit)
	if err != nil {
		handleTournamentError(c, err)
		return
	}

	log.Printf("Listed %d tournaments for organizer %s", len(tournaments), organizerID)
	c.JSON(http.StatusOK, gin.H{
		"status": "success",
		"data": dto.TournamentListResponse{
			Tournaments: tournaments,
			Total:       total,
			Page:        pagination.Page,
			Limit:       pagination.Limit,
		},
	})
}

// AddCompetition handles adding a competition to a tournament
// POST /tournaments/:id/competitions
func (h *TournamentHandler) AddCompetition(c *gin.Context) {
	tournamentID := c.Param("id")

	// Get authenticated user from context
	userIDObj, err := middlewares.GetUserIDFromContext(c)
	if err != nil {
		log.Printf("[TournamentHandler] Unauthorized: %v", err)
		c.JSON(http.StatusUnauthorized, gin.H{
			"status":  "error",
			"message": "Unauthorized",
		})
		return
	}
	userRole, _ := middlewares.GetUserRoleFromContext(c)

	// Parse request body
	var req struct {
		CompetitionID string `json:"competitionId" binding:"required"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		log.Printf("[TournamentHandler] Invalid request: %v", err)
		c.JSON(http.StatusBadRequest, gin.H{
			"status":  "error",
			"message": "Invalid request body: " + err.Error(),
		})
		return
	}

	// Execute use case
	tournament, err := h.addCompetitionToTournament.Execute(c.Request.Context(), tournamentID, req.CompetitionID, userIDObj, userRole)
	if err != nil {
		handleTournamentError(c, err)
		return
	}

	log.Printf("Added competition %s to tournament %s", req.CompetitionID, tournamentID)
	c.JSON(http.StatusOK, gin.H{
		"status":  "success",
		"message": "Competition added to tournament successfully",
		"data":    tournament,
	})
}

// GetStandings retrieves the standings for a tournament
// GET /tournaments/:id/standings
func (h *TournamentHandler) GetStandings(c *gin.Context) {
	tournamentID := c.Param("id")

	// Force recalculation and get updated standings
	standings, err := h.updateTournamentStandings.Execute(c.Request.Context(), tournamentID)
	if err != nil {
		handleTournamentError(c, err)
		return
	}

	log.Printf("Retrieved %d standings for tournament %s", len(standings), tournamentID)
	c.JSON(http.StatusOK, gin.H{
		"status": "success",
		"data":   standings,
	})
}

// GetTopStandings retrieves the top N standings for a tournament
// GET /tournaments/:id/standings/top
func (h *TournamentHandler) GetTopStandings(c *gin.Context) {
	tournamentID := c.Param("id")

	// Parse limit from query (default 10, max 100)
	limit := 10
	if limitQuery := c.Query("limit"); limitQuery != "" {
		// Simple integer parsing using Atoi
		if parsedLimit, err := strconv.Atoi(limitQuery); err == nil && parsedLimit > 0 {
			if parsedLimit > 100 {
				limit = 100
			} else {
				limit = parsedLimit
			}
		}
	}

	standings, err := h.updateTournamentStandings.ExecuteForTopN(c.Request.Context(), tournamentID, limit)
	if err != nil {
		handleTournamentError(c, err)
		return
	}

	log.Printf("Retrieved top %d standings for tournament %s", limit, tournamentID)
	c.JSON(http.StatusOK, gin.H{
		"status": "success",
		"data":   standings,
	})
}

// UpdateStandings forces a recalculation of tournament standings
// POST /tournaments/:id/standings/update
// Admin/Organizer only
func (h *TournamentHandler) UpdateStandings(c *gin.Context) {
	tournamentID := c.Param("id")

	// Get authenticated user
	_, err := middlewares.GetUserIDFromContext(c)
	if err != nil {
		log.Printf("[TournamentHandler] Unauthorized: %v", err)
		c.JSON(http.StatusUnauthorized, gin.H{
			"status":  "error",
			"message": "Unauthorized",
		})
		return
	}
	userRole, _ := middlewares.GetUserRoleFromContext(c)

	// Only admin or organizer can manually trigger standings update
	if userRole != "admin" && userRole != "verified_special" && userRole != "organizer" {
		log.Printf("[TournamentHandler] Forbidden: user role %s cannot update standings", userRole)
		c.JSON(http.StatusForbidden, gin.H{
			"status":  "error",
			"message": "Insufficient permissions",
		})
		return
	}

	standings, err := h.updateTournamentStandings.Execute(c.Request.Context(), tournamentID)
	if err != nil {
		handleTournamentError(c, err)
		return
	}

	log.Printf("Tournament standings updated successfully for %s", tournamentID)
	c.JSON(http.StatusOK, gin.H{
		"status":  "success",
		"message": "Tournament standings updated successfully",
		"data":    standings,
	})
}

// handleTournamentError maps domain errors to HTTP responses
func handleTournamentError(c *gin.Context, err error) {
	log.Printf("[TournamentHandler] Error: %v", err)

	switch err {
	case domainerrors.ErrCompetitionNotFound:
		c.JSON(http.StatusNotFound, gin.H{
			"status":  "error",
			"message": "Tournament not found",
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
	case domainerrors.ErrNotOwner:
		c.JSON(http.StatusForbidden, gin.H{
			"status":  "error",
			"message": "Only the tournament organizer can perform this action",
		})
	case domainerrors.ErrDatabaseOperation:
		c.JSON(http.StatusInternalServerError, gin.H{
			"status":  "error",
			"message": "Database operation failed",
		})
	case domainerrors.ErrDuplicateEntry:
		c.JSON(http.StatusConflict, gin.H{
			"status":  "error",
			"message": "Competition already added to tournament",
		})
	case domainerrors.ErrRegistrationClosed:
		c.JSON(http.StatusBadRequest, gin.H{
			"status":  "error",
			"message": "Tournament registration is closed",
		})
	case domainerrors.ErrMaxParticipantsReached:
		c.JSON(http.StatusBadRequest, gin.H{
			"status":  "error",
			"message": "Maximum participants reached for this tournament",
		})
	case domainerrors.ErrAlreadyRegistered:
		c.JSON(http.StatusConflict, gin.H{
			"status":  "error",
			"message": "Already registered for this tournament",
		})
	default:
		c.JSON(http.StatusInternalServerError, gin.H{
			"status":  "error",
			"message": "Internal server error",
		})
	}
}
