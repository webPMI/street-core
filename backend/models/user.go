package models

import (
	"errors"
	"strings"
	"time"

	"go.mongodb.org/mongo-driver/bson/primitive"
	"golang.org/x/crypto/bcrypt"
)

// Definición de valores permitidos para facilitar el código
const (
	GenderMale   = "male"
	GenderFemale = "female"
	GenderOther  = "other"

	RoleAdmin  = "admin"
	RoleEditor = "editor"
	RoleUser   = "user"
)

// User representa el modelo de usuario para MongoDB.
type User struct {
	// ID: Tipo ObjectID, mapeado a _id, y serializado a 'id' en JSON.
	ID primitive.ObjectID `json:"id" bson:"_id,omitempty"`

	// Fechas
	CreatedAt time.Time `json:"createdAt" bson:"createdAt"`
	UpdatedAt time.Time `json:"updatedAt" bson:"updatedAt"`

	// Campos Principales
	FirstName string `json:"firstName" bson:"firstName" validate:"required,min=2,max=50"`
	LastName  string `json:"lastName" bson:"lastName" validate:"omitempty,max=50"`
	Bio       string `json:"bio" bson:"bio" validate:"omitempty,max=500"`

	// Email: Será normalizado a minúsculas y debe ser único (configurado con índice en MongoDB).
	Email string `json:"email" bson:"email" validate:"required,email,max=100"`

	Phone string `json:"phone" bson:"phone" validate:"omitempty,min=10,max=15"`

	// Gender
	Gender string `json:"gender" bson:"gender" validate:"omitempty,oneof=male female other"`

	// NickName
	NickName *string `json:"nickName" bson:"nickName" validate:"omitempty,min=3,max=30"`

	IsPremium bool `json:"isPremium" bson:"isPremium"`

	ImageUrl string `json:"imageUrl" bson:"imageUrl" validate:"omitempty,url,max=500"`

	// Password: Oculta en JSON (json:"-") y almacena el hash.
	// 🔒 SECURITY: Password is now OPTIONAL for OAuth-only users
	// Traditional login users MUST have a password
	// Minimum 8 characters (enforced in handler with custom validation)
	Password string `json:"-" bson:"password,omitempty" validate:"omitempty,min=8"`

	// Role: Con valor por defecto (se asigna en PrepareForInsert si está vacío).
	Role string `json:"role" bson:"role" validate:"omitempty,oneof=admin editor user"`

	// Social features
	UserName       string `json:"userName" bson:"userName" validate:"omitempty,min=3,max=30"`
	AvatarURL      string `json:"avatarUrl" bson:"avatarUrl" validate:"omitempty,url,max=500"`
	IsPrivate      bool   `json:"isPrivate" bson:"isPrivate"`
	FollowersCount int    `json:"followersCount" bson:"followersCount"`
	FollowingCount int    `json:"followingCount" bson:"followingCount"`

	// OAuth fields (added for OAuth 2.0 support)
	// 🔒 SECURITY: Tracks which OAuth providers are linked to this account
	OAuthProviders []string `json:"oauthProviders,omitempty" bson:"oauthProviders,omitempty"`
	EmailVerified  bool     `json:"emailVerified" bson:"emailVerified"` // True if email confirmed via OAuth or verification email

	// Security: Token versioning for JWT revocation
	// Incrementing this value invalidates all tokens issued before the increment
	TokenVersion int `json:"-" bson:"tokenVersion"` // Hidden from JSON responses

	// Account status
	IsActive bool `json:"isActive" bson:"isActive"` // True if account is active, false if disabled/suspended

	// Two-Factor Authentication (2FA)
	TwoFactorEnabled    bool      `json:"twoFactorEnabled" bson:"twoFactorEnabled"`
	TwoFactorSecret     string    `json:"-" bson:"twoFactorSecret,omitempty"` // Hidden from JSON, stores TOTP secret
	TwoFactorVerifiedAt time.Time `json:"twoFactorVerifiedAt,omitempty" bson:"twoFactorVerifiedAt,omitempty"`
	BackupCodes         []string  `json:"-" bson:"backupCodes,omitempty"` // Hidden from JSON, stores hashed backup codes
}

// ------------------------------------
// 💡 Lógica de Negocio (Simulación de Middleware/Hooks)
// PrepareForInsert prepara el usuario antes de insertarlo en la base de datos.
func (u *User) PrepareForInsert() error {
	// 1. Asignar ID
	u.ID = primitive.NewObjectID()

	// 2. Asignar fechas
	now := time.Now()
	u.CreatedAt = now
	u.UpdatedAt = now

	// 3. Normalizar Email
	u.Email = strings.ToLower(u.Email)

	// 4. Hashear la contraseña (si se proporciona)
	if u.Password != "" {
		hashed, err := HashPassword(u.Password)
		if err != nil {
			return err
		}
		u.Password = hashed
	}

	// 5. Asignar rol por defecto
	if u.Role == "" {
		u.Role = RoleUser
	}

	// 6. Asignar estado activo por defecto
	// New accounts are active by default unless explicitly set to inactive
	u.IsActive = true

	return nil
}

// ------------------------------------
// 🔑 Funciones de Seguridad y Métodos

// HashPassword usa bcrypt para hashear la contraseña.
func HashPassword(password string) (string, error) {
	// Usamos cost 12 para mayor seguridad (mejor que el DefaultCost de 10)
	const bcryptCost = 12
	bytes, err := bcrypt.GenerateFromPassword([]byte(password), bcryptCost)
	if err != nil {
		return "", errors.New("falló el hashing de la contraseña")
	}
	return string(bytes), nil
}

// MatchPassword compara la contraseña ingresada con el hash almacenado.
func (u *User) MatchPassword(enteredPassword string) bool {
	// CompareHashAndPassword devuelve nil si la contraseña coincide
	err := bcrypt.CompareHashAndPassword([]byte(u.Password), []byte(enteredPassword))
	return err == nil
}

// ComparePassword compara una contraseña ingresada con un hash almacenado
// Returns true if the password matches the hash
func ComparePassword(password, hash string) bool {
	err := bcrypt.CompareHashAndPassword([]byte(hash), []byte(password))
	return err == nil
}

// DummyPasswordHash is a pre-computed bcrypt hash used for timing attack prevention.
// This hash is for a random password and is used when a user doesn't exist.
// SECURITY: Must be a valid bcrypt hash with the same cost factor (12) as real passwords.
// Generated with: bcrypt.GenerateFromPassword([]byte("dummy_password_for_timing_attack_prevention"), 12)
const DummyPasswordHash = "$2a$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/X4dOVGfXDE5POu.lS"

// CompareDummyPassword executes bcrypt compare with a pre-computed dummy hash.
// SECURITY: Used to maintain constant time during login when user doesn't exist.
// This prevents timing attacks that reveal whether an email exists in the system.
// The comparison always takes the same time regardless of whether the user exists.
func CompareDummyPassword(password string) {
	// Execute bcrypt comparison but ignore result
	// This takes the same time as a real password check
	_ = bcrypt.CompareHashAndPassword([]byte(DummyPasswordHash), []byte(password))
}

// ToLowerCase (Función auxiliar llamada por PrepareForInsert)
func ToLowerCase(s string) string {
	return strings.ToLower(s)
}
