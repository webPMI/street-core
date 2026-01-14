package routes

import (
	application "backend/app"
	"backend/handlers"
	"backend/services"

	"github.com/gin-gonic/gin"
)

// SiteConfigRoutes sets up routes for site configuration
// - GET is public (for frontend to display contact info, legal texts, etc.)
// - PUT is protected and requires admin role
func SiteConfigRoutes(router *gin.RouterGroup, container *application.Container) {
	siteConfigService := services.NewSiteConfigService(container.DB)
	siteConfigHandler := handlers.NewSiteConfigHandler(siteConfigService)

	siteConfig := router.Group("/site-config")
	{
		// ===== PUBLIC ROUTES =====

		// Full configuration (for admin panel or complete config needs)
		siteConfig.GET("", siteConfigHandler.GetConfig)

		// Section-specific endpoints (for on-demand loading)
		siteConfig.GET("/contact", siteConfigHandler.GetContactInfo)
		siteConfig.GET("/social", siteConfigHandler.GetSocialMedia)
		siteConfig.GET("/legal", siteConfigHandler.GetLegalTexts)
		siteConfig.GET("/company", siteConfigHandler.GetCompanyInfo)
		siteConfig.GET("/seo", siteConfigHandler.GetSEOConfig)
		siteConfig.GET("/landing", siteConfigHandler.GetLandingTexts)
		siteConfig.GET("/app", siteConfigHandler.GetAppConfig)
		siteConfig.GET("/consent", siteConfigHandler.GetConsentConfig)

		// Combined endpoint for header/footer (company + social)
		siteConfig.GET("/basic", siteConfigHandler.GetBasicConfig)
	}
}
