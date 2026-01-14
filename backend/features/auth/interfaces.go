package auth

import (
	"backend/app/dto/request"
	"backend/models"
	"context"

	"go.mongodb.org/mongo-driver/bson/primitive"
)

// TokenPair represents access and refresh tokens
type TokenPair struct {
	AccessToken  string `json:"access_token"`
	RefreshToken string `json:"refresh_token"`
}

// TokenClaims represents JWT token claims
type TokenClaims struct {
	UserID       primitive.ObjectID
	Email        string
	Role         string
	TokenVersion int
}

// AuthService defines the authentication service interface
type AuthService interface {
	RegisterUser(ctx context.Context, req *request.RegisterRequest) (*models.User, *TokenPair, error)
	LoginUser(ctx context.Context, req *request.LoginRequest, ipAddress string) (*models.User, *TokenPair, error)
	RefreshAccessToken(ctx context.Context, refreshToken string) (*TokenPair, error)
	LogoutUser(ctx context.Context, refreshToken string) error
	RequestPasswordReset(ctx context.Context, email string) (string, error)
	ResetPassword(ctx context.Context, token, newPassword string) error
	ValidateResetToken(ctx context.Context, token string) error
	GenerateTokensForUser(ctx context.Context, user *models.User) (*TokenPair, error)
	ValidateToken(token string) (*TokenClaims, error)
	VerifyAuthToken(tokenString string) (map[string]interface{}, error)
}

// ITokenRevocationService defines the token revocation service interface
type ITokenRevocationService interface {
	RevokeToken(ctx context.Context, token string) error
	IsTokenRevoked(ctx context.Context, token string) (bool, error)
	RevokeAllUserTokens(ctx context.Context, userID string) error
	CleanupExpiredTokens(ctx context.Context) error
}
