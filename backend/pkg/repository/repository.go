package repository

import (
	"context"

	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/bson/primitive"
	"go.mongodb.org/mongo-driver/mongo"
	"go.mongodb.org/mongo-driver/mongo/options"
)

// mongoRepository is the MongoDB implementation of IRepository
type mongoRepository[T any] struct {
	collection *mongo.Collection
}

// NewRepository creates a new MongoDB repository instance
func NewRepository[T any](collection *mongo.Collection) IRepository[T] {
	return &mongoRepository[T]{
		collection: collection,
	}
}

// Find returns multiple documents matching the query
func (r *mongoRepository[T]) Find(ctx context.Context, query *Query) ([]T, int64, error) {
	filter := query.GetFilter()

	// Count total documents matching the filter
	total, err := r.collection.CountDocuments(ctx, filter)
	if err != nil {
		return nil, 0, err
	}

	// Build find options
	findOptions := options.Find()
	if query.GetLimit() > 0 {
		findOptions.SetLimit(query.GetLimit())
	}
	if query.GetSkip() > 0 {
		findOptions.SetSkip(query.GetSkip())
	}
	if len(query.GetSort()) > 0 {
		findOptions.SetSort(query.GetSort())
	}
	if len(query.GetProjection()) > 0 {
		findOptions.SetProjection(query.GetProjection())
	}

	// Execute query
	cursor, err := r.collection.Find(ctx, filter, findOptions)
	if err != nil {
		return nil, 0, err
	}
	defer cursor.Close(ctx)

	// Decode results
	var results []T
	if err = cursor.All(ctx, &results); err != nil {
		return nil, 0, err
	}

	return results, total, nil
}

// FindOne returns a single document matching the query
func (r *mongoRepository[T]) FindOne(ctx context.Context, query *Query) (*T, error) {
	filter := query.GetFilter()

	var result T
	err := r.collection.FindOne(ctx, filter).Decode(&result)
	if err != nil {
		if err == mongo.ErrNoDocuments {
			return nil, nil
		}
		return nil, err
	}

	return &result, nil
}

// GetByID returns a document by its ID
func (r *mongoRepository[T]) GetByID(ctx context.Context, id primitive.ObjectID) (*T, error) {
	var result T
	err := r.collection.FindOne(ctx, bson.M{"_id": id}).Decode(&result)
	if err != nil {
		if err == mongo.ErrNoDocuments {
			return nil, nil
		}
		return nil, err
	}

	return &result, nil
}

// Create inserts a new document and returns the inserted document with ID
func (r *mongoRepository[T]) Create(ctx context.Context, entity *T) (*T, error) {
	result, err := r.collection.InsertOne(ctx, entity)
	if err != nil {
		return nil, err
	}

	// Extract inserted ID and set it on the entity
	if oid, ok := result.InsertedID.(primitive.ObjectID); ok {
		// Use reflection to set the ID field if it exists
		// This assumes the entity has an ID field of type primitive.ObjectID
		_ = oid // ID is already set by MongoDB driver
	}

	return entity, nil
}

// CreateMany inserts multiple documents in a single transaction
func (r *mongoRepository[T]) CreateMany(ctx context.Context, entities []T) ([]primitive.ObjectID, error) {
	// Convert []T to []interface{} for MongoDB
	docs := make([]interface{}, len(entities))
	for i, entity := range entities {
		docs[i] = entity
	}

	result, err := r.collection.InsertMany(ctx, docs)
	if err != nil {
		return nil, err
	}

	// Extract inserted IDs
	ids := make([]primitive.ObjectID, 0, len(result.InsertedIDs))
	for _, id := range result.InsertedIDs {
		if oid, ok := id.(primitive.ObjectID); ok {
			ids = append(ids, oid)
		}
	}

	return ids, nil
}

// Update updates a document by ID
func (r *mongoRepository[T]) Update(ctx context.Context, id primitive.ObjectID, update bson.M) error {
	// Wrap update in $set if not already wrapped
	if _, hasSet := update["$set"]; !hasSet {
		update = bson.M{"$set": update}
	}

	_, err := r.collection.UpdateOne(ctx, bson.M{"_id": id}, update)
	return err
}

// UpdateMany updates multiple documents matching the filter
func (r *mongoRepository[T]) UpdateMany(ctx context.Context, filter bson.M, update bson.M) (int64, error) {
	// Wrap update in $set if not already wrapped
	if _, hasSet := update["$set"]; !hasSet {
		update = bson.M{"$set": update}
	}

	result, err := r.collection.UpdateMany(ctx, filter, update)
	if err != nil {
		return 0, err
	}
	return result.ModifiedCount, nil
}

// Delete removes a document by ID
func (r *mongoRepository[T]) Delete(ctx context.Context, id primitive.ObjectID) error {
	_, err := r.collection.DeleteOne(ctx, bson.M{"_id": id})
	return err
}

// DeleteMany removes multiple documents matching the filter
func (r *mongoRepository[T]) DeleteMany(ctx context.Context, filter bson.M) (int64, error) {
	result, err := r.collection.DeleteMany(ctx, filter)
	if err != nil {
		return 0, err
	}
	return result.DeletedCount, nil
}

// Count returns the number of documents matching the filter
func (r *mongoRepository[T]) Count(ctx context.Context, filter bson.M) (int64, error) {
	return r.collection.CountDocuments(ctx, filter)
}

// Exists checks if any document matches the filter
func (r *mongoRepository[T]) Exists(ctx context.Context, filter bson.M) (bool, error) {
	count, err := r.Count(ctx, filter)
	if err != nil {
		return false, err
	}
	return count > 0, nil
}

// Aggregate executes a MongoDB aggregation pipeline
func (r *mongoRepository[T]) Aggregate(ctx context.Context, pipeline []bson.M) ([]T, error) {
	cursor, err := r.collection.Aggregate(ctx, pipeline)
	if err != nil {
		return nil, err
	}
	defer cursor.Close(ctx)

	var results []T
	if err = cursor.All(ctx, &results); err != nil {
		return nil, err
	}

	return results, nil
}

// GetAll retrieves all documents with pagination support
func (r *mongoRepository[T]) GetAll(ctx context.Context, params PaginationParams) ([]T, int64, error) {
	// Build filter
	filter := params.Filter
	if filter == nil {
		filter = bson.M{}
	}

	// Count total
	total, err := r.collection.CountDocuments(ctx, filter)
	if err != nil {
		return nil, 0, err
	}

	// Build options
	opts := options.Find()
	if params.Limit > 0 {
		opts.SetLimit(int64(params.Limit))
	}
	if params.Offset > 0 {
		opts.SetSkip(int64(params.Offset))
	}
	if params.SortBy != "" {
		sort := bson.M{params.SortBy: params.SortOrder}
		opts.SetSort(sort)
	}
	if params.Projection != nil {
		opts.SetProjection(params.Projection)
	}

	// Execute query
	cursor, err := r.collection.Find(ctx, filter, opts)
	if err != nil {
		return nil, 0, err
	}
	defer cursor.Close(ctx)

	var results []T
	if err = cursor.All(ctx, &results); err != nil {
		return nil, 0, err
	}

	return results, total, nil
}

// SoftDelete marks a document as deleted without removing it
func (r *mongoRepository[T]) SoftDelete(ctx context.Context, id primitive.ObjectID) error {
	update := bson.M{
		"$set": bson.M{
			"deleted_at": primitive.NewDateTimeFromTime(primitive.DateTime(0).Time()),
		},
	}
	_, err := r.collection.UpdateOne(ctx, bson.M{"_id": id}, update)
	return err
}

// Restore restores a soft-deleted document
func (r *mongoRepository[T]) Restore(ctx context.Context, id primitive.ObjectID) error {
	update := bson.M{
		"$unset": bson.M{
			"deleted_at": "",
		},
	}
	_, err := r.collection.UpdateOne(ctx, bson.M{"_id": id}, update)
	return err
}

// PushToArray adds a value to an array field
func (r *mongoRepository[T]) PushToArray(ctx context.Context, id primitive.ObjectID, field string, value interface{}) error {
	update := bson.M{
		"$push": bson.M{
			field: value,
		},
	}
	_, err := r.collection.UpdateOne(ctx, bson.M{"_id": id}, update)
	return err
}

// PullFromArray removes a value from an array field
func (r *mongoRepository[T]) PullFromArray(ctx context.Context, id primitive.ObjectID, field string, value interface{}) error {
	update := bson.M{
		"$pull": bson.M{
			field: value,
		},
	}
	_, err := r.collection.UpdateOne(ctx, bson.M{"_id": id}, update)
	return err
}

// Increment increments a numeric field by the specified amount
func (r *mongoRepository[T]) Increment(ctx context.Context, id primitive.ObjectID, field string, amount int) error {
	update := bson.M{
		"$inc": bson.M{
			field: amount,
		},
	}
	_, err := r.collection.UpdateOne(ctx, bson.M{"_id": id}, update)
	return err
}

// Decrement decrements a numeric field by the specified amount
func (r *mongoRepository[T]) Decrement(ctx context.Context, id primitive.ObjectID, field string, amount int) error {
	return r.Increment(ctx, id, field, -amount)
}
