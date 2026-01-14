/// API URIs for Media Upload
///
/// All media-related backend endpoints.
/// This is a cross-cutting concern used by multiple features.
library;

import '../../config/env.dart';

class MediaUris {
  static const String _api = '/api/${Env.apiVersion}';

  // ============================================================================
  // MEDIA UPLOAD
  // ============================================================================

  /// POST - Upload avatar (max 5MB)
  /// Content-Type: multipart/form-data
  /// Field name: 'file'
  /// Supported formats: jpg, jpeg, png, gif, webp
  static const String uploadAvatar = '$_api/media/upload/avatar';

  /// POST - Upload image (max 10MB)
  /// Content-Type: multipart/form-data
  /// Field name: 'file'
  /// Supported formats: jpg, jpeg, png, gif, webp
  static const String uploadImage = '$_api/media/upload/image';

  /// POST - Upload video (max 500MB)
  /// Content-Type: multipart/form-data
  /// Field name: 'file'
  /// Supported formats: mp4, webm, mpeg, mov, avi
  static const String uploadVideo = '$_api/media/upload/video';

  /// POST - Upload multiple files (max 10 files)
  /// Content-Type: multipart/form-data
  /// Field name: 'files'
  static const String uploadMultiple = '$_api/media/upload/multiple';

  /// DELETE - Delete uploaded media
  /// Only file owner can delete
  static String delete(String filename) => '$_api/media/$filename';
}
