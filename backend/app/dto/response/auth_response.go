package response

import "time"

// LoginResponse represents the response after successful login
type LoginResponse struct {
	User         *ProfileResponse `json:"user"`
	AccessToken  string           `json:"access_token"`
	RefreshToken string           `json:"refresh_token"`
	ExpiresIn    int              `json:"expires_in,omitempty"` // seconds until access token expires
}

// RegisterResponse represents the response after successful registration
type RegisterResponse struct {
	User         *ProfileResponse `json:"user"`
	AccessToken  string           `json:"access_token"`
	RefreshToken string           `json:"refresh_token"`
	ExpiresIn    int              `json:"expires_in,omitempty"`
}

// TokenPairResponse represents a pair of access and refresh tokens
type TokenPairResponse struct {
	AccessToken  string `json:"access_token"`
	RefreshToken string `json:"refresh_token"`
	ExpiresIn    int    `json:"expires_in,omitempty"`
	TokenType    string `json:"token_type"` // "Bearer"
}

// RefreshTokenResponse represents the response after token refresh
type RefreshTokenResponse struct {
	AccessToken  string `json:"access_token"`
	RefreshToken string `json:"refresh_token"`
	ExpiresIn    int    `json:"expires_in,omitempty"`
}

// LogoutResponse represents the response after logout
type LogoutResponse struct {
	Message string `json:"message"`
}

// PasswordResetResponse represents the response after password reset request
type PasswordResetResponse struct {
	Message string    `json:"message"`
	Email   string    `json:"email"`
	SentAt  time.Time `json:"sentAt"`
}

// NewLoginResponse creates a new login response
func NewLoginResponse(user *ProfileResponse, accessToken, refreshToken string, expiresIn int) *LoginResponse {
	return &LoginResponse{
		User:         user,
		AccessToken:  accessToken,
		RefreshToken: refreshToken,
		ExpiresIn:    expiresIn,
	}
}

// NewRegisterResponse creates a new register response
func NewRegisterResponse(user *ProfileResponse, accessToken, refreshToken string, expiresIn int) *RegisterResponse {
	return &RegisterResponse{
		User:         user,
		AccessToken:  accessToken,
		RefreshToken: refreshToken,
		ExpiresIn:    expiresIn,
	}
}

// NewTokenPairResponse creates a new token pair response
func NewTokenPairResponse(accessToken, refreshToken string, expiresIn int) *TokenPairResponse {
	return &TokenPairResponse{
		AccessToken:  accessToken,
		RefreshToken: refreshToken,
		ExpiresIn:    expiresIn,
		TokenType:    "Bearer",
	}
}
