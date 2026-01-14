package livestreams

import (
	"github.com/gin-gonic/gin"
	"go.mongodb.org/mongo-driver/mongo"
)

// RegisterRoutes registers all livestream routes
func RegisterRoutes(router *gin.RouterGroup, db *mongo.Database, authMiddleware gin.HandlerFunc) {
	handler := NewLiveStreamHandler(db)

	// Public routes (no authentication required)
	public := router.Group("/livestreams")
	{
		// Stream discovery
		public.GET("/live", handler.GetLiveStreams)           // Get all live streams
		public.GET("/scheduled", handler.GetScheduledStreams) // Get scheduled streams
		public.GET("/search", handler.SearchStreams)          // Search streams
		public.GET("/:id", handler.GetLiveStream)             // Get specific stream
		public.GET("/:id/stats", handler.GetStreamStats)      // Get stream statistics
		public.GET("/:id/viewers", handler.GetStreamViewers)  // Get stream viewers
		public.GET("/:id/chat", handler.GetChatMessages)      // Get chat messages (read-only)
	}

	// Protected routes (authentication required)
	protected := router.Group("/livestreams")
	protected.Use(authMiddleware)
	{
		// Stream management
		protected.POST("", handler.CreateLiveStream)          // Create new livestream
		protected.PATCH("/:id", handler.UpdateLiveStream)     // Update livestream
		protected.DELETE("/:id", handler.DeleteLiveStream)    // Delete livestream
		protected.GET("/my-streams", handler.GetMyStreams)    // Get user's streams

		// Stream lifecycle
		protected.POST("/:id/start", handler.StartLiveStream)   // Start scheduled stream
		protected.POST("/:id/end", handler.EndLiveStream)       // End live stream
		protected.POST("/:id/cancel", handler.CancelLiveStream) // Cancel scheduled stream

		// Viewer actions
		protected.POST("/:id/join", handler.JoinStream)   // Join as viewer
		protected.POST("/:id/leave", handler.LeaveStream) // Leave stream

		// Interaction
		protected.POST("/:id/chat", handler.SendChatMessage) // Send chat message
		protected.POST("/:id/react", handler.SendReaction)   // Send reaction
	}
}
