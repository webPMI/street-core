package routes

import (
	"backend/features/competitions/infrastructure/http/handlers"
	"backend/features/competitions/ports"
	"backend/middlewares"
	"backend/models"
	"backend/pkg/repository"

	"github.com/gin-gonic/gin"
)

// SetupCompetitionRoutes sets up all competition routes
func SetupCompetitionRoutes(router *gin.RouterGroup, handler *handlers.CompetitionHandler, categoryHandler *handlers.CategoryHandler, invitationHandler *handlers.JudgeInvitationHandler, heatHandler *handlers.HeatHandler, securityHandler *handlers.SecurityHandler, emergencyHandler *handlers.EmergencyHandler, sseHandler *handlers.SSEHandler, ownershipValidator middlewares.OwnershipValidator, authService middlewares.AuthTokenVerifier, tokenRevocationService middlewares.TokenRevocationChecker, userRepo repository.IRepository[models.User]) {
	competitions := router.Group("/competitions")
	{
		// Public routes - anyone can view competitions
		competitions.GET("", handler.List)                  // List all competitions with pagination
		competitions.GET("/upcoming", handler.ListUpcoming) // List upcoming competitions
		competitions.GET("/live", handler.ListLive)         // List live competitions
		competitions.GET("/search", handler.Search)         // Advanced search
		competitions.GET("/featured", handler.Featured)     // Featured competitions
		competitions.GET("/nearby", handler.Nearby)         // Nearby competitions
		competitions.GET("/:id", handler.Get)               // Get single competition

		// Public participant routes
		competitions.GET("/:id/participants", handler.ListParticipants)            // List participants
		competitions.GET("/:id/participants/count", handler.GetParticipantCount)   // Get participant count
		competitions.GET("/:id/participants/counts", handler.GetParticipantCounts) // Get participant counts by status
		competitions.GET("/:id/participants/pending", handler.ListPendingParticipants) // List pending participants

		// Public category routes
		competitions.GET("/:id/categories", categoryHandler.List)            // List categories
		competitions.GET("/:id/categories/:categoryId", categoryHandler.Get) // Get single category

		// Public score/leaderboard routes (public if results published)
		competitions.GET("/:id/scores", handler.GetScores)
		competitions.GET("/:id/scores/athlete/:athleteId", handler.GetScoresByAthlete)
		competitions.GET("/:id/scores/round/:roundId", handler.GetScoresByRound)
		competitions.GET("/:id/leaderboard", handler.GetLeaderboard)

		// Public heat routes - judges and spectators can view heats
		competitions.GET("/:id/heats", heatHandler.GetCompetitionHeats)                                             // Get all heats for competition
		competitions.GET("/:id/heats/:heatId", heatHandler.GetHeat)                                                 // Get single heat
		competitions.GET("/:id/rounds/:roundId/heats", heatHandler.GetRoundHeats)                                   // Get heats for round
		competitions.GET("/:id/rounds/:roundId/categories/:categoryId/heats", heatHandler.GetCategoryHeats)         // Get heats for category and round

		// Protected routes - require authentication
		auth := competitions.Group("")
		auth.Use(middlewares.JWTAuthMiddleware(authService, tokenRevocationService, userRepo))
		auth.Use(middlewares.CSRFProtection()) // 🔒 CSRF protection for competition operations
		{
			// My competitions - Get competitions where user is registered/organizer/judge
			auth.GET("/my", handler.GetMyCompetitions)

			// Create competition - Admin, Organizer, or Verified Special users
			auth.POST("", middlewares.RequireRole("admin", "organizer", "verified_special"), handler.Create)

			// Update competition - Owner or Admin
			// 🔒 SECURITY FIX (CRITICAL-1): Ownership validation at route layer (defense-in-depth)
			auth.PUT("/:id", middlewares.RequireOwnershipOrRole(ownershipValidator, "id", "organizer"), handler.Update)

			// Delete competition - Owner or Admin
			// 🔒 SECURITY FIX (CRITICAL-1): Ownership validation at route layer (defense-in-depth)
			auth.DELETE("/:id", middlewares.RequireOwnershipOrRole(ownershipValidator, "id", "organizer"), handler.Delete)

			// Competition lifecycle management - Owner or Admin only
			auth.GET("/:id/validate-start", handler.ValidateStart)    // Validate if competition can start
			auth.POST("/:id/start", handler.Start)                    // Start competition (upcoming → live)
			auth.POST("/:id/end", handler.End)                        // End competition (live → completed)
			auth.POST("/:id/postpone", handler.Postpone)              // Postpone competition
			auth.POST("/:id/publish-results", handler.PublishResults) // Publish results

			// Register/Unregister for competition - Any authenticated user
			auth.POST("/:id/register", handler.Register)
			auth.DELETE("/:id/register", handler.Unregister)

			// Submit scores - Judges or Admin only
			auth.POST("/:id/scores", handler.SubmitScore)

			// Force leaderboard update - Admin/Organizer only
			auth.POST("/:id/leaderboard/update", middlewares.RequireRole("admin", "organizer"), handler.UpdateLeaderboard)

			// Category management - Admin/Organizer only
			auth.POST("/:id/categories", middlewares.RequireRole("admin", "organizer"), categoryHandler.Create)
			auth.PUT("/:id/categories/:categoryId", middlewares.RequireRole("admin", "organizer"), categoryHandler.Update)
			auth.DELETE("/:id/categories/:categoryId", middlewares.RequireRole("admin", "organizer"), categoryHandler.Delete)

			// Category participant management
			auth.POST("/:id/categories/:categoryId/participants", categoryHandler.AddParticipant)
			auth.DELETE("/:id/categories/:categoryId/participants/:participantId", categoryHandler.RemoveParticipant)

			// Category judge management - Admin/Organizer only
			auth.POST("/:id/categories/:categoryId/judges", middlewares.RequireRole("admin", "organizer"), categoryHandler.AddJudge)
			auth.DELETE("/:id/categories/:categoryId/judges/:judgeId", middlewares.RequireRole("admin", "organizer"), categoryHandler.RemoveJudge)

			// Judge invitation management
			auth.GET("/judge-invitations/my", invitationHandler.ListMyInvitations)           // My invitations
			auth.POST("/judge-invitations/:invitationId/respond", invitationHandler.Respond) // Accept/decline invitation

			// Competition-specific judge invitations - Admin/Organizer only
			auth.GET("/:id/judge-invitations", middlewares.RequireRole("admin", "organizer"), invitationHandler.ListByCompetition)
			auth.POST("/:id/judge-invitations", middlewares.RequireRole("admin", "organizer"), invitationHandler.Create)
			auth.DELETE("/:id/judge-invitations/:invitationId", middlewares.RequireRole("admin", "organizer"), invitationHandler.Cancel)

			// Heat management - Admin/Organizer only
			auth.POST("/:id/rounds/:roundId/heats/generate", middlewares.RequireRole("admin", "organizer"), heatHandler.GenerateHeats)  // Generate heats for round
			auth.POST("/:id/heats/:heatId/complete", middlewares.RequireRole("admin", "organizer"), heatHandler.CompleteHeat)           // Mark heat as completed
			auth.POST("/:id/rounds/:roundId/heats/reset", middlewares.RequireRole("admin", "organizer"), heatHandler.ResetHeats)        // Reset (delete) all heats for round

			// =========================================================================
			// SECURITY ROUTES - CHECK-IN SYSTEM (Ready Protocol)
			// =========================================================================
			auth.POST("/:id/heats/:heatId/roles/assign", middlewares.RequireRole("admin"), securityHandler.AssignRole)
			auth.POST("/:id/heats/:heatId/checkin", securityHandler.CheckIn)
			auth.POST("/:id/heats/:heatId/checkout", securityHandler.CheckOut)
			auth.DELETE("/:id/heats/:heatId/roles/unassign", middlewares.RequireRole("admin"), securityHandler.UnassignRole)

			// =========================================================================
			// SECURITY ROUTES - CONTINGENCY MANAGEMENT (Crisis Control)
			// =========================================================================
			// Order: JWTAuth -> Audit -> RBAC -> Handler
			auth.POST("/:id/heats/:heatId/roles/replace", middlewares.RequireRole("admin"), securityHandler.ReplaceRole)
			auth.POST("/:id/heats/:heatId/bypass-judge", middlewares.RequireRole("admin"), securityHandler.BypassJudge)

			// =========================================================================
			// SECURITY ROUTES - MASTER PAUSE SYSTEM
			// =========================================================================
			auth.POST("/:id/heats/:heatId/pause", middlewares.RequireRole("admin"), securityHandler.PauseHeat)
			auth.POST("/:id/heats/:heatId/resume", middlewares.RequireRole("admin"), securityHandler.ResumeHeat)

			// =========================================================================
			// SECURITY ROUTES - SCORE UNLOCK SYSTEM (Grace Period)
			// =========================================================================
			auth.POST("/:id/scores/:scoreId/unlock/request", securityHandler.RequestScoreUnlock)
			auth.POST("/:id/scores/:scoreId/unlock/authorize", middlewares.RequireRole("admin"), securityHandler.AuthorizeScoreUnlock)
			auth.POST("/:id/scores/:scoreId/unlock/deny", middlewares.RequireRole("admin"), securityHandler.DenyScoreUnlock)

			// =========================================================================
			// SECURITY ROUTES - SPEAKER DASHBOARD (Real-time Panel)
			// =========================================================================
			auth.GET("/:id/heats/:heatId/speaker-dashboard", securityHandler.GetSpeakerDashboard)

			// =========================================================================
			// EMERGENCY ROUTES - CRISIS MANAGEMENT (X-Games, UCI BMX scenarios)
			// =========================================================================
			auth.POST("/:id/heats/:heatId/emergency/resolve-tie", middlewares.RequireRole("admin"), emergencyHandler.ResolveTieBreak)
			auth.POST("/:id/scores/:scoreId/emergency/under-review", middlewares.RequireRole("admin"), emergencyHandler.SetScoreUnderReview)
			auth.POST("/:id/scores/:scoreId/emergency/resolve-review", middlewares.RequireRole("admin"), emergencyHandler.ResolveScoreReview)
			auth.POST("/:id/heats/:heatId/emergency/freeze", middlewares.RequireRole("admin"), emergencyHandler.FreezeHeat)
			auth.POST("/:id/heats/:heatId/emergency/resume", middlewares.RequireRole("admin"), emergencyHandler.ResumeHeat)
			auth.POST("/:id/heats/:heatId/emergency/swap-scores", middlewares.RequireRole("admin"), emergencyHandler.SwapAthleteScores)
			auth.POST("/:id/heats/:heatId/emergency/rollback", middlewares.RequireRole("admin"), emergencyHandler.RollbackHeat)

			// NEW: BLOQUE 2 - Emergency Score Management
			auth.POST("/:id/heats/:heatId/emergency/reset-athlete", middlewares.RequireRole("admin"), emergencyHandler.ResetSingleAthleteScore)
			auth.POST("/:id/scores/:scoreId/emergency/admin-override", middlewares.RequireRole("admin"), emergencyHandler.AdminOverrideScore)

			// =========================================================================
			// REAL-TIME EVENTS - BLOQUE 3 (SSE for Speaker Dashboard)
			// =========================================================================
			// Speaker subscribes to real-time competition updates
			auth.GET("/:id/events", sseHandler.StreamCompetitionEvents)
			// Monitor active SSE connections
			auth.GET("/:id/events/subscribers", middlewares.RequireRole("admin"), sseHandler.GetSubscriberCount)
		}
	}
}

// SetupCompetitionRoutesWithPorts sets up routes using the ports.Dependencies interface.
// This provides a more decoupled way to set up routes without depending on external packages.
func SetupCompetitionRoutesWithPorts(router *gin.RouterGroup, handler *handlers.CompetitionHandler, categoryHandler *handlers.CategoryHandler, invitationHandler *handlers.JudgeInvitationHandler, heatHandler *handlers.HeatHandler, securityHandler *handlers.SecurityHandler, emergencyHandler *handlers.EmergencyHandler, sseHandler *handlers.SSEHandler, deps *ports.Dependencies) {
	competitions := router.Group("/competitions")
	{
		// Public routes - anyone can view competitions
		competitions.GET("", handler.List)
		competitions.GET("/upcoming", handler.ListUpcoming)
		competitions.GET("/live", handler.ListLive)
		competitions.GET("/search", handler.Search)
		competitions.GET("/featured", handler.Featured)
		competitions.GET("/nearby", handler.Nearby)
		competitions.GET("/:id", handler.Get)

		// Public participant routes
		competitions.GET("/:id/participants", handler.ListParticipants)
		competitions.GET("/:id/participants/count", handler.GetParticipantCount)
		competitions.GET("/:id/participants/counts", handler.GetParticipantCounts)
		competitions.GET("/:id/participants/pending", handler.ListPendingParticipants)

		// Public category routes
		competitions.GET("/:id/categories", categoryHandler.List)
		competitions.GET("/:id/categories/:categoryId", categoryHandler.Get)

		// Public score/leaderboard routes
		competitions.GET("/:id/scores", handler.GetScores)
		competitions.GET("/:id/scores/athlete/:athleteId", handler.GetScoresByAthlete)
		competitions.GET("/:id/scores/round/:roundId", handler.GetScoresByRound)
		competitions.GET("/:id/leaderboard", handler.GetLeaderboard)

		// Public heat routes - judges and spectators can view heats
		competitions.GET("/:id/heats", heatHandler.GetCompetitionHeats)
		competitions.GET("/:id/heats/:heatId", heatHandler.GetHeat)
		competitions.GET("/:id/rounds/:roundId/heats", heatHandler.GetRoundHeats)
		competitions.GET("/:id/rounds/:roundId/categories/:categoryId/heats", heatHandler.GetCategoryHeats)

		// Protected routes - require authentication
		auth := competitions.Group("")
		auth.Use(portsAuthMiddleware(deps))
		auth.Use(middlewares.CSRFProtection())
		{
			auth.GET("/my", handler.GetMyCompetitions)
			auth.POST("", middlewares.RequireRole("admin", "organizer", "verified_special"), handler.Create)
			auth.PUT("/:id", handler.Update)
			auth.DELETE("/:id", handler.Delete)
			auth.GET("/:id/validate-start", handler.ValidateStart)
			auth.POST("/:id/start", handler.Start)
			auth.POST("/:id/end", handler.End)
			auth.POST("/:id/publish-results", handler.PublishResults)
			auth.POST("/:id/register", handler.Register)
			auth.DELETE("/:id/register", handler.Unregister)
			auth.POST("/:id/scores", handler.SubmitScore)
			auth.POST("/:id/leaderboard/update", middlewares.RequireRole("admin", "organizer"), handler.UpdateLeaderboard)
			auth.POST("/:id/categories", middlewares.RequireRole("admin", "organizer"), categoryHandler.Create)
			auth.PUT("/:id/categories/:categoryId", middlewares.RequireRole("admin", "organizer"), categoryHandler.Update)
			auth.DELETE("/:id/categories/:categoryId", middlewares.RequireRole("admin", "organizer"), categoryHandler.Delete)
			auth.POST("/:id/categories/:categoryId/participants", categoryHandler.AddParticipant)
			auth.DELETE("/:id/categories/:categoryId/participants/:participantId", categoryHandler.RemoveParticipant)
			auth.POST("/:id/categories/:categoryId/judges", middlewares.RequireRole("admin", "organizer"), categoryHandler.AddJudge)
			auth.DELETE("/:id/categories/:categoryId/judges/:judgeId", middlewares.RequireRole("admin", "organizer"), categoryHandler.RemoveJudge)
			auth.GET("/judge-invitations/my", invitationHandler.ListMyInvitations)
			auth.POST("/judge-invitations/:invitationId/respond", invitationHandler.Respond)
			auth.GET("/:id/judge-invitations", middlewares.RequireRole("admin", "organizer"), invitationHandler.ListByCompetition)
			auth.POST("/:id/judge-invitations", middlewares.RequireRole("admin", "organizer"), invitationHandler.Create)
			auth.DELETE("/:id/judge-invitations/:invitationId", middlewares.RequireRole("admin", "organizer"), invitationHandler.Cancel)

			// Heat management - Admin/Organizer only
			auth.POST("/:id/rounds/:roundId/heats/generate", middlewares.RequireRole("admin", "organizer"), heatHandler.GenerateHeats)
			auth.POST("/:id/heats/:heatId/complete", middlewares.RequireRole("admin", "organizer"), heatHandler.CompleteHeat)
			auth.POST("/:id/rounds/:roundId/heats/reset", middlewares.RequireRole("admin", "organizer"), heatHandler.ResetHeats)

			// =========================================================================
			// SECURITY ROUTES - CHECK-IN SYSTEM (Ready Protocol)
			// =========================================================================
			auth.POST("/:id/heats/:heatId/roles/assign", middlewares.RequireRole("admin"), securityHandler.AssignRole)
			auth.POST("/:id/heats/:heatId/checkin", securityHandler.CheckIn)
			auth.POST("/:id/heats/:heatId/checkout", securityHandler.CheckOut)
			auth.DELETE("/:id/heats/:heatId/roles/unassign", middlewares.RequireRole("admin"), securityHandler.UnassignRole)

			// =========================================================================
			// SECURITY ROUTES - CONTINGENCY MANAGEMENT (Crisis Control)
			// =========================================================================
			auth.POST("/:id/heats/:heatId/roles/replace", middlewares.RequireRole("admin"), securityHandler.ReplaceRole)
			auth.POST("/:id/heats/:heatId/bypass-judge", middlewares.RequireRole("admin"), securityHandler.BypassJudge)

			// =========================================================================
			// SECURITY ROUTES - MASTER PAUSE SYSTEM
			// =========================================================================
			auth.POST("/:id/heats/:heatId/pause", middlewares.RequireRole("admin"), securityHandler.PauseHeat)
			auth.POST("/:id/heats/:heatId/resume", middlewares.RequireRole("admin"), securityHandler.ResumeHeat)

			// =========================================================================
			// SECURITY ROUTES - SCORE UNLOCK SYSTEM (Grace Period)
			// =========================================================================
			auth.POST("/:id/scores/:scoreId/unlock/request", securityHandler.RequestScoreUnlock)
			auth.POST("/:id/scores/:scoreId/unlock/authorize", middlewares.RequireRole("admin"), securityHandler.AuthorizeScoreUnlock)
			auth.POST("/:id/scores/:scoreId/unlock/deny", middlewares.RequireRole("admin"), securityHandler.DenyScoreUnlock)

			// =========================================================================
			// SECURITY ROUTES - SPEAKER DASHBOARD (Real-time Panel)
			// =========================================================================
			auth.GET("/:id/heats/:heatId/speaker-dashboard", securityHandler.GetSpeakerDashboard)

			// =========================================================================
			// EMERGENCY ROUTES - CRISIS MANAGEMENT (X-Games, UCI BMX scenarios)
			// =========================================================================
			auth.POST("/:id/heats/:heatId/emergency/resolve-tie", middlewares.RequireRole("admin"), emergencyHandler.ResolveTieBreak)
			auth.POST("/:id/scores/:scoreId/emergency/under-review", middlewares.RequireRole("admin"), emergencyHandler.SetScoreUnderReview)
			auth.POST("/:id/scores/:scoreId/emergency/resolve-review", middlewares.RequireRole("admin"), emergencyHandler.ResolveScoreReview)
			auth.POST("/:id/heats/:heatId/emergency/freeze", middlewares.RequireRole("admin"), emergencyHandler.FreezeHeat)
			auth.POST("/:id/heats/:heatId/emergency/resume", middlewares.RequireRole("admin"), emergencyHandler.ResumeHeat)
			auth.POST("/:id/heats/:heatId/emergency/swap-scores", middlewares.RequireRole("admin"), emergencyHandler.SwapAthleteScores)
			auth.POST("/:id/heats/:heatId/emergency/rollback", middlewares.RequireRole("admin"), emergencyHandler.RollbackHeat)

			// NEW: BLOQUE 2 - Emergency Score Management
			auth.POST("/:id/heats/:heatId/emergency/reset-athlete", middlewares.RequireRole("admin"), emergencyHandler.ResetSingleAthleteScore)
			auth.POST("/:id/scores/:scoreId/emergency/admin-override", middlewares.RequireRole("admin"), emergencyHandler.AdminOverrideScore)

			// =========================================================================
			// REAL-TIME EVENTS - BLOQUE 3 (SSE for Speaker Dashboard)
			// =========================================================================
			// Speaker subscribes to real-time competition updates
			auth.GET("/:id/events", sseHandler.StreamCompetitionEvents)
			// Monitor active SSE connections
			auth.GET("/:id/events/subscribers", middlewares.RequireRole("admin"), sseHandler.GetSubscriberCount)
		}
	}
}

// portsAuthMiddleware creates an auth middleware from ports.Dependencies
func portsAuthMiddleware(deps *ports.Dependencies) gin.HandlerFunc {
	// Create a wrapper that implements the required interface
	return middlewares.JWTAuthMiddlewareWithInterfaces(deps.AuthVerifier, deps.TokenChecker)
}
