/// Environment configuration using dart-define variables
/// Available Variables:
/// - API_URL: Full API URL (e.g., https://api.yourdomain.com)
/// - ENVIRONMENT: Environment name (development, staging, production)
/// - API_PORT: Port for localhost (default: 3000)
/// - TESTING_MODE: Enable testing features (default: false)
/// - DEBUG_MODE: Enable debug logging (default: false)
///
class Env {
  static const String apiVersion = String.fromEnvironment(
    'API_VERSION',
    defaultValue: 'v2',
  );
  static const String apiUrl = String.fromEnvironment(
    'API_URL',
  );

  /// Environment name
  /// Options: 'development', 'staging', 'production'
  static const String environment = String.fromEnvironment(
    'ENV',
    defaultValue: 'development',
  );

  /// Default API port for local development
  static const String apiPort = String.fromEnvironment(
    'API_PORT',
    defaultValue: '3000',
  );

  static const bool isProduction = bool.fromEnvironment(
    'dart.vm.product',
  );

  /// Use this for:
  /// - Mock data
  /// - Test accounts
  /// - Bypass authentication (dev only!)
  static const bool testingMode = bool.fromEnvironment(
    'TESTING_MODE',
    defaultValue: true,
  );

  /// Debug mode flag
  /// Use this for:
  /// - Verbose logging
  /// - Debug overlays
  /// - Performance monitoring
  static const bool debugMode = bool.fromEnvironment(
    'DEBUG_MODE',
  );

  // ========================================
  // Helper Getters
  // ========================================

  /// Check if environment is development
  static bool get isDevelopment => environment == 'development';

  /// Check if environment is staging
  static bool get isStaging => environment == 'staging';

  /// Check if environment is production
  static bool get isProductionEnv => environment == 'production';

  /// Check if using localhost (no explicit API URL set)
  static bool get isLocalhost => apiUrl.isEmpty;

  /// Get full environment name for display
  static String get environmentName {
    if (isProduction) return 'Production (Release Build)';
    if (isProductionEnv) return 'Production (Debug Build)';
    if (isStaging) return 'Staging';
    return 'Development';
  }

  // ========================================
  // Debug Information
  /// Get debug information string
  /// Usage:
  /// AppLogger.info(Env.debugInfo);

  static String get debugInfo =>
      '''
╔══════════════════════════════════════════════════════════
║ ENVIRONMENT CONFIGURATION
╠══════════════════════════════════════════════════════════
║ Environment:        $environmentName
║ API URL:            ${apiUrl.isEmpty ? 'Platform-specific localhost' : apiUrl}
║ API Port:           $apiPort (localhost only)
║ Production Build:   $isProduction
║ Testing Mode:       $testingMode
║ Debug Mode:         $debugMode
╚══════════════════════════════════════════════════════════
''';

  /// Validate environment configuration
  ///
  /// Throws exception if configuration is invalid
  static void validate() {
    // Production builds must have explicit API URL
    if (isProduction && apiUrl.isEmpty) {
      throw Exception(
        'CONFIGURATION ERROR: Production builds require explicit API_URL\n'
        'Use: flutter build apk --release --dart-define=API_URL=https://your-api.com',
      );
    }

    // Production API URLs must use HTTPS (checked in api_uri.dart)
    // Environment must be valid
    if (!['development', 'staging', 'production'].contains(environment)) {
      throw Exception(
        'CONFIGURATION ERROR: Invalid ENVIRONMENT value: $environment\n'
        'Valid values: development, staging, production',
      );
    }
  }
}
