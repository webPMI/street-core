# Media Module - Developer Guide

**Location**: `backend/features/media/`
**Version**: 2.0 (with architectural improvements)
**Last Updated**: 2026-01-05

---

## Overview

The media module handles file uploads, storage, processing, and management for the StreetCore platform. It supports images, videos, avatars, and thumbnails with advanced features like deduplication, async processing, and transactional operations.

---

## Architecture

```
media/
├── handler.go          # HTTP handlers
├── service.go          # Business logic + worker pool
├── repository.go       # Database operations + bulk queries
├── processor.go        # Image/video processing
├── interfaces.go       # Interface definitions
├── module.go          # Module initialization + background jobs
└── routes.go          # Route definitions
```

**Pattern**: Handler → Service → Repository → MongoDB

---

## Key Features

### 1. File Deduplication (SHA256-based)
Duplicate files are automatically detected and share the same physical file using reference counting.

```go
// Upload file
media, err := service.UploadFile(ctx, fileHeader, models.MediaFileTypeImage, userID)

// If file exists with same hash:
// - Physical file is NOT stored again
// - RefCount is incremented
// - Existing media record is returned
```

### 2. Asynchronous Processing
File processing (thumbnails, dimensions, etc.) happens asynchronously using a worker pool.

```go
// Uploads return immediately (non-blocking)
media, err := service.UploadFile(...)

// Check processing status
if media.Status == models.MediaFileStatusReady {
    // File is ready to use
}
```

**Worker Pool Configuration**:
```env
MEDIA_PROCESSING_WORKERS=10      # Number of concurrent workers
MEDIA_PROCESSING_TIMEOUT=5m      # Timeout per file
```

### 3. Transactional Batch Operations
Multiple files can be associated with a post atomically (all-or-nothing).

```go
// Associate multiple media files with a post (uses MongoDB transactions)
err := service.AssociateWithPost(ctx, []string{mediaID1, mediaID2}, postID)
// Either all succeed or all rollback
```

### 4. Bulk Queries
Fetch multiple files efficiently in a single query.

```go
// BEFORE (N+1 problem):
for _, id := range mediaIDs {
    media, _ := service.GetFile(ctx, id) // N queries
}

// AFTER (bulk query):
mediaFiles, err := service.GetFilesByIDs(ctx, mediaIDs) // 1 query
```

### 5. Retry Logic
Transient failures are automatically retried with exponential backoff.

```env
MEDIA_MAX_RETRIES=3  # Retry up to 3 times
# Backoff: 1s → 5s → 15s
```

### 6. Orphaned File Cleanup
Files not associated with any content are automatically deleted after 24 hours.

```go
// Runs every hour automatically
err := service.CleanupOrphanedFiles(ctx)
```

---

## API Usage Examples

### Upload a Single File

```go
import (
    "backend/features/media"
    "backend/models"
)

// In your handler
func UploadAvatar(c *gin.Context) {
    file, _ := c.FormFile("avatar")
    userID := c.GetString("user_id")

    mediaFile, err := mediaService.UploadFile(
        c.Request.Context(),
        file,
        models.MediaFileTypeAvatar,
        userID,
    )

    if err != nil {
        c.JSON(500, gin.H{"error": err.Error()})
        return
    }

    c.JSON(200, gin.H{"media": mediaFile})
}
```

### Upload Multiple Files (Carousel)

```go
func UploadCarousel(c *gin.Context) {
    form, _ := c.MultipartForm()
    files := form.File["images"]
    userID := c.GetString("user_id")

    mediaFiles, err := mediaService.UploadMultipleFiles(
        c.Request.Context(),
        files,
        models.MediaFileTypeImage,
        userID,
    )

    if err != nil {
        c.JSON(500, gin.H{"error": err.Error()})
        return
    }

    c.JSON(200, gin.H{"media": mediaFiles})
}
```

### Associate Media with Post (Transactional)

```go
func CreatePost(c *gin.Context) {
    var req struct {
        Content  string   `json:"content"`
        MediaIDs []string `json:"media_ids"`
    }
    c.BindJSON(&req)

    // Create post first...
    post, _ := postService.Create(...)

    // Associate media atomically (uses MongoDB transaction)
    err := mediaService.AssociateWithPost(
        c.Request.Context(),
        req.MediaIDs,
        post.ID.Hex(),
    )

    if err != nil {
        // Transaction failed - rollback or handle error
        return c.JSON(500, gin.H{"error": "Failed to associate media"})
    }

    c.JSON(200, gin.H{"post": post})
}
```

### Fetch Media for a Post (Bulk Query)

```go
func GetPost(c *gin.Context) {
    postID := c.Param("id")

    // Get post...
    post, _ := postService.GetByID(...)

    // Fetch all media in one query (no N+1)
    media, err := mediaService.GetPostMedia(c.Request.Context(), postID)

    c.JSON(200, gin.H{
        "post":  post,
        "media": media,
    })
}
```

### Delete Media (with RefCount)

```go
func DeleteMedia(c *gin.Context) {
    mediaID := c.Param("id")
    userID := c.GetString("user_id")

    // Decrements refCount
    // Physical file deleted only if refCount reaches 0
    err := mediaService.DeleteFile(
        c.Request.Context(),
        mediaID,
        userID,
    )

    if err != nil {
        c.JSON(500, gin.H{"error": err.Error()})
        return
    }

    c.JSON(200, gin.H{"message": "Media deleted successfully"})
}
```

---

## Database Schema

```go
type MediaFile struct {
    ID           primitive.ObjectID  `bson:"_id,omitempty" json:"id"`
    UserID       primitive.ObjectID  `bson:"userId" json:"userId"`
    PostID       *primitive.ObjectID `bson:"postId,omitempty" json:"postId,omitempty"`

    // File info
    FileName     string        `bson:"fileName" json:"fileName"`
    OriginalName string        `bson:"originalName" json:"originalName"`
    FileType     MediaFileType `bson:"fileType" json:"fileType"`
    MimeType     string        `bson:"mimeType" json:"mimeType"`
    FileSize     int64         `bson:"fileSize" json:"fileSize"`

    // Storage
    FilePath     string `bson:"filePath" json:"-"`
    PublicURL    string `bson:"publicUrl" json:"publicUrl"`
    ThumbnailURL string `bson:"thumbnailUrl,omitempty" json:"thumbnailUrl,omitempty"`

    // Metadata
    Width       int    `bson:"width,omitempty" json:"width,omitempty"`
    Height      int    `bson:"height,omitempty" json:"height,omitempty"`
    Duration    int    `bson:"duration,omitempty" json:"duration,omitempty"`
    AspectRatio string `bson:"aspectRatio,omitempty" json:"aspectRatio,omitempty"`

    // Processing
    Status          MediaFileStatus `bson:"status" json:"status"`
    ProcessingError string          `bson:"processingError,omitempty" json:"-"`

    // Security & Deduplication
    HashSHA256      string `bson:"hashSha256" json:"-"`
    VirusScanStatus string `bson:"virusScanStatus,omitempty" json:"-"`
    RefCount        int    `bson:"refCount" json:"-"` // NEW: Reference counting

    // Timestamps
    CreatedAt time.Time `bson:"createdAt" json:"createdAt"`
    UpdatedAt time.Time `bson:"updatedAt" json:"updatedAt"`
}
```

### Indexes
```javascript
// MongoDB indexes
db.media_files.createIndex({ "userId": 1 })
db.media_files.createIndex({ "postId": 1 }, { sparse: true })
db.media_files.createIndex({ "hashSha256": 1 }, { sparse: true })
db.media_files.createIndex({ "status": 1 })
db.media_files.createIndex({ "createdAt": -1 })
db.media_files.createIndex({ "userId": 1, "createdAt": -1 })
```

---

## Processing Status Flow

```
PENDING → PROCESSING → READY
    ↓
  FAILED
```

- **PENDING**: File uploaded, awaiting processing
- **PROCESSING**: Currently being processed (thumbnails, dimensions)
- **READY**: Fully processed and ready to use
- **FAILED**: Processing failed (see `processingError` field)

---

## File Type Categories

```go
const (
    MediaFileTypeImage     = "image"     // User-uploaded images
    MediaFileTypeVideo     = "video"     // User-uploaded videos
    MediaFileTypeThumbnail = "thumbnail" // Generated thumbnails
    MediaFileTypeAvatar    = "avatar"    // Profile pictures
)
```

---

## Configuration

```env
# Storage Paths
MEDIA_UPLOAD_DIR=./uploads

# Size Limits
MEDIA_MAX_IMAGE_SIZE=10485760   # 10MB
MEDIA_MAX_VIDEO_SIZE=524288000  # 500MB
MEDIA_MAX_AVATAR_SIZE=5242880   # 5MB

# Processing
MEDIA_PROCESSING_WORKERS=10
MEDIA_PROCESSING_TIMEOUT=5m
MEDIA_MAX_RETRIES=3

# Image Processing
MEDIA_THUMBNAIL_WIDTH=400
MEDIA_THUMBNAIL_HEIGHT=400
MEDIA_AVATAR_WIDTH=200
MEDIA_AVATAR_HEIGHT=200

# Security
MEDIA_ENABLE_VIRUS_SCAN=false
MEDIA_ENABLE_MAGIC_BYTE_CHECK=true
MEDIA_MAX_FILES_PER_UPLOAD=10

# Cloud Storage (Future)
MEDIA_STORAGE_TYPE=filesystem   # or "s3", "hybrid"
MEDIA_S3_BUCKET=
MEDIA_S3_REGION=us-east-1
MEDIA_CDN_DOMAIN=
```

---

## Background Jobs

The media module runs two background jobs:

### 1. Periodic Processing Job
Processes files stuck in PENDING status.

- **Interval**: Adaptive (30s to 5m)
- **Batch Size**: 100 files per run
- **Behavior**: Increases interval when idle, resets when busy

### 2. Orphaned File Cleanup Job
Deletes files not associated with any content after 24 hours.

- **Interval**: Every 1 hour
- **Grace Period**: 24 hours
- **Exclusions**: Avatars are never deleted

---

## Error Handling

### Retry Logic
```go
// Automatically retried (up to 3 times):
- Network errors
- Temporary MongoDB unavailability
- Processing failures

// NOT retried:
- Invalid file format
- File too large
- Permission errors
```

### Timeout Protection
```go
// All repository operations have defensive timeouts:
- Single operations: 5s timeout
- Batch operations: 10s timeout
- Heavy operations: 15s timeout
```

---

## Testing

```bash
# Unit tests
cd backend/features/media
go test -v

# Integration tests
go test -v -tags=integration

# Load test
ab -n 1000 -c 50 -p test.jpg http://localhost:3000/api/media/upload
```

---

## Performance Considerations

### Deduplication
- **Storage Saved**: ~30-50% in typical use cases
- **Hash Calculation**: ~1-5ms for 1MB file
- **Lookup**: O(1) via indexed hashSha256

### Worker Pool
- **Default Workers**: 10 concurrent
- **Queue Depth**: 20 jobs (workers * 2)
- **Throughput**: ~100 files/minute (image processing)

### Bulk Queries
- **GetFilesByIDs**: O(1) vs O(N) traditional approach
- **Typical Speedup**: 10x-100x for batch operations

---

## Common Patterns

### Upload → Process → Associate Pattern
```go
// 1. Upload file (returns immediately)
media, _ := service.UploadFile(ctx, file, fileType, userID)

// 2. Wait for processing (optional)
for media.Status != models.MediaFileStatusReady {
    time.Sleep(100 * time.Millisecond)
    media, _ = service.GetFile(ctx, media.ID.Hex())
}

// 3. Associate with post (transactional)
service.AssociateWithPost(ctx, []string{media.ID.Hex()}, postID)
```

### Carousel Upload Pattern
```go
// 1. Upload all files
mediaFiles, _ := service.UploadMultipleFiles(ctx, files, fileType, userID)

// 2. Extract IDs
mediaIDs := make([]string, len(mediaFiles))
for i, m := range mediaFiles {
    mediaIDs[i] = m.ID.Hex()
}

// 3. Associate all at once (transactional)
service.AssociateWithPost(ctx, mediaIDs, postID)
```

---

## Troubleshooting

### Files Stuck in PENDING
```bash
# Check worker pool status
# Look for logs: "Worker pool initialized"

# Manually trigger processing
curl -X POST http://localhost:3000/api/admin/media/process-pending
```

### Orphaned Files Not Cleaned
```bash
# Check cleanup job logs
# Look for: "Orphaned files cleanup completed"

# Manually trigger cleanup
curl -X POST http://localhost:3000/api/admin/media/cleanup
```

### High Memory Usage
```bash
# Reduce worker pool size
export MEDIA_PROCESSING_WORKERS=5

# Reduce processing timeout
export MEDIA_PROCESSING_TIMEOUT=2m
```

---

## Migration Guide

### From v1.0 to v2.0 (with improvements)

1. **Add RefCount to existing documents** (optional):
```javascript
db.media_files.updateMany(
  { refCount: { $exists: false } },
  { $set: { refCount: 1 } }
)
```

2. **Update configuration**:
```env
# Add new config variables
MEDIA_PROCESSING_WORKERS=10
MEDIA_PROCESSING_TIMEOUT=5m
MEDIA_MAX_RETRIES=3
```

3. **No code changes required** - fully backward compatible!

---

## Links

- [Architecture Improvements](../../../MEDIA_ARCHITECTURE_IMPROVEMENTS.md)
- [Cloud Migration Plan](../../../CLOUD_MIGRATION_IMPLEMENTATION.md)
- [Module Documentation](../../../docs/modules/media/)

---

**Maintained by**: Backend Team
**Questions**: See #backend-media Slack channel
