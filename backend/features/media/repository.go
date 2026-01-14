package media

import (
	"context"
	"fmt"
	"time"

	"backend/models"
	"backend/utils"

	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/bson/primitive"
	"go.mongodb.org/mongo-driver/mongo"
	"go.mongodb.org/mongo-driver/mongo/options"
)

const mediaCollection = "media_files"

type mediaRepository struct {
	collection *mongo.Collection
}

// NewMediaRepository creates a new media repository instance
func NewMediaRepository(db *mongo.Database) IMediaRepository {
	repo := &mediaRepository{
		collection: db.Collection(mediaCollection),
	}
	repo.ensureIndexes()
	return repo
}

// ensureIndexes creates necessary indexes for the media collection
func (r *mediaRepository) ensureIndexes() {
	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()

	indexes := []mongo.IndexModel{
		{
			Keys:    bson.D{{Key: "userId", Value: 1}},
			Options: options.Index().SetBackground(true),
		},
		{
			Keys:    bson.D{{Key: "postId", Value: 1}},
			Options: options.Index().SetBackground(true).SetSparse(true),
		},
		{
			Keys:    bson.D{{Key: "hashSha256", Value: 1}},
			Options: options.Index().SetBackground(true).SetSparse(true),
		},
		{
			Keys:    bson.D{{Key: "status", Value: 1}},
			Options: options.Index().SetBackground(true),
		},
		{
			Keys:    bson.D{{Key: "createdAt", Value: -1}},
			Options: options.Index().SetBackground(true),
		},
		{
			Keys:    bson.D{{Key: "userId", Value: 1}, {Key: "createdAt", Value: -1}},
			Options: options.Index().SetBackground(true),
		},
	}

	_, err := r.collection.Indexes().CreateMany(ctx, indexes)
	if err != nil {
		utils.Warn("Failed to create media indexes", map[string]interface{}{
			"error": err.Error(),
		})
	}
}

// Create saves a new media file record
func (r *mediaRepository) Create(ctx context.Context, media *models.MediaFile) error {
	// Add defensive timeout
	ctx, cancel := context.WithTimeout(ctx, 5*time.Second)
	defer cancel()

	if media.ID.IsZero() {
		media.ID = primitive.NewObjectID()
	}
	media.SetDefaults()

	_, err := r.collection.InsertOne(ctx, media)
	if err != nil {
		return fmt.Errorf("failed to create media record: %w", err)
	}
	return nil
}

// GetByID retrieves a media file by its ID
func (r *mediaRepository) GetByID(ctx context.Context, id string) (*models.MediaFile, error) {
	// Add defensive timeout
	ctx, cancel := context.WithTimeout(ctx, 5*time.Second)
	defer cancel()

	objectID, err := primitive.ObjectIDFromHex(id)
	if err != nil {
		return nil, fmt.Errorf("invalid media ID: %w", err)
	}

	var media models.MediaFile
	err = r.collection.FindOne(ctx, bson.M{"_id": objectID}).Decode(&media)
	if err != nil {
		if err == mongo.ErrNoDocuments {
			return nil, fmt.Errorf("media not found")
		}
		return nil, fmt.Errorf("failed to get media: %w", err)
	}
	return &media, nil
}

// GetByUserID retrieves all media files for a user
func (r *mediaRepository) GetByUserID(ctx context.Context, userID string, limit, offset int) ([]*models.MediaFile, error) {
	// Add defensive timeout (longer for batch operations)
	ctx, cancel := context.WithTimeout(ctx, 10*time.Second)
	defer cancel()

	userObjID, err := primitive.ObjectIDFromHex(userID)
	if err != nil {
		return nil, fmt.Errorf("invalid user ID: %w", err)
	}

	opts := options.Find().
		SetSort(bson.D{{Key: "createdAt", Value: -1}}).
		SetLimit(int64(limit)).
		SetSkip(int64(offset))

	cursor, err := r.collection.Find(ctx, bson.M{"userId": userObjID}, opts)
	if err != nil {
		return nil, fmt.Errorf("failed to get user media: %w", err)
	}
	defer cursor.Close(ctx)

	var mediaFiles []*models.MediaFile
	if err := cursor.All(ctx, &mediaFiles); err != nil {
		return nil, fmt.Errorf("failed to decode media files: %w", err)
	}
	return mediaFiles, nil
}

// GetByPostID retrieves all media files associated with a post
func (r *mediaRepository) GetByPostID(ctx context.Context, postID string) ([]*models.MediaFile, error) {
	// Add defensive timeout
	ctx, cancel := context.WithTimeout(ctx, 10*time.Second)
	defer cancel()

	postObjID, err := primitive.ObjectIDFromHex(postID)
	if err != nil {
		return nil, fmt.Errorf("invalid post ID: %w", err)
	}

	cursor, err := r.collection.Find(ctx, bson.M{"postId": postObjID})
	if err != nil {
		return nil, fmt.Errorf("failed to get post media: %w", err)
	}
	defer cursor.Close(ctx)

	var mediaFiles []*models.MediaFile
	if err := cursor.All(ctx, &mediaFiles); err != nil {
		return nil, fmt.Errorf("failed to decode media files: %w", err)
	}
	return mediaFiles, nil
}

// GetByHash finds a media file by its SHA256 hash
func (r *mediaRepository) GetByHash(ctx context.Context, hash string) (*models.MediaFile, error) {
	// Add defensive timeout
	ctx, cancel := context.WithTimeout(ctx, 5*time.Second)
	defer cancel()

	var media models.MediaFile
	err := r.collection.FindOne(ctx, bson.M{"hashSha256": hash}).Decode(&media)
	if err != nil {
		if err == mongo.ErrNoDocuments {
			return nil, nil // Not found is not an error for deduplication
		}
		return nil, fmt.Errorf("failed to get media by hash: %w", err)
	}
	return &media, nil
}

// Update updates an existing media file record
func (r *mediaRepository) Update(ctx context.Context, media *models.MediaFile) error {
	// Add defensive timeout
	ctx, cancel := context.WithTimeout(ctx, 5*time.Second)
	defer cancel()

	media.UpdatedAt = time.Now()

	result, err := r.collection.ReplaceOne(ctx, bson.M{"_id": media.ID}, media)
	if err != nil {
		return fmt.Errorf("failed to update media: %w", err)
	}
	if result.MatchedCount == 0 {
		return fmt.Errorf("media not found")
	}
	return nil
}

// UpdateStatus updates the processing status of a media file
func (r *mediaRepository) UpdateStatus(ctx context.Context, id string, status models.MediaFileStatus, errorMsg string) error {
	// Add defensive timeout
	ctx, cancel := context.WithTimeout(ctx, 5*time.Second)
	defer cancel()

	objectID, err := primitive.ObjectIDFromHex(id)
	if err != nil {
		return fmt.Errorf("invalid media ID: %w", err)
	}

	update := bson.M{
		"$set": bson.M{
			"status":    status,
			"updatedAt": time.Now(),
		},
	}

	if errorMsg != "" {
		update["$set"].(bson.M)["processingError"] = errorMsg
	}

	result, err := r.collection.UpdateOne(ctx, bson.M{"_id": objectID}, update)
	if err != nil {
		return fmt.Errorf("failed to update media status: %w", err)
	}
	if result.MatchedCount == 0 {
		return fmt.Errorf("media not found")
	}
	return nil
}

// Delete removes a media file record
func (r *mediaRepository) Delete(ctx context.Context, id string) error {
	// Add defensive timeout
	ctx, cancel := context.WithTimeout(ctx, 5*time.Second)
	defer cancel()

	objectID, err := primitive.ObjectIDFromHex(id)
	if err != nil {
		return fmt.Errorf("invalid media ID: %w", err)
	}

	result, err := r.collection.DeleteOne(ctx, bson.M{"_id": objectID})
	if err != nil {
		return fmt.Errorf("failed to delete media: %w", err)
	}
	if result.DeletedCount == 0 {
		return fmt.Errorf("media not found")
	}
	return nil
}

// DeleteByUserID removes all media files for a user
func (r *mediaRepository) DeleteByUserID(ctx context.Context, userID string) error {
	// Add defensive timeout (longer for batch operation)
	ctx, cancel := context.WithTimeout(ctx, 10*time.Second)
	defer cancel()

	userObjID, err := primitive.ObjectIDFromHex(userID)
	if err != nil {
		return fmt.Errorf("invalid user ID: %w", err)
	}

	_, err = r.collection.DeleteMany(ctx, bson.M{"userId": userObjID})
	if err != nil {
		return fmt.Errorf("failed to delete user media: %w", err)
	}
	return nil
}

// CountByUserID counts total media files for a user
func (r *mediaRepository) CountByUserID(ctx context.Context, userID string) (int64, error) {
	// Add defensive timeout
	ctx, cancel := context.WithTimeout(ctx, 5*time.Second)
	defer cancel()

	userObjID, err := primitive.ObjectIDFromHex(userID)
	if err != nil {
		return 0, fmt.Errorf("invalid user ID: %w", err)
	}

	count, err := r.collection.CountDocuments(ctx, bson.M{"userId": userObjID})
	if err != nil {
		return 0, fmt.Errorf("failed to count user media: %w", err)
	}
	return count, nil
}

// GetPendingFiles retrieves files with pending status for processing
func (r *mediaRepository) GetPendingFiles(ctx context.Context, limit int) ([]*models.MediaFile, error) {
	// Add defensive timeout
	ctx, cancel := context.WithTimeout(ctx, 10*time.Second)
	defer cancel()

	opts := options.Find().
		SetSort(bson.D{{Key: "createdAt", Value: 1}}).
		SetLimit(int64(limit))

	cursor, err := r.collection.Find(ctx, bson.M{"status": models.MediaFileStatusPending}, opts)
	if err != nil {
		return nil, fmt.Errorf("failed to get pending files: %w", err)
	}
	defer cursor.Close(ctx)

	var mediaFiles []*models.MediaFile
	if err := cursor.All(ctx, &mediaFiles); err != nil {
		return nil, fmt.Errorf("failed to decode pending files: %w", err)
	}
	return mediaFiles, nil
}

// AssociateWithPost links a media file to a post
func (r *mediaRepository) AssociateWithPost(ctx context.Context, mediaID string, postID primitive.ObjectID) error {
	// Note: No timeout here as this is used within transactions which have their own timeout
	objectID, err := primitive.ObjectIDFromHex(mediaID)
	if err != nil {
		return fmt.Errorf("invalid media ID: %w", err)
	}

	update := bson.M{
		"$set": bson.M{
			"postId":    postID,
			"updatedAt": time.Now(),
		},
	}

	result, err := r.collection.UpdateOne(ctx, bson.M{"_id": objectID}, update)
	if err != nil {
		return fmt.Errorf("failed to associate media with post: %w", err)
	}
	if result.MatchedCount == 0 {
		return fmt.Errorf("media not found")
	}
	return nil
}

// GetOrphanedFiles retrieves files without postId that are older than the specified time
// These are files that were uploaded but never associated with any content
func (r *mediaRepository) GetOrphanedFiles(ctx context.Context, olderThan time.Time, limit int) ([]*models.MediaFile, error) {
	// Add defensive timeout (longer for batch operations)
	ctx, cancel := context.WithTimeout(ctx, 15*time.Second)
	defer cancel()

	filter := bson.M{
		"postId": bson.M{"$exists": false}, // No postId field
		"createdAt": bson.M{"$lt": olderThan},
		"status":    models.MediaFileStatusReady, // Only processed files
		"fileType":  bson.M{"$ne": models.MediaFileTypeAvatar}, // Don't delete avatars
	}

	// Also include documents where postId is null
	filterWithNull := bson.M{
		"$or": []bson.M{
			filter,
			{
				"postId":    nil,
				"createdAt": bson.M{"$lt": olderThan},
				"status":    models.MediaFileStatusReady,
				"fileType":  bson.M{"$ne": models.MediaFileTypeAvatar},
			},
		},
	}

	opts := options.Find().
		SetSort(bson.D{{Key: "createdAt", Value: 1}}).
		SetLimit(int64(limit))

	cursor, err := r.collection.Find(ctx, filterWithNull, opts)
	if err != nil {
		return nil, fmt.Errorf("failed to get orphaned files: %w", err)
	}
	defer cursor.Close(ctx)

	var mediaFiles []*models.MediaFile
	if err := cursor.All(ctx, &mediaFiles); err != nil {
		return nil, fmt.Errorf("failed to decode orphaned files: %w", err)
	}
	return mediaFiles, nil
}

// CountOrphanedFiles counts files without postId older than specified time
func (r *mediaRepository) CountOrphanedFiles(ctx context.Context, olderThan time.Time) (int64, error) {
	// Add defensive timeout
	ctx, cancel := context.WithTimeout(ctx, 10*time.Second)
	defer cancel()

	filter := bson.M{
		"$or": []bson.M{
			{
				"postId":    bson.M{"$exists": false},
				"createdAt": bson.M{"$lt": olderThan},
				"status":    models.MediaFileStatusReady,
				"fileType":  bson.M{"$ne": models.MediaFileTypeAvatar},
			},
			{
				"postId":    nil,
				"createdAt": bson.M{"$lt": olderThan},
				"status":    models.MediaFileStatusReady,
				"fileType":  bson.M{"$ne": models.MediaFileTypeAvatar},
			},
		},
	}

	count, err := r.collection.CountDocuments(ctx, filter)
	if err != nil {
		return 0, fmt.Errorf("failed to count orphaned files: %w", err)
	}
	return count, nil
}

// IncrementRefCount atomically increments the reference count for a media file
// Used when a duplicate file is detected (same hash)
func (r *mediaRepository) IncrementRefCount(ctx context.Context, id string) error {
	ctx, cancel := context.WithTimeout(ctx, 5*time.Second)
	defer cancel()

	objectID, err := primitive.ObjectIDFromHex(id)
	if err != nil {
		return fmt.Errorf("invalid media ID: %w", err)
	}

	update := bson.M{
		"$inc": bson.M{"refCount": 1},
		"$set": bson.M{"updatedAt": time.Now()},
	}

	result, err := r.collection.UpdateOne(ctx, bson.M{"_id": objectID}, update)
	if err != nil {
		return fmt.Errorf("failed to increment refCount: %w", err)
	}
	if result.MatchedCount == 0 {
		return fmt.Errorf("media not found")
	}

	return nil
}

// DecrementRefCount atomically decrements the reference count for a media file
// Returns the new refCount value and error
func (r *mediaRepository) DecrementRefCount(ctx context.Context, id string) (int, error) {
	ctx, cancel := context.WithTimeout(ctx, 5*time.Second)
	defer cancel()

	objectID, err := primitive.ObjectIDFromHex(id)
	if err != nil {
		return 0, fmt.Errorf("invalid media ID: %w", err)
	}

	// Use findOneAndUpdate to get the updated document atomically
	update := bson.M{
		"$inc": bson.M{"refCount": -1},
		"$set": bson.M{"updatedAt": time.Now()},
	}

	opts := options.FindOneAndUpdate().SetReturnDocument(options.After)
	var media models.MediaFile
	err = r.collection.FindOneAndUpdate(ctx, bson.M{"_id": objectID}, update, opts).Decode(&media)
	if err != nil {
		if err == mongo.ErrNoDocuments {
			return 0, fmt.Errorf("media not found")
		}
		return 0, fmt.Errorf("failed to decrement refCount: %w", err)
	}

	return media.RefCount, nil
}

// CountByHash counts the number of files with the same hash
// Used for deduplication statistics
func (r *mediaRepository) CountByHash(ctx context.Context, hash string) (int64, error) {
	ctx, cancel := context.WithTimeout(ctx, 5*time.Second)
	defer cancel()

	count, err := r.collection.CountDocuments(ctx, bson.M{"hashSha256": hash})
	if err != nil {
		return 0, fmt.Errorf("failed to count files by hash: %w", err)
	}
	return count, nil
}

// GetByIDs retrieves multiple media files by their IDs in a single query
// This eliminates N+1 query problems when fetching multiple files
func (r *mediaRepository) GetByIDs(ctx context.Context, ids []string) ([]*models.MediaFile, error) {
	ctx, cancel := context.WithTimeout(ctx, 10*time.Second)
	defer cancel()

	// Convert string IDs to ObjectIDs
	objectIDs := make([]primitive.ObjectID, 0, len(ids))
	for _, id := range ids {
		oid, err := primitive.ObjectIDFromHex(id)
		if err != nil {
			utils.Warn("Invalid media ID in batch fetch", map[string]interface{}{
				"id": id,
			})
			continue // Skip invalid IDs
		}
		objectIDs = append(objectIDs, oid)
	}

	if len(objectIDs) == 0 {
		return []*models.MediaFile{}, nil
	}

	// Execute bulk query
	cursor, err := r.collection.Find(ctx, bson.M{
		"_id": bson.M{"$in": objectIDs},
	})
	if err != nil {
		return nil, fmt.Errorf("failed to get files by IDs: %w", err)
	}
	defer cursor.Close(ctx)

	var mediaFiles []*models.MediaFile
	if err := cursor.All(ctx, &mediaFiles); err != nil {
		return nil, fmt.Errorf("failed to decode media files: %w", err)
	}

	return mediaFiles, nil
}

// GetClient returns the MongoDB client for advanced operations (e.g., transactions)
func (r *mediaRepository) GetClient() *mongo.Client {
	return r.collection.Database().Client()
}
