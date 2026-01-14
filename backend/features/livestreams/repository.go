package livestreams

import (
	"context"
	"time"

	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/bson/primitive"
	"go.mongodb.org/mongo-driver/mongo"
	"go.mongodb.org/mongo-driver/mongo/options"

	"backend/pkg/repository"
)

// ============================================================================
// Model Interface Implementation
// ============================================================================

// LiveStream Model interface implementation
func (l *LiveStream) GetID() primitive.ObjectID {
	return l.ID
}

func (l *LiveStream) SetID(id primitive.ObjectID) {
	l.ID = id
}

func (l *LiveStream) SetTimestamps() {
	now := time.Now()
	if l.CreatedAt.IsZero() {
		l.CreatedAt = now
	}
	l.UpdatedAt = now
}

// LiveStreamViewer Model interface implementation
func (v *LiveStreamViewer) GetID() primitive.ObjectID {
	return v.ID
}

func (v *LiveStreamViewer) SetID(id primitive.ObjectID) {
	v.ID = id
}

func (v *LiveStreamViewer) SetTimestamps() {
	// Viewers use JoinedAt instead of created/updated
	if v.JoinedAt == nil {
		now := time.Now()
		v.JoinedAt = &now
	}
}

// ChatMessage Model interface implementation
func (m *ChatMessage) GetID() primitive.ObjectID {
	return m.ID
}

func (m *ChatMessage) SetID(id primitive.ObjectID) {
	m.ID = id
}

func (m *ChatMessage) SetTimestamps() {
	if m.CreatedAt.IsZero() {
		m.CreatedAt = time.Now()
	}
}

// StreamReaction Model interface implementation
func (r *StreamReaction) GetID() primitive.ObjectID {
	return r.ID
}

func (r *StreamReaction) SetID(id primitive.ObjectID) {
	r.ID = id
}

func (r *StreamReaction) SetTimestamps() {
	if r.CreatedAt.IsZero() {
		r.CreatedAt = time.Now()
	}
}

// ============================================================================
// LiveStream Repository
// ============================================================================

type LiveStreamRepository struct {
	*repository.BaseRepository[*LiveStream]
}

func NewLiveStreamRepository(db *mongo.Database) *LiveStreamRepository {
	return &LiveStreamRepository{
		BaseRepository: repository.NewBaseRepository[*LiveStream](db, LiveStreamsCollection),
	}
}

// FindLiveStreams finds all currently live streams
func (r *LiveStreamRepository) FindLiveStreams(ctx context.Context, limit int) ([]*LiveStream, error) {
	filter := bson.M{"status": LiveStreamStatusLive}
	opts := options.Find().
		SetSort(bson.D{{Key: "viewerCount", Value: -1}}). // Sort by viewer count
		SetLimit(int64(limit))

	return r.FindMany(ctx, filter, opts)
}

// FindScheduledStreams finds streams scheduled for the future
func (r *LiveStreamRepository) FindScheduledStreams(ctx context.Context, limit int) ([]*LiveStream, error) {
	filter := bson.M{
		"status": LiveStreamStatusScheduled,
		"scheduledTime": bson.M{
			"$gte": time.Now(),
		},
	}
	opts := options.Find().
		SetSort(bson.D{{Key: "scheduledTime", Value: 1}}). // Earliest first
		SetLimit(int64(limit))

	return r.FindMany(ctx, filter, opts)
}

// FindByHostID finds all streams by a specific host
func (r *LiveStreamRepository) FindByHostID(ctx context.Context, hostID string, queryOpts repository.QueryOptions) (*repository.PaginatedResult[*LiveStream], error) {
	objectID, err := primitive.ObjectIDFromHex(hostID)
	if err != nil {
		return nil, repository.ErrInvalidID
	}

	if queryOpts.Filter == nil {
		queryOpts.Filter = bson.M{}
	}
	queryOpts.Filter["hostId"] = objectID

	// Default sort by creation date (newest first)
	if queryOpts.SortField == "" {
		queryOpts.SortField = "createdAt"
		queryOpts.SortOrder = -1
	}

	return r.FindPaginated(ctx, queryOpts)
}

// FindByStatus finds streams by status
func (r *LiveStreamRepository) FindByStatus(ctx context.Context, status LiveStreamStatus, queryOpts repository.QueryOptions) (*repository.PaginatedResult[*LiveStream], error) {
	if queryOpts.Filter == nil {
		queryOpts.Filter = bson.M{}
	}
	queryOpts.Filter["status"] = status

	return r.FindPaginated(ctx, queryOpts)
}

// UpdateStatus updates only the stream status
func (r *LiveStreamRepository) UpdateStatus(ctx context.Context, streamID string, status LiveStreamStatus) error {
	update := bson.M{
		"$set": bson.M{
			"status": status,
		},
	}

	// Add timestamp based on status
	switch status {
	case LiveStreamStatusLive:
		now := time.Now()
		update["$set"].(bson.M)["startedAt"] = now
	case LiveStreamStatusEnded, LiveStreamStatusCancelled:
		now := time.Now()
		update["$set"].(bson.M)["endedAt"] = now
	}

	return r.UpdateByID(ctx, streamID, update)
}

// UpdateViewerCount updates the current viewer count
func (r *LiveStreamRepository) UpdateViewerCount(ctx context.Context, streamID string, count int) error {
	update := bson.M{
		"$set": bson.M{
			"viewerCount": count,
		},
	}

	// Also update peak viewers if current count is higher
	objectID, err := primitive.ObjectIDFromHex(streamID)
	if err != nil {
		return repository.ErrInvalidID
	}

	stream, err := r.FindByID(ctx, streamID)
	if err != nil {
		return err
	}

	if count > stream.PeakViewers {
		update["$set"].(bson.M)["peakViewers"] = count
	}

	result, err := r.GetCollection().UpdateOne(
		ctx,
		bson.M{"_id": objectID},
		update,
	)
	if err != nil {
		return err
	}

	if result.MatchedCount == 0 {
		return repository.ErrNotFound
	}

	return nil
}

// IncrementStats increments various counters atomically
func (r *LiveStreamRepository) IncrementStats(ctx context.Context, streamID string, field string, increment int) error {
	objectID, err := primitive.ObjectIDFromHex(streamID)
	if err != nil {
		return repository.ErrInvalidID
	}

	update := bson.M{
		"$inc": bson.M{
			field: increment,
		},
		"$set": bson.M{
			"updatedAt": time.Now(),
		},
	}

	result, err := r.GetCollection().UpdateOne(
		ctx,
		bson.M{"_id": objectID},
		update,
	)
	if err != nil {
		return err
	}

	if result.MatchedCount == 0 {
		return repository.ErrNotFound
	}

	return nil
}

// SearchStreams searches streams by title, description, or tags
func (r *LiveStreamRepository) SearchStreams(ctx context.Context, query string, queryOpts repository.QueryOptions) (*repository.PaginatedResult[*LiveStream], error) {
	if queryOpts.Filter == nil {
		queryOpts.Filter = bson.M{}
	}

	// Text search using regex
	queryOpts.Filter["$or"] = []bson.M{
		{"title": bson.M{"$regex": query, "$options": "i"}},
		{"description": bson.M{"$regex": query, "$options": "i"}},
		{"tags": bson.M{"$in": []string{query}}},
	}

	return r.FindPaginated(ctx, queryOpts)
}

// ============================================================================
// Viewer Repository
// ============================================================================

type ViewerRepository struct {
	*repository.BaseRepository[*LiveStreamViewer]
}

func NewViewerRepository(db *mongo.Database) *ViewerRepository {
	return &ViewerRepository{
		BaseRepository: repository.NewBaseRepository[*LiveStreamViewer](db, ViewersCollection),
	}
}

// FindByStreamID finds all viewers for a stream
func (r *ViewerRepository) FindByStreamID(ctx context.Context, streamID string) ([]*LiveStreamViewer, error) {
	objectID, err := primitive.ObjectIDFromHex(streamID)
	if err != nil {
		return nil, repository.ErrInvalidID
	}

	filter := bson.M{
		"streamId": objectID,
		"leftAt":   nil, // Only active viewers
	}

	return r.FindMany(ctx, filter)
}

// FindActiveViewer finds an active viewer session
func (r *ViewerRepository) FindActiveViewer(ctx context.Context, streamID, userID string) (*LiveStreamViewer, error) {
	streamObjID, err := primitive.ObjectIDFromHex(streamID)
	if err != nil {
		return nil, repository.ErrInvalidID
	}

	userObjID, err := primitive.ObjectIDFromHex(userID)
	if err != nil {
		return nil, repository.ErrInvalidID
	}

	filter := bson.M{
		"streamId": streamObjID,
		"userId":   userObjID,
		"leftAt":   nil,
	}

	return r.FindOne(ctx, filter)
}

// MarkViewerLeft marks a viewer as having left the stream
func (r *ViewerRepository) MarkViewerLeft(ctx context.Context, viewerID string) error {
	now := time.Now()

	// Get viewer to calculate duration
	viewer, err := r.FindByID(ctx, viewerID)
	if err != nil {
		return err
	}

	duration := 0
	if viewer.JoinedAt != nil {
		duration = int(now.Sub(*viewer.JoinedAt).Seconds())
	}

	update := bson.M{
		"$set": bson.M{
			"leftAt":   now,
			"duration": duration,
		},
	}

	return r.UpdateByID(ctx, viewerID, update)
}

// CountActiveViewers counts currently active viewers for a stream
func (r *ViewerRepository) CountActiveViewers(ctx context.Context, streamID string) (int64, error) {
	objectID, err := primitive.ObjectIDFromHex(streamID)
	if err != nil {
		return 0, repository.ErrInvalidID
	}

	filter := bson.M{
		"streamId": objectID,
		"leftAt":   nil,
	}

	return r.Count(ctx, filter)
}

// GetViewerHistory gets all viewer sessions for a stream (including past)
func (r *ViewerRepository) GetViewerHistory(ctx context.Context, streamID string, queryOpts repository.QueryOptions) (*repository.PaginatedResult[*LiveStreamViewer], error) {
	objectID, err := primitive.ObjectIDFromHex(streamID)
	if err != nil {
		return nil, repository.ErrInvalidID
	}

	if queryOpts.Filter == nil {
		queryOpts.Filter = bson.M{}
	}
	queryOpts.Filter["streamId"] = objectID

	// Sort by joined time (most recent first)
	if queryOpts.SortField == "" {
		queryOpts.SortField = "joinedAt"
		queryOpts.SortOrder = -1
	}

	return r.FindPaginated(ctx, queryOpts)
}

// ============================================================================
// Chat Message Repository
// ============================================================================

type ChatMessageRepository struct {
	*repository.BaseRepository[*ChatMessage]
}

func NewChatMessageRepository(db *mongo.Database) *ChatMessageRepository {
	return &ChatMessageRepository{
		BaseRepository: repository.NewBaseRepository[*ChatMessage](db, ChatMessagesCollection),
	}
}

// FindByStreamID finds chat messages for a stream
func (r *ChatMessageRepository) FindByStreamID(ctx context.Context, streamID string, queryOpts repository.QueryOptions) (*repository.PaginatedResult[*ChatMessage], error) {
	objectID, err := primitive.ObjectIDFromHex(streamID)
	if err != nil {
		return nil, repository.ErrInvalidID
	}

	if queryOpts.Filter == nil {
		queryOpts.Filter = bson.M{}
	}
	queryOpts.Filter["streamId"] = objectID
	queryOpts.Filter["isDeleted"] = false // Don't show deleted messages

	// Sort by creation time (newest first for pagination, reverse in UI)
	if queryOpts.SortField == "" {
		queryOpts.SortField = "createdAt"
		queryOpts.SortOrder = -1
	}

	return r.FindPaginated(ctx, queryOpts)
}

// FindRecentMessages finds the most recent messages for a stream
func (r *ChatMessageRepository) FindRecentMessages(ctx context.Context, streamID string, limit int) ([]*ChatMessage, error) {
	objectID, err := primitive.ObjectIDFromHex(streamID)
	if err != nil {
		return nil, repository.ErrInvalidID
	}

	filter := bson.M{
		"streamId":  objectID,
		"isDeleted": false,
	}

	opts := options.Find().
		SetSort(bson.D{{Key: "createdAt", Value: -1}}).
		SetLimit(int64(limit))

	messages, err := r.FindMany(ctx, filter, opts)
	if err != nil {
		return nil, err
	}

	// Reverse to show oldest first
	for i, j := 0, len(messages)-1; i < j; i, j = i+1, j-1 {
		messages[i], messages[j] = messages[j], messages[i]
	}

	return messages, nil
}

// SoftDelete marks a message as deleted without removing it
func (r *ChatMessageRepository) SoftDelete(ctx context.Context, messageID string) error {
	update := bson.M{
		"$set": bson.M{
			"isDeleted": true,
		},
	}

	return r.UpdateByID(ctx, messageID, update)
}

// PinMessage pins/unpins a message
func (r *ChatMessageRepository) PinMessage(ctx context.Context, messageID string, pinned bool) error {
	update := bson.M{
		"$set": bson.M{
			"isPinned": pinned,
		},
	}

	return r.UpdateByID(ctx, messageID, update)
}

// FindPinnedMessages finds all pinned messages for a stream
func (r *ChatMessageRepository) FindPinnedMessages(ctx context.Context, streamID string) ([]*ChatMessage, error) {
	objectID, err := primitive.ObjectIDFromHex(streamID)
	if err != nil {
		return nil, repository.ErrInvalidID
	}

	filter := bson.M{
		"streamId":  objectID,
		"isPinned":  true,
		"isDeleted": false,
	}

	opts := options.Find().SetSort(bson.D{{Key: "createdAt", Value: -1}})

	return r.FindMany(ctx, filter, opts)
}

// ============================================================================
// Reaction Repository
// ============================================================================

type ReactionRepository struct {
	*repository.BaseRepository[*StreamReaction]
}

func NewReactionRepository(db *mongo.Database) *ReactionRepository {
	return &ReactionRepository{
		BaseRepository: repository.NewBaseRepository[*StreamReaction](db, ReactionsCollection),
	}
}

// FindRecentReactions finds recent reactions for a stream
func (r *ReactionRepository) FindRecentReactions(ctx context.Context, streamID string, since time.Time) ([]*StreamReaction, error) {
	objectID, err := primitive.ObjectIDFromHex(streamID)
	if err != nil {
		return nil, repository.ErrInvalidID
	}

	filter := bson.M{
		"streamId": objectID,
		"createdAt": bson.M{
			"$gte": since,
		},
	}

	opts := options.Find().SetSort(bson.D{{Key: "createdAt", Value: -1}})

	return r.FindMany(ctx, filter, opts)
}

// CountReactionsByType counts reactions by type for a stream
func (r *ReactionRepository) CountReactionsByType(ctx context.Context, streamID string) (map[string]int64, error) {
	objectID, err := primitive.ObjectIDFromHex(streamID)
	if err != nil {
		return nil, repository.ErrInvalidID
	}

	pipeline := mongo.Pipeline{
		{{Key: "$match", Value: bson.M{"streamId": objectID}}},
		{{Key: "$group", Value: bson.M{
			"_id":   "$type",
			"count": bson.M{"$sum": 1},
		}}},
	}

	cursor, err := r.GetCollection().Aggregate(ctx, pipeline)
	if err != nil {
		return nil, err
	}
	defer cursor.Close(ctx)

	results := make(map[string]int64)
	for cursor.Next(ctx) {
		var result struct {
			Type  string `bson:"_id"`
			Count int64  `bson:"count"`
		}
		if err := cursor.Decode(&result); err != nil {
			return nil, err
		}
		results[result.Type] = result.Count
	}

	return results, nil
}

// DeleteOldReactions deletes reactions older than a certain time
func (r *ReactionRepository) DeleteOldReactions(ctx context.Context, before time.Time) (int64, error) {
	filter := bson.M{
		"createdAt": bson.M{
			"$lt": before,
		},
	}

	return r.DeleteMany(ctx, filter)
}
