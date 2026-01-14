// Package ports defines the external interfaces that the competitions module requires.
// This follows the Hexagonal Architecture (Ports & Adapters) pattern.
//
// By defining our own interfaces here, the module remains completely independent
// from the rest of the application. Any external service just needs to implement
// these interfaces to integrate with the competitions module.
package ports

import (
	"context"

	"github.com/gin-gonic/gin"
	"go.mongodb.org/mongo-driver/bson/primitive"
)

// AuthTokenVerifier verifies JWT tokens and returns claims.
// This interface allows the module to work with any authentication system.
type AuthTokenVerifier interface {
	VerifyAuthToken(tokenString string) (map[string]interface{}, error)
}

// TokenRevocationChecker checks if a token has been revoked.
// This interface allows the module to work with any token revocation system.
type TokenRevocationChecker interface {
	IsTokenRevoked(ctx context.Context, token string) (bool, error)
}

// UserInfo represents minimal user information needed by the competitions module.
type UserInfo struct {
	ID        primitive.ObjectID
	Email     string
	FirstName string
	LastName  string
	UserName  string
	Avatar    string
	Role      string
}

// UserProvider provides user information to the competitions module.
// This decouples the module from the user management system.
type UserProvider interface {
	GetUserByID(ctx context.Context, userID primitive.ObjectID) (*UserInfo, error)
	GetUsersByIDs(ctx context.Context, userIDs []primitive.ObjectID) ([]*UserInfo, error)
	SearchUsers(ctx context.Context, query string, limit int) ([]*UserInfo, error)
}

// EmailSender sends emails for competition-related notifications.
// This decouples the module from the email system.
type EmailSender interface {
	SendJudgeInvitation(ctx context.Context, to, judgeName, competitionName, acceptURL, rejectURL string) error
	SendCompetitionReminder(ctx context.Context, to, participantName, competitionName, date, location string) error
	SendResultsPublished(ctx context.Context, to, participantName, competitionName, position string) error
}

// NoOpEmailSender is a no-op implementation for when email is not configured.
type NoOpEmailSender struct{}

func (n *NoOpEmailSender) SendJudgeInvitation(ctx context.Context, to, judgeName, competitionName, acceptURL, rejectURL string) error {
	return nil
}
func (n *NoOpEmailSender) SendCompetitionReminder(ctx context.Context, to, participantName, competitionName, date, location string) error {
	return nil
}
func (n *NoOpEmailSender) SendResultsPublished(ctx context.Context, to, participantName, competitionName, position string) error {
	return nil
}

// ModuleConfig holds configuration for the competitions module.
type ModuleConfig struct {
	// Feature flags
	Enabled              bool
	EnableJudgeInvitations bool
	EnableLiveScoring    bool
	EnablePublicLeaderboard bool

	// Limits
	MaxParticipantsPerCompetition int
	MaxCategoriesPerCompetition   int
	MaxJudgesPerCategory          int

	// URLs for email links
	BaseURL              string
	JudgeInvitationPath  string
}

// DefaultConfig returns a default configuration.
func DefaultConfig() *ModuleConfig {
	return &ModuleConfig{
		Enabled:                      true,
		EnableJudgeInvitations:       true,
		EnableLiveScoring:            true,
		EnablePublicLeaderboard:      true,
		MaxParticipantsPerCompetition: 500,
		MaxCategoriesPerCompetition:   20,
		MaxJudgesPerCategory:          10,
		BaseURL:                       "http://localhost:3000",
		JudgeInvitationPath:          "/judge-invitations",
	}
}

// Dependencies holds all external dependencies for the competitions module.
// This struct is passed to NewModule() to initialize the module.
type Dependencies struct {
	AuthVerifier     AuthTokenVerifier
	TokenChecker     TokenRevocationChecker
	UserProvider     UserProvider
	EmailSender      EmailSender
	Config           *ModuleConfig
}

// Validate checks that all required dependencies are provided.
func (d *Dependencies) Validate() error {
	if d.AuthVerifier == nil {
		return ErrMissingAuthVerifier
	}
	if d.TokenChecker == nil {
		return ErrMissingTokenChecker
	}
	if d.UserProvider == nil {
		return ErrMissingUserProvider
	}
	if d.EmailSender == nil {
		// Use no-op email sender if not provided
		d.EmailSender = &NoOpEmailSender{}
	}
	if d.Config == nil {
		d.Config = DefaultConfig()
	}
	return nil
}

// RouteRegistrar is a function type for registering routes.
// This allows the module to register its routes without knowing about the router implementation.
type RouteRegistrar func(router *gin.RouterGroup)

// Module errors
var (
	ErrMissingAuthVerifier  = newModuleError("auth verifier is required")
	ErrMissingTokenChecker  = newModuleError("token checker is required")
	ErrMissingUserProvider  = newModuleError("user provider is required")
	ErrModuleDisabled       = newModuleError("competitions module is disabled")
)

type moduleError struct {
	message string
}

func newModuleError(message string) *moduleError {
	return &moduleError{message: message}
}

func (e *moduleError) Error() string {
	return "competitions: " + e.message
}
