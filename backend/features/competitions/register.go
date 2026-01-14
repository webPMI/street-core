package competitions

import (
	"backend/features/competitions/adapters"
	"backend/features/competitions/ports"
	"log"

	"github.com/gin-gonic/gin"
	"go.mongodb.org/mongo-driver/mongo"
)

// Register is the main entry point for integrating the competitions module.
// It creates and configures the module with minimal coupling to the main application.
//
// Usage in main.go or routes.go:
//
//	// Option 1: Quick setup with defaults
//	competitions.Register(db, router.Group("/api/v1"), authService, tokenService)
//
//	// Option 2: Full control with custom config
//	competitions.RegisterWithConfig(db, router, deps, config)
//
// The module will:
// - Create all necessary repositories
// - Initialize all use cases
// - Set up all HTTP handlers
// - Register all routes under /competitions
func Register(
	db *mongo.Database,
	router *gin.RouterGroup,
	authVerifier ports.AuthTokenVerifier,
	tokenChecker ports.TokenRevocationChecker,
) (*Module, error) {
	// Create user adapter from database
	userAdapter := adapters.NewMongoUserAdapter(db)

	deps := &ports.Dependencies{
		AuthVerifier: authVerifier,
		TokenChecker: tokenChecker,
		UserProvider: userAdapter,
		EmailSender:  &ports.NoOpEmailSender{},
		Config:       ports.DefaultConfig(),
	}

	return RegisterWithDependencies(db, router, deps)
}

// RegisterWithDependencies registers the module with full dependency control.
// Use this when you need custom implementations of the interfaces.
func RegisterWithDependencies(
	db *mongo.Database,
	router *gin.RouterGroup,
	deps *ports.Dependencies,
) (*Module, error) {
	// Validate dependencies
	if err := deps.Validate(); err != nil {
		return nil, err
	}

	// Check if module is enabled
	if deps.Config != nil && !deps.Config.Enabled {
		log.Println("[competitions] Module is disabled")
		return nil, ports.ErrModuleDisabled
	}

	// Create the module
	module := NewModuleWithDeps(db, deps)

	// Register routes
	module.RegisterRoutesWithDeps(router, deps)

	log.Println("[competitions] Module registered successfully")

	return module, nil
}

// MustRegister is like Register but panics on error.
// Use this when the competitions module is required for the application to run.
func MustRegister(
	db *mongo.Database,
	router *gin.RouterGroup,
	authVerifier ports.AuthTokenVerifier,
	tokenChecker ports.TokenRevocationChecker,
) *Module {
	module, err := Register(db, router, authVerifier, tokenChecker)
	if err != nil {
		panic("competitions: failed to register module: " + err.Error())
	}
	return module
}

// OptionalRegister attempts to register the module but doesn't fail if it can't.
// Returns nil if registration fails. Use this for optional features.
func OptionalRegister(
	db *mongo.Database,
	router *gin.RouterGroup,
	authVerifier ports.AuthTokenVerifier,
	tokenChecker ports.TokenRevocationChecker,
) *Module {
	module, err := Register(db, router, authVerifier, tokenChecker)
	if err != nil {
		log.Printf("[competitions] Module not registered: %v", err)
		return nil
	}
	return module
}
