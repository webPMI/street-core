package realtime

import (
	"context"
	"fmt"
	"sync"

	"github.com/gin-contrib/sse"
	"go.mongodb.org/mongo-driver/bson/primitive"
)

// SSEHub manages Server-Sent Events connections for real-time notifications
// CRITICAL: Used by Speaker to receive emergency updates without page refresh
type SSEHub struct {
	// Competition-based channels: competitionID -> list of client channels
	competitions map[string][]chan sse.Event
	mu           sync.RWMutex
}

// NewSSEHub creates a new SSE hub
func NewSSEHub() *SSEHub {
	return &SSEHub{
		competitions: make(map[string][]chan sse.Event),
	}
}

// Subscribe registers a new SSE client for a competition
// Returns a channel that will receive events
func (h *SSEHub) Subscribe(competitionID primitive.ObjectID) chan sse.Event {
	h.mu.Lock()
	defer h.mu.Unlock()

	clientChan := make(chan sse.Event, 10) // Buffered to prevent blocking
	key := competitionID.Hex()

	h.competitions[key] = append(h.competitions[key], clientChan)

	fmt.Printf("INFO: SSE client subscribed to competition %s (total: %d)\n",
		key, len(h.competitions[key]))

	return clientChan
}

// Unsubscribe removes a client channel
func (h *SSEHub) Unsubscribe(competitionID primitive.ObjectID, clientChan chan sse.Event) {
	h.mu.Lock()
	defer h.mu.Unlock()

	key := competitionID.Hex()
	clients := h.competitions[key]

	// Remove the client channel
	for i, ch := range clients {
		if ch == clientChan {
			// Close the channel
			close(ch)

			// Remove from slice
			h.competitions[key] = append(clients[:i], clients[i+1:]...)
			break
		}
	}

	// Clean up empty competition entries
	if len(h.competitions[key]) == 0 {
		delete(h.competitions, key)
	}

	fmt.Printf("INFO: SSE client unsubscribed from competition %s (remaining: %d)\n",
		key, len(h.competitions[key]))
}

// Broadcast sends an event to all clients subscribed to a competition
func (h *SSEHub) Broadcast(competitionID primitive.ObjectID, event sse.Event) {
	h.mu.RLock()
	defer h.mu.RUnlock()

	key := competitionID.Hex()
	clients := h.competitions[key]

	if len(clients) == 0 {
		fmt.Printf("INFO: No SSE clients for competition %s, skipping broadcast\n", key)
		return
	}

	fmt.Printf("INFO: Broadcasting to %d SSE clients for competition %s\n",
		len(clients), key)

	// Send to all clients (non-blocking)
	for _, clientChan := range clients {
		select {
		case clientChan <- event:
			// Event sent successfully
		default:
			// Channel full, skip this client (prevents blocking)
			fmt.Printf("WARN: SSE client channel full, dropping event for competition %s\n", key)
		}
	}
}

// BroadcastToMultiple sends an event to multiple competitions
func (h *SSEHub) BroadcastToMultiple(competitionIDs []primitive.ObjectID, event sse.Event) {
	for _, compID := range competitionIDs {
		h.Broadcast(compID, event)
	}
}

// GetSubscriberCount returns the number of active subscribers for a competition
func (h *SSEHub) GetSubscriberCount(competitionID primitive.ObjectID) int {
	h.mu.RLock()
	defer h.mu.RUnlock()

	key := competitionID.Hex()
	return len(h.competitions[key])
}

// Shutdown closes all client channels
func (h *SSEHub) Shutdown(ctx context.Context) error {
	h.mu.Lock()
	defer h.mu.Unlock()

	for compID, clients := range h.competitions {
		for _, clientChan := range clients {
			close(clientChan)
		}
		delete(h.competitions, compID)
	}

	fmt.Println("INFO: SSE hub shutdown complete")
	return nil
}
