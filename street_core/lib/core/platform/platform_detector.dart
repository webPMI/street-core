import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;

/// Centralized platform detection utility
///
/// Use this class to detect the current platform across the app.
/// This ensures consistent platform checks and makes it easy to add
/// platform-specific behavior.
class PlatformDetector {
  // Private constructor to prevent instantiation
  PlatformDetector._();

  /// Check if running on web
  static bool get isWeb => kIsWeb;

  /// Check if running on mobile (Android or iOS)
  static bool get isMobile => !kIsWeb && (isAndroid || isIOS);

  /// Check if running on Android
  static bool get isAndroid => !kIsWeb && Platform.isAndroid;

  /// Check if running on iOS
  static bool get isIOS => !kIsWeb && Platform.isIOS;

  /// Check if running on desktop (Windows, macOS, Linux)
  static bool get isDesktop => !kIsWeb && (isWindows || isMacOS || isLinux);

  /// Check if running on Windows
  static bool get isWindows => !kIsWeb && Platform.isWindows;

  /// Check if running on macOS
  static bool get isMacOS => !kIsWeb && Platform.isMacOS;

  /// Check if running on Linux
  static bool get isLinux => !kIsWeb && Platform.isLinux;

  /// Get platform name as string
  static String get platformName {
    if (kIsWeb) return 'web';
    if (Platform.isAndroid) return 'android';
    if (Platform.isIOS) return 'ios';
    if (Platform.isWindows) return 'windows';
    if (Platform.isMacOS) return 'macos';
    if (Platform.isLinux) return 'linux';
    return 'unknown';
  }

  /// Check if SEO features should be enabled
  /// (only makes sense on web)
  static bool get shouldEnableSEO => isWeb;

  /// Check if native features are available
  /// (e.g., file system, native notifications)
  static bool get hasNativeFeatures => !isWeb;

  /// Check if biometric authentication is available
  static bool get supportsBiometrics => isMobile;

  /// Check if file picker should use native picker
  static bool get useNativeFilePicker => !isWeb;
}
