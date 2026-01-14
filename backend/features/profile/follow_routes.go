package profile

import (
	"backend/middlewares"
	"backend/models"
	"backend/pkg/repository"

	"github.com/gin-gonic/gin"
)

// RegisterRoutes registra todas las rutas del módulo de seguidores
func RegisterRoutes(v1 *gin.RouterGroup, followService IFollowService, userService UserService, authService middlewares.AuthTokenVerifier, tokenRevocationService middlewares.TokenRevocationChecker, userRepo repository.IRepository[models.User]) {
	handler := NewFollowHandler(followService, NewUserAdapter(userService))

	// Rutas públicas - Obtener seguidores/siguiendo (no requiere autenticación)
	publicFollow := v1.Group("/users")
	publicFollow.Use(middlewares.APIRateLimitMiddleware())
	{
		publicFollow.GET("/:userId/followers", handler.GetFollowers)
		publicFollow.GET("/:userId/following", handler.GetFollowing)
		publicFollow.GET("/:userId/stats", handler.GetFollowStats)
	}

	// Rutas protegidas - Acciones de seguir/dejar de seguir (requiere autenticación JWT)
	protectedFollow := v1.Group("/users")
	protectedFollow.Use(middlewares.JWTAuthMiddleware(authService, tokenRevocationService, userRepo))
	protectedFollow.Use(middlewares.CSRFProtection()) // 🔒 CSRF protection for follow operations
	{
		// Seguir/dejar de seguir
		protectedFollow.POST("/:userId/follow",
			middlewares.AuditLog("follow_user"),
			handler.FollowUser)

		protectedFollow.DELETE("/:userId/follow",
			middlewares.AuditLog("unfollow_user"),
			handler.UnfollowUser)

		// Verificar estado de seguimiento
		protectedFollow.GET("/:userId/follow/status", handler.GetFollowStatus)

		// Bloquear/desbloquear
		protectedFollow.POST("/:userId/block",
			middlewares.AuditLog("block_user"),
			handler.BlockUser)

		protectedFollow.DELETE("/:userId/block",
			middlewares.AuditLog("unblock_user"),
			handler.UnblockUser)
	}

	// Gestión de solicitudes de seguimiento
	followRequests := v1.Group("/follow")
	followRequests.Use(middlewares.JWTAuthMiddleware(authService, tokenRevocationService, userRepo))
	followRequests.Use(middlewares.CSRFProtection()) // 🔒 CSRF protection for follow request operations
	{
		// Obtener solicitudes pendientes
		followRequests.GET("/requests", handler.GetPendingRequests)

		// Aceptar/rechazar solicitudes
		followRequests.PUT("/requests/:id/accept",
			middlewares.AuditLog("accept_follow_request"),
			handler.AcceptFollowRequest)

		followRequests.PUT("/requests/:id/reject",
			middlewares.AuditLog("reject_follow_request"),
			handler.RejectFollowRequest)
	}

	// Gestión de bloqueos
	blocks := v1.Group("/blocks")
	blocks.Use(middlewares.JWTAuthMiddleware(authService, tokenRevocationService, userRepo))
	{
		blocks.GET("", handler.GetBlockedUsers)
	}
}
