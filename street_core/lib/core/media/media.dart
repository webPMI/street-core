// lib/core/media/media.dart
//
// Media Module - Cross-cutting concern for file uploads
//
// This module provides:
// - MediaUploadService: Upload avatar, images, videos
// - MediaUris: API endpoints for media operations
// - Widgets: FileUploadWidget, ImagePickerWidget, progress dialogs
//
// Usage:
// ```dart
// import 'package:street_core/core/media/media.dart';
//
// // Access service via DI
// final mediaService = getIt<MediaUploadService>();
// final response = await mediaService.uploadAvatar(file);
//
// // Use widgets
// FileUploadWidget(onFilesSelected: handleFiles)
// ImagePickerWidget(onImageSelected: handleImage)
// ```

library;

// URIs
export 'media_uris.dart';

// Models
export 'models/media_response.dart';

// Services
export 'services/media_upload_service.dart';

// Widgets
export 'widgets/media_widgets.dart';

// DI
export 'di/media_injection.dart';
