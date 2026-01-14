package handlers

import (
	"log"
	"net/http"

	"backend/features/competitions/application/dto"
	"backend/features/competitions/application/usecases"
	"backend/features/competitions/domain/entities"
	"backend/middlewares"

	"github.com/gin-gonic/gin"
)

// JudgeInvitationHandler handles HTTP requests for judge invitations
type JudgeInvitationHandler struct {
	createInvitation *usecases.CreateJudgeInvitationUseCase
	respondToInvitation *usecases.RespondToInvitationUseCase
	listInvitations  *usecases.ListJudgeInvitationsUseCase
	cancelInvitation *usecases.CancelJudgeInvitationUseCase
}

// NewJudgeInvitationHandler creates a new judge invitation handler
func NewJudgeInvitationHandler(
	createInvitation *usecases.CreateJudgeInvitationUseCase,
	respondToInvitation *usecases.RespondToInvitationUseCase,
	listInvitations *usecases.ListJudgeInvitationsUseCase,
	cancelInvitation *usecases.CancelJudgeInvitationUseCase,
) *JudgeInvitationHandler {
	return &JudgeInvitationHandler{
		createInvitation:    createInvitation,
		respondToInvitation: respondToInvitation,
		listInvitations:     listInvitations,
		cancelInvitation:    cancelInvitation,
	}
}

// Create handles creating a new judge invitation
// POST /competitions/:id/judge-invitations
func (h *JudgeInvitationHandler) Create(c *gin.Context) {
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

	// Parse request body
	var req dto.CreateJudgeInvitationRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		log.Printf("[Handler] Invalid request: %v", err)
		c.JSON(http.StatusBadRequest, gin.H{
			"status":  "error",
			"message": "Invalid request body: " + err.Error(),
		})
		return
	}

	// Execute use case
	invitation, err := h.createInvitation.Execute(c.Request.Context(), competitionID, req, userIDObj)
	if err != nil {
		handleInvitationError(c, err)
		return
	}

	log.Printf("Created judge invitation %s for competition %s", invitation.ID.Hex(), competitionID)
	c.JSON(http.StatusCreated, gin.H{
		"status":  "success",
		"message": "Judge invitation sent successfully",
		"data":    dto.ToJudgeInvitationResponse(invitation),
	})
}

// ListByCompetition lists all invitations for a competition
// GET /competitions/:id/judge-invitations
func (h *JudgeInvitationHandler) ListByCompetition(c *gin.Context) {
	competitionID := c.Param("id")

	// Parse and validate pagination params
	pagination, err := middlewares.ParsePagination(c)
	if err != nil {
		return // Response already sent
	}
	status := c.Query("status")

	invitations, total, err := h.listInvitations.ExecuteByCompetition(c.Request.Context(), competitionID, status, pagination.Page, pagination.Limit)
	if err != nil {
		handleInvitationError(c, err)
		return
	}

	log.Printf("Listed %d judge invitations for competition %s", len(invitations), competitionID)
	c.JSON(http.StatusOK, gin.H{
		"status": "success",
		"data": gin.H{
			"invitations": dto.ToJudgeInvitationResponseList(invitations),
			"total":       total,
			"page":        pagination.Page,
			"limit":       pagination.Limit,
		},
	})
}

// ListMyInvitations lists all invitations for the current user
// GET /competitions/judge-invitations/my
func (h *JudgeInvitationHandler) ListMyInvitations(c *gin.Context) {
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
	status := c.Query("status")

	invitations, total, err := h.listInvitations.ExecuteByUser(c.Request.Context(), userIDObj, status, pagination.Page, pagination.Limit)
	if err != nil {
		handleInvitationError(c, err)
		return
	}

	log.Printf("Listed %d judge invitations for user %s", len(invitations), userIDObj.Hex())
	c.JSON(http.StatusOK, gin.H{
		"status": "success",
		"data": gin.H{
			"invitations": dto.ToJudgeInvitationResponseList(invitations),
			"total":       total,
			"page":        pagination.Page,
			"limit":       pagination.Limit,
		},
	})
}

// Respond handles responding to an invitation (accept or decline)
// POST /competitions/judge-invitations/:invitationId/respond
func (h *JudgeInvitationHandler) Respond(c *gin.Context) {
	invitationID := c.Param("invitationId")

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

	// Parse request body
	var req dto.RespondToInvitationRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		log.Printf("[Handler] Invalid request: %v", err)
		c.JSON(http.StatusBadRequest, gin.H{
			"status":  "error",
			"message": "Invalid request body: " + err.Error(),
		})
		return
	}

	// Execute use case
	invitation, err := h.respondToInvitation.Execute(c.Request.Context(), invitationID, userIDObj, req.Accept, req.Response)
	if err != nil {
		handleInvitationError(c, err)
		return
	}

	action := "declined"
	if req.Accept {
		action = "accepted"
	}
	log.Printf("Judge invitation %s %s", invitationID, action)
	c.JSON(http.StatusOK, gin.H{
		"status":  "success",
		"message": "Invitation " + action + " successfully",
		"data":    dto.ToJudgeInvitationResponse(invitation),
	})
}

// Cancel handles cancelling a pending invitation
// DELETE /competitions/:id/judge-invitations/:invitationId
func (h *JudgeInvitationHandler) Cancel(c *gin.Context) {
	invitationID := c.Param("invitationId")

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

	// Execute use case
	err = h.cancelInvitation.Execute(c.Request.Context(), invitationID, userIDObj)
	if err != nil {
		handleInvitationError(c, err)
		return
	}

	log.Printf("Cancelled judge invitation %s", invitationID)
	c.JSON(http.StatusOK, gin.H{
		"status":  "success",
		"message": "Invitation cancelled successfully",
	})
}

// handleInvitationError maps domain errors to HTTP responses
func handleInvitationError(c *gin.Context, err error) {
	log.Printf("[JudgeInvitationHandler] Error: %v", err)

	switch err {
	case entities.ErrInvitationNotFound:
		c.JSON(http.StatusNotFound, gin.H{
			"status":  "error",
			"message": "Invitation not found",
		})
	case entities.ErrInvitationNotPending:
		c.JSON(http.StatusBadRequest, gin.H{
			"status":  "error",
			"message": "Invitation is not pending",
		})
	case entities.ErrInvitationExpired:
		c.JSON(http.StatusBadRequest, gin.H{
			"status":  "error",
			"message": "Invitation has expired",
		})
	case entities.ErrAlreadyInvited:
		c.JSON(http.StatusConflict, gin.H{
			"status":  "error",
			"message": "User already has a pending invitation",
		})
	default:
		c.JSON(http.StatusInternalServerError, gin.H{
			"status":  "error",
			"message": "Internal server error",
		})
	}
}
