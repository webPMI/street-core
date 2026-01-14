# MongoDB Transaction Utilities

**Location**: `backend/pkg/mongodb/`
**Package**: `mongodb`
**Purpose**: Thread-safe MongoDB transaction and counter management utilities

## Overview

This package provides utilities for handling MongoDB transactions and atomic counter operations. It solves critical race conditions in operations like follow/unfollow, competition registration, and club membership management where multiple fields need to be updated atomically.

## Critical Problem Solved

**Race Condition in Follow/Unfollow Operations**

Before these utilities, follow/unfollow operations had a race condition:

```go
// BEFORE (UNSAFE - Race Condition)
// Thread A: User follows
CreateFollow(followerID, followingID)          // Step 1
IncrementFollowerCount(followingID)            // Step 2 - could fail
IncrementFollowingCount(followerID)            // Step 3 - could fail

// Thread B: User unfollows (runs concurrently)
DeleteFollow(followerID, followingID)          // Step 1
DecrementFollowerCount(followingID)            // Step 2 - could interfere
DecrementFollowingCount(followerID)            // Step 3 - could interfere
```

**Issues**:
1. Stats could become inconsistent if any step fails
2. Concurrent operations could result in incorrect counts
3. No rollback if intermediate steps fail
4. Counters could go negative

**After (SAFE - Atomic Transaction)**:

```go
// AFTER (SAFE - Atomic Transaction)
err := mongodb.ExecuteTransaction(ctx, client, func(sessCtx mongo.SessionContext) error {
    // All steps execute atomically - all succeed or all rollback
    CreateFollow(sessCtx, followerID, followingID)
    IncrementFollowerCount(sessCtx, followingID)
    IncrementFollowingCount(sessCtx, followerID)
    return nil
})
```

## Features

- **Atomic Transactions**: Execute multiple operations atomically with automatic rollback
- **Safe Counter Increments**: Atomic counter operations with optional validation
- **Batch Updates**: Update multiple counters in a single atomic operation
- **Automatic Session Management**: Handles session lifecycle automatically
- **Comprehensive Logging**: Structured logging for debugging and monitoring
- **Race Condition Prevention**: Thread-safe operations for concurrent updates

## API Reference

### ExecuteTransaction

Executes a function within a MongoDB transaction with automatic session management.

```go
func ExecuteTransaction(
    ctx context.Context,
    client *mongo.Client,
    fn func(sessCtx mongo.SessionContext) error
) error
```

**Features**:
- Automatic session start/end
- Commits on success, aborts on error
- Proper cleanup even on panic
- Structured logging

**Example**:

```go
err := mongodb.ExecuteTransaction(ctx, client, func(sessCtx mongo.SessionContext) error {
    // Create follow relationship
    _, err := followColl.InsertOne(sessCtx, follow)
    if err != nil {
        return err
    }

    // Update stats
    _, err = usersColl.UpdateOne(
        sessCtx,
        bson.M{"_id": followedUserID},
        bson.M{"$inc": bson.M{"stats.followers": 1}},
    )
    return err
})
```

### IncrementCounter

Atomically increments a counter field using MongoDB's `$inc` operator.

```go
func IncrementCounter(
    ctx context.Context,
    coll *mongo.Collection,
    filter bson.M,
    field string,
    delta int,
) error
```

**Features**:
- Atomic operation (thread-safe)
- Supports nested fields via dot notation
- Works with positive or negative deltas
- Returns error if document not found

**Example**:

```go
// Increment follower count
err := mongodb.IncrementCounter(
    ctx,
    usersColl,
    bson.M{"_id": userID},
    "stats.followers",
    1,
)

// Decrement follower count
err := mongodb.IncrementCounter(
    ctx,
    usersColl,
    bson.M{"_id": userID},
    "stats.followers",
    -1,
)
```

### IncrementCounterWithValidation

Atomically increments a counter with validation to prevent negative values.

```go
func IncrementCounterWithValidation(
    ctx context.Context,
    coll *mongo.Collection,
    filter bson.M,
    field string,
    delta int,
) error
```

**Features**:
- All features of `IncrementCounter`
- Prevents counters from going below zero
- Returns error if validation fails
- Useful for counts that should never be negative (followers, likes, etc.)

**Example**:

```go
// Safely decrement follower count (won't go below 0)
err := mongodb.IncrementCounterWithValidation(
    ctx,
    usersColl,
    bson.M{"_id": userID},
    "stats.followers",
    -1,
)

if err != nil {
    // Could fail if count is already 0
    log.Printf("Cannot unfollow: %v", err)
}
```

### BatchIncrementCounters

Atomically increments multiple counter fields in a single operation.

```go
func BatchIncrementCounters(
    ctx context.Context,
    coll *mongo.Collection,
    filter bson.M,
    counters map[string]int,
) error
```

**Features**:
- All counter updates happen atomically
- More efficient than multiple individual increments
- Reduces network round trips
- All-or-nothing operation

**Example**:

```go
// Update multiple stats in one atomic operation
counters := map[string]int{
    "stats.posts":       1,  // New post created
    "stats.total_likes": 5,  // Post received 5 likes
    "stats.followers":   -1, // One user unfollowed
}

err := mongodb.BatchIncrementCounters(
    ctx,
    usersColl,
    bson.M{"_id": userID},
    counters,
)
```

## Usage Examples

### Follow/Unfollow Service

Complete implementation using transactions for consistency:

```go
type FollowService struct {
    client     *mongo.Client
    followColl *mongo.Collection
    usersColl  *mongo.Collection
}

func (s *FollowService) Follow(ctx context.Context, followerID, followingID primitive.ObjectID) error {
    return mongodb.ExecuteTransaction(ctx, s.client, func(sessCtx mongo.SessionContext) error {
        // 1. Check if already following
        count, err := s.followColl.CountDocuments(sessCtx, bson.M{
            "follower":  followerID,
            "following": followingID,
        })
        if err != nil {
            return err
        }
        if count > 0 {
            return fmt.Errorf("already following this user")
        }

        // 2. Create follow relationship
        follow := bson.M{
            "_id":        primitive.NewObjectID(),
            "follower":   followerID,
            "following":  followingID,
            "created_at": time.Now(),
        }
        _, err = s.followColl.InsertOne(sessCtx, follow)
        if err != nil {
            return err
        }

        // 3. Update followed user's stats
        err = mongodb.IncrementCounter(
            sessCtx,
            s.usersColl,
            bson.M{"_id": followingID},
            "stats.followers",
            1,
        )
        if err != nil {
            return err
        }

        // 4. Update follower's stats
        err = mongodb.IncrementCounter(
            sessCtx,
            s.usersColl,
            bson.M{"_id": followerID},
            "stats.following",
            1,
        )
        return err
    })
}

func (s *FollowService) Unfollow(ctx context.Context, followerID, followingID primitive.ObjectID) error {
    return mongodb.ExecuteTransaction(ctx, s.client, func(sessCtx mongo.SessionContext) error {
        // 1. Delete follow relationship
        result, err := s.followColl.DeleteOne(sessCtx, bson.M{
            "follower":  followerID,
            "following": followingID,
        })
        if err != nil {
            return err
        }
        if result.DeletedCount == 0 {
            return fmt.Errorf("not following this user")
        }

        // 2. Decrement followed user's stats (with validation)
        err = mongodb.IncrementCounterWithValidation(
            sessCtx,
            s.usersColl,
            bson.M{"_id": followingID},
            "stats.followers",
            -1,
        )
        if err != nil {
            return err
        }

        // 3. Decrement follower's stats (with validation)
        err = mongodb.IncrementCounterWithValidation(
            sessCtx,
            s.usersColl,
            bson.M{"_id": followerID},
            "stats.following",
            -1,
        )
        return err
    })
}
```

### Competition Registration

Ensure atomic registration with participant count updates:

```go
func RegisterForCompetition(ctx context.Context, client *mongo.Client, db *mongo.Database, competitionID, athleteID primitive.ObjectID) error {
    competitionsColl := db.Collection("competitions")
    registrationsColl := db.Collection("competition_registrations")

    return mongodb.ExecuteTransaction(ctx, client, func(sessCtx mongo.SessionContext) error {
        // 1. Check competition status
        var competition bson.M
        err := competitionsColl.FindOne(sessCtx, bson.M{"_id": competitionID}).Decode(&competition)
        if err != nil {
            return err
        }

        if competition["status"] != "upcoming" {
            return fmt.Errorf("competition is not accepting registrations")
        }

        // 2. Check capacity
        maxParticipants := competition["max_participants"].(int32)
        currentCount := competition["participant_count"].(int32)

        if currentCount >= maxParticipants {
            return fmt.Errorf("competition is full")
        }

        // 3. Create registration
        registration := bson.M{
            "_id":            primitive.NewObjectID(),
            "competition_id": competitionID,
            "athlete_id":     athleteID,
            "registered_at":  time.Now(),
            "status":         "confirmed",
        }
        _, err = registrationsColl.InsertOne(sessCtx, registration)
        if err != nil {
            return err
        }

        // 4. Increment participant count atomically
        return mongodb.IncrementCounter(
            sessCtx,
            competitionsColl,
            bson.M{"_id": competitionID},
            "participant_count",
            1,
        )
    })
}
```

### Club Membership

Atomic join/leave operations:

```go
func JoinClub(ctx context.Context, client *mongo.Client, db *mongo.Database, clubID, userID primitive.ObjectID) error {
    clubsColl := db.Collection("clubs")
    membersColl := db.Collection("club_members")

    return mongodb.ExecuteTransaction(ctx, client, func(sessCtx mongo.SessionContext) error {
        // 1. Create membership
        member := bson.M{
            "_id":       primitive.NewObjectID(),
            "club_id":   clubID,
            "user_id":   userID,
            "role":      "member",
            "joined_at": time.Now(),
        }
        _, err := membersColl.InsertOne(sessCtx, member)
        if err != nil {
            return err
        }

        // 2. Update club stats atomically
        return mongodb.BatchIncrementCounters(
            sessCtx,
            clubsColl,
            bson.M{"_id": clubID},
            map[string]int{
                "stats.total_members":  1,
                "stats.active_members": 1,
            },
        )
    })
}
```

## Performance Considerations

### When to Use Transactions

**Use transactions when**:
- Multiple collections need to be updated atomically
- Operations depend on each other (create A, then update B based on A)
- Consistency is critical (financial operations, stats, relationships)
- Rollback is needed if any step fails

**Don't use transactions for**:
- Single document updates (already atomic in MongoDB)
- Read-only operations
- High-throughput simple operations

### When to Use Batch Increments

**Use BatchIncrementCounters when**:
- Updating multiple counters on the same document
- Want to reduce network round trips
- All updates are on the same collection

**Example - Don't do this**:
```go
// INEFFICIENT: 3 separate database calls
IncrementCounter(ctx, coll, filter, "stats.posts", 1)
IncrementCounter(ctx, coll, filter, "stats.likes", 5)
IncrementCounter(ctx, coll, filter, "stats.comments", 2)
```

**Example - Do this instead**:
```go
// EFFICIENT: 1 database call
BatchIncrementCounters(ctx, coll, filter, map[string]int{
    "stats.posts":    1,
    "stats.likes":    5,
    "stats.comments": 2,
})
```

## Error Handling

All functions return descriptive errors:

```go
err := mongodb.ExecuteTransaction(ctx, client, fn)
if err != nil {
    if errors.Is(err, mongo.ErrNoDocuments) {
        // Document not found
    } else if mongo.IsDuplicateKeyError(err) {
        // Duplicate key violation
    } else {
        // Other error
    }
}
```

## Testing

Comprehensive test coverage included:

- Unit tests: `transaction_test.go`
- Usage examples: `examples_test.go`
- Concurrent operations test
- Transaction rollback test
- Validation tests

Run tests:

```bash
cd backend
go test ./pkg/mongodb/... -v
```

## Requirements

- MongoDB 4.0+ (for multi-document transactions)
- MongoDB replica set (transactions require replica set)
- Go MongoDB Driver v1.11+

## Thread Safety

All operations are thread-safe:
- `IncrementCounter` uses MongoDB's atomic `$inc` operator
- `ExecuteTransaction` uses MongoDB's ACID transactions
- Concurrent increments to the same counter are handled correctly

## Logging

All operations use structured logging via `backend/pkg/logger`:

- Debug: Transaction success, counter increments
- Error: Transaction failures, validation errors, session errors
- Warn: Document not found, validation failures

## Migration Guide

### Updating Existing Code

**Before**:
```go
// UNSAFE - Race condition
CreateFollow(ctx, followerID, followingID)
IncrementFollowerCount(ctx, followingID)
IncrementFollowingCount(ctx, followerID)
```

**After**:
```go
// SAFE - Atomic transaction
err := mongodb.ExecuteTransaction(ctx, client, func(sessCtx mongo.SessionContext) error {
    err := CreateFollow(sessCtx, followerID, followingID)
    if err != nil {
        return err
    }

    err = mongodb.IncrementCounter(
        sessCtx,
        usersColl,
        bson.M{"_id": followingID},
        "stats.followers",
        1,
    )
    if err != nil {
        return err
    }

    return mongodb.IncrementCounter(
        sessCtx,
        usersColl,
        bson.M{"_id": followerID},
        "stats.following",
        1,
    )
})
```

## See Also

- `backend/tests/testutil/database.go` - Database testing utilities
- `backend/features/clubs/club_service.go` - Real-world transaction examples
- `backend/features/competitions/repository.go` - Competition transaction examples

## Last Updated

**Date**: 2025-12-24 00:10 UTC-5
**Version**: 1.0.0
**Status**: Production Ready
