import '/core/services/api_address.dart';
import '/core/helpers/logger.dart';

/// Media Upload Response Model
///
/// Represents the response from media upload endpoints.
/// Backend returns: {publicUrl: "...", thumbnailUrl: "...", fileType: "...", ...}
class MediaUploadResponse {
  MediaUploadResponse({required this.url, required this.filename});

  factory MediaUploadResponse.fromJson(Map<String, dynamic> json) {
    // Backend returns 'publicUrl', fallback to 'url' for compatibility
    final rawUrl = json['publicUrl'] as String? ?? json['url'] as String? ?? '';
    final filename = json['filename'] as String? ?? json['id'] as String? ?? '';

    AppLogger.debug('Parsing MediaUploadResponse - rawUrl: $rawUrl, filename: $filename', tag: 'MediaUploadResponse');
    AppLogger.debug('Full JSON: $json', tag: 'MediaUploadResponse');

    // Convert relative URL to absolute URL for proper image loading
    final url = buildMediaUrl(rawUrl);
    AppLogger.debug('Final URL after buildMediaUrl: $url', tag: 'MediaUploadResponse');

    return MediaUploadResponse(url: url, filename: filename);
  }

  final String url;
  final String filename;

  Map<String, dynamic> toJson() {
    return {'url': url, 'filename': filename};
  }

  @override
  String toString() => 'MediaUploadResponse(url: $url, filename: $filename)';
}
