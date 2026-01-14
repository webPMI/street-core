package mongodb

import (
	"context"
	"fmt"

	"backend/pkg/logger"

	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/mongo"
	"go.mongodb.org/mongo-driver/mongo/options"
)

// ExecuteTransaction executes a function within a MongoDB transaction.
// It automatically handles session management, commits on success, and aborts on error.
//
// Usage:
//
//	err := mongodb.ExecuteTransaction(ctx, client, func(sessCtx mongo.SessionContext) error {
//	    // Perform transactional operations using sessCtx
//	    _, err := collection.UpdateOne(sessCtx, filter, update)
//	    return err
//	})
//
// Parameters:
//   - ctx: The parent context
//   - client: MongoDB client instance
//   - fn: The function to execute within the transaction. It receives a SessionContext
//     that should be used for all database operations within the transaction.
//
// Returns:
//   - error: nil if transaction commits successfully, or the error that caused the abort
//
// Note: This function properly manages the session lifecycle - the session will be
// ended even if the function panics.
func ExecuteTransaction(ctx context.Context, client *mongo.Client, fn func(sessCtx mongo.SessionContext) error) error {
	// Start a new session
	session, err := client.StartSession()
	if err != nil {
		logger.Error("Failed to start MongoDB session", err, map[string]interface{}{
			"operation": "start_session",
		})
		return fmt.Errorf("failed to start transaction session: %w", err)
	}
	defer session.EndSession(ctx)

	// Execute the function within a transaction
	_, err = session.WithTransaction(ctx, func(sessCtx mongo.SessionContext) (interface{}, error) {
		return nil, fn(sessCtx)
	})

	if err != nil {
		logger.Error("Transaction failed and was aborted", err, map[string]interface{}{
			"operation": "transaction_execution",
		})
		return fmt.Errorf("transaction failed: %w", err)
	}

	logger.Debug("Transaction completed successfully", map[string]interface{}{
		"operation": "transaction_commit",
	})

	return nil
}

// IncrementCounter atomically increments a counter field in a document.
// This operation is atomic and safe for concurrent updates.
//
// Usage:
//
//	err := mongodb.IncrementCounter(ctx, collection, bson.M{"_id": userID}, "stats.followers", 1)
//
// Parameters:
//   - ctx: The context for the operation
//   - coll: The MongoDB collection
//   - filter: The filter to identify the document to update
//   - field: The field path to increment (supports dot notation for nested fields)
//   - delta: The increment value (positive to increase, negative to decrease)
//
// Returns:
//   - error: nil if successful, or an error if the operation fails or no document matches
//
// Note: This uses MongoDB's $inc operator which is atomic at the document level.
// Multiple concurrent increments to the same counter are handled safely by MongoDB.
func IncrementCounter(ctx context.Context, coll *mongo.Collection, filter bson.M, field string, delta int) error {
	update := bson.M{
		"$inc": bson.M{field: delta},
	}

	result, err := coll.UpdateOne(ctx, filter, update)
	if err != nil {
		logger.Error("Failed to increment counter", err, map[string]interface{}{
			"collection": coll.Name(),
			"field":      field,
			"delta":      delta,
		})
		return fmt.Errorf("failed to increment counter %s: %w", field, err)
	}

	if result.MatchedCount == 0 {
		logger.Warn("No document matched filter for counter increment", map[string]interface{}{
			"collection": coll.Name(),
			"field":      field,
			"delta":      delta,
		})
		return fmt.Errorf("no document found to increment counter %s", field)
	}

	logger.Debug("Counter incremented successfully", map[string]interface{}{
		"collection":     coll.Name(),
		"field":          field,
		"delta":          delta,
		"matched_count":  result.MatchedCount,
		"modified_count": result.ModifiedCount,
	})

	return nil
}

// IncrementCounterWithValidation atomically increments a counter field with validation.
// This prevents counters from going below zero (e.g., for follower counts).
//
// Usage:
//
//	err := mongodb.IncrementCounterWithValidation(ctx, collection, bson.M{"_id": userID}, "stats.followers", -1)
//
// Parameters:
//   - ctx: The context for the operation
//   - coll: The MongoDB collection
//   - filter: The filter to identify the document to update
//   - field: The field path to increment (supports dot notation for nested fields)
//   - delta: The increment value (positive to increase, negative to decrease)
//
// Returns:
//   - error: nil if successful, or an error if the operation fails, no document matches,
//     or the validation constraint would be violated
//
// Note: When decrementing (negative delta), this ensures the counter doesn't go below zero.
// It uses MongoDB's $gte condition to check the current value before applying the update.
func IncrementCounterWithValidation(ctx context.Context, coll *mongo.Collection, filter bson.M, field string, delta int) error {
	// For decrements, add validation to prevent negative values
	if delta < 0 {
		// Add condition to ensure the field is >= abs(delta) before decrementing
		filter[field] = bson.M{"$gte": -delta}
	}

	update := bson.M{
		"$inc": bson.M{field: delta},
	}

	opts := options.Update().SetUpsert(false)
	result, err := coll.UpdateOne(ctx, filter, update, opts)
	if err != nil {
		logger.Error("Failed to increment counter with validation", err, map[string]interface{}{
			"collection": coll.Name(),
			"field":      field,
			"delta":      delta,
		})
		return fmt.Errorf("failed to increment counter %s with validation: %w", field, err)
	}

	if result.MatchedCount == 0 {
		if delta < 0 {
			logger.Warn("Counter increment validation failed - would result in negative value", map[string]interface{}{
				"collection": coll.Name(),
				"field":      field,
				"delta":      delta,
			})
			return fmt.Errorf("cannot decrement counter %s: would result in negative value", field)
		}

		logger.Warn("No document matched filter for counter increment", map[string]interface{}{
			"collection": coll.Name(),
			"field":      field,
			"delta":      delta,
		})
		return fmt.Errorf("no document found to increment counter %s", field)
	}

	logger.Debug("Counter incremented with validation successfully", map[string]interface{}{
		"collection":     coll.Name(),
		"field":          field,
		"delta":          delta,
		"matched_count":  result.MatchedCount,
		"modified_count": result.ModifiedCount,
	})

	return nil
}

// BatchIncrementCounters atomically increments multiple counter fields in a single operation.
// This is more efficient than multiple individual increments.
//
// Usage:
//
//	counters := map[string]int{
//	    "stats.followers": 1,
//	    "stats.following": -1,
//	}
//	err := mongodb.BatchIncrementCounters(ctx, collection, bson.M{"_id": userID}, counters)
//
// Parameters:
//   - ctx: The context for the operation
//   - coll: The MongoDB collection
//   - filter: The filter to identify the document to update
//   - counters: A map of field paths to their increment deltas
//
// Returns:
//   - error: nil if successful, or an error if the operation fails or no document matches
//
// Note: All counter updates happen atomically in a single database operation.
func BatchIncrementCounters(ctx context.Context, coll *mongo.Collection, filter bson.M, counters map[string]int) error {
	if len(counters) == 0 {
		return nil // Nothing to do
	}

	update := bson.M{
		"$inc": counters,
	}

	result, err := coll.UpdateOne(ctx, filter, update)
	if err != nil {
		logger.Error("Failed to batch increment counters", err, map[string]interface{}{
			"collection": coll.Name(),
			"counters":   counters,
		})
		return fmt.Errorf("failed to batch increment counters: %w", err)
	}

	if result.MatchedCount == 0 {
		logger.Warn("No document matched filter for batch counter increment", map[string]interface{}{
			"collection": coll.Name(),
			"counters":   counters,
		})
		return fmt.Errorf("no document found to batch increment counters")
	}

	logger.Debug("Batch counter increment successful", map[string]interface{}{
		"collection":     coll.Name(),
		"counters":       counters,
		"matched_count":  result.MatchedCount,
		"modified_count": result.ModifiedCount,
	})

	return nil
}
