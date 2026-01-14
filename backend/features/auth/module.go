package auth

import (
	"github.com/gin-gonic/gin"
)

// Module represents the auth feature module
type Module struct {
	Handler           *Handler
	Service           AuthService
	RevocationService ITokenRevocationService
}

// NewModule creates a new auth module with all dependencies
func NewModule(authService AuthService, oauthService *OAuthService, revocationService ITokenRevocationService) *Module {
	handler := NewHandler(authService, oauthService, revocationService)

	return &Module{
		Handler:           handler,
		Service:           authService,
		RevocationService: revocationService,
	}
}

// RegisterRoutes registers all auth routes
func (m *Module) RegisterRoutes(version *gin.RouterGroup) {
	RegisterRoutes(version, m.Handler)
}
