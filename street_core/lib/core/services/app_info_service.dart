import 'package:package_info_plus/package_info_plus.dart';

/// App Info Service
///
/// Provides access to application information like version, build number, etc.
/// Uses package_info_plus to retrieve data from platform-specific sources.
class AppInfoService {
  PackageInfo? _packageInfo;

  /// Initialize the service by loading package information
  Future<void> initialize() async {
    _packageInfo = await PackageInfo.fromPlatform();
  }

  /// Get formatted version string (e.g., "1.0.0 (123)")
  String getVersionString() {
    if (_packageInfo == null) {
      return 'Loading...';
    }
    return '${_packageInfo!.version} (${_packageInfo!.buildNumber})';
  }

  /// Get app version only (e.g., "1.0.0")
  String getVersion() {
    return _packageInfo?.version ?? 'Unknown';
  }

  /// Get build number only (e.g., "123")
  String getBuildNumber() {
    return _packageInfo?.buildNumber ?? 'Unknown';
  }

  /// Get app name
  String getAppName() {
    return _packageInfo?.appName ?? 'StreetCore';
  }

  /// Get package name (bundle identifier)
  String getPackageName() {
    return _packageInfo?.packageName ?? 'Unknown';
  }
}
