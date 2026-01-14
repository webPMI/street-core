package media

import (
	"crypto/sha256"
	"encoding/hex"
	"fmt"
	"image"
	"image/gif"
	"image/jpeg"
	"image/png"
	_ "image/gif"
	_ "image/jpeg"
	_ "image/png"
	"io"
	"mime/multipart"
	"net/http"
	"os"
	"path/filepath"
	"strings"
	"time"

	"backend/config"
	"backend/models"
	"backend/utils"

	"github.com/disintegration/imaging"
	"github.com/google/uuid"
	"github.com/h2non/filetype"
)

// FileUploadResult represents the result of a file upload
type FileUploadResult struct {
	FileName     string
	FilePath     string
	PublicURL    string
	FileSize     int64
	MimeType     string
	Hash         string
	Width        int
	Height       int
	Duration     int
	ThumbnailURL string
}

// ValidateFileUpload validates uploaded file against security rules
func ValidateFileUpload(fileHeader *multipart.FileHeader, fileType models.MediaFileType) error {
	// Check file size
	maxSize := config.Media.GetMaxSizeForType(string(fileType))
	if fileHeader.Size > maxSize {
		return fmt.Errorf("file size %d exceeds maximum %d bytes", fileHeader.Size, maxSize)
	}

	// Open file for validation
	file, err := fileHeader.Open()
	if err != nil {
		return fmt.Errorf("failed to open file: %w", err)
	}
	defer file.Close()

	// SECURITY FIX: Increase buffer size for better detection
	buffer := make([]byte, 8192)
	n, err := file.Read(buffer)
	if err != nil && err != io.EOF {
		return fmt.Errorf("failed to read file: %w", err)
	}
	buffer = buffer[:n]

	// Reset file pointer
	file.Seek(0, 0)

	// SECURITY FIX: Explicit SVG/XML rejection for images
	if fileType == models.MediaFileTypeImage || fileType == models.MediaFileTypeAvatar || fileType == models.MediaFileTypeThumbnail {
		if err := rejectSVGAndXML(buffer, fileHeader.Filename); err != nil {
			return err
		}
	}

	// SECURITY FIX: Use filetype library for robust magic byte detection
	kind, err := filetype.Match(buffer)
	if err != nil || kind == filetype.Unknown {
		// Fallback to http.DetectContentType if filetype fails
		mimeType := http.DetectContentType(buffer)
		return validateMimeType(mimeType, fileType, fileHeader.Filename)
	}

	mimeType := kind.MIME.Value

	// Validate MIME type
	if err := validateMimeType(mimeType, fileType, fileHeader.Filename); err != nil {
		return err
	}

	// SECURITY FIX: For images, fully decode to ensure validity
	if fileType == models.MediaFileTypeImage || fileType == models.MediaFileTypeAvatar || fileType == models.MediaFileTypeThumbnail {
		file.Seek(0, 0)
		if err := validateImageByDecoding(file); err != nil {
			return err
		}

		// Validate image dimensions
		file.Seek(0, 0)
		if err := ValidateImageDimensions(file); err != nil {
			return err
		}
	}

	return nil
}

// rejectSVGAndXML detects and rejects SVG/XML files
func rejectSVGAndXML(buffer []byte, filename string) error {
	bufferStr := strings.ToLower(string(buffer))

	// Check for SVG/XML signatures in content
	svgSignatures := []string{
		"<svg",
		"<?xml",
		"<!doctype svg",
		"<svg:",
		"xmlns=\"http://www.w3.org/2000/svg\"",
	}

	for _, sig := range svgSignatures {
		if strings.Contains(bufferStr, sig) {
			return fmt.Errorf("SVG/XML content detected in file")
		}
	}

	// Check file extension
	ext := strings.ToLower(filepath.Ext(filename))
	if ext == ".svg" || ext == ".xml" {
		return fmt.Errorf("file extension %s not allowed", ext)
	}

	return nil
}

// validateMimeType validates MIME type against whitelist
func validateMimeType(mimeType string, fileType models.MediaFileType, filename string) error {
	// Reject SVG/XML MIME types
	rejectedMimeTypes := []string{
		"image/svg+xml",
		"text/xml",
		"application/xml",
		"application/svg+xml",
	}

	for _, rejected := range rejectedMimeTypes {
		if mimeType == rejected {
			return fmt.Errorf("MIME type %s not allowed", mimeType)
		}
	}

	// Validate against allowed types
	if fileType == models.MediaFileTypeImage || fileType == models.MediaFileTypeAvatar || fileType == models.MediaFileTypeThumbnail {
		if !config.Media.IsAllowedImageType(mimeType) {
			return fmt.Errorf("invalid image type: %s (allowed: %v)", mimeType, config.Media.AllowedImageTypes)
		}
	} else if fileType == models.MediaFileTypeVideo {
		if !config.Media.IsAllowedVideoType(mimeType) {
			return fmt.Errorf("invalid video type: %s (allowed: %v)", mimeType, config.Media.AllowedVideoTypes)
		}
	}

	// Verify extension matches MIME type
	ext := strings.ToLower(filepath.Ext(filename))
	if !isExtensionMatchesMimeType(ext, mimeType) {
		return fmt.Errorf("extension %s does not match MIME type %s", ext, mimeType)
	}

	return nil
}

// validateImageByDecoding fully decodes image to ensure it's valid
func validateImageByDecoding(file multipart.File) error {
	// Try to fully decode the image
	_, format, err := image.Decode(file)
	if err != nil {
		return fmt.Errorf("corrupted or invalid image data: %w", err)
	}

	// Ensure format is allowed
	allowedFormats := []string{"jpeg", "png", "gif", "webp"}
	formatAllowed := false
	for _, allowed := range allowedFormats {
		if format == allowed {
			formatAllowed = true
			break
		}
	}

	if !formatAllowed {
		return fmt.Errorf("image format %s not allowed", format)
	}

	return nil
}

// ValidateImageDimensions validates image dimensions
func ValidateImageDimensions(file multipart.File) error {
	// Decode image to get dimensions
	img, _, err := image.DecodeConfig(file)
	if err != nil {
		return fmt.Errorf("failed to decode image: %v", err)
	}

	// Check minimum dimensions (50x50)
	if img.Width < 50 || img.Height < 50 {
		return fmt.Errorf("image dimensions too small: %dx%d (min 50x50)", img.Width, img.Height)
	}

	// Note: We no longer reject large images, they will be auto-resized
	return nil
}

// needsResize checks if an image needs to be resized
func needsResize(filePath string, maxWidth, maxHeight int) (bool, int, int, error) {
	file, err := os.Open(filePath)
	if err != nil {
		return false, 0, 0, err
	}
	defer file.Close()

	img, _, err := image.DecodeConfig(file)
	if err != nil {
		return false, 0, 0, err
	}

	if img.Width > maxWidth || img.Height > maxHeight {
		return true, img.Width, img.Height, nil
	}

	return false, img.Width, img.Height, nil
}

// resizeImageInPlace resizes an image and saves it to the same file
func resizeImageInPlace(filePath string, maxWidth, maxHeight int) error {
	// Open and decode the image
	srcImage, err := imaging.Open(filePath)
	if err != nil {
		return fmt.Errorf("failed to open image: %w", err)
	}

	// Resize maintaining aspect ratio
	resized := imaging.Fit(srcImage, maxWidth, maxHeight, imaging.Lanczos)

	// Save back to the same file with high quality
	err = imaging.Save(resized, filePath, imaging.JPEGQuality(90))
	if err != nil {
		return fmt.Errorf("failed to save resized image: %w", err)
	}

	return nil
}

// stripImageMetadata re-encodes image to remove EXIF and other metadata
func stripImageMetadata(filePath string) error {
	// Open original file
	file, err := os.Open(filePath)
	if err != nil {
		return fmt.Errorf("failed to open image: %w", err)
	}
	defer file.Close()

	// Decode image
	img, format, err := image.Decode(file)
	if err != nil {
		return fmt.Errorf("failed to decode image: %w", err)
	}
	file.Close()

	// Create temporary file
	tempPath := filePath + ".tmp"
	tempFile, err := os.Create(tempPath)
	if err != nil {
		return fmt.Errorf("failed to create temp file: %w", err)
	}
	defer tempFile.Close()

	// Re-encode without metadata
	switch format {
	case "jpeg":
		err = jpeg.Encode(tempFile, img, &jpeg.Options{Quality: 90})
	case "png":
		err = png.Encode(tempFile, img)
	case "gif":
		err = gif.Encode(tempFile, img, nil)
	default:
		return fmt.Errorf("unsupported image format for metadata stripping: %s", format)
	}

	if err != nil {
		os.Remove(tempPath)
		return fmt.Errorf("failed to re-encode image: %w", err)
	}

	tempFile.Close()

	// Replace original file with stripped version
	if err := os.Remove(filePath); err != nil {
		os.Remove(tempPath)
		return fmt.Errorf("failed to remove original file: %w", err)
	}

	if err := os.Rename(tempPath, filePath); err != nil {
		return fmt.Errorf("failed to rename temp file: %w", err)
	}

	return nil
}

// SaveUploadedFile saves the uploaded file to disk with security measures (backward compatible)
func SaveUploadedFile(fileHeader *multipart.FileHeader, fileType models.MediaFileType, userID string) (*FileUploadResult, error) {
	return SaveUploadedFileWithContext(fileHeader, fileType, userID, config.MediaContextGeneral)
}

// SaveUploadedFileWithContext saves the uploaded file to disk with context-based organization
// Structure: uploads/{context}/{type}/{filename}
// Example: uploads/competitions/images/user123_uuid.jpg
func SaveUploadedFileWithContext(fileHeader *multipart.FileHeader, fileType models.MediaFileType, userID string, mediaCtx config.MediaContext) (*FileUploadResult, error) {
	// Validate file first
	if err := ValidateFileUpload(fileHeader, fileType); err != nil {
		return nil, err
	}

	// Open source file
	src, err := fileHeader.Open()
	if err != nil {
		return nil, fmt.Errorf("failed to open uploaded file: %v", err)
	}
	defer src.Close()

	// Generate unique filename
	ext := filepath.Ext(fileHeader.Filename)
	uniqueFileName := fmt.Sprintf("%s_%s%s", userID, uuid.New().String(), ext)

	// Build destination directory: uploads/{context}/{type}/
	destDir := buildContextPath(mediaCtx, fileType)

	// Ensure directory exists
	if err := os.MkdirAll(destDir, 0755); err != nil {
		return nil, fmt.Errorf("failed to create directory: %v", err)
	}

	// Create full file path
	filePath := filepath.Join(destDir, uniqueFileName)

	// Create destination file
	dst, err := os.Create(filePath)
	if err != nil {
		return nil, fmt.Errorf("failed to create destination file: %v", err)
	}
	defer dst.Close()

	// Calculate hash while copying
	hash := sha256.New()
	multiWriter := io.MultiWriter(dst, hash)

	// Copy file content
	written, err := io.Copy(multiWriter, src)
	if err != nil {
		os.Remove(filePath) // Clean up on error
		return nil, fmt.Errorf("failed to save file: %v", err)
	}

	// SECURITY FIX: Strip EXIF metadata from images
	if fileType == models.MediaFileTypeImage || fileType == models.MediaFileTypeAvatar || fileType == models.MediaFileTypeThumbnail {
		if err := stripImageMetadata(filePath); err != nil {
			utils.Warn("Failed to strip image metadata", map[string]interface{}{
				"file":  uniqueFileName,
				"error": err.Error(),
			})
			// Continue processing even if metadata stripping fails
		} else {
			// Update file size after metadata stripping
			fileInfo, err := os.Stat(filePath)
			if err == nil {
				written = fileInfo.Size()
			}
		}
	}

	// Generate hash
	hashString := hex.EncodeToString(hash.Sum(nil))

	// Detect MIME type
	src.Seek(0, 0)
	buffer := make([]byte, 512)
	src.Read(buffer)
	mimeType := http.DetectContentType(buffer)

	// Generate public URL with context
	publicURL := getPublicURL(fileType, mediaCtx, uniqueFileName)

	// Auto-resize large images (max 4096x4096 for web optimization)
	if fileType == models.MediaFileTypeImage || fileType == models.MediaFileTypeThumbnail {
		needs, origWidth, origHeight, err := needsResize(filePath, 4096, 4096)
		if err == nil && needs {
			utils.Info("Auto-resizing large image", map[string]interface{}{
				"original_size": fmt.Sprintf("%dx%d", origWidth, origHeight),
				"max_size":      "4096x4096",
				"file":          uniqueFileName,
			})

			if err := resizeImageInPlace(filePath, 4096, 4096); err != nil {
				utils.Warn("Failed to auto-resize image", map[string]interface{}{
					"file":  uniqueFileName,
					"error": err.Error(),
				})
			} else {
				// Update file size after resize
				fileInfo, err := os.Stat(filePath)
				if err == nil {
					written = fileInfo.Size()
				}
			}
		}
	}

	result := &FileUploadResult{
		FileName:  uniqueFileName,
		FilePath:  filePath,
		PublicURL: publicURL,
		FileSize:  written,
		MimeType:  mimeType,
		Hash:      hashString,
	}

	return result, nil
}

// DeleteFile deletes a file from the filesystem with enhanced security
func DeleteFile(filePath string) error {
	if filePath == "" {
		return nil
	}

	// SECURITY FIX 1: Clean path before validation
	filePath = filepath.Clean(filePath)

	// Get absolute paths for comparison
	absPath, err := filepath.Abs(filePath)
	if err != nil {
		return fmt.Errorf("failed to resolve absolute path: %w", err)
	}

	uploadsDir, err := filepath.Abs(config.Media.UploadDir)
	if err != nil {
		return fmt.Errorf("failed to resolve uploads directory: %w", err)
	}

	// SECURITY FIX 2: Use filepath.Rel for robust path traversal detection
	relPath, err := filepath.Rel(uploadsDir, absPath)
	if err != nil {
		return fmt.Errorf("path traversal attempt: %w", err)
	}

	// Check if relative path escapes uploads directory
	if strings.HasPrefix(relPath, "..") || strings.Contains(relPath, string(filepath.Separator)+"..") {
		return fmt.Errorf("path attempts to escape uploads directory: %s", relPath)
	}

	// SECURITY FIX 3: Check for symlinks
	fileInfo, err := os.Lstat(absPath)
	if err != nil {
		if os.IsNotExist(err) {
			return nil // File doesn't exist, consider it deleted
		}
		return fmt.Errorf("failed to stat file: %w", err)
	}

	// Reject symlinks
	if fileInfo.Mode()&os.ModeSymlink != 0 {
		return fmt.Errorf("symlink detected - not allowed: %s", absPath)
	}

	// Additional check: Ensure final path is still within uploads directory
	if !strings.HasPrefix(absPath, uploadsDir) {
		return fmt.Errorf("file path outside uploads directory: %s", absPath)
	}

	// Delete file
	if err := os.Remove(absPath); err != nil {
		if os.IsNotExist(err) {
			return nil
		}
		return fmt.Errorf("failed to delete file: %w", err)
	}

	return nil
}

// CleanupTempFiles removes temporary files older than 24 hours
func CleanupTempFiles() error {
	tempDir := config.Media.TempDir

	entries, err := os.ReadDir(tempDir)
	if err != nil {
		return err
	}

	now := time.Now()
	for _, entry := range entries {
		if entry.IsDir() {
			continue
		}

		info, err := entry.Info()
		if err != nil {
			continue
		}

		// Delete files older than 24 hours
		if now.Sub(info.ModTime()) > 24*time.Hour {
			filePath := filepath.Join(tempDir, entry.Name())
			os.Remove(filePath)
		}
	}

	return nil
}

// isExtensionMatchesMimeType validates that file extension matches MIME type
func isExtensionMatchesMimeType(ext, mimeType string) bool {
	validCombinations := map[string][]string{
		".jpg":  {"image/jpeg"},
		".jpeg": {"image/jpeg"},
		".png":  {"image/png"},
		".gif":  {"image/gif"},
		".webp": {"image/webp"},
		".mp4":  {"video/mp4"},
		".mov":  {"video/quicktime"},
		".webm": {"video/webm"},
		".avi":  {"video/x-msvideo"},
		".mpeg": {"video/mpeg"},
	}

	allowedMimeTypes, exists := validCombinations[ext]
	if !exists {
		return false
	}

	for _, allowed := range allowedMimeTypes {
		if mimeType == allowed {
			return true
		}
	}

	return false
}

// getUploadPath returns the subdirectory name for a file type
func getUploadPath(fileType models.MediaFileType) string {
	switch fileType {
	case models.MediaFileTypeImage:
		return "images"
	case models.MediaFileTypeVideo:
		return "videos"
	case models.MediaFileTypeAvatar:
		return "avatars"
	case models.MediaFileTypeThumbnail:
		return "thumbnails"
	default:
		return "temp"
	}
}

// buildContextPath creates the full directory path: uploads/{context}/{type}/
func buildContextPath(mediaCtx config.MediaContext, fileType models.MediaFileType) string {
	typePath := getUploadPath(fileType)

	// For general context, use legacy flat structure for backward compatibility
	if mediaCtx == "" || mediaCtx == config.MediaContextGeneral {
		switch fileType {
		case models.MediaFileTypeImage:
			return config.Media.ImageDir
		case models.MediaFileTypeVideo:
			return config.Media.VideoDir
		case models.MediaFileTypeAvatar:
			return config.Media.AvatarDir
		case models.MediaFileTypeThumbnail:
			return config.Media.ThumbnailDir
		default:
			return config.Media.TempDir
		}
	}

	// Context-based structure: uploads/{context}/{type}/
	return filepath.Join(config.Media.UploadDir, string(mediaCtx), typePath)
}

// getPublicURL generates the public URL for a file with context support
// Structure: /uploads/{context}/{type}/{filename}
func getPublicURL(fileType models.MediaFileType, mediaCtx config.MediaContext, fileName string) string {
	typePath := getUploadPath(fileType)

	// For general context, use legacy flat structure
	if mediaCtx == "" || mediaCtx == config.MediaContextGeneral {
		return fmt.Sprintf("/uploads/%s/%s", typePath, fileName)
	}

	// Context-based URL: /uploads/{context}/{type}/{filename}
	return fmt.Sprintf("/uploads/%s/%s/%s", string(mediaCtx), typePath, fileName)
}
