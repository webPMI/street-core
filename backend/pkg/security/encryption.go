package security

import (
	"crypto/aes"
	"crypto/cipher"
	"crypto/rand"
	"encoding/base64"
	"errors"
	"io"
	"sync"
)

var (
	// ErrInvalidKey is returned when the encryption key is invalid
	ErrInvalidKey = errors.New("encryption key must be 32 bytes for AES-256")
	// ErrDecryptionFailed is returned when decryption fails
	ErrDecryptionFailed = errors.New("decryption failed: invalid ciphertext")
	// ErrEncryptionNotInitialized is returned when encryption is used before initialization
	ErrEncryptionNotInitialized = errors.New("encryption service not initialized")
)

// Encryptor provides AES-256-GCM encryption for sensitive data at rest.
// SECURITY: Used for encrypting OAuth tokens and other sensitive data stored in the database.
type Encryptor struct {
	gcm cipher.AEAD
	mu  sync.RWMutex
}

// Global encryptor instance
var (
	globalEncryptor *Encryptor
	encryptorOnce   sync.Once
)

// InitEncryption initializes the global encryption service with the provided key.
// The key must be exactly 32 bytes for AES-256.
// Call this during application startup with the encryption key from config/secrets.
func InitEncryption(key []byte) error {
	if len(key) != 32 {
		return ErrInvalidKey
	}

	var initErr error
	encryptorOnce.Do(func() {
		block, err := aes.NewCipher(key)
		if err != nil {
			initErr = err
			return
		}

		gcm, err := cipher.NewGCM(block)
		if err != nil {
			initErr = err
			return
		}

		globalEncryptor = &Encryptor{gcm: gcm}
	})

	return initErr
}

// Encrypt encrypts plaintext using AES-256-GCM and returns base64-encoded ciphertext.
// Returns empty string if plaintext is empty (to handle optional fields).
func Encrypt(plaintext string) (string, error) {
	if plaintext == "" {
		return "", nil
	}

	if globalEncryptor == nil {
		return "", ErrEncryptionNotInitialized
	}

	globalEncryptor.mu.RLock()
	defer globalEncryptor.mu.RUnlock()

	// Generate random nonce
	nonce := make([]byte, globalEncryptor.gcm.NonceSize())
	if _, err := io.ReadFull(rand.Reader, nonce); err != nil {
		return "", err
	}

	// Encrypt and prepend nonce to ciphertext
	ciphertext := globalEncryptor.gcm.Seal(nonce, nonce, []byte(plaintext), nil)

	// Return base64-encoded ciphertext
	return base64.StdEncoding.EncodeToString(ciphertext), nil
}

// Decrypt decrypts base64-encoded ciphertext and returns plaintext.
// Returns empty string if ciphertext is empty (to handle optional fields).
func Decrypt(ciphertext string) (string, error) {
	if ciphertext == "" {
		return "", nil
	}

	if globalEncryptor == nil {
		return "", ErrEncryptionNotInitialized
	}

	globalEncryptor.mu.RLock()
	defer globalEncryptor.mu.RUnlock()

	// Decode base64
	data, err := base64.StdEncoding.DecodeString(ciphertext)
	if err != nil {
		return "", ErrDecryptionFailed
	}

	nonceSize := globalEncryptor.gcm.NonceSize()
	if len(data) < nonceSize {
		return "", ErrDecryptionFailed
	}

	// Extract nonce and ciphertext
	nonce, ciphertextBytes := data[:nonceSize], data[nonceSize:]

	// Decrypt
	plaintext, err := globalEncryptor.gcm.Open(nil, nonce, ciphertextBytes, nil)
	if err != nil {
		return "", ErrDecryptionFailed
	}

	return string(plaintext), nil
}

// EncryptBytes encrypts byte slice and returns base64-encoded ciphertext.
func EncryptBytes(plaintext []byte) (string, error) {
	if len(plaintext) == 0 {
		return "", nil
	}
	return Encrypt(string(plaintext))
}

// DecryptBytes decrypts base64-encoded ciphertext and returns byte slice.
func DecryptBytes(ciphertext string) ([]byte, error) {
	plaintext, err := Decrypt(ciphertext)
	if err != nil {
		return nil, err
	}
	return []byte(plaintext), nil
}

// MustEncrypt encrypts plaintext and panics on error.
// Use only during initialization or when errors are unrecoverable.
func MustEncrypt(plaintext string) string {
	ciphertext, err := Encrypt(plaintext)
	if err != nil {
		panic("encryption failed: " + err.Error())
	}
	return ciphertext
}

// MustDecrypt decrypts ciphertext and panics on error.
// Use only during initialization or when errors are unrecoverable.
func MustDecrypt(ciphertext string) string {
	plaintext, err := Decrypt(ciphertext)
	if err != nil {
		panic("decryption failed: " + err.Error())
	}
	return plaintext
}

// IsEncryptionInitialized returns true if the encryption service has been initialized.
func IsEncryptionInitialized() bool {
	return globalEncryptor != nil
}
