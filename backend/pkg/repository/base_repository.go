package repository

import (
	"context"
	"errors"
	"time"

	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/bson/primitive"
	"go.mongodb.org/mongo-driver/mongo"
	"go.mongodb.org/mongo-driver/mongo/options"
)

// Common repository errors
var (
	ErrNotFound      = errors.New("document not found")
	ErrInvalidID     = errors.New("invalid document ID")
	ErrDuplicateKey  = errors.New("duplicate key error")
	ErrUpdateFailed  = errors.New("update failed")
	ErrDeleteFailed  = errors.New("delete failed")
	ErrInvalidFilter = errors.New("invalid filter")
)

// Model interface that all models must implement
type Model interface {
	GetID() primitive.ObjectID
	SetID(id primitive.ObjectID)
	SetTimestamps()
}

// QueryOptions for pagination and filtering
type QueryOptions struct {
	Page      int
	Limit     int
	SortField string
	SortOrder int // 1 for ascending, -1 for descending
	Filter    bson.M
}

// PaginatedResult generic paginated response
type PaginatedResult[T any] struct {
	Data       []T   `json:"data"`
	Total      int64 `json:"total"`
	Page       int   `json:"page"`
	Limit      int   `json:"limit"`
	TotalPages int   `json:"total_pages"`
}

// BaseRepository generic CRUD operations for MongoDB
// T: the model type (must implement Model interface)
type BaseRepository[T Model] struct {
	collection *mongo.Collection
}

// NewBaseRepository creates a new generic repository
func NewBaseRepository[T Model](db *mongo.Database, collectionName string) *BaseRepository[T] {
	return &BaseRepository[T]{
		collection: db.Collection(collectionName),
	}
}

// Create inserts a new document
func (r *BaseRepository[T]) Create(ctx context.Context, model T) (T, error) {
	// Set ID if not set
	if model.GetID().IsZero() {
		model.SetID(primitive.NewObjectID())
	}

	// Set timestamps
	model.SetTimestamps()

	// Insert
	_, err := r.collection.InsertOne(ctx, model)
	if err != nil {
		if mongo.IsDuplicateKeyError(err) {
			return model, ErrDuplicateKey
		}
		return model, err
	}

	return model, nil
}

// CreateMany inserts multiple documents
func (r *BaseRepository[T]) CreateMany(ctx context.Context, models []T) ([]T, error) {
	if len(models) == 0 {
		return models, nil
	}

	// Prepare documents
	docs := make([]interface{}, len(models))
	for i, model := range models {
		if model.GetID().IsZero() {
			model.SetID(primitive.NewObjectID())
		}
		model.SetTimestamps()
		docs[i] = model
		models[i] = model // Update with timestamps
	}

	// Insert
	_, err := r.collection.InsertMany(ctx, docs)
	if err != nil {
		return models, err
	}

	return models, nil
}

// FindByID finds a document by ID
func (r *BaseRepository[T]) FindByID(ctx context.Context, id string) (T, error) {
	var zero T

	objectID, err := primitive.ObjectIDFromHex(id)
	if err != nil {
		return zero, ErrInvalidID
	}

	var result T
	err = r.collection.FindOne(ctx, bson.M{"_id": objectID}).Decode(&result)
	if err != nil {
		if err == mongo.ErrNoDocuments {
			return zero, ErrNotFound
		}
		return zero, err
	}

	return result, nil
}

// FindOne finds a single document by filter
func (r *BaseRepository[T]) FindOne(ctx context.Context, filter bson.M) (T, error) {
	var zero T
	var result T

	err := r.collection.FindOne(ctx, filter).Decode(&result)
	if err != nil {
		if err == mongo.ErrNoDocuments {
			return zero, ErrNotFound
		}
		return zero, err
	}

	return result, nil
}

// FindMany finds multiple documents by filter
func (r *BaseRepository[T]) FindMany(ctx context.Context, filter bson.M, opts ...*options.FindOptions) ([]T, error) {
	cursor, err := r.collection.Find(ctx, filter, opts...)
	if err != nil {
		return nil, err
	}
	defer cursor.Close(ctx)

	var results []T
	if err := cursor.All(ctx, &results); err != nil {
		return nil, err
	}

	return results, nil
}

// FindAll finds all documents (with optional limit)
func (r *BaseRepository[T]) FindAll(ctx context.Context, limit int) ([]T, error) {
	opts := options.Find()
	if limit > 0 {
		opts.SetLimit(int64(limit))
	}

	return r.FindMany(ctx, bson.M{}, opts)
}

// FindPaginated finds documents with pagination
func (r *BaseRepository[T]) FindPaginated(ctx context.Context, queryOpts QueryOptions) (*PaginatedResult[T], error) {
	// Default values
	if queryOpts.Page < 1 {
		queryOpts.Page = 1
	}
	if queryOpts.Limit < 1 {
		queryOpts.Limit = 20
	}
	if queryOpts.Limit > 100 {
		queryOpts.Limit = 100
	}
	if queryOpts.Filter == nil {
		queryOpts.Filter = bson.M{}
	}

	// Count total
	total, err := r.collection.CountDocuments(ctx, queryOpts.Filter)
	if err != nil {
		return nil, err
	}

	// Calculate pagination
	skip := (queryOpts.Page - 1) * queryOpts.Limit
	totalPages := int(total) / queryOpts.Limit
	if int(total)%queryOpts.Limit > 0 {
		totalPages++
	}

	// Find options
	findOpts := options.Find().
		SetSkip(int64(skip)).
		SetLimit(int64(queryOpts.Limit))

	// Add sorting if specified
	if queryOpts.SortField != "" {
		sortOrder := 1
		if queryOpts.SortOrder == -1 {
			sortOrder = -1
		}
		findOpts.SetSort(bson.D{{Key: queryOpts.SortField, Value: sortOrder}})
	}

	// Find documents
	data, err := r.FindMany(ctx, queryOpts.Filter, findOpts)
	if err != nil {
		return nil, err
	}

	return &PaginatedResult[T]{
		Data:       data,
		Total:      total,
		Page:       queryOpts.Page,
		Limit:      queryOpts.Limit,
		TotalPages: totalPages,
	}, nil
}

// UpdateByID updates a document by ID
func (r *BaseRepository[T]) UpdateByID(ctx context.Context, id string, update bson.M) error {
	objectID, err := primitive.ObjectIDFromHex(id)
	if err != nil {
		return ErrInvalidID
	}

	// Add updatedAt timestamp
	if update["$set"] == nil {
		update["$set"] = bson.M{}
	}
	update["$set"].(bson.M)["updatedAt"] = time.Now()

	result, err := r.collection.UpdateOne(
		ctx,
		bson.M{"_id": objectID},
		update,
	)
	if err != nil {
		return err
	}

	if result.MatchedCount == 0 {
		return ErrNotFound
	}

	return nil
}

// UpdateOne updates a single document by filter
func (r *BaseRepository[T]) UpdateOne(ctx context.Context, filter bson.M, update bson.M) error {
	// Add updatedAt timestamp
	if update["$set"] == nil {
		update["$set"] = bson.M{}
	}
	update["$set"].(bson.M)["updatedAt"] = time.Now()

	result, err := r.collection.UpdateOne(ctx, filter, update)
	if err != nil {
		return err
	}

	if result.MatchedCount == 0 {
		return ErrNotFound
	}

	return nil
}

// UpdateMany updates multiple documents by filter
func (r *BaseRepository[T]) UpdateMany(ctx context.Context, filter bson.M, update bson.M) (int64, error) {
	// Add updatedAt timestamp
	if update["$set"] == nil {
		update["$set"] = bson.M{}
	}
	update["$set"].(bson.M)["updatedAt"] = time.Now()

	result, err := r.collection.UpdateMany(ctx, filter, update)
	if err != nil {
		return 0, err
	}

	return result.ModifiedCount, nil
}

// DeleteByID deletes a document by ID
func (r *BaseRepository[T]) DeleteByID(ctx context.Context, id string) error {
	objectID, err := primitive.ObjectIDFromHex(id)
	if err != nil {
		return ErrInvalidID
	}

	result, err := r.collection.DeleteOne(ctx, bson.M{"_id": objectID})
	if err != nil {
		return err
	}

	if result.DeletedCount == 0 {
		return ErrNotFound
	}

	return nil
}

// DeleteOne deletes a single document by filter
func (r *BaseRepository[T]) DeleteOne(ctx context.Context, filter bson.M) error {
	result, err := r.collection.DeleteOne(ctx, filter)
	if err != nil {
		return err
	}

	if result.DeletedCount == 0 {
		return ErrNotFound
	}

	return nil
}

// DeleteMany deletes multiple documents by filter
func (r *BaseRepository[T]) DeleteMany(ctx context.Context, filter bson.M) (int64, error) {
	result, err := r.collection.DeleteMany(ctx, filter)
	if err != nil {
		return 0, err
	}

	return result.DeletedCount, nil
}

// Count counts documents by filter
func (r *BaseRepository[T]) Count(ctx context.Context, filter bson.M) (int64, error) {
	return r.collection.CountDocuments(ctx, filter)
}

// Exists checks if a document exists by filter
func (r *BaseRepository[T]) Exists(ctx context.Context, filter bson.M) (bool, error) {
	count, err := r.collection.CountDocuments(ctx, filter, options.Count().SetLimit(1))
	if err != nil {
		return false, err
	}
	return count > 0, nil
}

// Aggregate runs an aggregation pipeline
func (r *BaseRepository[T]) Aggregate(ctx context.Context, pipeline mongo.Pipeline) ([]T, error) {
	cursor, err := r.collection.Aggregate(ctx, pipeline)
	if err != nil {
		return nil, err
	}
	defer cursor.Close(ctx)

	var results []T
	if err := cursor.All(ctx, &results); err != nil {
		return nil, err
	}

	return results, nil
}

// GetCollection returns the underlying MongoDB collection
func (r *BaseRepository[T]) GetCollection() *mongo.Collection {
	return r.collection
}
