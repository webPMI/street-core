// lib/core/media/widgets/media_widgets.dart

/// Optimized media widgets with performance enhancements
///
/// This barrel file exports all media-related widgets:
///
/// **Upload & Progress:**
/// - `AnimatedUploadProgress` - Smooth progress animations
/// - `MediaUploadFeedback` - Enhanced upload feedback dialog
/// - `FloatingUploadFeedback` - Non-intrusive floating feedback
/// - `UploadProgressDialog` - Original progress dialog
///
/// **Image Display & Caching:**
/// - `CachedMediaImage` - Optimized cached network image
/// - `CachedAvatarImage` - Cached circular avatar
/// - `CachedThumbnailImage` - Optimized thumbnails
/// - `ZoomableImagePreview` - Full-screen zoomable preview
///
/// **Galleries & Collections:**
/// - `LazyMediaGallery` - Grid gallery with lazy loading
/// - `LazyMediaCarousel` - Horizontal carousel with lazy loading
///
/// **File Selection:**
/// - `FileUploadWidget` - File picker with validation
/// - `SelectImage` - Image selection widget
///
/// Usage:
/// ```dart
/// import 'package:street_core/core/media/widgets/media_widgets.dart';
///
/// // Cached image with shimmer loading
/// CachedMediaImage(imageUrl: url)
///
/// // Lazy loading gallery
/// LazyMediaGallery(imageUrls: urls)
///
/// // Animated upload progress
/// AnimatedUploadProgress(progress: 0.5)
/// ```
library;

// Upload progress & feedback
export 'animated_upload_progress.dart';
export 'media_upload_feedback.dart';
export 'upload_progress_dialog.dart';

// Image display & caching
export 'cached_media_image.dart';
export 'zoomable_image_preview.dart';

// Galleries & collections
export 'lazy_media_gallery.dart';

// File selection & upload
export 'file_upload_widget.dart';
export 'select_image.dart';
