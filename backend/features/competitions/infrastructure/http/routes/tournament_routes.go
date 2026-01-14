package routes

import (
	"backend/features/competitions/infrastructure/http/handlers"
	"backend/middlewares"
	"backend/models"
	"backend/pkg/repository"

	"github.com/gin-gonic/gin"
)

// SetupTournamentRoutes sets up all tournament routes
func SetupTournamentRoutes(router *gin.RouterGroup, handler *handlers.TournamentHandler, authService middlewares.AuthTokenVerifier, tokenRevocationService middlewares.TokenRevocationChecker, userRepo repository.IRepository[models.User]) {
	tournaments := router.Group("/tournaments")
	{
		// Public routes - anyone can view tournaments
		tournaments.GET("", handler.List)                                    // List all tournaments with pagination
		tournaments.GET("/upcoming", handler.ListUpcoming)                   // List upcoming tournaments
		tournaments.GET("/live", handler.ListLive)                           // List live tournaments
		tournaments.GET("/status/:status", handler.ListByStatus)             // List by status
		tournaments.GET("/organizer/:organizerId", handler.ListByOrganizer)  // List by organizer
		tournaments.GET("/:id", handler.Get)                                 // Get single tournament

		// Public standings routes
		tournaments.GET("/:id/standings", handler.GetStandings)              // Get tournament standings
		tournaments.GET("/:id/standings/top", handler.GetTopStandings)       // Get top N standings

		// Protected routes - require authentication
		auth := tournaments.Group("")
		auth.Use(middlewares.JWTAuthMiddleware(authService, tokenRevocationService, userRepo))
		auth.Use(middlewares.CSRFProtection()) // 🔒 CSRF protection for tournament operations
		{
			// Create tournament - Admin, Organizer, or Verified Special users
			auth.POST("", middlewares.RequireRole("admin", "organizer", "verified_special"), handler.Create)

			// Update tournament - Owner or Admin
			// auth.PUT("/:id", handler.Update) // TODO: Create UpdateTournament usecase

			// Delete tournament - Owner or Admin
			// auth.DELETE("/:id", handler.Delete) // TODO: Create DeleteTournament usecase

			// Add competition to tournament - Owner or Admin
			auth.POST("/:id/competitions", handler.AddCompetition)

			// Force standings update - Admin/Organizer only
			auth.POST("/:id/standings/update", middlewares.RequireRole("admin", "organizer", "verified_special"), handler.UpdateStandings)

			// Register for tournament - Any authenticated user
			// auth.POST("/:id/register", handler.Register) // TODO: Create RegisterToTournament usecase

			// Unregister from tournament - Any authenticated user
			// auth.DELETE("/:id/register", handler.Unregister) // TODO: Create UnregisterFromTournament usecase

			// Approve/reject registrations - Admin/Organizer only
			// auth.POST("/:id/registrations/:registrationId/approve", middlewares.RequireRole("admin", "organizer"), handler.ApproveRegistration)
			// auth.POST("/:id/registrations/:registrationId/reject", middlewares.RequireRole("admin", "organizer"), handler.RejectRegistration)

			// Bulk approve/reject
			// auth.POST("/:id/registrations/approve-many", middlewares.RequireRole("admin", "organizer"), handler.ApproveManyRegistrations)
			// auth.POST("/:id/registrations/reject-many", middlewares.RequireRole("admin", "organizer"), handler.RejectManyRegistrations)
		}
	}
}
