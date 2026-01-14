package handlers

import (
	"backend/models"
	"backend/pkg/errors"
	"backend/pkg/response"
	"backend/services"

	"github.com/gin-gonic/gin"
)

// SiteConfigHandler handles site configuration HTTP requests
type SiteConfigHandler struct {
	siteConfigService *services.SiteConfigService
}

// NewSiteConfigHandler creates a new site config handler
func NewSiteConfigHandler(siteConfigService *services.SiteConfigService) *SiteConfigHandler {
	return &SiteConfigHandler{
		siteConfigService: siteConfigService,
	}
}

// GetConfig returns the full site configuration
func (h *SiteConfigHandler) GetConfig(c *gin.Context) {
	ctx := c.Request.Context()

	config, err := h.siteConfigService.GetConfig(ctx)
	if err != nil {
		response.HandleError(c, errors.ErrDatabaseError("get config", err))
		return
	}

	response.OK(c, models.ConfigRetrieved, gin.H{"config": config})
}

// GetContactInfo returns contact information
func (h *SiteConfigHandler) GetContactInfo(c *gin.Context) {
	ctx := c.Request.Context()

	contactInfo, err := h.siteConfigService.GetContactInfo(ctx)
	if err != nil {
		response.HandleError(c, errors.ErrDatabaseError("get contact info", err))
		return
	}

	response.OK(c, models.ContactInfoRetrieved, gin.H{"contactInfo": contactInfo})
}

// GetSocialMedia returns social media links
func (h *SiteConfigHandler) GetSocialMedia(c *gin.Context) {
	ctx := c.Request.Context()

	socialMedia, err := h.siteConfigService.GetSocialMedia(ctx)
	if err != nil {
		response.HandleError(c, errors.ErrDatabaseError("get social media", err))
		return
	}

	response.OK(c, models.SocialMediaRetrieved, gin.H{"socialMedia": socialMedia})
}

// GetLegalTexts returns legal texts
func (h *SiteConfigHandler) GetLegalTexts(c *gin.Context) {
	ctx := c.Request.Context()

	legalTexts, err := h.siteConfigService.GetLegalTexts(ctx)
	if err != nil {
		response.HandleError(c, errors.ErrDatabaseError("get legal texts", err))
		return
	}

	response.OK(c, models.LegalTextsRetrieved, gin.H{"legalTexts": legalTexts})
}

// GetCompanyInfo returns company information
func (h *SiteConfigHandler) GetCompanyInfo(c *gin.Context) {
	ctx := c.Request.Context()

	companyInfo, err := h.siteConfigService.GetCompanyInfo(ctx)
	if err != nil {
		response.HandleError(c, errors.ErrDatabaseError("get company info", err))
		return
	}

	response.OK(c, models.CompanyInfoRetrieved, gin.H{"companyInfo": companyInfo})
}

// GetSEOConfig returns SEO configuration
func (h *SiteConfigHandler) GetSEOConfig(c *gin.Context) {
	ctx := c.Request.Context()

	seoConfig, err := h.siteConfigService.GetSEOConfig(ctx)
	if err != nil {
		response.HandleError(c, errors.ErrDatabaseError("get seo config", err))
		return
	}

	response.OK(c, models.SEOConfigRetrieved, gin.H{"seoConfig": seoConfig})
}

// GetLandingTexts returns landing page texts
func (h *SiteConfigHandler) GetLandingTexts(c *gin.Context) {
	ctx := c.Request.Context()

	landingTexts, err := h.siteConfigService.GetLandingTexts(ctx)
	if err != nil {
		response.HandleError(c, errors.ErrDatabaseError("get landing texts", err))
		return
	}

	response.OK(c, models.LandingTextsRetrieved, gin.H{"landingTexts": landingTexts})
}

// GetAppConfig returns app configuration
func (h *SiteConfigHandler) GetAppConfig(c *gin.Context) {
	ctx := c.Request.Context()

	appConfig, err := h.siteConfigService.GetAppConfig(ctx)
	if err != nil {
		response.HandleError(c, errors.ErrDatabaseError("get app config", err))
		return
	}

	response.OK(c, models.AppConfigRetrieved, gin.H{"appConfig": appConfig})
}

// GetConsentConfig returns consent configuration
func (h *SiteConfigHandler) GetConsentConfig(c *gin.Context) {
	ctx := c.Request.Context()

	consentConfig, err := h.siteConfigService.GetConsentConfig(ctx)
	if err != nil {
		response.HandleError(c, errors.ErrDatabaseError("get consent config", err))
		return
	}

	response.OK(c, models.ConsentConfigRetrieved, gin.H{"consentConfig": consentConfig})
}

// GetBasicConfig returns basic configuration (company + contact)
func (h *SiteConfigHandler) GetBasicConfig(c *gin.Context) {
	ctx := c.Request.Context()

	basicConfig, err := h.siteConfigService.GetBasicConfig(ctx)
	if err != nil {
		response.HandleError(c, errors.ErrDatabaseError("get basic config", err))
		return
	}

	response.OK(c, models.BasicConfigRetrieved, basicConfig)
}
