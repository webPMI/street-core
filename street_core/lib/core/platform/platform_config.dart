import '/core/platform/platform_detector.dart';

/// Platform-specific configuration for UI, features, and behavior.
///
/// This class provides configuration values that vary by platform.
/// Use this to centralize all platform-specific settings.
///
/// NOTE: For API URL configuration, use:
/// - [Env] in config/env.dart for environment variables (--dart-define)
/// - [getApiAddress] in services/api_address.dart for resolved URL
class PlatformConfig {
  // Private constructor
  PlatformConfig._();

  /// Check if running in production
  static const bool _isProduction = bool.fromEnvironment('dart.vm.product');

  /// Storage Configuration
  /// Defines where to store persistent data based on platform
  static bool get useSecureStorage => PlatformDetector.isMobile;
  static bool get useSharedPreferences => !PlatformDetector.isWeb;
  static bool get useLocalStorage => PlatformDetector.isWeb;

  /// UI Configuration
  /// Platform-specific UI adjustments
  static double get defaultPadding {
    if (PlatformDetector.isMobile) return 16;
    if (PlatformDetector.isDesktop) return 24;
    return 16; // web
  }

  static double get maxContentWidth {
    if (PlatformDetector.isMobile) return double.infinity;
    if (PlatformDetector.isDesktop) return 1200;
    return 1440; // web
  }

  /// Feature Flags
  /// Enable/disable features based on platform
  static bool get enableSEO => PlatformDetector.isWeb;
  static bool get enablePushNotifications => PlatformDetector.isMobile;
  static bool get enableBiometrics => PlatformDetector.isMobile;
  static bool get enableFileSystem => PlatformDetector.hasNativeFeatures;
  static bool get enableOfflineMode => !PlatformDetector.isWeb;
  static bool get enableDeepLinking => true; // All platforms
  static bool get enableAnalytics => true; // All platforms

  /// Performance Configuration
  static int get imageCacheSize {
    if (PlatformDetector.isMobile) return 100; // 100 images
    if (PlatformDetector.isDesktop) return 200;
    return 150; // web
  }

  static int get maxConcurrentRequests {
    if (PlatformDetector.isMobile) return 4;
    if (PlatformDetector.isDesktop) return 8;
    return 6; // web
  }

  /// Navigation Configuration
  static bool get useSystemNavigation => PlatformDetector.isMobile;
  static bool get showBackButton {
    if (PlatformDetector.isMobile) return true;
    return false; // Desktop/Web use browser back
  }

  /// Media Configuration
  static bool get supportsCameraAccess => PlatformDetector.isMobile;
  static bool get supportsGalleryAccess => !PlatformDetector.isWeb;
  static bool get supportsFilePicker => true; // All platforms

  /// Localization Configuration
  static bool get useSystemLocale => true; // All platforms

  /// Debug Configuration
  static bool get showPlatformBanner => !_isProduction;

  // this neded to be fixed ,use the translatiosn keys
  /// Get platform-specific error messages
  static String getErrorMessage(String errorType) {
    switch (errorType) {
      case 'network':
        if (PlatformDetector.isWeb) {
          return 'Connection error. Please check your internet connection.';
        }
        return 'No internet connection. Please check your network settings.';
      case 'permission':
        if (PlatformDetector.isMobile) {
          return 'Permission denied. Please enable it in your device settings.';
        }
        return 'Permission denied. Please check your browser settings.';
      case 'storage':
        if (PlatformDetector.isWeb) {
          return 'Storage quota exceeded. Please clear some space.';
        }
        return 'Not enough storage space available.';
      default:
        return 'An error occurred. Please try again.';
    }
  }
}
