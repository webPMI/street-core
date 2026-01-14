/// Media Validator
/// Validates media files before upload
/// Provides detailed error messages for better UX

import 'dart:io' show File;
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import '../../helpers/logger.dart';

class MediaValidator {
  // File size limits (in bytes)
  static const int maxAvatarSize = 5 * 1024 * 1024; // 5MB
  static const int maxImageSize = 10 * 1024 * 1024; // 10MB
  static const int maxVideoSize = 500 * 1024 * 1024; // 500MB

  // Image dimension limits
  static const int minImageWidth = 50;
  static const int minImageHeight = 50;
  static const int maxImageWidth = 8192; // 8K
  static const int maxImageHeight = 8192; // 8K

  // Allowed MIME types
  static const List<String> allowedImageTypes = [
    'image/jpeg',
    'image/jpg',
    'image/png',
    'image/gif',
    'image/webp',
  ];

  static const List<String> allowedVideoTypes = [
    'video/mp4',
    'video/mpeg',
    'video/quicktime',
    'video/x-msvideo',
    'video/webm',
  ];

  // File extensions
  static const List<String> allowedImageExtensions = [
    '.jpg',
    '.jpeg',
    '.png',
    '.gif',
    '.webp',
  ];

  static const List<String> allowedVideoExtensions = [
    '.mp4',
    '.mpeg',
    '.mpg',
    '.mov',
    '.avi',
    '.webm',
  ];

  /// Validates an image file for avatar upload
  static MediaValidationResult validateAvatar(File file) {
    // Check file size
    final size = file.lengthSync();
    if (size > maxAvatarSize) {
      return MediaValidationResult.error(
        'media.error.avatar_too_large',
        'Avatar must be less than ${_formatBytes(maxAvatarSize)}',
      );
    }

    // Check minimum size
    if (size < 1024) {
      return MediaValidationResult.error(
        'media.error.file_too_small',
        'File is too small (min 1KB)',
      );
    }

    // Check extension
    final extension = _getFileExtension(file.path).toLowerCase();
    if (!allowedImageExtensions.contains(extension)) {
      return MediaValidationResult.error(
        'media.error.invalid_file_type',
        'Only ${allowedImageExtensions.join(", ")} files are allowed',
      );
    }

    return MediaValidationResult.success();
  }

  /// Validates an image file for general upload
  static MediaValidationResult validateImage(File file) {
    // Check file size
    final size = file.lengthSync();
    if (size > maxImageSize) {
      return MediaValidationResult.error(
        'media.error.image_too_large',
        'Image must be less than ${_formatBytes(maxImageSize)}',
      );
    }

    // Check minimum size
    if (size < 1024) {
      return MediaValidationResult.error(
        'media.error.file_too_small',
        'File is too small (min 1KB)',
      );
    }

    // Check extension
    final extension = _getFileExtension(file.path).toLowerCase();
    if (!allowedImageExtensions.contains(extension)) {
      return MediaValidationResult.error(
        'media.error.invalid_file_type',
        'Only ${allowedImageExtensions.join(", ")} files are allowed',
      );
    }

    return MediaValidationResult.success();
  }

  /// Validates an XFile (cross-platform)
  static Future<MediaValidationResult> validateXFile(
    XFile file, {
    bool isAvatar = false,
    bool isVideo = false,
  }) async {
    // Determine file type and limits
    int maxSize;
    List<String> allowedExtensions;
    List<String> allowedMimeTypes;

    if (isVideo) {
      maxSize = maxVideoSize;
      allowedExtensions = allowedVideoExtensions;
      allowedMimeTypes = allowedVideoTypes;
    } else if (isAvatar) {
      maxSize = maxAvatarSize;
      allowedExtensions = allowedImageExtensions;
      allowedMimeTypes = allowedImageTypes;
    } else {
      maxSize = maxImageSize;
      allowedExtensions = allowedImageExtensions;
      allowedMimeTypes = allowedImageTypes;
    }

    // Check file size
    final size = await file.length();
    if (size > maxSize) {
      return MediaValidationResult.error(
        isVideo ? 'media.error.video_too_large' : (isAvatar ? 'media.error.avatar_too_large' : 'media.error.image_too_large'),
        'File must be less than ${_formatBytes(maxSize)}',
      );
    }

    if (size < 1024) {
      return MediaValidationResult.error(
        'media.error.file_too_small',
        'File is too small (min 1KB)',
      );
    }

    // Check extension (prefer file.name over file.path for better extension detection)
    final rawExtension = _getFileExtension(file.name);
    final extension = rawExtension.toLowerCase();

    // Debug logging
    if (kDebugMode) {
      AppLogger.debug('File name: ${file.name}', tag: 'MediaValidator');
      AppLogger.debug('Raw extension: "$rawExtension"', tag: 'MediaValidator');
      AppLogger.debug('Lowercase extension: "$extension"', tag: 'MediaValidator');
      AppLogger.debug('Allowed extensions: $allowedExtensions', tag: 'MediaValidator');
    }

    if (!allowedExtensions.contains(extension)) {
      return MediaValidationResult.error(
        'media.error.invalid_file_type',
        'Only ${allowedExtensions.join(", ")} files are allowed',
      );
    }

    // Check MIME type if available
    if (file.mimeType != null && !allowedMimeTypes.contains(file.mimeType)) {
      return MediaValidationResult.error(
        'media.error.invalid_mime_type',
        'Invalid file format: ${file.mimeType}',
      );
    }

    return MediaValidationResult.success();
  }

  /// Validates multiple files
  static Future<MediaValidationResult> validateMultipleFiles(
    List<XFile> files, {
    int maxFiles = 10,
  }) async {
    // Check file count
    if (files.isEmpty) {
      return MediaValidationResult.error(
        'media.error.no_files_selected',
        'Please select at least one file',
      );
    }

    if (files.length > maxFiles) {
      return MediaValidationResult.error(
        'media.error.too_many_files',
        'Maximum $maxFiles files allowed',
      );
    }

    // Validate each file
    for (var i = 0; i < files.length; i++) {
      // Auto-detect if file is video based on extension (use file.name for better detection)
      final extension = _getFileExtension(files[i].name).toLowerCase();
      final isVideo = allowedVideoExtensions.contains(extension);

      final result = await validateXFile(files[i], isVideo: isVideo);
      if (!result.isValid) {
        return MediaValidationResult.error(
          result.errorCode ?? 'media.error.validation_failed',
          'File ${i + 1}: ${result.errorMessage}',
        );
      }
    }

    // Check total size
    int totalSize = 0;
    for (final file in files) {
      totalSize += await file.length();
    }

    final maxTotalSize = maxImageSize * maxFiles;
    if (totalSize > maxTotalSize) {
      return MediaValidationResult.error(
        'media.error.total_size_exceeded',
        'Total size must be less than ${_formatBytes(maxTotalSize)}',
      );
    }

    return MediaValidationResult.success();
  }

  /// Validates a video file
  static MediaValidationResult validateVideo(File file) {
    // Check file size
    final size = file.lengthSync();
    if (size > maxVideoSize) {
      return MediaValidationResult.error(
        'media.error.video_too_large',
        'Video must be less than ${_formatBytes(maxVideoSize)}',
      );
    }

    // Check extension
    final extension = _getFileExtension(file.path).toLowerCase();
    if (!allowedVideoExtensions.contains(extension)) {
      return MediaValidationResult.error(
        'media.error.invalid_video_format',
        'Only ${allowedVideoExtensions.join(", ")} files are allowed',
      );
    }

    return MediaValidationResult.success();
  }

  // Helper methods
  static String _getFileExtension(String path) {
    final lastDot = path.lastIndexOf('.');
    if (lastDot == -1) return '';
    return path.substring(lastDot);
  }

  static String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  /// Quick validation helper
  static bool isValidImageExtension(String filename) {
    final extension = _getFileExtension(filename).toLowerCase();
    return allowedImageExtensions.contains(extension);
  }

  static bool isValidVideoExtension(String filename) {
    final extension = _getFileExtension(filename).toLowerCase();
    return allowedVideoExtensions.contains(extension);
  }
}

/// Validation result
class MediaValidationResult {
  final bool isValid;
  final String? errorCode;
  final String? errorMessage;

  const MediaValidationResult._({
    required this.isValid,
    this.errorCode,
    this.errorMessage,
  });

  factory MediaValidationResult.success() {
    return const MediaValidationResult._(isValid: true);
  }

  factory MediaValidationResult.error(String code, String message) {
    return MediaValidationResult._(
      isValid: false,
      errorCode: code,
      errorMessage: message,
    );
  }

  @override
  String toString() {
    if (isValid) return 'Valid';
    return 'Invalid: $errorCode - $errorMessage';
  }
}
