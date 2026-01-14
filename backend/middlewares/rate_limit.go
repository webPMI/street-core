package middlewares

import (
	"context"
	"fmt"
	"net/http"
	"sync"
	"time"

	"backend/models"

	"github.com/gin-gonic/gin"
	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/mongo"
	"go.mongodb.org/mongo-driver/mongo/options"
)

// RateLimitStore is the interface for rate limit storage backends
type RateLimitStore interface {
	Allow(ctx context.Context, key string, config models.RateLimitConfig) (bool, error)
}

// MongoRateLimitStore implements RateLimitStore using MongoDB
type MongoRateLimitStore struct {
	collection  *mongo.Collection
	mu          sync.Mutex
	initialized bool
}

// Global store instance (initialized via InitRateLimitStore)
var rateLimitStore RateLimitStore

// Fallback store with sync.Once to ensure single initialization
var (
	fallbackStore     *memoryRateLimitStore
	fallbackStoreOnce sync.Once
)

// memoryRateLimitStore is a fallback in-memory implementation
type memoryRateLimitStore struct {
	requests map[string]*userLimit
	mu       sync.RWMutex
}

type userLimit struct {
	tokens     int
	lastRefill time.Time
	window     time.Duration
}

// InitRateLimitStore initializes the rate limit store with MongoDB
// Call this during application startup after MongoDB connection is established
func InitRateLimitStore(db *mongo.Database) {
	store := &MongoRateLimitStore{
		collection: db.Collection("rate_limits"),
	}

	// Create indexes in background
	go store.ensureIndexes()

	rateLimitStore = store
}

// ensureIndexes creates necessary MongoDB indexes
func (s *MongoRateLimitStore) ensureIndexes() {
	s.mu.Lock()
	defer s.mu.Unlock()

	if s.initialized {
		return
	}

	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()

	// TTL index for automatic cleanup
	ttlIndex := mongo.IndexModel{
		Keys:    bson.D{{Key: "expires_at", Value: 1}},
		Options: options.Index().SetExpireAfterSeconds(0),
	}
	s.collection.Indexes().CreateOne(ctx, ttlIndex)

	// Unique index on key for fast lookups and preventing duplicates
	keyIndex := mongo.IndexModel{
		Keys:    bson.D{{Key: "key", Value: 1}},
		Options: options.Index().SetUnique(true),
	}
	s.collection.Indexes().CreateOne(ctx, keyIndex)

	s.initialized = true
}

// Allow checks if request should be allowed (MongoDB implementation)
// SECURITY: Uses atomic FindOneAndUpdate to prevent race conditions.
// All rate limit decisions are made in a single atomic operation.
func (s *MongoRateLimitStore) Allow(ctx context.Context, key string, config models.RateLimitConfig) (bool, error) {
	now := time.Now()
	compositeKey := config.Name + ":" + key
	expiresAt := now.Add(config.Window)

	// Single atomic operation using aggregation pipeline update (MongoDB 4.2+)
	// This handles all cases atomically:
	// 1. Document doesn't exist -> insert with initial tokens
	// 2. Document expired -> reset tokens
	// 3. Document valid with tokens > 0 -> decrement
	// 4. Document valid with tokens = 0 -> deny (no change)
	pipeline := mongo.Pipeline{
		{{Key: "$set", Value: bson.M{
			"key":        compositeKey,
			"updated_at": now,
			// Reset tokens if expired, otherwise keep current value
			"tokens": bson.M{
				"$cond": bson.M{
					"if": bson.M{"$lt": bson.A{"$expires_at", now}},
					// Expired: reset to full tokens minus 1 for this request
					"then": config.Rate - 1,
					// Not expired: decrement if > 0, otherwise keep at 0
					"else": bson.M{
						"$max": bson.A{
							bson.M{"$subtract": bson.A{"$tokens", 1}},
							0,
						},
					},
				},
			},
			// Reset expiration if expired
			"expires_at": bson.M{
				"$cond": bson.M{
					"if":   bson.M{"$lt": bson.A{"$expires_at", now}},
					"then": expiresAt,
					"else": "$expires_at",
				},
			},
			"window": config.Window,
		}}},
	}

	opts := options.FindOneAndUpdate().
		SetUpsert(true).
		SetReturnDocument(options.Before) // Get state BEFORE update to check if we had tokens

	var before models.RateLimit
	err := s.collection.FindOneAndUpdate(ctx,
		bson.M{"key": compositeKey},
		pipeline,
		opts,
	).Decode(&before)

	// If document didn't exist, it was just created with tokens = rate-1
	// This means the request is allowed
	if err == mongo.ErrNoDocuments {
		return true, nil
	}

	if err != nil {
		return false, err
	}

	// Check state before the update
	// If was expired, we reset it, so request is allowed
	if before.ExpiresAt.Before(now) {
		return true, nil
	}

	// If had tokens before decrement, request is allowed
	return before.Tokens > 0, nil
}

// Allow checks if request should be allowed (in-memory fallback)
func (s *memoryRateLimitStore) Allow(ctx context.Context, key string, config models.RateLimitConfig) (bool, error) {
	s.mu.Lock()
	defer s.mu.Unlock()

	compositeKey := config.Name + ":" + key
	now := time.Now()

	limit, exists := s.requests[compositeKey]
	if !exists {
		s.requests[compositeKey] = &userLimit{
			tokens:     config.Rate - 1,
			lastRefill: now,
			window:     config.Window,
		}
		return true, nil
	}

	// Refill if window passed
	if now.Sub(limit.lastRefill) >= limit.window {
		limit.tokens = config.Rate
		limit.lastRefill = now
	}

	if limit.tokens > 0 {
		limit.tokens--
		return true, nil
	}

	return false, nil
}

// getStore returns the current rate limit store (MongoDB or fallback)
// Uses sync.Once to ensure fallback store is only created once
func getStore() RateLimitStore {
	if rateLimitStore != nil {
		return rateLimitStore
	}
	// Fallback to in-memory if MongoDB not initialized
	// Use sync.Once to prevent race condition and ensure single instance
	fallbackStoreOnce.Do(func() {
		fallbackStore = &memoryRateLimitStore{
			requests: make(map[string]*userLimit),
		}
	})
	return fallbackStore
}

// RateLimitMiddlewareWithConfig creates rate limit middleware with specific config
func RateLimitMiddlewareWithConfig(config models.RateLimitConfig) gin.HandlerFunc {
	return func(c *gin.Context) {
		// Use IP address as key (or user ID if authenticated)
		key := c.ClientIP()

		if userID, exists := c.Get("userID"); exists {
			if uid, ok := userID.(string); ok {
				key = "user:" + uid
			}
		} else {
			key = "ip:" + key
		}

		store := getStore()
		ctx, cancel := context.WithTimeout(c.Request.Context(), 5*time.Second)
		defer cancel()

		// Get current limit info
		compositeKey := config.Name + ":" + key
		remaining, resetAt, err := getRateLimitInfo(ctx, store, compositeKey, config)

		// Set rate limit headers
		c.Header("X-RateLimit-Limit", fmt.Sprintf("%d", config.Rate))
		c.Header("X-RateLimit-Remaining", fmt.Sprintf("%d", remaining))
		if !resetAt.IsZero() {
			c.Header("X-RateLimit-Reset", fmt.Sprintf("%d", resetAt.Unix()))
		}

		allowed, err := store.Allow(ctx, key, config)
		if err != nil {
			// Log error but don't block request on storage failure
			c.Next()
			return
		}

		if !allowed {
			// Calculate retry-after in seconds
			retryAfter := int(time.Until(resetAt).Seconds())
			if retryAfter < 0 {
				retryAfter = int(config.Window.Seconds())
			}

			c.Header("Retry-After", fmt.Sprintf("%d", retryAfter))
			c.Header("X-RateLimit-Remaining", "0")

			c.JSON(http.StatusTooManyRequests, gin.H{
				"status":  "error",
				"message": models.RateLimitExceeded,
				"code":    "RATE_LIMIT_EXCEEDED",
				"details": gin.H{
					"limit":       config.Rate,
					"window":      config.Window.String(),
					"retry_after": retryAfter,
				},
			})
			c.Abort()
			return
		}

		c.Next()
	}
}

// getRateLimitInfo retrieves current rate limit status without decrementing
func getRateLimitInfo(ctx context.Context, store RateLimitStore, key string, config models.RateLimitConfig) (remaining int, resetAt time.Time, err error) {
	// Try to get current state from MongoDB
	if mongoStore, ok := store.(*MongoRateLimitStore); ok {
		var result models.RateLimit
		err := mongoStore.collection.FindOne(ctx, bson.M{"key": key}).Decode(&result)
		if err == nil {
			return result.Tokens, result.ExpiresAt, nil
		}
		// If not found, return full limit
		return config.Rate, time.Now().Add(config.Window), nil
	}

	// For in-memory store, return full limit (can't peek without mutex complexity)
	return config.Rate, time.Now().Add(config.Window), nil
}

// Legacy support - predefined middleware functions

// AuthRateLimitMiddleware limits authentication requests (10 per minute)
func AuthRateLimitMiddleware() gin.HandlerFunc {
	return RateLimitMiddlewareWithConfig(models.AuthRateLimitConfig)
}

// PasswordChangeRateLimitMiddleware limits password changes (5 per hour)
func PasswordChangeRateLimitMiddleware() gin.HandlerFunc {
	return RateLimitMiddlewareWithConfig(models.PasswordChangeRateLimitConfig)
}

// TokenRefreshRateLimitMiddleware limits token refresh (3 per 5 minutes)
func TokenRefreshRateLimitMiddleware() gin.HandlerFunc {
	return RateLimitMiddlewareWithConfig(models.TokenRefreshRateLimitConfig)
}

// UploadRateLimitMiddleware limits file uploads (10 per minute)
func UploadRateLimitMiddleware() gin.HandlerFunc {
	return RateLimitMiddlewareWithConfig(models.UploadRateLimitConfig)
}

// PostCreationRateLimitMiddleware limits post creation (20 per hour)
func PostCreationRateLimitMiddleware() gin.HandlerFunc {
	return RateLimitMiddlewareWithConfig(models.PostCreationRateLimitConfig)
}

// CommentRateLimitMiddleware limits comments (50 per hour)
func CommentRateLimitMiddleware() gin.HandlerFunc {
	return RateLimitMiddlewareWithConfig(models.CommentRateLimitConfig)
}

// LikeRateLimitMiddleware limits likes (100 per minute)
func LikeRateLimitMiddleware() gin.HandlerFunc {
	return RateLimitMiddlewareWithConfig(models.LikeRateLimitConfig)
}

// APIRateLimitMiddleware limits general API requests (1000 per hour)
func APIRateLimitMiddleware() gin.HandlerFunc {
	return RateLimitMiddlewareWithConfig(models.APIRateLimitConfig)
}

// TwoFactorVerifyRateLimitMiddleware limits 2FA verification (3 per minute)
func TwoFactorVerifyRateLimitMiddleware() gin.HandlerFunc {
	return RateLimitMiddlewareWithConfig(models.TwoFactorVerifyRateLimitConfig)
}

// ContactMessageRateLimitMiddleware limits contact messages (5 per hour)
func ContactMessageRateLimitMiddleware() gin.HandlerFunc {
	return RateLimitMiddlewareWithConfig(models.ContactMessageRateLimitConfig)
}

// ConfigUpdateRateLimitMiddleware limits config updates (10 per hour)
func ConfigUpdateRateLimitMiddleware() gin.HandlerFunc {
	return RateLimitMiddlewareWithConfig(models.ConfigUpdateRateLimitConfig)
}

// AdminImageUploadRateLimitMiddleware limits admin image uploads (20 per hour)
func AdminImageUploadRateLimitMiddleware() gin.HandlerFunc {
	return RateLimitMiddlewareWithConfig(models.AdminImageUploadRateLimitConfig)
}

// FileUploadRateLimitMiddleware is an alias for UploadRateLimitMiddleware
func FileUploadRateLimitMiddleware() gin.HandlerFunc {
	return UploadRateLimitMiddleware()
}

// PasswordResetRateLimitMiddleware limits password reset requests (3 per 5 minutes)
func PasswordResetRateLimitMiddleware() gin.HandlerFunc {
	return RateLimitMiddlewareWithConfig(models.PasswordResetRateLimitConfig)
}

// RateLimitMiddleware is the legacy function for backward compatibility
// Accepts either a RateLimitConfig or (rate int, window time.Duration)
func RateLimitMiddleware(params ...interface{}) gin.HandlerFunc {
	// Check if first param is a RateLimitConfig
	if len(params) == 1 {
		if config, ok := params[0].(models.RateLimitConfig); ok {
			return RateLimitMiddlewareWithConfig(config)
		}
	}

	// Legacy API: (rate int, window time.Duration)
	if len(params) == 2 {
		if rate, ok := params[0].(int); ok {
			if window, ok := params[1].(time.Duration); ok {
				config := models.RateLimitConfig{
					Name:   "legacy",
					Rate:   rate,
					Window: window,
				}
				return RateLimitMiddlewareWithConfig(config)
			}
		}
	}

	// Default to API limiter
	return APIRateLimitMiddleware()
}
