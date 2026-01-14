package services

import (
	"backend/models"
	"context"
	"errors"
	"time"

	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/bson/primitive"
	"go.mongodb.org/mongo-driver/mongo"
	"go.mongodb.org/mongo-driver/mongo/options"
)

// SiteConfigService handles site configuration operations
type SiteConfigService struct {
	db         *mongo.Database
	collection *mongo.Collection
}

// NewSiteConfigService creates a new site config service
func NewSiteConfigService(db *mongo.Database) *SiteConfigService {
	return &SiteConfigService{
		db:         db,
		collection: db.Collection("site_config"),
	}
}

// GetConfig retrieves the site configuration
func (s *SiteConfigService) GetConfig(ctx context.Context) (*models.SiteConfig, error) {
	var config models.SiteConfig
	err := s.collection.FindOne(ctx, bson.M{"key": "main"}).Decode(&config)
	if err != nil {
		if err == mongo.ErrNoDocuments {
			// Return empty config if not found
			return &models.SiteConfig{Key: "main"}, nil
		}
		return nil, err
	}
	return &config, nil
}

// GetContactInfo retrieves contact information
func (s *SiteConfigService) GetContactInfo(ctx context.Context) (*models.ContactInfo, error) {
	config, err := s.GetConfig(ctx)
	if err != nil {
		return nil, err
	}
	if config.ContactInfo == nil {
		return &models.ContactInfo{}, nil
	}
	return config.ContactInfo, nil
}

// GetSocialMedia retrieves social media links
func (s *SiteConfigService) GetSocialMedia(ctx context.Context) (*models.SocialMedia, error) {
	config, err := s.GetConfig(ctx)
	if err != nil {
		return nil, err
	}
	if config.SocialMedia == nil {
		return &models.SocialMedia{}, nil
	}
	return config.SocialMedia, nil
}

// GetLegalTexts retrieves legal texts
func (s *SiteConfigService) GetLegalTexts(ctx context.Context) (*models.LegalTexts, error) {
	config, err := s.GetConfig(ctx)
	if err != nil {
		return nil, err
	}
	if config.LegalTexts == nil {
		return &models.LegalTexts{}, nil
	}
	return config.LegalTexts, nil
}

// GetCompanyInfo retrieves company information
func (s *SiteConfigService) GetCompanyInfo(ctx context.Context) (*models.CompanyInfo, error) {
	config, err := s.GetConfig(ctx)
	if err != nil {
		return nil, err
	}
	if config.CompanyInfo == nil {
		return &models.CompanyInfo{}, nil
	}
	return config.CompanyInfo, nil
}

// GetSEOConfig retrieves SEO configuration
func (s *SiteConfigService) GetSEOConfig(ctx context.Context) (*models.SEOConfig, error) {
	config, err := s.GetConfig(ctx)
	if err != nil {
		return nil, err
	}
	if config.SEOConfig == nil {
		return &models.SEOConfig{}, nil
	}
	return config.SEOConfig, nil
}

// GetLandingTexts retrieves landing page texts
func (s *SiteConfigService) GetLandingTexts(ctx context.Context) (*models.LandingTexts, error) {
	config, err := s.GetConfig(ctx)
	if err != nil {
		return nil, err
	}
	if config.LandingTexts == nil {
		return &models.LandingTexts{}, nil
	}
	return config.LandingTexts, nil
}

// GetAppConfig retrieves app configuration
func (s *SiteConfigService) GetAppConfig(ctx context.Context) (*models.AppConfig, error) {
	config, err := s.GetConfig(ctx)
	if err != nil {
		return nil, err
	}
	if config.AppConfig == nil {
		return &models.AppConfig{}, nil
	}
	return config.AppConfig, nil
}

// GetConsentConfig retrieves consent configuration
func (s *SiteConfigService) GetConsentConfig(ctx context.Context) (*models.ConsentConfig, error) {
	config, err := s.GetConfig(ctx)
	if err != nil {
		return nil, err
	}
	if config.ConsentConfig == nil {
		return &models.ConsentConfig{}, nil
	}
	return config.ConsentConfig, nil
}

// GetBasicConfig retrieves basic configuration (company + contact)
func (s *SiteConfigService) GetBasicConfig(ctx context.Context) (map[string]interface{}, error) {
	config, err := s.GetConfig(ctx)
	if err != nil {
		return nil, err
	}
	return map[string]interface{}{
		"companyInfo": config.CompanyInfo,
		"contactInfo": config.ContactInfo,
	}, nil
}

// UpdateSection updates a specific section of the site configuration
func (s *SiteConfigService) UpdateSection(ctx context.Context, section string, data interface{}, userID primitive.ObjectID) error {
	if section == "" {
		return errors.New("section is required")
	}

	fieldName := sectionToFieldName(section)
	if fieldName == "" {
		return errors.New("invalid section")
	}

	update := bson.M{
		"$set": bson.M{
			fieldName:   data,
			"updatedAt": time.Now(),
			"updatedBy": userID,
		},
		"$inc": bson.M{"version": 1},
	}

	opts := options.Update().SetUpsert(true)
	_, err := s.collection.UpdateOne(ctx, bson.M{"key": "main"}, update, opts)
	return err
}

// sectionToFieldName converts section name to MongoDB field name
func sectionToFieldName(section string) string {
	mapping := map[string]string{
		"contact":  "contactInfo",
		"social":   "socialMedia",
		"legal":    "legalTexts",
		"company":  "companyInfo",
		"seo":      "seoConfig",
		"landing":  "landingTexts",
		"email":    "emailConfig",
		"app":      "appConfig",
		"consent":  "consentConfig",
	}
	return mapping[section]
}
