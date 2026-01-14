import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;

import '../../config/env.dart';
import '../helpers/logger.dart';

/// Cached API base URL for synchronous access
String? _cachedApiAddress;

/// Get API address synchronously (uses cached value or calculates it)
/// This is safe to use in JSON parsers and other synchronous contexts.
String getApiAddressSync() {
  if (_cachedApiAddress != null) return _cachedApiAddress!;

  if (Env.apiUrl.isNotEmpty) {
    _cachedApiAddress = Env.apiUrl;
  } else {
    const port = Env.apiPort;
    if (kIsWeb) {
      _cachedApiAddress = 'http://localhost:$port';
    } else if (Platform.isAndroid) {
      _cachedApiAddress = 'http://10.0.2.2:$port';
    } else if (Platform.isIOS) {
      _cachedApiAddress = 'http://127.0.0.1:$port';
    } else {
      _cachedApiAddress = 'http://localhost:$port';
    }
  }
  return _cachedApiAddress!;
}

/// Build a full media URL from a relative path
/// Handles both relative (/uploads/...) and absolute (http://...) URLs
String buildMediaUrl(String? relativePath) {
  if (relativePath == null || relativePath.isEmpty) return '';

  // Already absolute URL
  if (relativePath.startsWith('http://') || relativePath.startsWith('https://')) {
    return relativePath;
  }

  // Relative URL - prepend base URL
  final baseUrl = getApiAddressSync();
  if (relativePath.startsWith('/')) {
    return '$baseUrl$relativePath';
  }
  return '$baseUrl/$relativePath';
}

/// Convert a dynamic value to an absolute media URL, or null if empty
/// Use this in model fromJson() methods for optional media URL fields
String? mediaUrlOrNull(dynamic value) {
  if (value == null) return null;
  final str = value.toString().trim();
  if (str.isEmpty) return null;
  final url = buildMediaUrl(str);
  return url.isEmpty ? null : url;
}

/// Parse a list of media URLs, converting each to absolute URL
/// Use this in model fromJson() methods for `List<String>` media URL fields
List<String> parseMediaUrls(dynamic value) {
  if (value == null) return [];
  if (value is List) {
    return value
        .map((e) => buildMediaUrl(e.toString()))
        .where((url) => url.isNotEmpty)
        .toList();
  }
  return [];
}

/// - Web: http://localhost:PORT
/// - Android Emulator: http://10.0.2.2:PORT (special IP to reach host machine)
/// - iOS Simulator: http://127.0.0.1:PORT
/// - Desktop: http://localhost:PORT
Future<String> getApiAddress() async {
  String address;

  // If API_URL is explicitly set via dart-define, use it
  if (Env.apiUrl.isNotEmpty) {
    address = Env.apiUrl;
    AppLogger.info('Using configured API URL: $address', tag: 'API');
  } else {
    // Otherwise, use platform-specific localhost for development
    const port = Env.apiPort;

    if (kIsWeb) {
      address = 'http://localhost:$port';
    } else if (Platform.isAndroid) {
      // Android emulator uses 10.0.2.2 to reach host machine
      address = 'http://10.0.2.2:$port';
      AppLogger.info('Android Emulator mode: $address', tag: 'API');
    } else if (Platform.isIOS) {
      // iOS simulator uses localhost/127.0.0.1
      address = 'http://127.0.0.1:$port';
      AppLogger.info('iOS Simulator mode: $address', tag: 'API');
    } else {
      // Desktop (Windows, macOS, Linux) uses localhost
      address = 'http://localhost:$port';
      AppLogger.info('Desktop mode: $address', tag: 'API');
    }
  }

  // Security validation: Production builds MUST use HTTPS
  if (Env.isProduction && !address.startsWith('https://')) {
    throw Exception(
      'SECURITY ERROR: Production builds must use HTTPS.\n'
      'Current address: $address\n'
      'Use: flutter build --dart-define=API_URL=https://your-api.com --dart-define=ENVIRONMENT=production',
    );
  }

  // Warning for staging/production environments without explicit URL
  if ((Env.isStaging || Env.isProductionEnv) && Env.apiUrl.isEmpty) {
    AppLogger.warning(
      'Environment is ${Env.environment} but no API_URL is set. Using localhost.',
      tag: 'API',
    );
  }

  return address;
}
