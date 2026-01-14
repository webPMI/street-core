package utils

import (
	"crypto/aes"
	"crypto/cipher"
	"crypto/rand"
	"encoding/hex"
	"errors"
	"io"
)

// 🔒 SECURITY: Token Encryption using AES-256-GCM
//
// All OAuth tokens are encrypted at rest in the database using AES-256-GCM
// (Galois/Counter Mode) which provides both confidentiality and authenticity.
//
// Key properties:
// - Algorithm: AES-256-GCM (AEAD - Authenticated Encryption with Associated Data)
// - Key size: 256 bits (32 bytes)
// - Nonce: 96 bits (12 bytes) - generated randomly for each encryption
// - Authentication tag: 128 bits (16 bytes) - prevents tampering
//
// Security features:
// 1. Confidentiality: Encrypted tokens cannot be read without the key
// 2. Authenticity: Tampering is detected via authentication tag
// 3. Unique nonce: Each encryption uses a new random nonce
// 4. No key reuse: GCM mode is safe for multiple encryptions with same key

// EncryptToken encrypts a plaintext token using AES-256-GCM
//
// The encrypted output format is: nonce + ciphertext + auth_tag
// Total length: 12 bytes (nonce) + len(plaintext) + 16 bytes (tag)
//
// Parameters:
//   - plaintext: The token to encrypt (e.g., OAuth access token)
//   - keyHex: The encryption key as a 64-character hex string (32 bytes)
//
// Returns:
//   - Hex-encoded encrypted data (nonce + ciphertext + tag)
//   - Error if encryption fails
func EncryptToken(plaintext string, keyHex string) (string, error) {
	// Validate inputs
	if plaintext == "" {
		return "", errors.New("plaintext cannot be empty")
	}
	if len(keyHex) != 64 {
		return "", errors.New("encryption key must be 64 hex characters (32 bytes)")
	}

	// Decode hex key to bytes
	key, err := hex.DecodeString(keyHex)
	if err != nil {
		return "", errors.New("invalid encryption key: must be valid hexadecimal")
	}

	// Create AES cipher
	block, err := aes.NewCipher(key)
	if err != nil {
		return "", err
	}

	// Create GCM mode
	gcm, err := cipher.NewGCM(block)
	if err != nil {
		return "", err
	}

	// Generate random nonce (12 bytes for GCM)
	nonce := make([]byte, gcm.NonceSize())
	if _, err := io.ReadFull(rand.Reader, nonce); err != nil {
		return "", errors.New("failed to generate nonce")
	}

	// Encrypt and authenticate
	// GCM appends the authentication tag to the ciphertext
	ciphertext := gcm.Seal(nonce, nonce, []byte(plaintext), nil)

	// Encode to hex for storage
	return hex.EncodeToString(ciphertext), nil
}

// DecryptToken decrypts a token that was encrypted with EncryptToken
//
// Parameters:
//   - ciphertextHex: Hex-encoded encrypted data (nonce + ciphertext + tag)
//   - keyHex: The encryption key as a 64-character hex string (32 bytes)
//
// Returns:
//   - Decrypted plaintext token
//   - Error if decryption or authentication fails
func DecryptToken(ciphertextHex string, keyHex string) (string, error) {
	// Validate inputs
	if ciphertextHex == "" {
		return "", errors.New("ciphertext cannot be empty")
	}
	if len(keyHex) != 64 {
		return "", errors.New("encryption key must be 64 hex characters (32 bytes)")
	}

	// Decode hex key to bytes
	key, err := hex.DecodeString(keyHex)
	if err != nil {
		return "", errors.New("invalid encryption key: must be valid hexadecimal")
	}

	// Decode hex ciphertext to bytes
	ciphertext, err := hex.DecodeString(ciphertextHex)
	if err != nil {
		return "", errors.New("invalid ciphertext: must be valid hexadecimal")
	}

	// Create AES cipher
	block, err := aes.NewCipher(key)
	if err != nil {
		return "", err
	}

	// Create GCM mode
	gcm, err := cipher.NewGCM(block)
	if err != nil {
		return "", err
	}

	// Verify ciphertext is long enough for nonce + tag
	nonceSize := gcm.NonceSize()
	if len(ciphertext) < nonceSize {
		return "", errors.New("ciphertext too short")
	}

	// Extract nonce and ciphertext
	nonce := ciphertext[:nonceSize]
	ciphertextData := ciphertext[nonceSize:]

	// Decrypt and verify authentication tag
	plaintext, err := gcm.Open(nil, nonce, ciphertextData, nil)
	if err != nil {
		return "", errors.New("decryption failed: invalid ciphertext or authentication tag")
	}

	return string(plaintext), nil
}

// GenerateEncryptionKey generates a new random 256-bit (32-byte) encryption key
// Returns a 64-character hex string suitable for use as OAUTH_ENCRYPTION_KEY
//
// This function is provided for convenience when generating new keys.
// In production, keys should be generated using:
//
//	openssl rand -hex 32
func GenerateEncryptionKey() (string, error) {
	// Generate 32 random bytes
	key := make([]byte, 32)
	if _, err := rand.Read(key); err != nil {
		return "", errors.New("failed to generate random key")
	}

	// Encode to hex
	return hex.EncodeToString(key), nil
}
