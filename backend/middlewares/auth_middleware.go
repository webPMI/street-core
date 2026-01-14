package middlewares

import (
	"context"
	"net/http"
	"strings"
	"time"

	"backend/app/dto/response"
	"backend/models"
	"backend/pkg/repository"

	"github.com/gin-gonic/gin"
	"go.mongodb.org/mongo-driver/bson/primitive"
)

// Context keys for storing authentication data
const (
	UserIDKey   = "userID"
	UserRoleKey = "userRole"
)

// AuthTokenVerifier interface for verifying JWT tokens
// This interface is defined here to avoid import cycles with features/auth
type AuthTokenVerifier interface {
	VerifyAuthToken(tokenString string) (map[string]interface{}, error)
}

// TokenRevocationChecker interface for checking token revocation status
type TokenRevocationChecker interface {
	IsTokenRevoked(ctx context.Context, token string) (bool, error)
}

// JWTAuthMiddleware crea un middleware que verifica la validez de un token JWT.
// Recibe las dependencias necesarias para validar el token, su revocación y versión.
func JWTAuthMiddleware(
	authService AuthTokenVerifier,
	revocationService TokenRevocationChecker,
	userRepo repository.IRepository[models.User],
) gin.HandlerFunc {
	return func(c *gin.Context) {
		// 1. Obtener la cabecera Authorization (ej: "Bearer eyJhbGciOi...")
		authHeader := c.GetHeader("Authorization")

		// Verificar que la cabecera existe y tiene el formato correcto.
		if authHeader == "" || !strings.HasPrefix(authHeader, "Bearer ") {
			response.Error(c, http.StatusUnauthorized, models.Unauthorized)
			c.Abort() // Detiene el procesamiento de la solicitud
			return
		}

		// 2. Extraer el token de la cadena "Bearer [token]"
		tokenString := strings.TrimPrefix(authHeader, "Bearer ")

		// 3. Llamar al servicio de autenticación para verificar y obtener los claims
		claims, err := authService.VerifyAuthToken(tokenString)

		if err != nil {
			// El token es inválido, expiró, o la firma es incorrecta
			response.Error(c, http.StatusUnauthorized, models.InvalidToken)
			c.Abort() // Detiene el procesamiento
			return
		}

		// 4. Verificar si el token ha sido revocado (blacklist check)
		jtiAny, hasJTI := claims["jti"]
		if hasJTI {
			if jti, ok := jtiAny.(string); ok && jti != "" {
				isRevoked, err := revocationService.IsTokenRevoked(c.Request.Context(), jti)
				if err != nil {
					// Log error but continue - fail open for availability
					// In production, you might want to fail closed
					response.Error(c, http.StatusInternalServerError, models.ServerError)
					c.Abort()
					return
				}
				if isRevoked {
					response.Error(c, http.StatusUnauthorized, models.InvalidToken)
					c.Abort()
					return
				}
			}
		}

		// 5. Extraer el ID de usuario (claim "sub")
		userIDAny, ok := claims["sub"]
		if !ok {
			response.Error(c, http.StatusUnauthorized, models.InvalidToken)
			c.Abort()
			return
		}

		// Convertir el ID a string
		userIDStr, ok := userIDAny.(string)
		if !ok || userIDStr == "" {
			response.Error(c, http.StatusInternalServerError, models.ServerError)
			c.Abort()
			return
		}

		// 6. Verificar la versión del token contra la versión del usuario
		tokenVersionAny, hasVersion := claims["ver"]
		if hasVersion {
			// Use request context for proper cancellation propagation
			ctx, cancel := context.WithTimeout(c.Request.Context(), 5*time.Second)
			defer cancel()

			userObjID, err := primitive.ObjectIDFromHex(userIDStr)
			if err != nil {
				response.Error(c, http.StatusUnauthorized, models.InvalidToken)
				c.Abort()
				return
			}

			user, err := userRepo.GetByID(ctx, userObjID)
			if err != nil || user == nil {
				response.Error(c, http.StatusUnauthorized, models.InvalidToken)
				c.Abort()
				return
			}

			// Convert token version to int
			tokenVersion := 0
			if tv, ok := tokenVersionAny.(float64); ok {
				tokenVersion = int(tv)
			}

			// If user's current token version is higher, this token is invalidated
			if user.TokenVersion > tokenVersion {
				response.Error(c, http.StatusUnauthorized, models.InvalidToken)
				c.Abort()
				return
			}
		}

		// 7. Extract and inject user role from claims (for RBAC)
		userRoleAny, roleExists := claims["role"]
		if roleExists {
			if userRole, ok := userRoleAny.(string); ok {
				c.Set(UserRoleKey, userRole)
			}
		}

		// 8. INYECTAR el ID de usuario en el contexto de Gin.
		c.Set(UserIDKey, userIDStr)

		// Continuar con el siguiente middleware/handler
		c.Next()
	}
}

// JWTAuthMiddlewareWithInterfaces creates an auth middleware using generic interfaces.
// This allows modules to use the middleware without depending on specific implementations.
// It creates an internal user lookup using the database.
func JWTAuthMiddlewareWithInterfaces(
	authService AuthTokenVerifier,
	revocationService TokenRevocationChecker,
) gin.HandlerFunc {
	return func(c *gin.Context) {
		// 1. Get Authorization header
		authHeader := c.GetHeader("Authorization")
		if authHeader == "" || !strings.HasPrefix(authHeader, "Bearer ") {
			response.Error(c, http.StatusUnauthorized, models.Unauthorized)
			c.Abort()
			return
		}

		// 2. Extract token
		tokenString := strings.TrimPrefix(authHeader, "Bearer ")

		// 3. Verify token
		claims, err := authService.VerifyAuthToken(tokenString)
		if err != nil {
			response.Error(c, http.StatusUnauthorized, models.InvalidToken)
			c.Abort()
			return
		}

		// 4. Check token revocation
		if jtiAny, hasJTI := claims["jti"]; hasJTI {
			if jti, ok := jtiAny.(string); ok && jti != "" {
				isRevoked, err := revocationService.IsTokenRevoked(c.Request.Context(), jti)
				if err != nil {
					response.Error(c, http.StatusInternalServerError, models.ServerError)
					c.Abort()
					return
				}
				if isRevoked {
					response.Error(c, http.StatusUnauthorized, models.InvalidToken)
					c.Abort()
					return
				}
			}
		}

		// 5. Extract user ID
		userIDAny, ok := claims["sub"]
		if !ok {
			response.Error(c, http.StatusUnauthorized, models.InvalidToken)
			c.Abort()
			return
		}

		userIDStr, ok := userIDAny.(string)
		if !ok || userIDStr == "" {
			response.Error(c, http.StatusInternalServerError, models.ServerError)
			c.Abort()
			return
		}

		// 6. Extract and inject user role from claims
		if userRoleAny, roleExists := claims["role"]; roleExists {
			if userRole, ok := userRoleAny.(string); ok {
				c.Set(UserRoleKey, userRole)
			}
		}

		// 7. Inject user ID into context
		c.Set(UserIDKey, userIDStr)

		c.Next()
	}
}

// AdminOnlyMiddleware checks if the authenticated user has admin role
// Must be used AFTER JWTAuthMiddleware
func AdminOnlyMiddleware() gin.HandlerFunc {
	return func(c *gin.Context) {
		userRole, exists := c.Get(UserRoleKey)
		if !exists {
			response.Error(c, http.StatusForbidden, models.Unauthorized)
			c.Abort()
			return
		}

		role, ok := userRole.(string)
		if !ok || role != "admin" {
			response.Error(c, http.StatusForbidden, models.Unauthorized)
			c.Abort()
			return
		}

		c.Next()
	}
}
