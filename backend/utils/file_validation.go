package utils

import (
	"bytes"
	"fmt"
	"io"
	"mime/multipart"
	"net/http"
	"path/filepath"
	"strings"
)

// File size limits (in bytes)
const (
	MaxImageSize = 10 * 1024 * 1024  // 10MB
	MaxVideoSize = 500 * 1024 * 1024 // 500MB
	MaxAudioSize = 20 * 1024 * 1024  // 20MB
	MaxDocSize   = 10 * 1024 * 1024  // 10MB
)

// Allowed MIME types
var (
	AllowedImageTypes = map[string]bool{
		"image/jpeg": true,
		"image/jpg":  true,
		"image/png":  true,
		"image/gif":  true,
		"image/webp": true,
	}

	AllowedVideoTypes = map[string]bool{
		"video/mp4":  true,
		"video/webm": true,
		"video/mpeg": true,
	}

	AllowedAudioTypes = map[string]bool{
		"audio/mpeg": true,
		"audio/mp3":  true,
		"audio/wav":  true,
		"audio/ogg":  true,
	}

	AllowedDocTypes = map[string]bool{
		"application/pdf": true,
		"text/plain":      true,
	}

	// Allowed file extensions (backup validation)
	AllowedImageExtensions = map[string]bool{
		".jpg":  true,
		".jpeg": true,
		".png":  true,
		".gif":  true,
		".webp": true,
	}

	AllowedVideoExtensions = map[string]bool{
		".mp4":  true,
		".webm": true,
		".mpeg": true,
	}
)

// ValidationError represents a file validation error
type ValidationError struct {
	Field   string
	Message string
}

func (e *ValidationError) Error() string {
	return fmt.Sprintf("%s: %s", e.Field, e.Message)
}

// ValidateFile validates file size and MIME type
// 🔒 SECURITY HIGH-004: Enhanced MIME validation with malicious pattern detection
//
// Parameters:
//   - file: The uploaded file
//   - allowedTypes: Map of allowed MIME types
//   - maxSize: Maximum file size in bytes
//
// Returns:
//   - error if validation fails
func ValidateFile(file *multipart.FileHeader, allowedTypes map[string]bool, maxSize int64) error {
	// 1. Check file size
	if file.Size > maxSize {
		return &ValidationError{
			Field:   "file_size",
			Message: fmt.Sprintf("File size exceeds limit: %d bytes (max: %d bytes)", file.Size, maxSize),
		}
	}

	// 2. Check file size minimum (prevent empty files)
	if file.Size == 0 {
		return &ValidationError{
			Field:   "file_size",
			Message: "File is empty",
		}
	}

	// 3. Open file to read content
	src, err := file.Open()
	if err != nil {
		return &ValidationError{
			Field:   "file_read",
			Message: fmt.Sprintf("Failed to open file: %v", err),
		}
	}
	defer src.Close()

	// 4. Read more bytes for better detection (1024 instead of 512)
	buffer := make([]byte, 1024)
	n, err := src.Read(buffer)
	if err != nil && err != io.EOF {
		return &ValidationError{
			Field:   "file_read",
			Message: fmt.Sprintf("Failed to read file: %v", err),
		}
	}

	// 5. Detect MIME type from content (more reliable than extension)
	mimeType := http.DetectContentType(buffer[:n])

	// 6. 🔒 SECURITY: Verify extension matches MIME type
	ext := strings.ToLower(filepath.Ext(file.Filename))
	if !extensionMatchesMime(ext, mimeType) {
		return &ValidationError{
			Field:   "file_type",
			Message: fmt.Sprintf("File extension (%s) doesn't match content type (%s)", ext, mimeType),
		}
	}

	// 7. 🔒 SECURITY: Detect malicious patterns (executables disguised as images)
	if DetectMaliciousPatterns(buffer[:n]) {
		return &ValidationError{
			Field:   "file_content",
			Message: "Malicious file content detected",
		}
	}

	// 8. Check if MIME type is allowed
	if !allowedTypes[mimeType] {
		return &ValidationError{
			Field:   "file_type",
			Message: fmt.Sprintf("Invalid file type: %s (detected from content)", mimeType),
		}
	}

	// 9. Additional extension check (defense in depth)
	if ext == "" {
		return &ValidationError{
			Field:   "file_extension",
			Message: "File has no extension",
		}
	}

	return nil
}

// extensionMatchesMime verifies that file extension matches MIME type
// 🔒 SECURITY HIGH-004: Prevents file type confusion attacks
func extensionMatchesMime(ext, mimeType string) bool {
	validPairs := map[string][]string{
		".jpg":  {"image/jpeg"},
		".jpeg": {"image/jpeg"},
		".png":  {"image/png"},
		".gif":  {"image/gif"},
		".webp": {"image/webp"},
		".mp4":  {"video/mp4"},
		".mov":  {"video/quicktime"},
		".avi":  {"video/x-msvideo"},
		".webm": {"video/webm"},
		".mpeg": {"video/mpeg"},
	}

	allowedMimes, exists := validPairs[ext]
	if !exists {
		return false
	}

	for _, allowed := range allowedMimes {
		if mimeType == allowed {
			return true
		}
	}

	return false
}

// DetectMaliciousPatterns scans for executable or script patterns
// 🔒 SECURITY HIGH-004: Detects disguised executables
func DetectMaliciousPatterns(data []byte) bool {
	// Malicious file signatures (executables disguised as media)
	maliciousPatterns := [][]byte{
		[]byte("MZ"),      // Windows PE executable
		[]byte("\x7fELF"), // Linux ELF executable
		[]byte("#!/"),     // Shell script
		[]byte("<?php"),   // PHP code
		[]byte("<script"), // JavaScript in image
		[]byte("eval("),   // Eval injection
	}

	for _, pattern := range maliciousPatterns {
		if bytes.Contains(data, pattern) {
			return true
		}
	}

	return false
}

// ValidateImageFile validates image uploads
func ValidateImageFile(file *multipart.FileHeader) error {
	if err := ValidateFile(file, AllowedImageTypes, MaxImageSize); err != nil {
		return err
	}

	// Additional extension check
	ext := strings.ToLower(filepath.Ext(file.Filename))
	if !AllowedImageExtensions[ext] {
		return &ValidationError{
			Field:   "file_extension",
			Message: fmt.Sprintf("Invalid image file extension: %s", ext),
		}
	}

	return nil
}

// ValidateVideoFile validates video uploads
func ValidateVideoFile(file *multipart.FileHeader) error {
	if err := ValidateFile(file, AllowedVideoTypes, MaxVideoSize); err != nil {
		return err
	}

	// Additional extension check
	ext := strings.ToLower(filepath.Ext(file.Filename))
	if !AllowedVideoExtensions[ext] {
		return &ValidationError{
			Field:   "file_extension",
			Message: fmt.Sprintf("Invalid video file extension: %s", ext),
		}
	}

	return nil
}

// ValidateAudioFile validates audio uploads
func ValidateAudioFile(file *multipart.FileHeader) error {
	return ValidateFile(file, AllowedAudioTypes, MaxAudioSize)
}

// ValidateDocumentFile validates document uploads
func ValidateDocumentFile(file *multipart.FileHeader) error {
	return ValidateFile(file, AllowedDocTypes, MaxDocSize)
}

// SanitizeFilename removes dangerous characters from filenames
func SanitizeFilename(filename string) string {
	// Remove path traversal attempts
	filename = filepath.Base(filename)

	// Replace dangerous characters
	dangerous := []string{
		"..", "/", "\\", ":", "*", "?", "\"", "<", ">", "|",
		"\x00", // Null byte
	}

	for _, char := range dangerous {
		filename = strings.ReplaceAll(filename, char, "_")
	}

	// Limit filename length
	if len(filename) > 255 {
		ext := filepath.Ext(filename)
		name := filename[:255-len(ext)]
		filename = name + ext
	}

	return filename
}

// GetSafeContentType returns a safe content type for file download
func GetSafeContentType(filename string) string {
	ext := strings.ToLower(filepath.Ext(filename))

	contentTypes := map[string]string{
		".jpg":  "image/jpeg",
		".jpeg": "image/jpeg",
		".png":  "image/png",
		".gif":  "image/gif",
		".webp": "image/webp",
		".mp4":  "video/mp4",
		".webm": "video/webm",
		".pdf":  "application/pdf",
		".txt":  "text/plain",
	}

	if ct, ok := contentTypes[ext]; ok {
		return ct
	}

	// Default to octet-stream (force download)
	return "application/octet-stream"
}
