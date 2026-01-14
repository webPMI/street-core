package application

import (
	"context"
	"time"

	"backend/config"
	"backend/features/auth"
	"backend/features/competitions"
	"backend/features/media"
	"backend/features/profile"
	"backend/handlers"
	"backend/models"
	"backend/pkg/repository"
	"backend/services"

	"go.mongodb.org/mongo-driver/mongo"
)

// Container holds all application dependencies (services and handlers)
// This provides a centralized dependency injection mechanism
type Container struct {
	DB       *mongo.Database
	Config   *config.Config
	Services *Services
	Handlers *Handlers
	// Repositories exposed for middleware use
	UserRepo repository.IRepository[models.User]
	// Feature modules
	Auth         *auth.Module
	Profile      *profile.Module
	Competitions *competitions.Module
	Media        *media.Module
}

// Services holds all business logic services
type Services struct {
	// Auth services (from features/auth)
	OAuth           *auth.OAuthService
	Auth            auth.AuthService
	TokenRevocation auth.ITokenRevocationService
	// User service (from features/profile)
	User profile.UserService
	// Site services (from services/)
	SiteConfig     *services.SiteConfigService
	ContactMessage *services.ContactMessageService
}

// Handlers holds all HTTP request handlers
type Handlers struct {
	User           *handlers.UserHandler
	SiteConfig     *handlers.SiteConfigHandler
	ContactMessage *handlers.ContactMessageHandler
}

// NewContainer creates and initializes all application dependencies
func NewContainer(db *mongo.Database, client *mongo.Client, cfg *config.Config) *Container {
	// Create repositories for dependency injection
	userRepo := repository.NewRepository[models.User](db.Collection("users"))

	// Initialize all services
	svcs := initializeServices(db, cfg, userRepo)

	// Initialize all handlers
	hdlrs := initializeHandlers(svcs)

	// Initialize Feature Modules
	authModule := auth.NewModule(svcs.Auth, svcs.OAuth, svcs.TokenRevocation)
	profileModule := profile.NewModule(db, svcs.User)
	competitionsModule := competitions.NewModule(db)
	mediaModule := media.NewModule(db)

	return &Container{
		DB:       db,
		Config:   cfg,
		Services: svcs,
		Handlers: hdlrs,
		UserRepo: userRepo,
		// Feature modules
		Auth:         authModule,
		Profile:      profileModule,
		Competitions: competitionsModule,
		Media:        mediaModule,
	}
}

// initializeServices creates all service instances with proper dependencies
func initializeServices(db *mongo.Database, cfg *config.Config, userRepo repository.IRepository[models.User]) *Services {
	// Create repositories for auth
	refreshTokenRepo := repository.NewRepository[models.RefreshToken](db.Collection("refresh_tokens"))
	failedLoginRepo := repository.NewRepository[models.FailedLoginAttempt](db.Collection("failed_login_attempts"))
	passwordResetRepo := repository.NewRepository[models.PasswordResetToken](db.Collection("password_reset_tokens"))

	// User service (from profile feature)
	userService := profile.NewUserService(db)

	// Auth services (from auth feature)
	tokenRevocationService := auth.NewTokenRevocationService(db)
	authService := auth.NewAuthService(
		userRepo,
		refreshTokenRepo,
		failedLoginRepo,
		passwordResetRepo,
		db.Collection("refresh_tokens"),
		cfg.JWTSecret,
		cfg.JWTExpiresIn,
		cfg.RefreshTokenExpireIn,
	)
	oauthService := auth.NewOAuthService(db, userService)

	// Site services
	siteConfigService := services.NewSiteConfigService(db)
	contactMessageService := services.NewContactMessageService(db)

	return &Services{
		Auth:            authService,
		User:            userService,
		OAuth:           oauthService,
		TokenRevocation: tokenRevocationService,
		SiteConfig:      siteConfigService,
		ContactMessage:  contactMessageService,
	}
}

// initializeHandlers creates all handler instances with service dependencies
func initializeHandlers(svcs *Services) *Handlers {
	return &Handlers{
		User:           handlers.NewUserHandler(svcs.User, svcs.Auth),
		SiteConfig:     handlers.NewSiteConfigHandler(svcs.SiteConfig),
		ContactMessage: handlers.NewContactMessageHandler(svcs.ContactMessage),
	}
}

// StartBackgroundJobs starts all background jobs across all modules.
// This should be called after the container is initialized.
func (c *Container) StartBackgroundJobs(ctx context.Context) {
	// Start Media module background jobs (cleanup, processing)
	if c.Media != nil {
		c.Media.StartBackgroundJobs(ctx)
	}
}

// WaitForBackgroundTasks waits for all background tasks across all modules.
// This should be called during graceful shutdown to ensure all pending operations complete.
// Returns true if all tasks completed within timeout, false if timed out.
func (c *Container) WaitForBackgroundTasks(timeout time.Duration) bool {
	allCompleted := true

	// Wait for Profile module background tasks
	if c.Profile != nil {
		if !c.Profile.WaitForBackgroundTasks(timeout) {
			allCompleted = false
		}
	}

	return allCompleted
}
