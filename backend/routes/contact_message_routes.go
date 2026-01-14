package routes

import (
	application "backend/app"
	"backend/middlewares"
	"time"

	"github.com/gin-gonic/gin"
)

// ContactMessageRoutes registers public contact message routes
// POST /api/version/contact - Submit contact form (rate limited)
func ContactMessageRoutes(version *gin.RouterGroup, container *application.Container) {
	contactHandler := container.Handlers.ContactMessage

	contactGroup := version.Group("/contact")
	// Rate limit public form submissions: 5 requests per hour per IP
	contactGroup.Use(middlewares.RateLimitMiddleware(5, time.Hour))
	{
		// POST /api/version/contact - Submit contact form
		contactGroup.POST("", contactHandler.SubmitContactForm)
	}
}
