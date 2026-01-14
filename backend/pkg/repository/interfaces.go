package repository

import (
	"context"
	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/bson/primitive"
)

// IRepository defines the contract for generic repository operations
// This interface enables dependency injection and makes services testable via mocking
type IRepository[T any] interface {
	// =========================================================================
	// BASIC CRUD OPERATIONS
	// =========================================================================

	// GetByID retrieves a single document by its ObjectID
	// Returns nil if document not found (does not return error)
	GetByID(ctx context.Context, id primitive.ObjectID) (*T, error)

	// GetAll retrieves all documents with pagination support
	// Uses PaginationParams for limit, offset, and sorting
	GetAll(ctx context.Context, params PaginationParams) ([]T, int64, error)

	// Create inserts a new document and returns the inserted document with ID
	Create(ctx context.Context, entity *T) (*T, error)

	// Update updates an existing document by ID with partial updates
	// Uses bson.M for flexible field updates
	Update(ctx context.Context, id primitive.ObjectID, update bson.M) error

	// Delete performs hard delete of a document by ID
	Delete(ctx context.Context, id primitive.ObjectID) error

	// =========================================================================
	// QUERY OPERATIONS
	// =========================================================================

	// Find retrieves documents matching the query with pagination
	Find(ctx context.Context, query *Query) ([]T, int64, error)

	// FindOne retrieves the first document matching the query
	// Returns nil if no document found (does not return error)
	FindOne(ctx context.Context, query *Query) (*T, error)

	// Count returns the number of documents matching the filter
	Count(ctx context.Context, filter bson.M) (int64, error)

	// Exists checks if any document matches the filter
	Exists(ctx context.Context, filter bson.M) (bool, error)

	// =========================================================================
	// SOFT DELETE OPERATIONS
	// =========================================================================

	// SoftDelete marks a document as deleted (sets deletedAt timestamp)
	SoftDelete(ctx context.Context, id primitive.ObjectID) error

	// Restore unmarks a soft-deleted document (unsets deletedAt)
	Restore(ctx context.Context, id primitive.ObjectID) error

	// =========================================================================
	// BULK OPERATIONS
	// =========================================================================

	// CreateMany inserts multiple documents in a single transaction
	CreateMany(ctx context.Context, entities []T) ([]primitive.ObjectID, error)

	// UpdateMany updates multiple documents matching the filter
	// Returns the number of documents updated
	UpdateMany(ctx context.Context, filter bson.M, update bson.M) (int64, error)

	// DeleteMany deletes multiple documents matching the filter
	// Returns the number of documents deleted
	DeleteMany(ctx context.Context, filter bson.M) (int64, error)

	// =========================================================================
	// ARRAY OPERATIONS
	// =========================================================================

	// PushToArray adds an item to an array field
	PushToArray(ctx context.Context, id primitive.ObjectID, field string, value interface{}) error

	// PullFromArray removes an item from an array field
	PullFromArray(ctx context.Context, id primitive.ObjectID, field string, value interface{}) error

	// =========================================================================
	// COUNTER OPERATIONS
	// =========================================================================

	// Increment increments a numeric field by the specified amount
	Increment(ctx context.Context, id primitive.ObjectID, field string, amount int) error

	// Decrement decrements a numeric field by the specified amount
	Decrement(ctx context.Context, id primitive.ObjectID, field string, amount int) error

	// =========================================================================
	// AGGREGATION OPERATIONS
	// =========================================================================

	// Aggregate executes a MongoDB aggregation pipeline
	// Returns results as []T or error
	Aggregate(ctx context.Context, pipeline []bson.M) ([]T, error)
}

// PaginationParams encapsulates pagination, sorting, and filtering options
type PaginationParams struct {
	Limit      int    // Maximum number of documents to return (0 = no limit)
	Offset     int    // Number of documents to skip
	SortBy     string // Field name to sort by
	SortOrder  int    // Sort direction: 1 for ascending, -1 for descending
	Filter     bson.M // Additional filter criteria
	Projection bson.M // Fields to include/exclude in results
}

// DefaultPaginationParams returns sensible defaults for pagination
func DefaultPaginationParams() PaginationParams {
	return PaginationParams{
		Limit:     50,
		Offset:    0,
		SortBy:    "createdAt",
		SortOrder: -1, // Newest first
		Filter:    bson.M{},
	}
}
