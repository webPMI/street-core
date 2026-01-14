package middlewares

import (
	"context"
	"crypto/rand"
	"encoding/base64"
	"net/http"
	"sync"
	"time"

	"backend/models"

	"github.com/gin-gonic/gin"
	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/mongo"
	"go.mongodb.org/mongo-driver/mongo/options"
)

// CSRFStore is the interface for CSRF token storage backends
type CSRFStore interface {
	Create(ctx context.Context, token string, expiresAt time.Time) error
	Validate(ctx context.Context, token string) (bool, error)
	Delete(ctx context.Context, token string) error
}

// MongoCSRFStore implements CSRFStore using MongoDB
type MongoCSRFStore struct {
	collection  *mongo.Collection
	mu          sync.Mutex
	initialized bool
}

// Global CSRF store instance with sync.Once for thread-safe fallback initialization
var (
	csrfStore         CSRFStore
	csrfFallbackStore *memoryCSRFStore
	csrfFallbackOnce  sync.Once
)

// memoryCSRFStore is a fallback in-memory implementation
type memoryCSRFStore struct {
	tokens map[string]time.Time // token -> expiresAt
	mu     sync.RWMutex
}

// InitCSRFStore initializes the CSRF store with MongoDB
// Call this during application startup after MongoDB connection is established
func InitCSRFStore(db *mongo.Database) {
	store := &MongoCSRFStore{
		collection: db.Collection("csrf_tokens"),
	}

	// Create indexes in background
	go store.ensureIndexes()

	csrfStore = store
}

// ensureIndexes creates necessary MongoDB indexes
func (s *MongoCSRFStore) ensureIndexes() {
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

	// Unique index on token for fast lookups
	tokenIndex := mongo.IndexModel{
		Keys:    bson.D{{Key: "token", Value: 1}},
		Options: options.Index().SetUnique(true),
	}
	s.collection.Indexes().CreateOne(ctx, tokenIndex)

	s.initialized = true
}

// Create stores a new CSRF token (MongoDB implementation)
func (s *MongoCSRFStore) Create(ctx context.Context, token string, expiresAt time.Time) error {
	csrfToken := models.CSRFToken{
		Token:     token,
		ExpiresAt: expiresAt,
		CreatedAt: time.Now(),
	}

	_, err := s.collection.InsertOne(ctx, csrfToken)
	return err
}

// Validate checks if a CSRF token is valid (MongoDB implementation)
func (s *MongoCSRFStore) Validate(ctx context.Context, token string) (bool, error) {
	now := time.Now()

	var csrfToken models.CSRFToken
	err := s.collection.FindOne(ctx, bson.M{
		"token":      token,
		"expires_at": bson.M{"$gt": now},
	}).Decode(&csrfToken)

	if err == mongo.ErrNoDocuments {
		return false, nil
	}
	if err != nil {
		return false, err
	}

	return true, nil
}

// Delete removes a CSRF token (MongoDB implementation)
func (s *MongoCSRFStore) Delete(ctx context.Context, token string) error {
	_, err := s.collection.DeleteOne(ctx, bson.M{"token": token})
	return err
}

// Create stores a new CSRF token (in-memory fallback)
func (s *memoryCSRFStore) Create(ctx context.Context, token string, expiresAt time.Time) error {
	s.mu.Lock()
	defer s.mu.Unlock()
	s.tokens[token] = expiresAt
	return nil
}

// Validate checks if a CSRF token is valid (in-memory fallback)
func (s *memoryCSRFStore) Validate(ctx context.Context, token string) (bool, error) {
	s.mu.RLock()
	defer s.mu.RUnlock()

	expiresAt, exists := s.tokens[token]
	if !exists {
		return false, nil
	}

	if time.Now().After(expiresAt) {
		return false, nil
	}

	return true, nil
}

// Delete removes a CSRF token (in-memory fallback)
func (s *memoryCSRFStore) Delete(ctx context.Context, token string) error {
	s.mu.Lock()
	defer s.mu.Unlock()
	delete(s.tokens, token)
	return nil
}

// getCSRFStore returns the current CSRF store (MongoDB or fallback).
// Uses sync.Once to ensure the fallback store is only created once,
// preventing race conditions and ensuring all requests use the same store.
func getCSRFStore() CSRFStore {
	if csrfStore != nil {
		return csrfStore
	}
	// Fallback to in-memory if MongoDB not initialized
	// Use sync.Once to ensure single instance across all requests
	csrfFallbackOnce.Do(func() {
		csrfFallbackStore = &memoryCSRFStore{
			tokens: make(map[string]time.Time),
		}
	})
	return csrfFallbackStore
}

// generateCSRFToken generates a cryptographically secure CSRF token
func generateCSRFToken() (string, error) {
	b := make([]byte, 32)
	_, err := rand.Read(b)
	if err != nil {
		return "", err
	}
	return base64.URLEncoding.EncodeToString(b), nil
}

// CSRFProtection middleware protects against CSRF attacks
func CSRFProtection() gin.HandlerFunc {
	return func(c *gin.Context) {
		// Only apply to state-changing methods
		if c.Request.Method == "GET" || c.Request.Method == "HEAD" || c.Request.Method == "OPTIONS" {
			c.Next()
			return
		}

		// Get token from header
		token := c.GetHeader("X-CSRF-Token")
		if token == "" {
			c.JSON(http.StatusForbidden, gin.H{
				"status":  "error",
				"message": "CSRF token missing",
				"code":    "CSRF_TOKEN_MISSING",
			})
			c.Abort()
			return
		}

		// Validate token
		store := getCSRFStore()
		ctx, cancel := context.WithTimeout(c.Request.Context(), 5*time.Second)
		defer cancel()

		valid, err := store.Validate(ctx, token)
		if err != nil {
			// Log error but reject request for security
			c.JSON(http.StatusInternalServerError, gin.H{
				"status":  "error",
				"message": "Failed to validate CSRF token",
				"code":    "CSRF_VALIDATION_ERROR",
			})
			c.Abort()
			return
		}

		if !valid {
			c.JSON(http.StatusForbidden, gin.H{
				"status":  "error",
				"message": "Invalid or expired CSRF token",
				"code":    "CSRF_TOKEN_INVALID",
			})
			c.Abort()
			return
		}

		c.Next()
	}
}

// GetCSRFToken handler returns a new CSRF token
func GetCSRFToken(c *gin.Context) {
	token, err := generateCSRFToken()
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"status":  "error",
			"message": "Failed to generate CSRF token",
		})
		return
	}

	expiresAt := time.Now().Add(models.CSRFTokenDuration)

	store := getCSRFStore()
	ctx, cancel := context.WithTimeout(c.Request.Context(), 5*time.Second)
	defer cancel()

	err = store.Create(ctx, token, expiresAt)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"status":  "error",
			"message": "Failed to store CSRF token",
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"status":     "success",
		"csrf_token": token,
		"expires_at": expiresAt.Unix(),
	})
}

// InvalidateCSRFToken removes a CSRF token (optional - for logout scenarios)
func InvalidateCSRFToken(c *gin.Context) {
	token := c.GetHeader("X-CSRF-Token")
	if token == "" {
		c.JSON(http.StatusBadRequest, gin.H{
			"status":  "error",
			"message": "No CSRF token provided",
		})
		return
	}

	store := getCSRFStore()
	ctx, cancel := context.WithTimeout(c.Request.Context(), 5*time.Second)
	defer cancel()

	err := store.Delete(ctx, token)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"status":  "error",
			"message": "Failed to invalidate CSRF token",
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"status":  "success",
		"message": "CSRF token invalidated",
	})
}
