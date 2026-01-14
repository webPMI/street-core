package auth

import (
	"backend/app/dto/request"
	"backend/models"
	"backend/pkg/repository"
	"context"
	"crypto/rand"
	"encoding/hex"
	"errors"
	"fmt"
	"time"

	"github.com/golang-jwt/jwt/v5"
	"github.com/google/uuid"
	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/bson/primitive"
	"go.mongodb.org/mongo-driver/mongo"
)

// Common errors
var (
	ErrInvalidCredentials  = errors.New("invalid credentials")
	ErrUserExists          = errors.New("user already exists")
	ErrIncompleteFields    = errors.New("incomplete fields")
	ErrInvalidRefreshToken = errors.New("invalid refresh token")
	ErrTokenRevoked        = errors.New("token has been revoked")
	ErrEmailNotFound       = errors.New("email not found")
	ErrInvalidResetToken   = errors.New("invalid reset token")
	ErrResetTokenExpired   = errors.New("reset token expired")
	ErrResetTokenUsed      = errors.New("reset token already used")
)

// authServiceImpl implements AuthService interface
type authServiceImpl struct {
	userRepo          repository.IRepository[models.User]
	refreshTokenRepo  repository.IRepository[models.RefreshToken]
	failedLoginRepo   repository.IRepository[models.FailedLoginAttempt]
	passwordResetRepo repository.IRepository[models.PasswordResetToken]
	refreshTokenColl  *mongo.Collection
	jwtSecret         string
	jwtExpiresIn      time.Duration
	refreshExpiresIn  time.Duration
}

// NewAuthService creates a new auth service instance
func NewAuthService(
	userRepo repository.IRepository[models.User],
	refreshTokenRepo repository.IRepository[models.RefreshToken],
	failedLoginRepo repository.IRepository[models.FailedLoginAttempt],
	passwordResetRepo repository.IRepository[models.PasswordResetToken],
	refreshTokenColl *mongo.Collection,
	jwtSecret string,
	jwtExpiresIn time.Duration,
	refreshExpiresIn time.Duration,
) AuthService {
	return &authServiceImpl{
		userRepo:          userRepo,
		refreshTokenRepo:  refreshTokenRepo,
		failedLoginRepo:   failedLoginRepo,
		passwordResetRepo: passwordResetRepo,
		refreshTokenColl:  refreshTokenColl,
		jwtSecret:         jwtSecret,
		jwtExpiresIn:      jwtExpiresIn,
		refreshExpiresIn:  refreshExpiresIn,
	}
}

// RegisterUser registers a new user
func (s *authServiceImpl) RegisterUser(ctx context.Context, req *request.RegisterRequest) (*models.User, *TokenPair, error) {
	// Check if user exists
	query := repository.NewQuery().Where("email", req.Email)
	existing, _ := s.userRepo.FindOne(ctx, query)
	if existing != nil {
		return nil, nil, ErrUserExists
	}

	// Create new user
	user := &models.User{
		Email:     req.Email,
		Password:  req.Password,
		FirstName: req.FirstName,
		LastName:  req.LastName,
		UserName:  req.Username,
	}

	if err := user.PrepareForInsert(); err != nil {
		return nil, nil, err
	}

	if _, err := s.userRepo.Create(ctx, user); err != nil {
		return nil, nil, err
	}

	// Generate tokens
	tokens, err := s.GenerateTokensForUser(ctx, user)
	if err != nil {
		return nil, nil, err
	}

	return user, tokens, nil
}

// LoginUser authenticates a user
func (s *authServiceImpl) LoginUser(ctx context.Context, req *request.LoginRequest, ipAddress string) (*models.User, *TokenPair, error) {
	query := repository.NewQuery().Where("email", req.Email)
	user, err := s.userRepo.FindOne(ctx, query)
	if err != nil {
		// SECURITY: Constant-time comparison to prevent timing attacks
		// This ensures login attempts for non-existent users take the same time
		// as attempts for existing users, preventing email enumeration
		models.CompareDummyPassword(req.Password)
		return nil, nil, ErrInvalidCredentials
	}

	if !user.MatchPassword(req.Password) {
		return nil, nil, ErrInvalidCredentials
	}

	if !user.IsActive {
		return nil, nil, ErrInvalidCredentials
	}

	tokens, err := s.GenerateTokensForUser(ctx, user)
	if err != nil {
		return nil, nil, err
	}

	return user, tokens, nil
}

// RefreshAccessToken refreshes the access token
func (s *authServiceImpl) RefreshAccessToken(ctx context.Context, refreshToken string) (*TokenPair, error) {
	query := repository.NewQuery().Where("token", refreshToken)
	token, err := s.refreshTokenRepo.FindOne(ctx, query)
	if err != nil {
		return nil, ErrInvalidRefreshToken
	}

	if !token.IsValid() {
		return nil, ErrTokenRevoked
	}

	// Get user
	user, err := s.userRepo.GetByID(ctx, token.UserID)
	if err != nil {
		return nil, err
	}

	// Mark old token as used
	_, err = s.refreshTokenColl.UpdateOne(ctx,
		bson.M{"_id": token.ID},
		bson.M{"$set": bson.M{"used": true, "used_at": time.Now()}},
	)
	if err != nil {
		return nil, err
	}

	return s.GenerateTokensForUser(ctx, user)
}

// LogoutUser logs out a user by revoking their refresh token
func (s *authServiceImpl) LogoutUser(ctx context.Context, refreshToken string) error {
	now := time.Now()
	_, err := s.refreshTokenColl.UpdateOne(ctx,
		bson.M{"token": refreshToken},
		bson.M{"$set": bson.M{"revoked": true, "revoked_at": now}},
	)
	return err
}

// RequestPasswordReset creates a password reset token
func (s *authServiceImpl) RequestPasswordReset(ctx context.Context, email string) (string, error) {
	query := repository.NewQuery().Where("email", email)
	user, err := s.userRepo.FindOne(ctx, query)
	if err != nil {
		return "", ErrEmailNotFound
	}

	// Generate reset token
	tokenBytes := make([]byte, 32)
	if _, err := rand.Read(tokenBytes); err != nil {
		return "", err
	}
	plainToken := hex.EncodeToString(tokenBytes)

	// Hash the token for storage
	hashedToken, err := models.HashPassword(plainToken)
	if err != nil {
		return "", err
	}

	resetToken := &models.PasswordResetToken{
		ID:        primitive.NewObjectID(),
		Token:     hashedToken,
		UserID:    user.ID,
		Email:     email,
		ExpiresAt: time.Now().Add(1 * time.Hour),
		CreatedAt: time.Now(),
	}

	if _, err := s.passwordResetRepo.Create(ctx, resetToken); err != nil {
		return "", err
	}

	return plainToken, nil
}

// ResetPassword resets user password with token
func (s *authServiceImpl) ResetPassword(ctx context.Context, token, newPassword string) error {
	// Find all non-used, non-expired tokens
	query := repository.NewQuery().
		Where("used", false).
		Where("expires_at", bson.M{"$gt": time.Now()})

	tokens, _, err := s.passwordResetRepo.Find(ctx, query)
	if err != nil {
		return ErrInvalidResetToken
	}

	// Find matching token
	var matchedToken *models.PasswordResetToken
	for _, t := range tokens {
		if models.ComparePassword(token, t.Token) {
			matchedToken = &t
			break
		}
	}

	if matchedToken == nil {
		return ErrInvalidResetToken
	}

	// Hash new password
	hashedPassword, err := models.HashPassword(newPassword)
	if err != nil {
		return err
	}

	// Update user password
	if err := s.userRepo.Update(ctx, matchedToken.UserID, map[string]interface{}{
		"password":  hashedPassword,
		"updatedAt": time.Now(),
	}); err != nil {
		return err
	}

	// Mark token as used
	now := time.Now()
	return s.passwordResetRepo.Update(ctx, matchedToken.ID, map[string]interface{}{
		"used":    true,
		"used_at": now,
	})
}

// ValidateResetToken validates a password reset token
func (s *authServiceImpl) ValidateResetToken(ctx context.Context, token string) error {
	query := repository.NewQuery().
		Where("used", false).
		Where("expires_at", bson.M{"$gt": time.Now()})

	tokens, _, err := s.passwordResetRepo.Find(ctx, query)
	if err != nil {
		return ErrInvalidResetToken
	}

	for _, t := range tokens {
		if models.ComparePassword(token, t.Token) {
			return nil
		}
	}

	return ErrInvalidResetToken
}

// GenerateTokensForUser generates access and refresh tokens for a user
func (s *authServiceImpl) GenerateTokensForUser(ctx context.Context, user *models.User) (*TokenPair, error) {
	// Generate access token
	accessToken, err := s.generateAccessToken(user)
	if err != nil {
		return nil, err
	}

	// Generate refresh token
	refreshTokenBytes := make([]byte, 32)
	if _, err := rand.Read(refreshTokenBytes); err != nil {
		return nil, err
	}
	refreshTokenStr := hex.EncodeToString(refreshTokenBytes)

	// Generate family ID for token rotation
	familyBytes := make([]byte, 16)
	if _, err := rand.Read(familyBytes); err != nil {
		return nil, err
	}
	familyID := hex.EncodeToString(familyBytes)

	// Store refresh token
	refreshToken := &models.RefreshToken{
		ID:        primitive.NewObjectID(),
		Token:     refreshTokenStr,
		UserID:    user.ID,
		FamilyID:  familyID,
		ExpiresAt: time.Now().Add(s.refreshExpiresIn),
		CreatedAt: time.Now(),
	}

	if _, err := s.refreshTokenRepo.Create(ctx, refreshToken); err != nil {
		return nil, err
	}

	return &TokenPair{
		AccessToken:  accessToken,
		RefreshToken: refreshTokenStr,
	}, nil
}

// ValidateToken validates a JWT token and returns claims
func (s *authServiceImpl) ValidateToken(tokenString string) (*TokenClaims, error) {
	token, err := jwt.Parse(tokenString, func(token *jwt.Token) (interface{}, error) {
		if _, ok := token.Method.(*jwt.SigningMethodHMAC); !ok {
			return nil, fmt.Errorf("unexpected signing method: %v", token.Header["alg"])
		}
		return []byte(s.jwtSecret), nil
	})

	if err != nil {
		return nil, err
	}

	if claims, ok := token.Claims.(jwt.MapClaims); ok && token.Valid {
		userID, _ := primitive.ObjectIDFromHex(claims["sub"].(string))
		return &TokenClaims{
			UserID:       userID,
			Email:        claims["email"].(string),
			Role:         claims["role"].(string),
			TokenVersion: int(claims["token_version"].(float64)),
		}, nil
	}

	return nil, errors.New("invalid token")
}

// VerifyAuthToken verifies a token and returns the claims as a map
func (s *authServiceImpl) VerifyAuthToken(tokenString string) (map[string]interface{}, error) {
	token, err := jwt.Parse(tokenString, func(token *jwt.Token) (interface{}, error) {
		if _, ok := token.Method.(*jwt.SigningMethodHMAC); !ok {
			return nil, fmt.Errorf("unexpected signing method: %v", token.Header["alg"])
		}
		return []byte(s.jwtSecret), nil
	})

	if err != nil {
		return nil, err
	}

	if claims, ok := token.Claims.(jwt.MapClaims); ok && token.Valid {
		return claims, nil
	}

	return nil, errors.New("invalid token")
}

// generateAccessToken generates a JWT access token
func (s *authServiceImpl) generateAccessToken(user *models.User) (string, error) {
	now := time.Now()
	claims := jwt.MapClaims{
		"jti":   uuid.New().String(), // JWT ID for token revocation support
		"sub":   user.ID.Hex(),
		"email": user.Email,
		"role":  user.Role,
		"ver":   user.TokenVersion, // Token version for mass revocation
		"exp":   now.Add(s.jwtExpiresIn).Unix(),
		"iat":   now.Unix(),
	}

	token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
	return token.SignedString([]byte(s.jwtSecret))
}
