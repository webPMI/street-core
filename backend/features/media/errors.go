package media

import "errors"

// Security errors
var (
	ErrUnauthorized      = errors.New("unauthorized access")
	ErrPathTraversal     = errors.New("path traversal attempt detected")
	ErrSymlinkDetected   = errors.New("symlink detected - not allowed")
	ErrOutsideUploadsDir = errors.New("file path outside uploads directory")

	// Validation errors
	ErrInvalidInput           = errors.New("invalid input")
	ErrInvalidFileType        = errors.New("invalid file type")
	ErrFileSizeExceeded       = errors.New("file size exceeds maximum")
	ErrInvalidImageDimensions = errors.New("invalid image dimensions")
	ErrExtensionMismatch      = errors.New("file extension does not match content")

	// SVG/XML specific
	ErrSVGNotAllowed = errors.New("SVG files not allowed")
	ErrXMLNotAllowed = errors.New("XML files not allowed")

	// File operations
	ErrNotFound       = errors.New("file not found")
	ErrFileOpenFailed = errors.New("failed to open file")
	ErrFileReadFailed = errors.New("failed to read file")
	ErrFileSaveFailed = errors.New("failed to save file")
)
