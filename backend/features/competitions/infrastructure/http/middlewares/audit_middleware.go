package middlewares

import (
	"fmt"
	"time"

	globalMiddlewares "backend/middlewares"

	"github.com/gin-gonic/gin"
)

// AuditCrisisAction registra acciones críticas con UserID y contexto completo
//
// SECURITY: Audit Log Middleware
// Todas las acciones de 'Crisis' (Bypass, Replace, Unlock, Pause) quedan registradas
// con el ID del usuario que las ejecutó
//
// Ejecuta DESPUÉS del handler para capturar el resultado de la operación
func AuditCrisisAction(actionType string) gin.HandlerFunc {
	return func(c *gin.Context) {
		// Capturar UserID y contexto ANTES de ejecutar el handler
		userIDObj, _ := c.Get(globalMiddlewares.UserIDKey)
		userRoleObj, _ := c.Get(globalMiddlewares.UserRoleKey)

		userID := "unknown"
		userRole := "unknown"

		if uid, ok := userIDObj.(string); ok {
			userID = uid
		}

		if role, ok := userRoleObj.(string); ok {
			userRole = role
		}

		// Capturar request details
		requestPath := c.Request.URL.Path
		clientIP := c.ClientIP()
		timestamp := time.Now()

		// Ejecutar el handler
		c.Next()

		// Solo loguear si la operación fue EXITOSA (status 200-299)
		statusCode := c.Writer.Status()
		if statusCode >= 200 && statusCode < 300 {
			// Log con formato estructurado para facilitar análisis posterior
			fmt.Printf(
				"[AUDIT] ⚠️  CRISIS_ACTION | Action: %s | UserID: %s | Role: %s | Resource: %s | IP: %s | Status: %d | Timestamp: %s\n",
				actionType,
				userID,
				userRole,
				requestPath,
				clientIP,
				statusCode,
				timestamp.Format(time.RFC3339),
			)
		} else {
			// También loguear intentos FALLIDOS para detectar comportamiento sospechoso
			fmt.Printf(
				"[AUDIT] ❌ CRISIS_ACTION_FAILED | Action: %s | UserID: %s | Role: %s | Resource: %s | IP: %s | Status: %d | Timestamp: %s\n",
				actionType,
				userID,
				userRole,
				requestPath,
				clientIP,
				statusCode,
				timestamp.Format(time.RFC3339),
			)
		}

		// FUTURE ENHANCEMENT: Enviar a sistema de logging centralizado (ELK, Datadog, etc.)
		// FUTURE ENHANCEMENT: Alertas en tiempo real para acciones críticas
	}
}
