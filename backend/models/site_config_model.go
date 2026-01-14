package models

import (
	"time"

	"go.mongodb.org/mongo-driver/bson/primitive"
)

// SiteConfig stores all configurable site content
type SiteConfig struct {
	ID        primitive.ObjectID `json:"id" bson:"_id,omitempty"`
	Key       string             `json:"key" bson:"key" validate:"required"`
	Version   int                `json:"version" bson:"version"` // Optimistic locking
	UpdatedAt time.Time          `json:"updatedAt" bson:"updatedAt"`
	UpdatedBy primitive.ObjectID `json:"updatedBy" bson:"updatedBy"`

	// Contact Information
	ContactInfo *ContactInfo `json:"contactInfo,omitempty" bson:"contactInfo,omitempty"`

	// Social Media Links
	SocialMedia *SocialMedia `json:"socialMedia,omitempty" bson:"socialMedia,omitempty"`

	// Legal Texts
	LegalTexts *LegalTexts `json:"legalTexts,omitempty" bson:"legalTexts,omitempty"`

	// Company Information
	CompanyInfo *CompanyInfo `json:"companyInfo,omitempty" bson:"companyInfo,omitempty"`

	// SEO Configuration
	SEOConfig *SEOConfig `json:"seoConfig,omitempty" bson:"seoConfig,omitempty"`

	// Landing Page Texts
	LandingTexts *LandingTexts `json:"landingTexts,omitempty" bson:"landingTexts,omitempty"`

	// Email Configuration
	EmailConfig *EmailConfig `json:"emailConfig,omitempty" bson:"emailConfig,omitempty"`

	// App Configuration
	AppConfig *AppConfig `json:"appConfig,omitempty" bson:"appConfig,omitempty"`

	// Consent Configuration (GDPR/Granular)
	ConsentConfig *ConsentConfig `json:"consentConfig,omitempty" bson:"consentConfig,omitempty"`
}

// ConfigAuditLog stores audit trail for configuration changes
type ConfigAuditLog struct {
	ID            primitive.ObjectID `json:"id" bson:"_id,omitempty"`
	ConfigVersion int                `json:"configVersion" bson:"configVersion"`
	Section       string             `json:"section" bson:"section"`
	Action        string             `json:"action" bson:"action"` // "update", "create"
	ChangedBy     primitive.ObjectID `json:"changedBy" bson:"changedBy"`
	ChangedAt     time.Time          `json:"changedAt" bson:"changedAt"`
	OldValue      interface{}        `json:"oldValue,omitempty" bson:"oldValue,omitempty"`
	NewValue      interface{}        `json:"newValue" bson:"newValue"`
	IPAddress     string             `json:"ipAddress,omitempty" bson:"ipAddress,omitempty"`
}

// ConsentConfig stores texts for granular consent switches
type ConsentConfig struct {
	CookieConsentText    string `json:"cookieConsentText,omitempty" bson:"cookieConsentText,omitempty"`
	AnalyticsConsentText string `json:"analyticsConsentText,omitempty" bson:"analyticsConsentText,omitempty"`
	LocationConsentText  string `json:"locationConsentText,omitempty" bson:"locationConsentText,omitempty"`
	MarketingConsentText string `json:"marketingConsentText,omitempty" bson:"marketingConsentText,omitempty"`
}

// ContactInfo stores contact information
type ContactInfo struct {
	Email         string `json:"email,omitempty" bson:"email,omitempty" validate:"omitempty,email"`
	Phone         string `json:"phone,omitempty" bson:"phone,omitempty" validate:"omitempty,e164"`
	WhatsApp      string `json:"whatsapp,omitempty" bson:"whatsapp,omitempty" validate:"omitempty,e164"`
	Address       string `json:"address,omitempty" bson:"address,omitempty" validate:"omitempty,max=200"`
	City          string `json:"city,omitempty" bson:"city,omitempty" validate:"omitempty,max=100"`
	Country       string `json:"country,omitempty" bson:"country,omitempty" validate:"omitempty,max=100"`
	PostalCode    string `json:"postalCode,omitempty" bson:"postalCode,omitempty" validate:"omitempty,max=20"`
	BusinessHours string `json:"businessHours,omitempty" bson:"businessHours,omitempty" validate:"omitempty,max=200"`
	MapLatitude   string `json:"mapLatitude,omitempty" bson:"mapLatitude,omitempty" validate:"omitempty,latitude"`
	MapLongitude  string `json:"mapLongitude,omitempty" bson:"mapLongitude,omitempty" validate:"omitempty,longitude"`
	MapEmbedURL   string `json:"mapEmbedUrl,omitempty" bson:"mapEmbedUrl,omitempty" validate:"omitempty,url"`
}

// SocialMedia stores social media links
type SocialMedia struct {
	Facebook  string `json:"facebook,omitempty" bson:"facebook,omitempty" validate:"omitempty,url"`
	Instagram string `json:"instagram,omitempty" bson:"instagram,omitempty" validate:"omitempty,url"`
	Twitter   string `json:"twitter,omitempty" bson:"twitter,omitempty" validate:"omitempty,url"`
	YouTube   string `json:"youtube,omitempty" bson:"youtube,omitempty" validate:"omitempty,url"`
	TikTok    string `json:"tiktok,omitempty" bson:"tiktok,omitempty" validate:"omitempty,url"`
	LinkedIn  string `json:"linkedin,omitempty" bson:"linkedin,omitempty" validate:"omitempty,url"`
	Discord   string `json:"discord,omitempty" bson:"discord,omitempty" validate:"omitempty,url"`
	Telegram  string `json:"telegram,omitempty" bson:"telegram,omitempty" validate:"omitempty,url"`
}

// LegalRegion represents supported legal regions
type LegalRegion string

const (
	// LegalRegionEU - European Union (GDPR/RGPD)
	LegalRegionEU LegalRegion = "eu"
	// LegalRegionLATAM - Latin America (LFPDPPP, local laws)
	LegalRegionLATAM LegalRegion = "latam"
	// LegalRegionUSA - United States (CCPA, state laws)
	LegalRegionUSA LegalRegion = "usa"
)

// RegionalLegalTexts stores jurisdiction-specific legal content
type RegionalLegalTexts struct {
	// Privacy policy content (GDPR Art. 13-14 / CCPA / LFPDPPP)
	PrivacyPolicy string `json:"privacyPolicy,omitempty" bson:"privacyPolicy,omitempty"`
	// Terms and conditions / Terms of service
	TermsConditions string `json:"termsConditions,omitempty" bson:"termsConditions,omitempty"`
	// Cookie policy (required for EU, recommended elsewhere)
	CookiesPolicy string `json:"cookiesPolicy,omitempty" bson:"cookiesPolicy,omitempty"`
	// Refund and cancellation policy
	RefundPolicy string `json:"refundPolicy,omitempty" bson:"refundPolicy,omitempty"`
	// Data protection policy / rights
	DataProtection string `json:"dataProtection,omitempty" bson:"dataProtection,omitempty"`
	// Legal notice / Imprint (required in EU)
	LegalNotice string `json:"legalNotice,omitempty" bson:"legalNotice,omitempty"`
	// Local supervisory authority contact
	LocalAuthority string `json:"localAuthority,omitempty" bson:"localAuthority,omitempty"`
	// Local DPO/contact for data requests
	LocalContact string `json:"localContact,omitempty" bson:"localContact,omitempty"`
	// Minimum age for consent in this region
	MinConsentAge int `json:"minConsentAge,omitempty" bson:"minConsentAge,omitempty"`
	// Additional rights text specific to region
	AdditionalRights string `json:"additionalRights,omitempty" bson:"additionalRights,omitempty"`
	// Effective date for this region's policies
	EffectiveDate *time.Time `json:"effectiveDate,omitempty" bson:"effectiveDate,omitempty"`
	// Language code for this region's texts (e.g., 'es', 'en', 'pt')
	LanguageCode string `json:"languageCode,omitempty" bson:"languageCode,omitempty"`
}

// HasContent checks if this region has meaningful content
func (r *RegionalLegalTexts) HasContent() bool {
	if r == nil {
		return false
	}
	return r.PrivacyPolicy != "" ||
		r.TermsConditions != "" ||
		r.CookiesPolicy != "" ||
		r.RefundPolicy != ""
}

// LegalTexts stores legal documents with optional multi-region support.
// Maintains backward compatibility with single-region structure while
// supporting multi-region (EU, LATAM, USA) configurations.
type LegalTexts struct {
	// ============================================================
	// COMMON FIELDS
	// ============================================================

	// Company/site title for legal documents
	Title string `json:"title,omitempty" bson:"title,omitempty"`
	// Brief description of the company/service
	Description string `json:"description,omitempty" bson:"description,omitempty"`
	// Common footer text (shown on all regions)
	Footer string `json:"footer,omitempty" bson:"footer,omitempty"`

	// ============================================================
	// DIRECT LEGAL TEXT FIELDS (original structure - single region)
	// ============================================================

	// Privacy policy content
	PrivacyPolicy string `json:"privacyPolicy,omitempty" bson:"privacyPolicy,omitempty"`
	// Terms and conditions / Terms of service
	TermsConditions string `json:"termsConditions,omitempty" bson:"termsConditions,omitempty"`
	// Legal notice / Imprint
	LegalNotice string `json:"legalNotice,omitempty" bson:"legalNotice,omitempty"`
	// Cookie policy
	CookiesPolicy string `json:"cookiesPolicy,omitempty" bson:"cookiesPolicy,omitempty"`
	// Refund and cancellation policy
	RefundPolicy string `json:"refundPolicy,omitempty" bson:"refundPolicy,omitempty"`
	// Data protection policy / rights
	DataProtection string `json:"dataProtection,omitempty" bson:"dataProtection,omitempty"`

	// ============================================================
	// MULTI-REGION FIELDS (optional - for international apps)
	// ============================================================

	// European Union legal texts (GDPR/RGPD compliant)
	EU *RegionalLegalTexts `json:"eu,omitempty" bson:"eu,omitempty"`
	// Latin America legal texts
	LATAM *RegionalLegalTexts `json:"latam,omitempty" bson:"latam,omitempty"`
	// United States legal texts (CCPA compliant)
	USA *RegionalLegalTexts `json:"usa,omitempty" bson:"usa,omitempty"`
	// Default region to use when user region cannot be determined
	DefaultRegion string `json:"defaultRegion,omitempty" bson:"defaultRegion,omitempty"`
}

// IsMultiRegion checks if multi-region mode is enabled
func (l *LegalTexts) IsMultiRegion() bool {
	if l == nil {
		return false
	}
	return l.EU != nil || l.LATAM != nil || l.USA != nil
}

// GetRegion returns the regional texts for a given region
func (l *LegalTexts) GetRegion(region LegalRegion) *RegionalLegalTexts {
	if l == nil {
		return nil
	}
	switch region {
	case LegalRegionEU:
		return l.EU
	case LegalRegionLATAM:
		return l.LATAM
	case LegalRegionUSA:
		return l.USA
	default:
		return nil
	}
}

// GetEffectiveRegion returns the appropriate regional texts with fallback
func (l *LegalTexts) GetEffectiveRegion(region LegalRegion) *RegionalLegalTexts {
	if l == nil {
		return nil
	}

	// Try requested region first
	regional := l.GetRegion(region)
	if regional != nil && regional.HasContent() {
		return regional
	}

	// Fallback to default region
	defaultRegion := LegalRegion(l.DefaultRegion)
	if defaultRegion == "" {
		defaultRegion = LegalRegionEU
	}

	return l.GetRegion(defaultRegion)
}

// ParseLegalRegion converts a string to LegalRegion
func ParseLegalRegion(s string) LegalRegion {
	switch s {
	case "eu":
		return LegalRegionEU
	case "latam":
		return LegalRegionLATAM
	case "usa":
		return LegalRegionUSA
	default:
		return LegalRegionEU // Default to EU
	}
}

// CompanyInfo stores company information
type CompanyInfo struct {
	Name             string `json:"name,omitempty" bson:"name,omitempty" validate:"omitempty,min=2,max=100"`
	LegalName        string `json:"legalName,omitempty" bson:"legalName,omitempty" validate:"omitempty,min=2,max=150"`
	Slogan           string `json:"slogan,omitempty" bson:"slogan,omitempty" validate:"omitempty,max=200"`
	ShortDescription string `json:"shortDescription,omitempty" bson:"shortDescription,omitempty" validate:"omitempty,max=160"`
	LongDescription  string `json:"longDescription,omitempty" bson:"longDescription,omitempty" validate:"omitempty,max=2000"`
	LogoURL          string `json:"logoUrl,omitempty" bson:"logoUrl,omitempty" validate:"omitempty,url,http_url"`
	LogoDarkURL      string `json:"logoDarkUrl,omitempty" bson:"logoDarkUrl,omitempty" validate:"omitempty,url,http_url"`
	FaviconURL       string `json:"faviconUrl,omitempty" bson:"faviconUrl,omitempty" validate:"omitempty,url,http_url"`
	FoundedYear      string `json:"foundedYear,omitempty" bson:"foundedYear,omitempty" validate:"omitempty,numeric,len=4"`
	TaxID            string `json:"taxId,omitempty" bson:"taxId,omitempty" validate:"omitempty,alphanum,max=50"`
}

// SEOConfig stores SEO settings
type SEOConfig struct {
	DefaultTitle       string   `json:"defaultTitle,omitempty" bson:"defaultTitle,omitempty"`
	DefaultDescription string   `json:"defaultDescription,omitempty" bson:"defaultDescription,omitempty"`
	DefaultKeywords    []string `json:"defaultKeywords,omitempty" bson:"defaultKeywords,omitempty"`
	OGImage            string   `json:"ogImage,omitempty" bson:"ogImage,omitempty"`
	TwitterHandle      string   `json:"twitterHandle,omitempty" bson:"twitterHandle,omitempty"`
	GoogleAnalyticsID  string   `json:"googleAnalyticsId,omitempty" bson:"googleAnalyticsId,omitempty"`
	FacebookPixelID    string   `json:"facebookPixelId,omitempty" bson:"facebookPixelId,omitempty"`
	CanonicalURL       string   `json:"canonicalUrl,omitempty" bson:"canonicalUrl,omitempty"`
}

// LandingTexts stores landing page content
type LandingTexts struct {
	HeroTitle      string        `json:"heroTitle,omitempty" bson:"heroTitle,omitempty"`
	HeroSubtitle   string        `json:"heroSubtitle,omitempty" bson:"heroSubtitle,omitempty"`
	HeroButtonText string        `json:"heroButtonText,omitempty" bson:"heroButtonText,omitempty"`
	HeroButtonURL  string        `json:"heroButtonUrl,omitempty" bson:"heroButtonUrl,omitempty"`
	HeroImageURL   string        `json:"heroImageUrl,omitempty" bson:"heroImageUrl,omitempty"`
	AboutTitle     string        `json:"aboutTitle,omitempty" bson:"aboutTitle,omitempty"`
	AboutText      string        `json:"aboutText,omitempty" bson:"aboutText,omitempty"`
	Features       []FeatureItem `json:"features,omitempty" bson:"features,omitempty"`
	Testimonials   []Testimonial `json:"testimonials,omitempty" bson:"testimonials,omitempty"`
	CTATitle       string        `json:"ctaTitle,omitempty" bson:"ctaTitle,omitempty"`
	CTAText        string        `json:"ctaText,omitempty" bson:"ctaText,omitempty"`
	CTAButtonText  string        `json:"ctaButtonText,omitempty" bson:"ctaButtonText,omitempty"`
}

// FeatureItem represents a feature on the landing page
type FeatureItem struct {
	Icon        string `json:"icon,omitempty" bson:"icon,omitempty"`
	Title       string `json:"title,omitempty" bson:"title,omitempty"`
	Description string `json:"description,omitempty" bson:"description,omitempty"`
}

// Testimonial represents a testimonial
type Testimonial struct {
	Name   string `json:"name,omitempty" bson:"name,omitempty"`
	Role   string `json:"role,omitempty" bson:"role,omitempty"`
	Text   string `json:"text,omitempty" bson:"text,omitempty"`
	Avatar string `json:"avatar,omitempty" bson:"avatar,omitempty"`
	Rating int    `json:"rating,omitempty" bson:"rating,omitempty"`
}

// EmailConfig stores email configuration
type EmailConfig struct {
	SupportEmail       string `json:"supportEmail,omitempty" bson:"supportEmail,omitempty"`
	SalesEmail         string `json:"salesEmail,omitempty" bson:"salesEmail,omitempty"`
	NotificationsEmail string `json:"notificationsEmail,omitempty" bson:"notificationsEmail,omitempty"`
	NoReplyEmail       string `json:"noReplyEmail,omitempty" bson:"noReplyEmail,omitempty"`
	WelcomeSubject     string `json:"welcomeSubject,omitempty" bson:"welcomeSubject,omitempty"`
	WelcomeTemplate    string `json:"welcomeTemplate,omitempty" bson:"welcomeTemplate,omitempty"`
	ResetSubject       string `json:"resetSubject,omitempty" bson:"resetSubject,omitempty"`
	ResetTemplate      string `json:"resetTemplate,omitempty" bson:"resetTemplate,omitempty"`
}

// AppConfig stores app configuration
type AppConfig struct {
	MinVersionIOS         string `json:"minVersionIos,omitempty" bson:"minVersionIos,omitempty"`
	MinVersionAndroid     string `json:"minVersionAndroid,omitempty" bson:"minVersionAndroid,omitempty"`
	CurrentVersionIOS     string `json:"currentVersionIos,omitempty" bson:"currentVersionIos,omitempty"`
	CurrentVersionAndroid string `json:"currentVersionAndroid,omitempty" bson:"currentVersionAndroid,omitempty"`
	AppStoreURL           string `json:"appStoreUrl,omitempty" bson:"appStoreUrl,omitempty"`
	PlayStoreURL          string `json:"playStoreUrl,omitempty" bson:"playStoreUrl,omitempty"`
	MaintenanceMode       bool   `json:"maintenanceMode" bson:"maintenanceMode"`
	MaintenanceMessage    string `json:"maintenanceMessage,omitempty" bson:"maintenanceMessage,omitempty"`
	MaintenanceEndTime    string `json:"maintenanceEndTime,omitempty" bson:"maintenanceEndTime,omitempty"`
	ForceUpdate           bool   `json:"forceUpdate" bson:"forceUpdate"`
	UpdateMessage         string `json:"updateMessage,omitempty" bson:"updateMessage,omitempty"`
}

// SiteConfigUpdateRequest for partial updates
type SiteConfigUpdateRequest struct {
	Section string      `json:"section" validate:"required,oneof=contact social legal company seo landing email app consent"`
	Data    interface{} `json:"data" validate:"required"`
}
