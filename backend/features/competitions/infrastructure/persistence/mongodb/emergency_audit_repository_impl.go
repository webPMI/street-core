package mongodb

import (
	"context"
	"log"
	"sync"
	"time"

	"backend/features/competitions/domain/entities"
	"backend/features/competitions/domain/repositories"

	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/bson/primitive"
	"go.mongodb.org/mongo-driver/mongo"
	"go.mongodb.org/mongo-driver/mongo/options"
	"go.mongodb.org/mongo-driver/mongo/writeconcern"
)

// emergencyAuditRepositoryImpl implements EmergencyAuditRepository with optimized writes
// OPTIMIZATION STRATEGY:
// 1. Write Concern w:1 (fast, accepts write when received by primary)
// 2. Async buffer for fire-and-forget writes
// 3. Batch inserts when buffer reaches threshold
// 4. Separate connection pool to avoid blocking competition queries
type emergencyAuditRepositoryImpl struct {
	actionsCollection    *mongo.Collection
	broadcastsCollection *mongo.Collection

	// Async write buffer (for zero-latency writes)
	asyncBuffer     chan *entities.EmergencyAction
	asyncBufferSize int
	flushInterval   time.Duration
	mu              sync.Mutex
	wg              sync.WaitGroup
}

// NewEmergencyAuditRepository creates a new optimized emergency audit repository
//
// PERFORMANCE OPTIMIZATIONS:
// - Write Concern: w:1 (primary acknowledgment only, ~1-5ms latency)
// - Async Buffer: 100 actions buffered, flushed every 500ms or when full
// - Batch Writes: Up to 100 actions written in a single batch operation
// - Dedicated Collections: emergency_actions, emergency_broadcasts
//
// Collections:
// - emergency_actions: Stores audit logs with before/after state (JSON)
// - emergency_broadcasts: Stores broadcast messages
func NewEmergencyAuditRepository(db *mongo.Database) repositories.EmergencyAuditRepository {
	// OPTIMIZATION: Use write concern w:1 for fastest writes
	// w:1 = primary acknowledgment (default behavior, but explicit for clarity)
	// This provides ~1-5ms write latency vs w:majority (~10-50ms)
	wc := writeconcern.New(writeconcern.W(1))

	actionsCollection := db.Collection("emergency_actions",
		options.Collection().SetWriteConcern(wc))
	broadcastsCollection := db.Collection("emergency_broadcasts",
		options.Collection().SetWriteConcern(wc))

	repo := &emergencyAuditRepositoryImpl{
		actionsCollection:    actionsCollection,
		broadcastsCollection: broadcastsCollection,
		asyncBufferSize:      100,              // Buffer up to 100 actions
		flushInterval:        500 * time.Millisecond, // Flush every 500ms
		asyncBuffer:          make(chan *entities.EmergencyAction, 100),
	}

	// Start async flush worker
	repo.startAsyncFlushWorker()

	return repo
}

// startAsyncFlushWorker starts a background worker that flushes buffered writes
// This provides fire-and-forget writes with zero latency for emergency actions
func (r *emergencyAuditRepositoryImpl) startAsyncFlushWorker() {
	r.wg.Add(1)
	go func() {
		defer r.wg.Done()
		ticker := time.NewTicker(r.flushInterval)
		defer ticker.Stop()

		buffer := make([]*entities.EmergencyAction, 0, r.asyncBufferSize)

		flush := func() {
			if len(buffer) == 0 {
				return
			}

			// OPTIMIZATION: Batch insert for better performance
			ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
			defer cancel()

			documents := make([]interface{}, len(buffer))
			for i, action := range buffer {
				documents[i] = action
			}

			_, err := r.actionsCollection.InsertMany(ctx, documents)
			if err != nil {
				log.Printf("ERROR: Failed to flush emergency actions buffer: %v", err)
				// TODO: Implement retry mechanism or dead letter queue
			} else {
				log.Printf("INFO: Flushed %d emergency actions to database", len(buffer))
			}

			buffer = buffer[:0] // Clear buffer
		}

		for {
			select {
			case action, ok := <-r.asyncBuffer:
				if !ok {
					flush() // Final flush before shutdown
					return
				}
				buffer = append(buffer, action)

				// Flush immediately if buffer is full
				if len(buffer) >= r.asyncBufferSize {
					flush()
				}

			case <-ticker.C:
				// Periodic flush
				flush()
			}
		}
	}()
}

// Close gracefully shuts down the async flush worker
func (r *emergencyAuditRepositoryImpl) Close() {
	close(r.asyncBuffer)
	r.wg.Wait()
}

// Create creates a new emergency action with FAST synchronous write
// Uses w:1 write concern for minimal latency (~1-5ms)
func (r *emergencyAuditRepositoryImpl) Create(ctx context.Context, action *entities.EmergencyAction) error {
	// Set timestamps
	now := time.Now()
	action.CreatedAt = now
	action.UpdatedAt = now
	action.InitiatedAt = now

	// Initialize maps if nil
	if action.StateBefore == nil {
		action.StateBefore = make(map[string]interface{})
	}
	if action.StateAfter == nil {
		action.StateAfter = make(map[string]interface{})
	}
	if action.Metadata == nil {
		action.Metadata = make(map[string]interface{})
	}

	// Validate before insert
	if err := action.Validate(); err != nil {
		return err
	}

	// OPTIMIZATION: Direct insert with w:1 write concern
	// This returns immediately after primary acknowledgment
	_, err := r.actionsCollection.InsertOne(ctx, action)
	return err
}

// CreateAsync creates an emergency action asynchronously (ZERO LATENCY)
// This is a fire-and-forget operation that returns immediately
// The action is buffered and flushed to DB in batches
//
// USE CASE: During active emergencies when you can't afford ANY latency
func (r *emergencyAuditRepositoryImpl) CreateAsync(action *entities.EmergencyAction) error {
	// Set timestamps
	now := time.Now()
	action.CreatedAt = now
	action.UpdatedAt = now
	action.InitiatedAt = now

	// Initialize maps if nil
	if action.StateBefore == nil {
		action.StateBefore = make(map[string]interface{})
	}
	if action.StateAfter == nil {
		action.StateAfter = make(map[string]interface{})
	}
	if action.Metadata == nil {
		action.Metadata = make(map[string]interface{})
	}

	// Validate before buffering
	if err := action.Validate(); err != nil {
		return err
	}

	// Non-blocking send to buffer
	select {
	case r.asyncBuffer <- action:
		return nil
	default:
		// Buffer full - fall back to synchronous write
		log.Printf("WARNING: Async buffer full, falling back to synchronous write")
		ctx, cancel := context.WithTimeout(context.Background(), 2*time.Second)
		defer cancel()
		return r.Create(ctx, action)
	}
}

// Update updates an existing emergency action
func (r *emergencyAuditRepositoryImpl) Update(ctx context.Context, action *entities.EmergencyAction) error {
	action.UpdatedAt = time.Now()

	filter := bson.M{"_id": action.ID}
	update := bson.M{"$set": action}

	result, err := r.actionsCollection.UpdateOne(ctx, filter, update)
	if err != nil {
		return err
	}

	if result.MatchedCount == 0 {
		return mongo.ErrNoDocuments
	}

	return nil
}

// CreateBroadcast creates a new emergency broadcast
func (r *emergencyAuditRepositoryImpl) CreateBroadcast(ctx context.Context, broadcast *entities.EmergencyBroadcast) error {
	now := time.Now()
	broadcast.CreatedAt = now
	broadcast.UpdatedAt = now
	broadcast.SentAt = now

	// Initialize arrays if nil
	if broadcast.AcknowledgedBy == nil {
		broadcast.AcknowledgedBy = []primitive.ObjectID{}
	}
	if broadcast.AcknowledgedAt == nil {
		broadcast.AcknowledgedAt = make(map[string]time.Time)
	}

	// Validate before insert
	if err := broadcast.Validate(); err != nil {
		return err
	}

	_, err := r.broadcastsCollection.InsertOne(ctx, broadcast)
	return err
}

// FindByID finds an emergency action by ID
func (r *emergencyAuditRepositoryImpl) FindByID(ctx context.Context, id primitive.ObjectID) (*entities.EmergencyAction, error) {
	var action entities.EmergencyAction
	err := r.actionsCollection.FindOne(ctx, bson.M{"_id": id}).Decode(&action)
	if err != nil {
		return nil, err
	}
	return &action, nil
}

// FindByCompetition finds all emergency actions for a competition
// OPTIMIZATION: Uses compound index {competitionId: 1, createdAt: -1}
func (r *emergencyAuditRepositoryImpl) FindByCompetition(
	ctx context.Context,
	competitionID primitive.ObjectID,
	limit int,
) ([]*entities.EmergencyAction, error) {
	filter := bson.M{"competitionId": competitionID}
	opts := options.Find().
		SetSort(bson.D{{Key: "createdAt", Value: -1}})

	if limit > 0 {
		opts.SetLimit(int64(limit))
	}

	cursor, err := r.actionsCollection.Find(ctx, filter, opts)
	if err != nil {
		return nil, err
	}
	defer cursor.Close(ctx)

	var actions []*entities.EmergencyAction
	if err := cursor.All(ctx, &actions); err != nil {
		return nil, err
	}

	return actions, nil
}

// FindByHeat finds all emergency actions for a heat
// OPTIMIZATION: Uses index {heatId: 1}
func (r *emergencyAuditRepositoryImpl) FindByHeat(
	ctx context.Context,
	heatID primitive.ObjectID,
	limit int,
) ([]*entities.EmergencyAction, error) {
	filter := bson.M{"heatId": heatID}
	opts := options.Find().
		SetSort(bson.D{{Key: "createdAt", Value: -1}})

	if limit > 0 {
		opts.SetLimit(int64(limit))
	}

	cursor, err := r.actionsCollection.Find(ctx, filter, opts)
	if err != nil {
		return nil, err
	}
	defer cursor.Close(ctx)

	var actions []*entities.EmergencyAction
	if err := cursor.All(ctx, &actions); err != nil {
		return nil, err
	}

	return actions, nil
}

// FindByActionType finds emergency actions by type
// OPTIMIZATION: Uses compound index {actionType: 1, competitionId: 1, createdAt: -1}
func (r *emergencyAuditRepositoryImpl) FindByActionType(
	ctx context.Context,
	competitionID primitive.ObjectID,
	actionType string,
	limit int,
) ([]*entities.EmergencyAction, error) {
	filter := bson.M{
		"competitionId": competitionID,
		"actionType":    actionType,
	}
	opts := options.Find().
		SetSort(bson.D{{Key: "createdAt", Value: -1}})

	if limit > 0 {
		opts.SetLimit(int64(limit))
	}

	cursor, err := r.actionsCollection.Find(ctx, filter, opts)
	if err != nil {
		return nil, err
	}
	defer cursor.Close(ctx)

	var actions []*entities.EmergencyAction
	if err := cursor.All(ctx, &actions); err != nil {
		return nil, err
	}

	return actions, nil
}

// FindUnresolved finds all unresolved emergency actions
// OPTIMIZATION: Uses compound index {competitionId: 1, status: 1}
func (r *emergencyAuditRepositoryImpl) FindUnresolved(
	ctx context.Context,
	competitionID primitive.ObjectID,
) ([]*entities.EmergencyAction, error) {
	filter := bson.M{
		"competitionId": competitionID,
		"status":        bson.M{"$in": []string{entities.ActionStatusPending, entities.ActionStatusApplied}},
	}
	opts := options.Find().
		SetSort(bson.D{{Key: "createdAt", Value: -1}})

	cursor, err := r.actionsCollection.Find(ctx, filter, opts)
	if err != nil {
		return nil, err
	}
	defer cursor.Close(ctx)

	var actions []*entities.EmergencyAction
	if err := cursor.All(ctx, &actions); err != nil {
		return nil, err
	}

	return actions, nil
}

// GetBroadcastByID finds a broadcast by ID
func (r *emergencyAuditRepositoryImpl) GetBroadcastByID(
	ctx context.Context,
	id primitive.ObjectID,
) (*entities.EmergencyBroadcast, error) {
	var broadcast entities.EmergencyBroadcast
	err := r.broadcastsCollection.FindOne(ctx, bson.M{"_id": id}).Decode(&broadcast)
	if err != nil {
		return nil, err
	}
	return &broadcast, nil
}

// GetActiveBroadcasts finds all active broadcasts for a competition
// OPTIMIZATION: Uses compound index {competitionId: 1, sentAt: -1}
func (r *emergencyAuditRepositoryImpl) GetActiveBroadcasts(
	ctx context.Context,
	competitionID primitive.ObjectID,
) ([]*entities.EmergencyBroadcast, error) {
	now := time.Now()
	filter := bson.M{
		"competitionId": competitionID,
		"$or": []bson.M{
			{"expiresAt": nil},
			{"expiresAt": bson.M{"$gt": now}},
		},
	}
	opts := options.Find().
		SetSort(bson.D{{Key: "sentAt", Value: -1}})

	cursor, err := r.broadcastsCollection.Find(ctx, filter, opts)
	if err != nil {
		return nil, err
	}
	defer cursor.Close(ctx)

	var broadcasts []*entities.EmergencyBroadcast
	if err := cursor.All(ctx, &broadcasts); err != nil {
		return nil, err
	}

	return broadcasts, nil
}

// AcknowledgeBroadcast marks a broadcast as acknowledged by a user
// OPTIMIZATION: Uses $addToSet to prevent duplicates in a single operation
func (r *emergencyAuditRepositoryImpl) AcknowledgeBroadcast(
	ctx context.Context,
	broadcastID, userID primitive.ObjectID,
) error {
	filter := bson.M{"_id": broadcastID}
	update := bson.M{
		"$addToSet": bson.M{
			"acknowledgedBy": userID,
		},
		"$set": bson.M{
			"acknowledgedAt." + userID.Hex(): time.Now(),
			"updatedAt":                      time.Now(),
		},
	}

	result, err := r.broadcastsCollection.UpdateOne(ctx, filter, update)
	if err != nil {
		return err
	}

	if result.MatchedCount == 0 {
		return mongo.ErrNoDocuments
	}

	return nil
}
