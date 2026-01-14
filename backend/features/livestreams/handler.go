package livestreams

import (
	"net/http"
	"strconv"
	"time"

	"github.com/gin-gonic/gin"
	"go.mongodb.org/mongo-driver/mongo"

	"backend/pkg/repository"
	"backend/pkg/response"
)

// LiveStreamHandler handles HTTP requests for livestreaming
type LiveStreamHandler struct {
	service ILiveStreamService
}

// NewLiveStreamHandler creates a new livestream handler
func NewLiveStreamHandler(db *mongo.Database) *LiveStreamHandler {
	return &LiveStreamHandler{
		service: NewLiveStreamService(db),
	}
}

// ============================================================================
// Stream Management
// ============================================================================

// CreateLiveStream creates a new livestream
// @Summary Create a new livestream
// @Tags Livestreams
// @Accept json
// @Produce json
// @Param request body CreateLiveStreamRequest true "Livestream details"
// @Success 201 {object} LiveStreamResponse
// @Failure 400 {object} utils.ErrorResponse
// @Failure 500 {object} utils.ErrorResponse
// @Router /livestreams [post]
func (h *LiveStreamHandler) CreateLiveStream(c *gin.Context) {
	// Get authenticated user ID
	userID, exists := c.Get("userID")
	if !exists {
		response.Unauthorized(c, "unauthorized")
		return
	}

	// Parse request
	var req CreateLiveStreamRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		response.ErrorWithDetails(c, http.StatusBadRequest, "invalid request", map[string]interface{}{
			"error": err.Error(),
		})
		return
	}

	// Create livestream
	stream, err := h.service.CreateLiveStream(c.Request.Context(), userID.(string), req)
	if err != nil {
		response.ErrorWithDetails(c, http.StatusInternalServerError, "failed to create livestream", map[string]interface{}{
			"error": err.Error(),
		})
		return
	}

	// Map to response
	resp := h.mapToResponse(stream)
	response.Created(c, "livestream created successfully", resp)
}

// GetLiveStream retrieves a livestream by ID
// @Summary Get a livestream
// @Tags Livestreams
// @Produce json
// @Param id path string true "Livestream ID"
// @Success 200 {object} LiveStreamResponse
// @Failure 404 {object} utils.ErrorResponse
// @Router /livestreams/{id} [get]
func (h *LiveStreamHandler) GetLiveStream(c *gin.Context) {
	streamID := c.Param("id")

	stream, err := h.service.GetLiveStream(c.Request.Context(), streamID)
	if err != nil {
		response.NotFound(c, "livestream not found")
		return
	}

	resp := h.mapToResponse(stream)
	response.OK(c, "livestream retrieved successfully", resp)
}

// UpdateLiveStream updates a livestream
// @Summary Update a livestream
// @Tags Livestreams
// @Accept json
// @Produce json
// @Param id path string true "Livestream ID"
// @Param request body UpdateLiveStreamRequest true "Updated details"
// @Success 200 {object} LiveStreamResponse
// @Failure 400 {object} utils.ErrorResponse
// @Failure 403 {object} utils.ErrorResponse
// @Router /livestreams/{id} [patch]
func (h *LiveStreamHandler) UpdateLiveStream(c *gin.Context) {
	streamID := c.Param("id")

	// Get authenticated user ID
	userID, exists := c.Get("userID")
	if !exists {
		response.Unauthorized(c, "unauthorized")
		return
	}

	// Parse request
	var req UpdateLiveStreamRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		response.ErrorWithDetails(c, http.StatusBadRequest, "invalid request", map[string]interface{}{
			"error": err.Error(),
		})
		return
	}

	// Update livestream
	stream, err := h.service.UpdateLiveStream(c.Request.Context(), streamID, userID.(string), req)
	if err != nil {
		response.ErrorWithDetails(c, http.StatusForbidden, "failed to update livestream", map[string]interface{}{
			"error": err.Error(),
		})
		return
	}

	resp := h.mapToResponse(stream)
	response.OK(c, "livestream updated successfully", resp)
}

// DeleteLiveStream deletes a livestream
// @Summary Delete a livestream
// @Tags Livestreams
// @Param id path string true "Livestream ID"
// @Success 200 {object} utils.SuccessResponse
// @Failure 403 {object} utils.ErrorResponse
// @Router /livestreams/{id} [delete]
func (h *LiveStreamHandler) DeleteLiveStream(c *gin.Context) {
	streamID := c.Param("id")

	// Get authenticated user ID
	userID, exists := c.Get("userID")
	if !exists {
		response.Unauthorized(c, "unauthorized")
		return
	}

	// Delete livestream
	if err := h.service.DeleteLiveStream(c.Request.Context(), streamID, userID.(string)); err != nil {
		response.ErrorWithDetails(c, http.StatusForbidden, "failed to delete livestream", map[string]interface{}{
			"error": err.Error(),
		})
		return
	}

	response.OK(c, "livestream deleted successfully", nil)
}

// ============================================================================
// Stream Lifecycle
// ============================================================================

// StartLiveStream starts a scheduled livestream
// @Summary Start a livestream
// @Tags Livestreams
// @Param id path string true "Livestream ID"
// @Success 200 {object} utils.SuccessResponse
// @Failure 403 {object} utils.ErrorResponse
// @Router /livestreams/{id}/start [post]
func (h *LiveStreamHandler) StartLiveStream(c *gin.Context) {
	streamID := c.Param("id")

	// Get authenticated user ID
	userID, exists := c.Get("userID")
	if !exists {
		response.Unauthorized(c, "unauthorized")
		return
	}

	// Start livestream
	if err := h.service.StartLiveStream(c.Request.Context(), streamID, userID.(string)); err != nil {
		response.ErrorWithDetails(c, http.StatusForbidden, "failed to start livestream", map[string]interface{}{
			"error": err.Error(),
		})
		return
	}

	response.OK(c, "livestream started successfully", nil)
}

// EndLiveStream ends a live livestream
// @Summary End a livestream
// @Tags Livestreams
// @Accept json
// @Produce json
// @Param id path string true "Livestream ID"
// @Param request body EndLiveStreamRequest true "End options"
// @Success 200 {object} utils.SuccessResponse
// @Failure 403 {object} utils.ErrorResponse
// @Router /livestreams/{id}/end [post]
func (h *LiveStreamHandler) EndLiveStream(c *gin.Context) {
	streamID := c.Param("id")

	// Get authenticated user ID
	userID, exists := c.Get("userID")
	if !exists {
		response.Unauthorized(c, "unauthorized")
		return
	}

	// Parse request
	var req EndLiveStreamRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		req.SaveRecording = false // Default to not saving
	}

	// End livestream
	if err := h.service.EndLiveStream(c.Request.Context(), streamID, userID.(string), req.SaveRecording); err != nil {
		response.ErrorWithDetails(c, http.StatusForbidden, "failed to end livestream", map[string]interface{}{
			"error": err.Error(),
		})
		return
	}

	response.OK(c, "livestream ended successfully", nil)
}

// CancelLiveStream cancels a scheduled livestream
// @Summary Cancel a scheduled livestream
// @Tags Livestreams
// @Param id path string true "Livestream ID"
// @Success 200 {object} utils.SuccessResponse
// @Failure 403 {object} utils.ErrorResponse
// @Router /livestreams/{id}/cancel [post]
func (h *LiveStreamHandler) CancelLiveStream(c *gin.Context) {
	streamID := c.Param("id")

	// Get authenticated user ID
	userID, exists := c.Get("userID")
	if !exists {
		response.Unauthorized(c, "unauthorized")
		return
	}

	// Cancel livestream
	if err := h.service.CancelLiveStream(c.Request.Context(), streamID, userID.(string)); err != nil {
		response.ErrorWithDetails(c, http.StatusForbidden, "failed to cancel livestream", map[string]interface{}{
			"error": err.Error(),
		})
		return
	}

	response.OK(c, "livestream cancelled successfully", nil)
}

// ============================================================================
// Stream Discovery
// ============================================================================

// GetLiveStreams retrieves all currently live streams
// @Summary Get live streams
// @Tags Livestreams
// @Produce json
// @Param page query int false "Page number" default(1)
// @Param limit query int false "Items per page" default(20)
// @Success 200 {object} StreamListResponse
// @Router /livestreams/live [get]
func (h *LiveStreamHandler) GetLiveStreams(c *gin.Context) {
	page := getIntQuery(c, "page", 1)
	limit := getIntQuery(c, "limit", 20)

	result, err := h.service.GetLiveStreams(c.Request.Context(), page, limit)
	if err != nil {
		response.ErrorWithDetails(c, http.StatusInternalServerError, "failed to get livestreams", map[string]interface{}{
			"error": err.Error(),
		})
		return
	}

	resp := h.mapPaginatedResponse(result)
	response.OK(c, "livestreams retrieved successfully", resp)
}

// GetScheduledStreams retrieves scheduled streams
// @Summary Get scheduled streams
// @Tags Livestreams
// @Produce json
// @Param page query int false "Page number" default(1)
// @Param limit query int false "Items per page" default(20)
// @Success 200 {object} StreamListResponse
// @Router /livestreams/scheduled [get]
func (h *LiveStreamHandler) GetScheduledStreams(c *gin.Context) {
	page := getIntQuery(c, "page", 1)
	limit := getIntQuery(c, "limit", 20)

	result, err := h.service.GetScheduledStreams(c.Request.Context(), page, limit)
	if err != nil {
		response.ErrorWithDetails(c, http.StatusInternalServerError, "failed to get scheduled streams", map[string]interface{}{
			"error": err.Error(),
		})
		return
	}

	resp := h.mapPaginatedResponse(result)
	response.OK(c, "scheduled streams retrieved successfully", resp)
}

// GetMyStreams retrieves streams created by the authenticated user
// @Summary Get my streams
// @Tags Livestreams
// @Produce json
// @Param page query int false "Page number" default(1)
// @Param limit query int false "Items per page" default(20)
// @Success 200 {object} StreamListResponse
// @Router /livestreams/my-streams [get]
func (h *LiveStreamHandler) GetMyStreams(c *gin.Context) {
	// Get authenticated user ID
	userID, exists := c.Get("userID")
	if !exists {
		response.Unauthorized(c, "unauthorized")
		return
	}

	page := getIntQuery(c, "page", 1)
	limit := getIntQuery(c, "limit", 20)

	result, err := h.service.GetHostStreams(c.Request.Context(), userID.(string), page, limit)
	if err != nil {
		response.ErrorWithDetails(c, http.StatusInternalServerError, "failed to get streams", map[string]interface{}{
			"error": err.Error(),
		})
		return
	}

	resp := h.mapPaginatedResponse(result)
	response.OK(c, "streams retrieved successfully", resp)
}

// SearchStreams searches for livestreams
// @Summary Search streams
// @Tags Livestreams
// @Produce json
// @Param q query string true "Search query"
// @Param page query int false "Page number" default(1)
// @Param limit query int false "Items per page" default(20)
// @Success 200 {object} StreamListResponse
// @Router /livestreams/search [get]
func (h *LiveStreamHandler) SearchStreams(c *gin.Context) {
	query := c.Query("q")
	if query == "" {
		response.BadRequest(c, "search query is required")
		return
	}

	page := getIntQuery(c, "page", 1)
	limit := getIntQuery(c, "limit", 20)

	result, err := h.service.SearchStreams(c.Request.Context(), query, page, limit)
	if err != nil {
		response.ErrorWithDetails(c, http.StatusInternalServerError, "failed to search streams", map[string]interface{}{
			"error": err.Error(),
		})
		return
	}

	resp := h.mapPaginatedResponse(result)
	response.OK(c, "search completed successfully", resp)
}

// ============================================================================
// Viewer Management
// ============================================================================

// JoinStream allows a user to join a livestream
// @Summary Join a livestream
// @Tags Livestreams
// @Produce json
// @Param id path string true "Livestream ID"
// @Success 200 {object} JoinStreamResponse
// @Failure 403 {object} utils.ErrorResponse
// @Router /livestreams/{id}/join [post]
func (h *LiveStreamHandler) JoinStream(c *gin.Context) {
	streamID := c.Param("id")

	// Get authenticated user ID
	userID, exists := c.Get("userID")
	if !exists {
		response.Unauthorized(c, "unauthorized")
		return
	}

	// Get username (should be in context from auth middleware)
	username := c.GetString("username")
	if username == "" {
		username = "Anonymous"
	}

	// Join stream
	resp, err := h.service.JoinStream(c.Request.Context(), streamID, userID.(string), username)
	if err != nil {
		response.ErrorWithDetails(c, http.StatusForbidden, "failed to join stream", map[string]interface{}{
			"error": err.Error(),
		})
		return
	}

	response.OK(c, "joined stream successfully", resp)
}

// LeaveStream allows a user to leave a livestream
// @Summary Leave a livestream
// @Tags Livestreams
// @Param id path string true "Livestream ID"
// @Success 200 {object} utils.SuccessResponse
// @Router /livestreams/{id}/leave [post]
func (h *LiveStreamHandler) LeaveStream(c *gin.Context) {
	streamID := c.Param("id")

	// Get authenticated user ID
	userID, exists := c.Get("userID")
	if !exists {
		response.Unauthorized(c, "unauthorized")
		return
	}

	// Leave stream
	if err := h.service.LeaveStream(c.Request.Context(), streamID, userID.(string)); err != nil {
		response.ErrorWithDetails(c, http.StatusBadRequest, "failed to leave stream", map[string]interface{}{
			"error": err.Error(),
		})
		return
	}

	response.OK(c, "left stream successfully", nil)
}

// GetStreamViewers retrieves current viewers of a livestream
// @Summary Get stream viewers
// @Tags Livestreams
// @Produce json
// @Param id path string true "Livestream ID"
// @Success 200 {object} ViewerListResponse
// @Router /livestreams/{id}/viewers [get]
func (h *LiveStreamHandler) GetStreamViewers(c *gin.Context) {
	streamID := c.Param("id")

	viewers, err := h.service.GetStreamViewers(c.Request.Context(), streamID)
	if err != nil {
		response.ErrorWithDetails(c, http.StatusInternalServerError, "failed to get viewers", map[string]interface{}{
			"error": err.Error(),
		})
		return
	}

	// Map to response
	viewerResponses := make([]ViewerResponse, len(viewers))
	for i, v := range viewers {
		duration := 0
		if v.JoinedAt != nil {
			duration = int(time.Since(*v.JoinedAt).Seconds())
		}

		viewerResponses[i] = ViewerResponse{
			UserID:   v.UserID.Hex(),
			Username: v.Username,
			JoinedAt: v.JoinedAt.Format(time.RFC3339),
			Duration: duration,
		}
	}

	resp := ViewerListResponse{
		Viewers: viewerResponses,
		Total:   len(viewerResponses),
	}

	response.OK(c, "viewers retrieved successfully", resp)
}

// ============================================================================
// Chat Management
// ============================================================================

// SendChatMessage sends a chat message in a livestream
// @Summary Send chat message
// @Tags Livestreams
// @Accept json
// @Produce json
// @Param id path string true "Livestream ID"
// @Param request body SendChatMessageRequest true "Message"
// @Success 200 {object} ChatMessageResponse
// @Failure 400 {object} utils.ErrorResponse
// @Router /livestreams/{id}/chat [post]
func (h *LiveStreamHandler) SendChatMessage(c *gin.Context) {
	streamID := c.Param("id")

	// Get authenticated user ID
	userID, exists := c.Get("userID")
	if !exists {
		response.Unauthorized(c, "unauthorized")
		return
	}

	// Parse request
	var req SendChatMessageRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		response.ErrorWithDetails(c, http.StatusBadRequest, "invalid request", map[string]interface{}{
			"error": err.Error(),
		})
		return
	}

	// Get user info from context
	username := c.GetString("username")
	avatarURL := c.GetString("avatarURL")

	// Send message
	msg, err := h.service.SendChatMessage(c.Request.Context(), streamID, userID.(string), username, avatarURL, req.Message)
	if err != nil {
		response.ErrorWithDetails(c, http.StatusForbidden, "failed to send message", map[string]interface{}{
			"error": err.Error(),
		})
		return
	}

	// Map to response
	resp := ChatMessageResponse{
		ID:        msg.ID.Hex(),
		StreamID:  msg.StreamID.Hex(),
		UserID:    msg.UserID.Hex(),
		Username:  msg.Username,
		AvatarURL: msg.AvatarURL,
		Message:   msg.Message,
		CreatedAt: msg.CreatedAt.Format(time.RFC3339),
		IsPinned:  msg.IsPinned,
	}

	response.OK(c, "message sent successfully", resp)
}

// GetChatMessages retrieves chat messages for a livestream
// @Summary Get chat messages
// @Tags Livestreams
// @Produce json
// @Param id path string true "Livestream ID"
// @Param page query int false "Page number" default(1)
// @Param limit query int false "Items per page" default(50)
// @Success 200 {object} []ChatMessageResponse
// @Router /livestreams/{id}/chat [get]
func (h *LiveStreamHandler) GetChatMessages(c *gin.Context) {
	streamID := c.Param("id")
	page := getIntQuery(c, "page", 1)
	limit := getIntQuery(c, "limit", 50)

	result, err := h.service.GetChatMessages(c.Request.Context(), streamID, page, limit)
	if err != nil {
		response.ErrorWithDetails(c, http.StatusInternalServerError, "failed to get messages", map[string]interface{}{
			"error": err.Error(),
		})
		return
	}

	// Map to responses
	messages := make([]ChatMessageResponse, len(result.Data))
	for i, msg := range result.Data {
		messages[i] = ChatMessageResponse{
			ID:        msg.ID.Hex(),
			StreamID:  msg.StreamID.Hex(),
			UserID:    msg.UserID.Hex(),
			Username:  msg.Username,
			AvatarURL: msg.AvatarURL,
			Message:   msg.Message,
			CreatedAt: msg.CreatedAt.Format(time.RFC3339),
			IsPinned:  msg.IsPinned,
		}
	}

	response.OK(c, "messages retrieved successfully", messages)
}

// ============================================================================
// Reactions
// ============================================================================

// SendReaction sends a reaction to a livestream
// @Summary Send reaction
// @Tags Livestreams
// @Accept json
// @Produce json
// @Param id path string true "Livestream ID"
// @Param request body SendReactionRequest true "Reaction"
// @Success 200 {object} ReactionResponse
// @Failure 400 {object} utils.ErrorResponse
// @Router /livestreams/{id}/react [post]
func (h *LiveStreamHandler) SendReaction(c *gin.Context) {
	streamID := c.Param("id")

	// Get authenticated user ID
	userID, exists := c.Get("userID")
	if !exists {
		response.Unauthorized(c, "unauthorized")
		return
	}

	// Parse request
	var req SendReactionRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		response.ErrorWithDetails(c, http.StatusBadRequest, "invalid request", map[string]interface{}{
			"error": err.Error(),
		})
		return
	}

	// Send reaction
	reaction, err := h.service.SendReaction(c.Request.Context(), streamID, userID.(string), req.Type)
	if err != nil {
		response.ErrorWithDetails(c, http.StatusForbidden, "failed to send reaction", map[string]interface{}{
			"error": err.Error(),
		})
		return
	}

	// Map to response
	resp := ReactionResponse{
		ID:        reaction.ID.Hex(),
		StreamID:  reaction.StreamID.Hex(),
		UserID:    reaction.UserID.Hex(),
		Type:      reaction.Type,
		CreatedAt: reaction.CreatedAt.Format(time.RFC3339),
	}

	response.OK(c, "reaction sent successfully", resp)
}

// ============================================================================
// Statistics
// ============================================================================

// GetStreamStats retrieves statistics for a livestream
// @Summary Get stream statistics
// @Tags Livestreams
// @Produce json
// @Param id path string true "Livestream ID"
// @Success 200 {object} StreamStatsResponse
// @Router /livestreams/{id}/stats [get]
func (h *LiveStreamHandler) GetStreamStats(c *gin.Context) {
	streamID := c.Param("id")

	stats, err := h.service.GetStreamStats(c.Request.Context(), streamID)
	if err != nil {
		response.NotFound(c, "stream not found")
		return
	}

	response.OK(c, "stats retrieved successfully", stats)
}

// ============================================================================
// Helper Functions
// ============================================================================

func (h *LiveStreamHandler) mapToResponse(stream *LiveStream) LiveStreamResponse {
	resp := LiveStreamResponse{
		ID:            stream.ID.Hex(),
		Title:         stream.Title,
		Description:   stream.Description,
		ThumbnailURL:  stream.ThumbnailURL,
		HostID:        stream.HostID.Hex(),
		HostName:      stream.HostName,
		Status:        string(stream.Status),
		ViewerCount:   stream.ViewerCount,
		PeakViewers:   stream.PeakViewers,
		TotalViews:    stream.TotalViews,
		ReactionCount: stream.ReactionCount,
		MessageCount:  stream.MessageCount,
		Tags:          stream.Tags,
		CreatedAt:     stream.CreatedAt.Format(time.RFC3339),
	}

	if stream.ScheduledTime != nil {
		scheduledStr := stream.ScheduledTime.Format(time.RFC3339)
		resp.ScheduledTime = &scheduledStr
	}

	if stream.StartedAt != nil {
		startedStr := stream.StartedAt.Format(time.RFC3339)
		resp.StartedAt = &startedStr
	}

	if stream.EndedAt != nil {
		endedStr := stream.EndedAt.Format(time.RFC3339)
		resp.EndedAt = &endedStr
	}

	return resp
}

func (h *LiveStreamHandler) mapPaginatedResponse(result *repository.PaginatedResult[*LiveStream]) StreamListResponse {
	streams := make([]LiveStreamResponse, len(result.Data))
	for i, stream := range result.Data {
		streams[i] = h.mapToResponse(stream)
	}

	return StreamListResponse{
		Streams:    streams,
		Total:      result.Total,
		Page:       result.Page,
		Limit:      result.Limit,
		TotalPages: result.TotalPages,
	}
}

func getIntQuery(c *gin.Context, key string, defaultValue int) int {
	valueStr := c.Query(key)
	if valueStr == "" {
		return defaultValue
	}

	value, err := strconv.Atoi(valueStr)
	if err != nil {
		return defaultValue
	}

	return value
}
