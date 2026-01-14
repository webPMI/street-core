package media

import (
	"context"
	"fmt"
	"image"
	_ "image/gif"
	_ "image/jpeg"
	_ "image/png"
	"os"
	"path/filepath"

	"github.com/disintegration/imaging"

	"backend/config"
	"backend/models"
	"backend/utils"
)

type mediaProcessor struct{}

// NewMediaProcessor creates a new media processor instance
func NewMediaProcessor() IMediaProcessor {
	return &mediaProcessor{}
}

// ProcessImage processes an image (get dimensions, create thumbnail)
func (p *mediaProcessor) ProcessImage(ctx context.Context, media *models.MediaFile) error {
	// Get image dimensions
	width, height, err := p.GetImageDimensions(media.FilePath)
	if err != nil {
		utils.Warn("Failed to get image dimensions", map[string]interface{}{
			"file_id": media.ID.Hex(),
			"path":    media.FilePath,
			"error":   err.Error(),
		})
	} else {
		media.Width = width
		media.Height = height
		media.AspectRatio = calculateAspectRatio(width, height)
	}

	// Create thumbnail for images (not avatars, they're already small)
	if media.FileType == models.MediaFileTypeImage {
		thumbnailPath := p.getThumbnailPath(media.FilePath)
		err := p.CreateThumbnail(media.FilePath, thumbnailPath, config.Media.ThumbnailWidth, config.Media.ThumbnailHeight)
		if err != nil {
			utils.Warn("Failed to create thumbnail", map[string]interface{}{
				"file_id": media.ID.Hex(),
				"error":   err.Error(),
			})
		} else {
			// Generate thumbnail URL
			thumbnailName := filepath.Base(thumbnailPath)
			media.ThumbnailURL = fmt.Sprintf("/uploads/thumbnails/%s", thumbnailName)
		}
	}

	media.MarkAsReady()
	return nil
}

// ProcessVideo processes a video (placeholder for future ffmpeg integration)
func (p *mediaProcessor) ProcessVideo(ctx context.Context, media *models.MediaFile) error {
	// For now, just mark as ready
	// Future: Use ffmpeg to:
	// 1. Extract thumbnail at 1 second
	// 2. Get duration
	// 3. Validate codec/format

	utils.Info("Video processing placeholder", map[string]interface{}{
		"file_id": media.ID.Hex(),
		"path":    media.FilePath,
	})

	// Placeholder values
	media.Duration = 0
	media.Width = 0
	media.Height = 0

	media.MarkAsReady()
	return nil
}

// CreateThumbnail creates a high-quality thumbnail for an image using the imaging library
func (p *mediaProcessor) CreateThumbnail(sourcePath, destPath string, maxWidth, maxHeight int) error {
	// Open and decode the source image
	srcImage, err := imaging.Open(sourcePath)
	if err != nil {
		return fmt.Errorf("failed to open source image: %w", err)
	}

	// Resize using Lanczos resampling (high quality)
	// Fit resizes the image to fit within the specified dimensions while preserving aspect ratio
	thumbnail := imaging.Fit(srcImage, maxWidth, maxHeight, imaging.Lanczos)

	// Ensure destination directory exists
	destDir := filepath.Dir(destPath)
	if err := os.MkdirAll(destDir, 0755); err != nil {
		return fmt.Errorf("failed to create thumbnail directory: %w", err)
	}

	// Save the thumbnail with quality settings
	// imaging.Save automatically detects format from extension
	err = imaging.Save(thumbnail, destPath, imaging.JPEGQuality(85))
	if err != nil {
		return fmt.Errorf("failed to save thumbnail: %w", err)
	}

	return nil
}

// ResizeImage resizes an image to specified dimensions with high quality
func (p *mediaProcessor) ResizeImage(sourcePath, destPath string, maxWidth, maxHeight int) error {
	srcImage, err := imaging.Open(sourcePath)
	if err != nil {
		return fmt.Errorf("failed to open source image: %w", err)
	}

	// Use Fit to maintain aspect ratio
	resized := imaging.Fit(srcImage, maxWidth, maxHeight, imaging.Lanczos)

	// Ensure destination directory exists
	destDir := filepath.Dir(destPath)
	if err := os.MkdirAll(destDir, 0755); err != nil {
		return fmt.Errorf("failed to create destination directory: %w", err)
	}

	err = imaging.Save(resized, destPath, imaging.JPEGQuality(90))
	if err != nil {
		return fmt.Errorf("failed to save resized image: %w", err)
	}

	return nil
}

// GetImageDimensions returns the width and height of an image
func (p *mediaProcessor) GetImageDimensions(filePath string) (width, height int, err error) {
	file, err := os.Open(filePath)
	if err != nil {
		return 0, 0, fmt.Errorf("failed to open file: %w", err)
	}
	defer file.Close()

	imgConfig, _, err := image.DecodeConfig(file)
	if err != nil {
		return 0, 0, fmt.Errorf("failed to decode image config: %w", err)
	}

	return imgConfig.Width, imgConfig.Height, nil
}

// GetVideoDuration returns the duration of a video in seconds
// Placeholder - requires ffmpeg for actual implementation
func (p *mediaProcessor) GetVideoDuration(filePath string) (int, error) {
	// TODO: Implement using ffprobe/ffmpeg
	// Example command: ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 video.mp4
	return 0, nil
}

// ExtractVideoThumbnail extracts a thumbnail from a video
// Placeholder - requires ffmpeg for actual implementation
func (p *mediaProcessor) ExtractVideoThumbnail(videoPath, thumbnailPath string) error {
	// TODO: Implement using ffmpeg
	// Example command: ffmpeg -i video.mp4 -ss 00:00:01 -vframes 1 thumbnail.jpg
	return nil
}

// getThumbnailPath generates the thumbnail path for a source image
func (p *mediaProcessor) getThumbnailPath(sourcePath string) string {
	filename := filepath.Base(sourcePath)
	ext := filepath.Ext(filename)
	name := filename[:len(filename)-len(ext)]
	thumbnailName := fmt.Sprintf("%s_thumb.jpg", name) // Always save as JPEG for consistency
	return filepath.Join(config.Media.ThumbnailDir, thumbnailName)
}

// calculateAspectRatio returns the aspect ratio as a string (e.g., "16:9")
func calculateAspectRatio(width, height int) string {
	if width == 0 || height == 0 {
		return ""
	}

	gcd := gcdFunc(width, height)
	return fmt.Sprintf("%d:%d", width/gcd, height/gcd)
}

// gcdFunc calculates the greatest common divisor
func gcdFunc(a, b int) int {
	for b != 0 {
		a, b = b, a%b
	}
	return a
}
