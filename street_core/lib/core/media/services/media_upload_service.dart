import 'dart:io' show File;
import 'dart:math';

import '/core/media/media_uris.dart';
import '/core/media/models/media_response.dart';
import '/core/media/validators/media_validator.dart';
import '/core/helpers/logger.dart';
import '/core/services/api_media_service.dart';
import 'package:flutter/foundation.dart' show Uint8List;
import 'package:image_picker/image_picker.dart';

/// Media Upload Service
/// Handles all media upload operations (avatar, images, videos)
///
/// Uses ApiMediaService for low-level HTTP operations.
class MediaUploadService {
  MediaUploadService(this._mediaService);

  final ApiMediaService _mediaService;

  /// Retry an operation with exponential backoff
  ///
  /// Retries failed operations up to [maxRetries] times with exponential backoff.
  /// Useful for handling transient network errors.
  Future<T> _withRetry<T>(
    Future<T> Function() operation, {
    int maxRetries = 3,
  }) async {
    for (int attempt = 0; attempt < maxRetries; attempt++) {
      try {
        return await operation();
      } catch (e) {
        if (attempt == maxRetries - 1) {
          // Last attempt failed, rethrow
          rethrow;
        }

        // Calculate exponential backoff delay (2^attempt seconds)
        final delaySeconds = pow(2, attempt).toInt();
        AppLogger.info(
          'Retry attempt ${attempt + 1}/$maxRetries after ${delaySeconds}s delay',
          tag: 'MediaUploadService',
        );

        // Wait before retrying
        await Future.delayed(Duration(seconds: delaySeconds));
      }
    }

    // Should never reach here, but for type safety
    throw Exception('Failed after $maxRetries retries');
  }

  /// Upload avatar image
  /// Endpoint: POST /api/v1/media/upload/avatar
  /// Max size: 5MB
  /// Supported formats: jpg, jpeg, png, gif, webp
  /// Includes retry logic for transient failures
  Future<MediaUploadResponse> uploadAvatar(File file) async {
    try {
      // Validate file before upload
      final validation = MediaValidator.validateAvatar(file);
      if (!validation.isValid) {
        throw Exception(validation.errorMessage ?? 'Invalid file');
      }

      AppLogger.info('Uploading avatar', tag: 'MediaUploadService');

      // Use retry logic for upload
      return await _withRetry(() async {
        final response = await _mediaService.uploadFile(
          file: file,
          endpoint: MediaUris.uploadAvatar,
          fieldName: 'file',
        );

        if (response.status == 'success' && response.data != null) {
          return MediaUploadResponse.fromJson(response.data!);
        } else {
          throw Exception(response.message);
        }
      });
    } catch (e, stackTrace) {
      AppLogger.error(
        'Failed to upload avatar (filePath: ${file.path})',
        tag: 'MediaUploadService',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Upload avatar from web (bytes)
  /// Endpoint: POST /api/v1/media/upload/avatar
  Future<MediaUploadResponse> uploadAvatarWeb(
    Uint8List bytes,
    String filename,
  ) async {
    try {
      AppLogger.info('Uploading avatar (web)', tag: 'MediaUploadService');

      final response = await _mediaService.uploadBytes(
        bytes: bytes,
        filename: filename,
        endpoint: MediaUris.uploadAvatar,
        fieldName: 'file',
      );

      if (response.status == 'success' && response.data != null) {
        return MediaUploadResponse.fromJson(response.data!);
      } else {
        throw Exception(response.message);
      }
    } catch (e, stackTrace) {
      AppLogger.error(
        'Failed to upload avatar (web) (filename: $filename, bytesLength: ${bytes.length})',
        tag: 'MediaUploadService',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Upload image
  /// Endpoint: POST /api/v1/media/upload/image
  /// Max size: 10MB
  Future<MediaUploadResponse> uploadImage(File file) async {
    try {
      // Validate file before upload
      final validation = MediaValidator.validateImage(file);
      if (!validation.isValid) {
        throw Exception(validation.errorMessage ?? 'Invalid file');
      }

      AppLogger.info('Uploading image', tag: 'MediaUploadService');

      final response = await _mediaService.uploadFile(
        file: file,
        endpoint: MediaUris.uploadImage,
        fieldName: 'file',
      );

      if (response.status == 'success' && response.data != null) {
        return MediaUploadResponse.fromJson(response.data!);
      } else {
        throw Exception(response.message);
      }
    } catch (e, stackTrace) {
      AppLogger.error(
        'Failed to upload image (filePath: ${file.path})',
        tag: 'MediaUploadService',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Upload image from web (bytes)
  /// Endpoint: POST /api/v1/media/upload/image
  /// Max size: 10MB
  Future<MediaUploadResponse> uploadImageWeb(
    Uint8List bytes,
    String filename,
  ) async {
    try {
      AppLogger.info('Uploading image (web)', tag: 'MediaUploadService');

      final response = await _mediaService.uploadBytes(
        bytes: bytes,
        filename: filename,
        endpoint: MediaUris.uploadImage,
        fieldName: 'file',
      );

      if (response.status == 'success' && response.data != null) {
        return MediaUploadResponse.fromJson(response.data!);
      } else {
        throw Exception(response.message);
      }
    } catch (e, stackTrace) {
      AppLogger.error(
        'Failed to upload image (web) (filename: $filename, bytesLength: ${bytes.length})',
        tag: 'MediaUploadService',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Upload multiple images using File (mobile only)
  /// Endpoint: POST /api/v1/media/upload/multiple
  /// Max 10 files
  Future<List<MediaUploadResponse>> uploadMultiple(List<File> files) async {
    try {
      AppLogger.info(
        'Uploading ${files.length} files',
        tag: 'MediaUploadService',
      );

      if (files.length > 10) {
        throw Exception('Maximum 10 files allowed');
      }

      final response = await _mediaService.uploadMultipleFiles(
        files: files,
        endpoint: MediaUris.uploadMultiple,
        fieldName: 'files',
      );

      if (response.status == 'success' && response.data != null) {
        final dataList = response.data!['files'] as List<dynamic>?;
        if (dataList != null) {
          return dataList
              .map((item) => MediaUploadResponse.fromJson(item))
              .toList();
        }
        // Single file response format
        return [MediaUploadResponse.fromJson(response.data!)];
      } else {
        throw Exception(response.message);
      }
    } catch (e, stackTrace) {
      AppLogger.error(
        'Failed to upload multiple files (fileCount: ${files.length}, filePaths: ${files.map((f) => f.path).toList()})',
        tag: 'MediaUploadService',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Upload multiple images using XFile (cross-platform: web, mobile, desktop)
  /// Endpoint: POST /api/v1/media/upload/multiple
  /// Max 10 files
  Future<List<MediaUploadResponse>> uploadMultipleXFile(
    List<XFile> files,
  ) async {
    try {
      // Validate files before upload
      final validation = await MediaValidator.validateMultipleFiles(files);
      if (!validation.isValid) {
        AppLogger.error(
          'File validation failed',
          error: validation.errorMessage,
          tag: 'MediaUploadService',
        );
        throw Exception(validation.errorMessage ?? 'Invalid files');
      }

      AppLogger.info(
        'Uploading ${files.length} XFiles',
        tag: 'MediaUploadService',
      );

      final response = await _mediaService.uploadMultipleXFiles(
        files: files,
        endpoint: MediaUris.uploadMultiple,
        fieldName: 'files',
      );

      AppLogger.debug(
        'Upload response status: ${response.status}',
        tag: 'MediaUploadService',
      );
      AppLogger.debug(
        'Upload response data: ${response.data}',
        tag: 'MediaUploadService',
      );

      if (response.status == 'success' && response.data != null) {
        // Check for failed uploads
        final failed = response.data!['failed'] as int? ?? 0;
        final errors = response.data!['errors'] as List<dynamic>?;

        if (failed > 0 && errors != null && errors.isNotEmpty) {
          // Extract error messages
          final errorMessages = errors
              .map((e) => '${e['fileName']}: ${e['error']}')
              .join('\n');
          AppLogger.error(
            'Upload failed for $failed files',
            error: errorMessages,
            tag: 'MediaUploadService',
          );
          throw Exception('upload_failed_details\n$errorMessages');
        }

        final dataList = response.data!['files'] as List<dynamic>?;
        AppLogger.debug(
          'Files list from response: $dataList',
          tag: 'MediaUploadService',
        );

        if (dataList != null && dataList.isNotEmpty) {
          final parsedResponses = dataList
              .map((item) => MediaUploadResponse.fromJson(item))
              .toList();
          AppLogger.debug(
            'Parsed ${parsedResponses.length} media responses',
            tag: 'MediaUploadService',
          );
          for (var i = 0; i < parsedResponses.length; i++) {
            AppLogger.debug(
              'File $i URL: ${parsedResponses[i].url}',
              tag: 'MediaUploadService',
            );
          }
          return parsedResponses;
        }

        // No files uploaded successfully
        throw Exception('no_files_uploaded');
      } else {
        throw Exception(response.message);
      }
    } catch (e, stackTrace) {
      AppLogger.error(
        'Failed to upload multiple XFiles (fileCount: ${files.length}, fileNames: ${files.map((f) => f.name).toList()})',
        tag: 'MediaUploadService',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Download file as bytes
  Future<Uint8List?> downloadFile(String url) async {
    try {
      final response = await _mediaService.downloadFile(url);

      if (response.status == 'success' && response.data != null) {
        return response.data;
      }
      return null;
    } catch (e, stackTrace) {
      AppLogger.error(
        'Failed to download file (url: $url)',
        tag: 'MediaUploadService',
        error: e,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  /// Helper: Pick image from gallery or camera
  Future<File?> pickImage({bool fromCamera = false}) async {
    try {
      final picker = ImagePicker();
      final source = fromCamera ? ImageSource.camera : ImageSource.gallery;

      final XFile? pickedFile = await picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        return File(pickedFile.path);
      }
      return null;
    } catch (e, stackTrace) {
      AppLogger.error(
        'Failed to pick image (fromCamera: $fromCamera)',
        tag: 'MediaUploadService',
        error: e,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  /// Helper: Pick multiple images from gallery
  Future<List<File>> pickMultipleImages({int maxImages = 10}) async {
    try {
      final picker = ImagePicker();
      final List<XFile> pickedFiles = await picker.pickMultiImage(
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (pickedFiles.length > maxImages) {
        throw Exception('Maximum $maxImages images allowed');
      }

      return pickedFiles.map((xFile) => File(xFile.path)).toList();
    } catch (e, stackTrace) {
      AppLogger.error(
        'Failed to pick multiple images (maxImages: $maxImages)',
        tag: 'MediaUploadService',
        error: e,
        stackTrace: stackTrace,
      );
      return [];
    }
  }
}

// Backward compatibility alias
typedef MediaUploadRepository = MediaUploadService;
