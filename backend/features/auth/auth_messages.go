package auth

import "backend/models"

// ============================================================================
// AUTH MODULE MESSAGES
// ============================================================================
// Este archivo extiende models/messages.go con claves específicas del módulo

// Re-export de claves centrales para conveniencia
const (
	// Success messages
	LoginSuccessful             = models.LoginSuccessful
	RegisterSuccessful          = models.RegisterSuccessful
	LogoutSuccessful            = models.LogoutSuccessful
	PasswordResetSent           = models.PasswordResetSent
	PasswordResetSuccessful     = models.PasswordResetSuccessful
	TokenValidatedSuccessful    = models.TokenValidatedSuccessful
	PasswordChangedSuccessfully = models.PasswordChangedSuccessfully

	// Error messages
	InvalidCredentials      = models.InvalidCredentials
	EmailAlreadyExists      = models.EmailAlreadyExists
	WeakPassword            = models.WeakPassword
	TokenExpired            = models.TokenExpired
	InvalidToken            = models.InvalidToken
	Unauthorized            = models.Unauthorized
	IncorrectPassword       = models.IncorrectPassword
	NewPasswordTooWeak      = models.NewPasswordTooWeak
	PasswordChangeFailure   = models.PasswordChangeFailure
	AccountLocked           = models.AccountLocked
	TokenRevoked            = models.TokenRevoked
	UsernameAlreadyExists   = models.UsernameAlreadyExists
	InvalidUserID           = models.InvalidUserID
	InvalidResetToken       = models.InvalidResetToken
	ResetTokenExpired       = models.ResetTokenExpired
	ResetTokenAlreadyUsed   = models.ResetTokenAlreadyUsed
	EmailNotFound           = models.EmailNotFound
	PasswordResetEmailError = models.PasswordResetEmailError

	// OAuth
	OAuthNotConfigured = models.OAuthNotConfigured
	OAuthProviderError = models.OAuthProviderError
	OAuthStateMismatch = models.OAuthStateMismatch
)

// Claves específicas del módulo Auth
const (
	// JWT Token
	TokenGenerated        = "auth.token.generated"
	TokenRefreshed        = "auth.token.refreshed"
	TokenValidated        = "auth.token.validated"
	TokenInvalidSignature = "auth.token.invalid.signature"
	TokenMalformed        = "auth.token.malformed"
	TokenMissingClaims    = "auth.token.missing.claims"
	RefreshTokenExpired   = "auth.refresh.token.expired"
	RefreshTokenInvalid   = "auth.refresh.token.invalid"

	// Session management
	SessionCreated           = "auth.session.created"
	SessionExpired           = "auth.session.expired"
	SessionInvalidated       = "auth.session.invalidated"
	SessionNotFound          = "auth.session.not.found"
	MultipleSessionsDetected = "auth.session.multiple.detected"

	// Two-factor authentication
	TwoFactorEnabled     = "auth.2fa.enabled"
	TwoFactorDisabled    = "auth.2fa.disabled"
	TwoFactorCodeSent    = "auth.2fa.code.sent"
	TwoFactorCodeInvalid = "auth.2fa.code.invalid"
	TwoFactorCodeExpired = "auth.2fa.code.expired"
	TwoFactorRequired    = "auth.2fa.required"

	// Account verification
	VerificationEmailSent   = "auth.verification.email.sent"
	EmailVerified           = "auth.email.verified"
	EmailNotVerified        = "auth.email.not.verified"
	VerificationCodeInvalid = "auth.verification.code.invalid"
	VerificationCodeExpired = "auth.verification.code.expired"

	// Rate limiting
	TooManyLoginAttempts     = "auth.rate.limit.login.attempts"
	TooManyPasswordResets    = "auth.rate.limit.password.resets"
	AccountTemporarilyLocked = "auth.account.temporarily.locked"

	// OAuth specific
	OAuthAccountLinked     = "auth.oauth.account.linked"
	OAuthAccountUnlinked   = "auth.oauth.account.unlinked"
	OAuthProviderNotLinked = "auth.oauth.provider.not.linked"
	OAuthEmailMismatch     = "auth.oauth.email.mismatch"
)
