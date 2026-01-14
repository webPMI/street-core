package handlers

import (
	"fmt"
	"net/http"

	"backend/app/dto/response"
	"backend/features/competitions/domain/repositories"
	"backend/features/competitions/infrastructure/realtime"
	"backend/middlewares"

	"github.com/gin-gonic/gin"
	"go.mongodb.org/mongo-driver/bson/primitive"
)

// SSEHandler handles Server-Sent Events connections for real-time updates
type SSEHandler struct {
	sseHub               *realtime.SSEHub
	competitionRepo      repositories.CompetitionRepository
}

// NewSSEHandler creates a new SSE handler
func NewSSEHandler(sseHub *realtime.SSEHub, competitionRepo repositories.CompetitionRepository) *SSEHandler {
	return &SSEHandler{
		sseHub:          sseHub,
		competitionRepo: competitionRepo,
	}
}

// StreamCompetitionEvents establishes SSE connection for competition updates
// GET /competitions/:id/events
//
// USAGE (JavaScript):
// const eventSource = new EventSource('/api/v1/competitions/673d1f2e8b5c4a1d2e3f4a5b/events');
//
// eventSource.addEventListener('score_reset', (event) => {
//   const data = JSON.parse(event.data);
//   console.log('Score reset:', data);
//   // Update UI without refresh
// });
//
// eventSource.addEventListener('score_swap', (event) => {
//   const data = JSON.parse(event.data);
//   console.log('Score swap:', data.athlete1Id, data.athlete2Id);
// });
//
// eventSource.addEventListener('emergency', (event) => {
//   const data = JSON.parse(event.data);
//   if (data.priority === 'CRITICAL') {
//     showAlert(data.message);
//   }
// });
func (h *SSEHandler) StreamCompetitionEvents(c *gin.Context) {
	competitionID := c.Param("id")

	// Parse competition ID
	compID, err := primitive.ObjectIDFromHex(competitionID)
	if err != nil {
		response.Error(c, http.StatusBadRequest, "invalid ID")
		return
	}

	// 🔒 SECURITY FIX (CRITICAL-2): Authorization check before subscribing to SSE stream
	// Get authenticated user ID from context (set by JWTAuthMiddleware)
	userIDObj, err := middlewares.GetUserIDFromContext(c)
	if err != nil {
		response.Error(c, http.StatusUnauthorized, "unauthorized")
		return
	}

	// Load competition to check access permissions
	competition, err := h.competitionRepo.FindByID(c.Request.Context(), compID)
	if err != nil {
		response.Error(c, http.StatusNotFound, "competition not found")
		return
	}

	// Authorization rules (Defense-in-depth):
	// 1. Allow if competition is LIVE (public real-time updates)
	// 2. Allow if user is the organizer
	// 3. Allow if user is a judge
	// 4. Allow if user is a registered athlete
	// 5. Otherwise DENY (403 Forbidden)
	isLive := competition.Status == "live"
	isOrganizer := competition.IsOwner(userIDObj)
	isJudge := competition.IsJudge(userIDObj)
	isAthlete := competition.IsAthleteRegistered(userIDObj)

	if !isLive && !isOrganizer && !isJudge && !isAthlete {
		response.Error(c, http.StatusForbidden, "access denied: you don't have permission to view this competition's real-time updates")
		return
	}

	// Set SSE headers
	c.Header("Content-Type", "text/event-stream")
	c.Header("Cache-Control", "no-cache")
	c.Header("Connection", "keep-alive")
	c.Header("X-Accel-Buffering", "no") // Disable nginx buffering

	// Subscribe to competition events
	clientChan := h.sseHub.Subscribe(compID)

	// Clean up when connection closes
	defer h.sseHub.Unsubscribe(compID, clientChan)

	// Send initial connection event
	c.SSEvent("connected", gin.H{
		"competitionId": competitionID,
		"message":       "Real-time updates active",
		"timestamp":     fmt.Sprintf("%d", primitive.NewObjectID().Timestamp().Unix()),
	})
	c.Writer.Flush()

	fmt.Printf("INFO: SSE stream opened for competition %s\n", competitionID)

	// Stream events to client
	for {
		select {
		case event, ok := <-clientChan:
			if !ok {
				// Channel closed, exit
				fmt.Printf("INFO: SSE stream closed for competition %s\n", competitionID)
				return
			}

			// Send event to client
			c.SSEvent(event.Event, event.Data)
			c.Writer.Flush()

		case <-c.Request.Context().Done():
			// Client disconnected
			fmt.Printf("INFO: Client disconnected from SSE stream for competition %s\n", competitionID)
			return
		}
	}
}

// GetSubscriberCount returns the number of active SSE connections
// GET /competitions/:id/events/subscribers
func (h *SSEHandler) GetSubscriberCount(c *gin.Context) {
	competitionID := c.Param("id")

	compID, err := primitive.ObjectIDFromHex(competitionID)
	if err != nil {
		response.Error(c, http.StatusBadRequest, "invalid ID")
		return
	}

	count := h.sseHub.GetSubscriberCount(compID)

	response.Success(c, http.StatusOK, "Subscriber count retrieved", gin.H{
		"competitionId": competitionID,
		"subscribers":   count,
	})
}
