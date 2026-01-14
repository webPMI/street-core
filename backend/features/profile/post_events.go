package profile

import (
	"context"
	"sync"
	"time"

	"backend/utils"

	"go.mongodb.org/mongo-driver/bson/primitive"
)

// PostEvent represents an event that occurred on a post
type PostEvent struct {
	Type      PostEventType
	PostID    primitive.ObjectID
	UserID    primitive.ObjectID
	UserName  string
	Avatar    string
	Mentions  []string
	Timestamp time.Time
}

// PostEventType defines the type of post event
type PostEventType string

const (
	PostEventCreated PostEventType = "created"
	PostEventDeleted PostEventType = "deleted"
	PostEventUpdated PostEventType = "updated"
)

// PostEventHandler handles side effects of post events.
// This separates the core post operations from side effects like
// notifications, counter updates, and analytics.
type PostEventHandler struct {
	userService         UserService
	notificationService *NotificationService
	wg                  sync.WaitGroup
}

// NewPostEventHandler creates a new post event handler
func NewPostEventHandler(userService UserService, notificationService *NotificationService) *PostEventHandler {
	return &PostEventHandler{
		userService:         userService,
		notificationService: notificationService,
	}
}

// HandlePostCreated handles side effects when a post is created.
// This runs asynchronously but with proper error logging.
func (h *PostEventHandler) HandlePostCreated(event PostEvent) {
	h.wg.Add(1)
	go func() {
		defer h.wg.Done()

		// Use a timeout context for background operations
		ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
		defer cancel()

		// Increment user post count
		if h.userService != nil {
			if err := h.userService.IncrementPostCountWithContext(ctx, event.UserID.Hex()); err != nil {
				utils.Error("Failed to increment post count", map[string]interface{}{
					"user_id": event.UserID.Hex(),
					"post_id": event.PostID.Hex(),
					"error":   err.Error(),
				})
			}
		}

		// Create mention notifications
		if len(event.Mentions) > 0 && h.notificationService != nil {
			h.notificationService.CreateMentionNotificationsFromUsernames(
				ctx,
				event.Mentions,
				event.UserID,
				event.UserName,
				event.Avatar,
				event.PostID,
			)
		}
	}()
}

// HandlePostDeleted handles side effects when a post is deleted.
func (h *PostEventHandler) HandlePostDeleted(event PostEvent) {
	h.wg.Add(1)
	go func() {
		defer h.wg.Done()

		ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
		defer cancel()

		// Decrement user post count
		if h.userService != nil {
			if err := h.userService.DecrementPostCountWithContext(ctx, event.UserID.Hex()); err != nil {
				utils.Error("Failed to decrement post count", map[string]interface{}{
					"user_id": event.UserID.Hex(),
					"post_id": event.PostID.Hex(),
					"error":   err.Error(),
				})
			}
		}
	}()
}

// IncrementPostCountSync synchronously increments the post count.
// Use this for transactional operations where async is not appropriate.
func (h *PostEventHandler) IncrementPostCountSync(ctx context.Context, userID string) error {
	if h.userService == nil {
		return nil
	}
	return h.userService.IncrementPostCountWithContext(ctx, userID)
}

// DecrementPostCountSync synchronously decrements the post count.
// Use this for transactional operations where async is not appropriate.
func (h *PostEventHandler) DecrementPostCountSync(ctx context.Context, userID string) error {
	if h.userService == nil {
		return nil
	}
	return h.userService.DecrementPostCountWithContext(ctx, userID)
}

// Wait waits for all background event handlers to complete.
// Useful for graceful shutdown.
func (h *PostEventHandler) Wait() {
	h.wg.Wait()
}

// WaitWithTimeout waits for handlers with a timeout.
// Returns true if all handlers completed, false if timed out.
func (h *PostEventHandler) WaitWithTimeout(timeout time.Duration) bool {
	done := make(chan struct{})
	go func() {
		h.wg.Wait()
		close(done)
	}()

	select {
	case <-done:
		return true
	case <-time.After(timeout):
		return false
	}
}
