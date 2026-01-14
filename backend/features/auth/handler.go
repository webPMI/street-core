package auth

import (
	"backend/app/dto/request"
	"backend/config"
	"backend/middlewares"
	"backend/models"
	"backend/pkg/base"
	pkgErrors "backend/pkg/errors"
	"backend/pkg/response"
	"backend/utils"
	"strings"

	"github.com/gin-gonic/gin"
)

// Handler handles authentication-related HTTP requests
type Handler struct {
	authService       AuthService
	oauthService      *OAuthService
	revocationService ITokenRevocationService
}

// NewHandler creates a new auth Handler instance
func NewHandler(authService AuthService, oauthService *OAuthService, revocationService ITokenRevocationService) *Handler {
	return &Handler{
		authService:       authService,
		oauthService:      oauthService,
		revocationService: revocationService,
	}
}

// Register handles user registration requests
func (h *Handler) Register(c *gin.Context) {
	var req request.RegisterRequest
	ctx := c.Request.Context()

	utils.Info("Register attempt", map[string]interface{}{
		"ip":         c.ClientIP(),
		"method":     c.Request.Method,
		"path":       c.Request.URL.Path,
		"origin":     c.GetHeader("Origin"),
		"referer":    c.GetHeader("Referer"),
		"user_agent": c.GetHeader("User-Agent"),
		"host":       c.Request.Host,
	})

	if err := base.BindJSON(c, &req); err != nil {
		return
	}

	req.Email = middlewares.SanitizeInput(req.Email)
	req.FirstName = middlewares.SanitizeInput(req.FirstName)
	req.LastName = middlewares.SanitizeInput(req.LastName)

	if passwordErrors := middlewares.ValidatePasswordStrength(req.Password); len(passwordErrors) > 0 {
		utils.Warn("Registration failed - weak password", map[string]interface{}{
			"email":           req.Email,
			"ip":              c.ClientIP(),
			"password_errors": passwordErrors,
		})
		err := pkgErrors.ErrWeakPassword(passwordErrors)
		response.HandleError(c, err)
		return
	}

	newUser, tokens, err := h.authService.RegisterUser(ctx, &req)
	if err != nil {
		utils.Warn("Registration failed", map[string]interface{}{
			"email": req.Email,
			"ip":    c.ClientIP(),
			"error": err.Error(),
		})
		appErr := h.convertAuthError(err)
		response.HandleError(c, appErr)
		return
	}

	utils.Info("User registered successfully", map[string]interface{}{
		"user_id":    newUser.ID.Hex(),
		"email_hash": utils.HashEmailForLogging(req.Email),
		"role":       newUser.Role,
		"ip":         c.ClientIP(),
	})

	response.Created(c, models.RegisterSuccessful, gin.H{
		"user":          newUser,
		"access_token":  tokens.AccessToken,
		"refresh_token": tokens.RefreshToken,
	})
}

// Login handles user authentication requests
func (h *Handler) Login(c *gin.Context) {
	var loginData request.LoginRequest
	ctx := c.Request.Context()

	utils.Info("Login attempt", map[string]interface{}{
		"ip":         c.ClientIP(),
		"method":     c.Request.Method,
		"path":       c.Request.URL.Path,
		"origin":     c.GetHeader("Origin"),
		"referer":    c.GetHeader("Referer"),
		"user_agent": c.GetHeader("User-Agent"),
		"host":       c.Request.Host,
	})

	if err := base.BindJSON(c, &loginData); err != nil {
		return
	}

	loginData.Email = middlewares.SanitizeInput(loginData.Email)
	ipAddress := c.ClientIP()

	user, tokens, err := h.authService.LoginUser(ctx, &loginData, ipAddress)
	if err != nil {
		if pkgErrors.Is(err, ErrInvalidCredentials) {
			appErr := h.handleLoginError(c, err, ipAddress, loginData.Email)
			response.HandleError(c, appErr)
			return
		}

		utils.Warn("Login failed - authentication error", map[string]interface{}{
			"email": loginData.Email,
			"ip":    ipAddress,
			"error": err.Error(),
		})
		appErr := h.convertAuthError(err)
		response.HandleError(c, appErr)
		return
	}

	utils.Info("Login successful", map[string]interface{}{
		"user_id": user.ID.Hex(),
		"email":   user.Email,
		"role":    user.Role,
		"ip":      ipAddress,
	})

	response.OK(c, models.LoginSuccessful, gin.H{
		"user":          user,
		"access_token":  tokens.AccessToken,
		"refresh_token": tokens.RefreshToken,
	})
}

// RefreshToken handles token refresh requests
func (h *Handler) RefreshToken(c *gin.Context) {
	var refreshData request.RefreshTokenRequest
	ctx := c.Request.Context()

	if err := base.BindJSON(c, &refreshData); err != nil {
		return
	}

	tokens, err := h.authService.RefreshAccessToken(ctx, refreshData.RefreshToken)
	if err != nil {
		appErr := h.convertTokenError(err)
		response.HandleError(c, appErr)
		return
	}

	utils.Debug("Token refreshed successfully", map[string]interface{}{
		"ip": c.ClientIP(),
	})

	response.OK(c, "token_refreshed_successfully", gin.H{
		"access_token":  tokens.AccessToken,
		"refresh_token": tokens.RefreshToken,
	})
}

// Logout handles user logout requests
// Revokes both the refresh token and the current access token for immediate invalidation
func (h *Handler) Logout(c *gin.Context) {
	var logoutData request.LogoutRequest
	ctx := c.Request.Context()

	if err := base.BindJSON(c, &logoutData); err != nil {
		return
	}

	// 1. Revoke the refresh token
	err := h.authService.LogoutUser(ctx, logoutData.RefreshToken)
	if err != nil {
		utils.Error("Logout failed - refresh token revocation", map[string]interface{}{
			"error": err.Error(),
			"ip":    c.ClientIP(),
		})
		response.HandleError(c, pkgErrors.ErrInternalServer("Logout failed", err))
		return
	}

	// 2. Revoke the access token immediately (extract JTI from Authorization header)
	if h.revocationService != nil {
		authHeader := c.GetHeader("Authorization")
		if authHeader != "" && strings.HasPrefix(authHeader, "Bearer ") {
			tokenString := strings.TrimPrefix(authHeader, "Bearer ")

			// Extract JTI from the token
			claims, err := h.authService.VerifyAuthToken(tokenString)
			if err == nil {
				if jti, ok := claims["jti"].(string); ok && jti != "" {
					// Add access token JTI to revocation list
					if revokeErr := h.revocationService.RevokeToken(c.Request.Context(), jti); revokeErr != nil {
						// Log but don't fail the logout - refresh token is already revoked
						utils.Warn("Failed to revoke access token", map[string]interface{}{
							"error": revokeErr.Error(),
							"ip":    c.ClientIP(),
						})
					} else {
						utils.Debug("Access token revoked", map[string]interface{}{
							"jti": jti[:8] + "...",
							"ip":  c.ClientIP(),
						})
					}
				}
			}
		}
	}

	utils.Info("Logout successful", map[string]interface{}{
		"ip": c.ClientIP(),
	})

	response.OK(c, models.LogoutSuccessful, nil)
}

// ForgotPassword handles password reset requests
func (h *Handler) ForgotPassword(c *gin.Context) {
	var req request.ForgotPasswordRequest
	ctx := c.Request.Context()

	utils.Info("Password reset requested", map[string]interface{}{
		"ip":         c.ClientIP(),
		"user_agent": c.GetHeader("User-Agent"),
	})

	if err := base.BindJSON(c, &req); err != nil {
		return
	}

	req.Email = middlewares.SanitizeInput(req.Email)

	plainToken, err := h.authService.RequestPasswordReset(ctx, req.Email)
	if err != nil {
		if pkgErrors.Is(err, ErrEmailNotFound) {
			utils.Warn("Password reset requested for non-existent email", map[string]interface{}{
				"email_hash": utils.HashEmailForLogging(req.Email),
				"ip":         c.ClientIP(),
			})
			response.OK(c, models.PasswordResetSent, nil)
			return
		}

		utils.Error("Password reset request failed", map[string]interface{}{
			"error": err.Error(),
			"ip":    c.ClientIP(),
		})
		response.HandleError(c, pkgErrors.ErrInternalServer("Password reset failed", err))
		return
	}

	utils.Info("Password reset token generated", map[string]interface{}{
		"email_hash": utils.HashEmailForLogging(req.Email),
		"token":      plainToken[:8] + "...",
	})

	// Only expose token in development mode - NEVER in production
	if config.Cfg.Env != "production" {
		utils.Warn("PASSWORD RESET TOKEN (Development Only)", map[string]interface{}{
			"email":      req.Email,
			"token":      plainToken,
			"reset_link": "http://localhost:8080/reset-password?token=" + plainToken,
		})

		response.OK(c, models.PasswordResetSent, gin.H{
			"message":    "If your email exists in our system, you will receive a password reset link.",
			"_dev_token": plainToken,
		})
		return
	}

	response.OK(c, models.PasswordResetSent, gin.H{
		"message": "If your email exists in our system, you will receive a password reset link.",
	})
}

// ResetPassword handles password reset with token
func (h *Handler) ResetPassword(c *gin.Context) {
	var req request.ResetPasswordRequest
	ctx := c.Request.Context()

	utils.Info("Password reset attempt", map[string]interface{}{
		"ip":         c.ClientIP(),
		"user_agent": c.GetHeader("User-Agent"),
	})

	if err := base.BindJSON(c, &req); err != nil {
		return
	}

	if passwordErrors := middlewares.ValidatePasswordStrength(req.NewPassword); len(passwordErrors) > 0 {
		utils.Warn("Password reset failed - weak password", map[string]interface{}{
			"ip":              c.ClientIP(),
			"password_errors": passwordErrors,
		})
		err := pkgErrors.ErrWeakPassword(passwordErrors)
		response.HandleError(c, err)
		return
	}

	err := h.authService.ResetPassword(ctx, req.Token, req.NewPassword)
	if err != nil {
		var appErr *pkgErrors.AppError

		if pkgErrors.Is(err, ErrInvalidResetToken) {
			appErr = pkgErrors.NewAppError(models.InvalidResetToken, "Invalid reset token", 400, err)
		} else if pkgErrors.Is(err, ErrResetTokenExpired) {
			appErr = pkgErrors.NewAppError(models.ResetTokenExpired, "Reset token has expired", 400, err)
		} else if pkgErrors.Is(err, ErrResetTokenUsed) {
			appErr = pkgErrors.NewAppError(models.ResetTokenAlreadyUsed, "Reset token has already been used", 400, err)
		} else {
			appErr = pkgErrors.ErrInternalServer("Password reset failed", err)
		}

		utils.Warn("Password reset failed", map[string]interface{}{
			"error": err.Error(),
			"ip":    c.ClientIP(),
		})
		response.HandleError(c, appErr)
		return
	}

	utils.Info("Password reset successful", map[string]interface{}{
		"ip": c.ClientIP(),
	})

	response.OK(c, models.PasswordResetSuccessful, gin.H{
		"message": "Your password has been reset successfully. Please login with your new password.",
	})
}

// ValidateToken validates if a reset token is valid
func (h *Handler) ValidateToken(c *gin.Context) {
	ctx := c.Request.Context()

	token := c.Query("token")
	if token == "" {
		response.HandleError(c, pkgErrors.ErrRequiredField("token"))
		return
	}

	err := h.authService.ValidateResetToken(ctx, token)
	if err != nil {
		var appErr *pkgErrors.AppError

		if pkgErrors.Is(err, ErrInvalidResetToken) {
			appErr = pkgErrors.NewAppError(models.InvalidResetToken, "Invalid reset token", 400, err)
		} else if pkgErrors.Is(err, ErrResetTokenExpired) {
			appErr = pkgErrors.NewAppError(models.ResetTokenExpired, "Reset token has expired", 400, err)
		} else if pkgErrors.Is(err, ErrResetTokenUsed) {
			appErr = pkgErrors.NewAppError(models.ResetTokenAlreadyUsed, "Reset token has already been used", 400, err)
		} else {
			appErr = pkgErrors.ErrInternalServer("Token validation failed", err)
		}

		response.HandleError(c, appErr)
		return
	}

	response.OK(c, models.TokenValidatedSuccessful, gin.H{
		"valid": true,
	})
}

// OAuth Handlers

// InitiateGoogleOAuth initiates Google OAuth flow
func (h *Handler) InitiateGoogleOAuth(c *gin.Context) {
	if h.oauthService == nil {
		utils.Warn("OAuth not configured - Google login attempted", map[string]interface{}{
			"ip": c.ClientIP(),
		})
		response.Error(c, 503, models.OAuthNotConfigured)
		return
	}

	ctx := c.Request.Context()

	redirectURI := c.Query("redirect_uri")
	if redirectURI == "" {
		redirectURI = config.Cfg.GoogleRedirectURI
	}

	authURL, state, err := h.oauthService.InitiateOAuthLogin(ctx, models.OAuthProviderGoogle, redirectURI)
	if err != nil {
		utils.Error("Failed to initiate Google OAuth", map[string]interface{}{
			"error": err.Error(),
			"ip":    c.ClientIP(),
		})
		response.HandleError(c, pkgErrors.ErrInternalServer("OAuth initiation failed", err))
		return
	}

	utils.Info("Google OAuth initiated", map[string]interface{}{
		"ip":    c.ClientIP(),
		"state": state,
	})

	response.OK(c, "oauth_initiated", gin.H{
		"auth_url": authURL,
		"state":    state,
	})
}

// HandleGoogleCallback handles Google OAuth callback
func (h *Handler) HandleGoogleCallback(c *gin.Context) {
	if h.oauthService == nil {
		utils.Warn("OAuth not configured - Google callback received", map[string]interface{}{
			"ip": c.ClientIP(),
		})
		response.Error(c, 503, models.OAuthNotConfigured)
		return
	}

	ctx := c.Request.Context()

	code := c.Query("code")
	state := c.Query("state")

	if code == "" || state == "" {
		utils.Warn("OAuth callback missing parameters", map[string]interface{}{
			"ip": c.ClientIP(),
		})
		response.HandleError(c, pkgErrors.ErrRequiredField("code and state"))
		return
	}

	user, _, err := h.oauthService.HandleOAuthCallback(ctx, models.OAuthProviderGoogle, code, state)
	if err != nil {
		utils.Error("Google OAuth callback failed", map[string]interface{}{
			"error": err.Error(),
			"ip":    c.ClientIP(),
		})
		response.HandleError(c, pkgErrors.ErrInternalServer("OAuth callback failed", err))
		return
	}

	tokens, err := h.authService.GenerateTokensForUser(ctx, user)
	if err != nil {
		utils.Error("Failed to generate tokens for OAuth user", map[string]interface{}{
			"error":   err.Error(),
			"user_id": user.ID.Hex(),
			"ip":      c.ClientIP(),
		})
		response.HandleError(c, pkgErrors.ErrInternalServer("Token generation failed", err))
		return
	}

	utils.Info("Google OAuth login successful", map[string]interface{}{
		"user_id": user.ID.Hex(),
		"email":   utils.HashEmailForLogging(user.Email),
		"ip":      c.ClientIP(),
	})

	response.OK(c, models.LoginSuccessful, gin.H{
		"user":          user,
		"access_token":  tokens.AccessToken,
		"refresh_token": tokens.RefreshToken,
	})
}

// InitiateFacebookOAuth initiates Facebook OAuth flow
func (h *Handler) InitiateFacebookOAuth(c *gin.Context) {
	if h.oauthService == nil {
		utils.Warn("OAuth not configured - Facebook login attempted", map[string]interface{}{
			"ip": c.ClientIP(),
		})
		response.Error(c, 503, models.OAuthNotConfigured)
		return
	}

	ctx := c.Request.Context()

	redirectURI := c.Query("redirect_uri")
	if redirectURI == "" {
		redirectURI = config.Cfg.FacebookRedirectURI
	}

	authURL, state, err := h.oauthService.InitiateOAuthLogin(ctx, models.OAuthProviderFacebook, redirectURI)
	if err != nil {
		utils.Error("Failed to initiate Facebook OAuth", map[string]interface{}{
			"error": err.Error(),
			"ip":    c.ClientIP(),
		})
		response.HandleError(c, pkgErrors.ErrInternalServer("OAuth initiation failed", err))
		return
	}

	utils.Info("Facebook OAuth initiated", map[string]interface{}{
		"ip":    c.ClientIP(),
		"state": state,
	})

	response.OK(c, "oauth_initiated", gin.H{
		"auth_url": authURL,
		"state":    state,
	})
}

// HandleFacebookCallback handles Facebook OAuth callback
func (h *Handler) HandleFacebookCallback(c *gin.Context) {
	if h.oauthService == nil {
		utils.Warn("OAuth not configured - Facebook callback received", map[string]interface{}{
			"ip": c.ClientIP(),
		})
		response.Error(c, 503, models.OAuthNotConfigured)
		return
	}

	ctx := c.Request.Context()

	code := c.Query("code")
	state := c.Query("state")

	if code == "" || state == "" {
		utils.Warn("OAuth callback missing parameters", map[string]interface{}{
			"ip": c.ClientIP(),
		})
		response.HandleError(c, pkgErrors.ErrRequiredField("code and state"))
		return
	}

	user, _, err := h.oauthService.HandleOAuthCallback(ctx, models.OAuthProviderFacebook, code, state)
	if err != nil {
		utils.Error("Facebook OAuth callback failed", map[string]interface{}{
			"error": err.Error(),
			"ip":    c.ClientIP(),
		})
		response.HandleError(c, pkgErrors.ErrInternalServer("OAuth callback failed", err))
		return
	}

	tokens, err := h.authService.GenerateTokensForUser(ctx, user)
	if err != nil {
		utils.Error("Failed to generate tokens for OAuth user", map[string]interface{}{
			"error":   err.Error(),
			"user_id": user.ID.Hex(),
			"ip":      c.ClientIP(),
		})
		response.HandleError(c, pkgErrors.ErrInternalServer("Token generation failed", err))
		return
	}

	utils.Info("Facebook OAuth login successful", map[string]interface{}{
		"user_id": user.ID.Hex(),
		"email":   utils.HashEmailForLogging(user.Email),
		"ip":      c.ClientIP(),
	})

	response.OK(c, models.LoginSuccessful, gin.H{
		"user":          user,
		"access_token":  tokens.AccessToken,
		"refresh_token": tokens.RefreshToken,
	})
}

// Helper methods

func (h *Handler) convertAuthError(err error) *pkgErrors.AppError {
	if pkgErrors.Is(err, ErrIncompleteFields) {
		return pkgErrors.ErrRequiredField("")
	}
	if pkgErrors.Is(err, ErrUserExists) {
		return pkgErrors.ErrEmailAlreadyExists()
	}
	if pkgErrors.Is(err, ErrInvalidCredentials) {
		return pkgErrors.ErrInvalidCredentials()
	}
	if pkgErrors.IsDuplicateKeyError(err) {
		return pkgErrors.ErrEmailAlreadyExists()
	}
	return pkgErrors.ErrInternalServer("Authentication error", err)
}

func (h *Handler) handleLoginError(c *gin.Context, err error, ipAddress string, email string) *pkgErrors.AppError {
	errMsg := err.Error()

	if len(errMsg) > 50 && errMsg[:15] == "account tempora" {
		utils.Warn("Account lockout detected", map[string]interface{}{
			"ip":         ipAddress,
			"email":      email,
			"origin":     c.GetHeader("Origin"),
			"user_agent": c.GetHeader("User-Agent"),
		})
		return pkgErrors.NewAppError(models.AccountLocked, "Account temporarily locked", 429, err)
	}

	utils.Warn("Login failed - invalid credentials", map[string]interface{}{
		"ip":    ipAddress,
		"email": email,
	})
	return pkgErrors.ErrInvalidCredentials()
}

func (h *Handler) convertTokenError(err error) *pkgErrors.AppError {
	if pkgErrors.Is(err, ErrInvalidRefreshToken) {
		return pkgErrors.ErrInvalidToken()
	}
	if pkgErrors.Is(err, ErrTokenRevoked) {
		return pkgErrors.ErrTokenRevoked()
	}
	return pkgErrors.ErrInvalidToken()
}
