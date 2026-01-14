package livestreams

import (
	"context"
	"fmt"
	"time"

	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/bson/primitive"
	"go.mongodb.org/mongo-driver/mongo"

	"backend/config"
	"backend/pkg/repository"
	"backend/utils"
)

// ILiveStreamService defines the interface for livestream business logic
type ILiveStreamService interface {
	// Stream Management
	CreateLiveStream(ctx context.Context, hostID string, req CreateLiveStreamRequest) (*LiveStream, error)
	GetLiveStream(ctx context.Context, streamID string) (*LiveStream, error)
	UpdateLiveStream(ctx context.Context, streamID, userID string, req UpdateLiveStreamRequest) (*LiveStream, error)
	DeleteLiveStream(ctx context.Context, streamID, userID string) error

	// Stream Lifecycle
	StartLiveStream(ctx context.Context, streamID, hostID string) error
	EndLiveStream(ctx context.Context, streamID, hostID string, saveRecording bool) error
	CancelLiveStream(ctx context.Context, streamID, hostID string) error

	// Stream Discovery
	GetLiveStreams(ctx context.Context, page, limit int) (*repository.PaginatedResult[*LiveStream], error)
	GetScheduledStreams(ctx context.Context, page, limit int) (*repository.PaginatedResult[*LiveStream], error)
	GetHostStreams(ctx context.Context, hostID string, page, limit int) (*repository.PaginatedResult[*LiveStream], error)
	SearchStreams(ctx context.Context, query string, page, limit int) (*repository.PaginatedResult[*LiveStream], error)

	// Viewer Management
	JoinStream(ctx context.Context, streamID, userID, username string) (*JoinStreamResponse, error)
	LeaveStream(ctx context.Context, streamID, userID string) error
	GetStreamViewers(ctx context.Context, streamID string) ([]*LiveStreamViewer, error)
	GetViewerCount(ctx context.Context, streamID string) (int64, error)

	// Chat Management
	SendChatMessage(ctx context.Context, streamID, userID, username, avatarURL, message string) (*ChatMessage, error)
	GetChatMessages(ctx context.Context, streamID string, page, limit int) (*repository.PaginatedResult[*ChatMessage], error)
	DeleteChatMessage(ctx context.Context, messageID, userID string) error
	PinChatMessage(ctx context.Context, messageID, streamID, userID string, pinned bool) error

	// Reactions
	SendReaction(ctx context.Context, streamID, userID, reactionType string) (*StreamReaction, error)
	GetRecentReactions(ctx context.Context, streamID string, since time.Time) ([]*StreamReaction, error)

	// Statistics
	GetStreamStats(ctx context.Context, streamID string) (*StreamStatsResponse, error)
	UpdateViewerCount(ctx context.Context, streamID string) error
}

// liveStreamService implements ILiveStreamService
type liveStreamService struct {
	streamRepo   *LiveStreamRepository
	viewerRepo   *ViewerRepository
	chatRepo     *ChatMessageRepository
	reactionRepo *ReactionRepository
}

// NewLiveStreamService creates a new livestream service
func NewLiveStreamService(db *mongo.Database) ILiveStreamService {
	return &liveStreamService{
		streamRepo:   NewLiveStreamRepository(db),
		viewerRepo:   NewViewerRepository(db),
		chatRepo:     NewChatMessageRepository(db),
		reactionRepo: NewReactionRepository(db),
	}
}

// ============================================================================
// Stream Management
// ============================================================================

func (s *liveStreamService) CreateLiveStream(ctx context.Context, hostID string, req CreateLiveStreamRequest) (*LiveStream, error) {
	// Validate Agora is enabled
	if !config.Agora.Enabled {
		return nil, fmt.Errorf("livestreaming is not available: Agora SDK not configured")
	}

	// Parse host ID
	hostObjID, err := primitive.ObjectIDFromHex(hostID)
	if err != nil {
		return nil, repository.ErrInvalidID
	}

	// Create stream
	stream := &LiveStream{
		Title:       req.Title,
		Description: req.Description,
		ThumbnailURL: req.ThumbnailURL,
		HostID:      hostObjID,
		Status:      LiveStreamStatusScheduled,
		Tags:        req.Tags,
		RecordingEnabled: req.RecordingEnabled,
		ViewerCount: 0,
		PeakViewers: 0,
		TotalViews:  0,
		ReactionCount: 0,
		MessageCount:  0,
	}

	// Set scheduled time if provided
	if req.ScheduledTime != nil {
		stream.ScheduledTime = req.ScheduledTime
	}

	// Generate Agora channel configuration
	stream.AppID = config.Agora.AppID
	stream.ChannelName = config.GenerateChannelName(stream.ID.Hex())
	stream.UID = config.GenerateUID(hostID)

	// Generate host token (longer expiry for host)
	token, err := config.GenerateRTCToken(
		stream.ChannelName,
		stream.UID,
		config.RolePublisher,
		config.Agora.HostTokenExpiry,
	)
	if err != nil {
		return nil, fmt.Errorf("failed to generate Agora token: %w", err)
	}
	stream.Token = token

	// Save to database
	created, err := s.streamRepo.Create(ctx, stream)
	if err != nil {
		return nil, fmt.Errorf("failed to create livestream: %w", err)
	}

	utils.Info("Livestream created", map[string]interface{}{
		"stream_id": created.ID.Hex(),
		"host_id":   hostID,
		"title":     created.Title,
	})

	return created, nil
}

func (s *liveStreamService) GetLiveStream(ctx context.Context, streamID string) (*LiveStream, error) {
	return s.streamRepo.FindByID(ctx, streamID)
}

func (s *liveStreamService) UpdateLiveStream(ctx context.Context, streamID, userID string, req UpdateLiveStreamRequest) (*LiveStream, error) {
	// Get existing stream
	stream, err := s.streamRepo.FindByID(ctx, streamID)
	if err != nil {
		return nil, err
	}

	// Verify user is the host
	if stream.HostID.Hex() != userID {
		return nil, fmt.Errorf("only the host can update the livestream")
	}

	// Can only update scheduled or live streams
	if stream.Status != LiveStreamStatusScheduled && stream.Status != LiveStreamStatusLive {
		return nil, fmt.Errorf("cannot update stream in %s status", stream.Status)
	}

	// Build update document
	update := bson.M{"$set": bson.M{}}

	if req.Title != nil {
		update["$set"].(bson.M)["title"] = *req.Title
	}
	if req.Description != nil {
		update["$set"].(bson.M)["description"] = *req.Description
	}
	if req.ThumbnailURL != nil {
		update["$set"].(bson.M)["thumbnailUrl"] = *req.ThumbnailURL
	}
	if req.Tags != nil {
		update["$set"].(bson.M)["tags"] = *req.Tags
	}

	// Update
	if err := s.streamRepo.UpdateByID(ctx, streamID, update); err != nil {
		return nil, err
	}

	// Return updated stream
	return s.streamRepo.FindByID(ctx, streamID)
}

func (s *liveStreamService) DeleteLiveStream(ctx context.Context, streamID, userID string) error {
	// Get stream
	stream, err := s.streamRepo.FindByID(ctx, streamID)
	if err != nil {
		return err
	}

	// Verify user is the host
	if stream.HostID.Hex() != userID {
		return fmt.Errorf("only the host can delete the livestream")
	}

	// Can only delete scheduled streams or ended streams
	if stream.Status != LiveStreamStatusScheduled && stream.Status != LiveStreamStatusEnded {
		return fmt.Errorf("can only delete scheduled or ended streams")
	}

	return s.streamRepo.DeleteByID(ctx, streamID)
}

// ============================================================================
// Stream Lifecycle
// ============================================================================

func (s *liveStreamService) StartLiveStream(ctx context.Context, streamID, hostID string) error {
	// Get stream
	stream, err := s.streamRepo.FindByID(ctx, streamID)
	if err != nil {
		return err
	}

	// Verify user is the host
	if stream.HostID.Hex() != hostID {
		return fmt.Errorf("only the host can start the livestream")
	}

	// Can only start scheduled streams
	if stream.Status != LiveStreamStatusScheduled {
		return fmt.Errorf("can only start scheduled streams")
	}

	// Update status to live
	if err := s.streamRepo.UpdateStatus(ctx, streamID, LiveStreamStatusLive); err != nil {
		return err
	}

	utils.Info("Livestream started", map[string]interface{}{
		"stream_id": streamID,
		"host_id":   hostID,
	})

	return nil
}

func (s *liveStreamService) EndLiveStream(ctx context.Context, streamID, hostID string, saveRecording bool) error {
	// Get stream
	stream, err := s.streamRepo.FindByID(ctx, streamID)
	if err != nil {
		return err
	}

	// Verify user is the host
	if stream.HostID.Hex() != hostID {
		return fmt.Errorf("only the host can end the livestream")
	}

	// Can only end live streams
	if stream.Status != LiveStreamStatusLive {
		return fmt.Errorf("stream is not live")
	}

	// Update status to ended
	if err := s.streamRepo.UpdateStatus(ctx, streamID, LiveStreamStatusEnded); err != nil {
		return err
	}

	// Mark all active viewers as left
	viewers, err := s.viewerRepo.FindByStreamID(ctx, streamID)
	if err == nil {
		for _, viewer := range viewers {
			_ = s.viewerRepo.MarkViewerLeft(ctx, viewer.ID.Hex())
		}
	}

	// TODO: Handle cloud recording if enabled
	// if saveRecording && config.Agora.RecordingEnabled {
	//     s.stopCloudRecording(stream)
	// }

	utils.Info("Livestream ended", map[string]interface{}{
		"stream_id": streamID,
		"host_id":   hostID,
		"save_recording": saveRecording,
	})

	return nil
}

func (s *liveStreamService) CancelLiveStream(ctx context.Context, streamID, hostID string) error {
	// Get stream
	stream, err := s.streamRepo.FindByID(ctx, streamID)
	if err != nil {
		return err
	}

	// Verify user is the host
	if stream.HostID.Hex() != hostID {
		return fmt.Errorf("only the host can cancel the livestream")
	}

	// Can only cancel scheduled streams
	if stream.Status != LiveStreamStatusScheduled {
		return fmt.Errorf("can only cancel scheduled streams")
	}

	// Update status to cancelled
	if err := s.streamRepo.UpdateStatus(ctx, streamID, LiveStreamStatusCancelled); err != nil {
		return err
	}

	utils.Info("Livestream cancelled", map[string]interface{}{
		"stream_id": streamID,
		"host_id":   hostID,
	})

	return nil
}

// ============================================================================
// Stream Discovery
// ============================================================================

func (s *liveStreamService) GetLiveStreams(ctx context.Context, page, limit int) (*repository.PaginatedResult[*LiveStream], error) {
	queryOpts := repository.QueryOptions{
		Page:      page,
		Limit:     limit,
		SortField: "viewerCount",
		SortOrder: -1, // Most viewers first
	}

	return s.streamRepo.FindByStatus(ctx, LiveStreamStatusLive, queryOpts)
}

func (s *liveStreamService) GetScheduledStreams(ctx context.Context, page, limit int) (*repository.PaginatedResult[*LiveStream], error) {
	queryOpts := repository.QueryOptions{
		Page:      page,
		Limit:     limit,
		SortField: "scheduledTime",
		SortOrder: 1, // Earliest first
		Filter: bson.M{
			"scheduledTime": bson.M{"$gte": time.Now()},
		},
	}

	return s.streamRepo.FindByStatus(ctx, LiveStreamStatusScheduled, queryOpts)
}

func (s *liveStreamService) GetHostStreams(ctx context.Context, hostID string, page, limit int) (*repository.PaginatedResult[*LiveStream], error) {
	queryOpts := repository.QueryOptions{
		Page:  page,
		Limit: limit,
	}

	return s.streamRepo.FindByHostID(ctx, hostID, queryOpts)
}

func (s *liveStreamService) SearchStreams(ctx context.Context, query string, page, limit int) (*repository.PaginatedResult[*LiveStream], error) {
	queryOpts := repository.QueryOptions{
		Page:  page,
		Limit: limit,
	}

	return s.streamRepo.SearchStreams(ctx, query, queryOpts)
}

// ============================================================================
// Viewer Management
// ============================================================================

func (s *liveStreamService) JoinStream(ctx context.Context, streamID, userID, username string) (*JoinStreamResponse, error) {
	// Get stream
	stream, err := s.streamRepo.FindByID(ctx, streamID)
	if err != nil {
		return nil, err
	}

	// Only allow joining live streams
	if stream.Status != LiveStreamStatusLive {
		return nil, fmt.Errorf("stream is not live")
	}

	// Check if viewer already joined
	existing, err := s.viewerRepo.FindActiveViewer(ctx, streamID, userID)
	if err == nil && existing != nil {
		// User already joined, return existing session
		return &JoinStreamResponse{
			Stream:      s.mapStreamToResponse(stream),
			ChannelName: stream.ChannelName,
			Token:       existing.Token,
			UID:         existing.UID,
			AppID:       config.Agora.AppID,
		}, nil
	}

	// Create viewer session
	userObjID, _ := primitive.ObjectIDFromHex(userID)
	streamObjID, _ := primitive.ObjectIDFromHex(streamID)

	viewer := &LiveStreamViewer{
		StreamID: streamObjID,
		UserID:   userObjID,
		Username: username,
		UID:      config.GenerateUID(userID),
	}

	// Generate viewer token
	token, err := config.GenerateRTCToken(
		stream.ChannelName,
		viewer.UID,
		config.RoleAttendee,
		config.Agora.ViewerTokenExpiry,
	)
	if err != nil {
		return nil, fmt.Errorf("failed to generate viewer token: %w", err)
	}
	viewer.Token = token

	// Save viewer
	viewer, err = s.viewerRepo.Create(ctx, viewer)
	if err != nil {
		return nil, fmt.Errorf("failed to create viewer session: %w", err)
	}

	// Increment total views (unique viewers)
	_ = s.streamRepo.IncrementStats(ctx, streamID, "totalViews", 1)

	// Update current viewer count
	_ = s.UpdateViewerCount(ctx, streamID)

	utils.Info("User joined livestream", map[string]interface{}{
		"stream_id": streamID,
		"user_id":   userID,
	})

	return &JoinStreamResponse{
		Stream:      s.mapStreamToResponse(stream),
		ChannelName: stream.ChannelName,
		Token:       token,
		UID:         viewer.UID,
		AppID:       config.Agora.AppID,
	}, nil
}

func (s *liveStreamService) LeaveStream(ctx context.Context, streamID, userID string) error {
	// Find active viewer
	viewer, err := s.viewerRepo.FindActiveViewer(ctx, streamID, userID)
	if err != nil {
		return err
	}

	// Mark as left
	if err := s.viewerRepo.MarkViewerLeft(ctx, viewer.ID.Hex()); err != nil {
		return err
	}

	// Update viewer count
	_ = s.UpdateViewerCount(ctx, streamID)

	utils.Info("User left livestream", map[string]interface{}{
		"stream_id": streamID,
		"user_id":   userID,
	})

	return nil
}

func (s *liveStreamService) GetStreamViewers(ctx context.Context, streamID string) ([]*LiveStreamViewer, error) {
	return s.viewerRepo.FindByStreamID(ctx, streamID)
}

func (s *liveStreamService) GetViewerCount(ctx context.Context, streamID string) (int64, error) {
	return s.viewerRepo.CountActiveViewers(ctx, streamID)
}

func (s *liveStreamService) UpdateViewerCount(ctx context.Context, streamID string) error {
	count, err := s.viewerRepo.CountActiveViewers(ctx, streamID)
	if err != nil {
		return err
	}

	return s.streamRepo.UpdateViewerCount(ctx, streamID, int(count))
}

// ============================================================================
// Chat Management
// ============================================================================

func (s *liveStreamService) SendChatMessage(ctx context.Context, streamID, userID, username, avatarURL, message string) (*ChatMessage, error) {
	// Verify stream exists and is live
	stream, err := s.streamRepo.FindByID(ctx, streamID)
	if err != nil {
		return nil, err
	}

	if stream.Status != LiveStreamStatusLive {
		return nil, fmt.Errorf("stream is not live")
	}

	// Verify user is viewing the stream
	_, err = s.viewerRepo.FindActiveViewer(ctx, streamID, userID)
	if err != nil {
		return nil, fmt.Errorf("user is not viewing this stream")
	}

	// Create message
	userObjID, _ := primitive.ObjectIDFromHex(userID)
	streamObjID, _ := primitive.ObjectIDFromHex(streamID)

	chatMsg := &ChatMessage{
		StreamID:  streamObjID,
		UserID:    userObjID,
		Username:  username,
		AvatarURL: avatarURL,
		Message:   message,
	}

	chatMsg, err = s.chatRepo.Create(ctx, chatMsg)
	if err != nil {
		return nil, fmt.Errorf("failed to send chat message: %w", err)
	}

	// Increment message count
	_ = s.streamRepo.IncrementStats(ctx, streamID, "messageCount", 1)

	return chatMsg, nil
}

func (s *liveStreamService) GetChatMessages(ctx context.Context, streamID string, page, limit int) (*repository.PaginatedResult[*ChatMessage], error) {
	queryOpts := repository.QueryOptions{
		Page:  page,
		Limit: limit,
	}

	return s.chatRepo.FindByStreamID(ctx, streamID, queryOpts)
}

func (s *liveStreamService) DeleteChatMessage(ctx context.Context, messageID, userID string) error {
	// Get message
	msg, err := s.chatRepo.FindByID(ctx, messageID)
	if err != nil {
		return err
	}

	// Get stream
	stream, err := s.streamRepo.FindByID(ctx, msg.StreamID.Hex())
	if err != nil {
		return err
	}

	// Only message author or stream host can delete
	if msg.UserID.Hex() != userID && stream.HostID.Hex() != userID {
		return fmt.Errorf("only message author or stream host can delete messages")
	}

	return s.chatRepo.SoftDelete(ctx, messageID)
}

func (s *liveStreamService) PinChatMessage(ctx context.Context, messageID, streamID, userID string, pinned bool) error {
	// Get stream
	stream, err := s.streamRepo.FindByID(ctx, streamID)
	if err != nil {
		return err
	}

	// Only host can pin messages
	if stream.HostID.Hex() != userID {
		return fmt.Errorf("only stream host can pin messages")
	}

	return s.chatRepo.PinMessage(ctx, messageID, pinned)
}

// ============================================================================
// Reactions
// ============================================================================

func (s *liveStreamService) SendReaction(ctx context.Context, streamID, userID, reactionType string) (*StreamReaction, error) {
	// Verify stream is live
	stream, err := s.streamRepo.FindByID(ctx, streamID)
	if err != nil {
		return nil, err
	}

	if stream.Status != LiveStreamStatusLive {
		return nil, fmt.Errorf("stream is not live")
	}

	// Create reaction
	userObjID, _ := primitive.ObjectIDFromHex(userID)
	streamObjID, _ := primitive.ObjectIDFromHex(streamID)

	reaction := &StreamReaction{
		StreamID: streamObjID,
		UserID:   userObjID,
		Type:     reactionType,
	}

	reaction, err = s.reactionRepo.Create(ctx, reaction)
	if err != nil {
		return nil, err
	}

	// Increment reaction count
	_ = s.streamRepo.IncrementStats(ctx, streamID, "reactionCount", 1)

	return reaction, nil
}

func (s *liveStreamService) GetRecentReactions(ctx context.Context, streamID string, since time.Time) ([]*StreamReaction, error) {
	return s.reactionRepo.FindRecentReactions(ctx, streamID, since)
}

// ============================================================================
// Statistics
// ============================================================================

func (s *liveStreamService) GetStreamStats(ctx context.Context, streamID string) (*StreamStatsResponse, error) {
	stream, err := s.streamRepo.FindByID(ctx, streamID)
	if err != nil {
		return nil, err
	}

	duration := 0
	if stream.StartedAt != nil {
		end := time.Now()
		if stream.EndedAt != nil {
			end = *stream.EndedAt
		}
		duration = int(end.Sub(*stream.StartedAt).Seconds())
	}

	return &StreamStatsResponse{
		StreamID:       streamID,
		CurrentViewers: stream.ViewerCount,
		PeakViewers:    stream.PeakViewers,
		TotalViews:     stream.TotalViews,
		ReactionCount:  stream.ReactionCount,
		MessageCount:   stream.MessageCount,
		Duration:       duration,
	}, nil
}

// ============================================================================
// Helper Methods
// ============================================================================

func (s *liveStreamService) mapStreamToResponse(stream *LiveStream) LiveStreamResponse {
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
