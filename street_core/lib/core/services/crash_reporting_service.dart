// lib/core/services/crash_reporting_service.dart
import '/core/helpers/logger.dart';
import 'package:flutter/foundation.dart';

import 'api_service.dart';

/// Service for crash reporting and error tracking
///
/// Integrates with custom backend for error tracking and monitoring
class CrashReportingService {
  factory CrashReportingService() => _instance;
  CrashReportingService._internal();
  static final CrashReportingService _instance =
      CrashReportingService._internal();

  bool _initialized = false;
  ApiService? _apiService;
  String? _currentUserId;
  String? _currentUserEmail;
  String? _currentUsername;
  final Map<String, dynamic> _customKeys = {};
  final List<Map<String, dynamic>> _breadcrumbs = [];
  static const int _maxBreadcrumbs = 50;

  /// Initialize crash reporting service
  Future<void> initialize({ApiService? apiService}) async {
    if (_initialized) return;

    try {
      _apiService = apiService;
      _initialized = true;
      AppLogger.info('Crash Reporting Service initialized', tag: 'CrashReporting');
    } catch (e) {
      AppLogger.error('Failed to initialize CrashReportingService', error: e);
    }
  }

  /// Report an error to crash reporting service
  Future<void> reportError(
    dynamic error,
    StackTrace? stackTrace, {
    String? context,
    Map<String, dynamic>? extras,
  }) async {
    if (!_initialized) {
      AppLogger.warning('CrashReportingService not initialized. Error: $error');
      return;
    }

    try {
      // Log to console in debug mode
      if (kDebugMode) {
        AppLogger.error('Error reported', error: error, tag: 'CrashReporting');
        if (context != null) AppLogger.debug('Context: $context', tag: 'CrashReporting');
        if (extras != null) AppLogger.debug('Extras: $extras', tag: 'CrashReporting');
        if (stackTrace != null) {
          AppLogger.debug('Stack trace:\n$stackTrace', tag: 'CrashReporting');
        }
      }

      // Send to custom backend
      await _sendToCustomBackend(
        type: 'error',
        message: error.toString(),
        stackTrace: stackTrace?.toString(),
        context: context,
        extras: extras,
      );
    } catch (e) {
      AppLogger.debug('Failed to report error to crash reporting service: $e');
    }
  }

  /// Report a message (non-error event)
  Future<void> reportMessage(
    String message, {
    String? level, // 'info', 'warning', 'error'
    Map<String, dynamic>? extras,
  }) async {
    if (!_initialized) return;

    try {
      AppLogger.info('Message reported [$level]: $message');

      // Send to custom backend
      await _sendToCustomBackend(
        type: 'message',
        message: message,
        level: level ?? 'info',
        extras: extras,
      );
    } catch (e) {
      AppLogger.error('Failed to report message', error: e, tag: 'CrashReporting');
    }
  }

  /// Set user information for crash reports
  Future<void> setUser({
    String? id,
    String? email,
    String? username,
    Map<String, dynamic>? extras,
  }) async {
    if (!_initialized) return;

    try {
      _currentUserId = id;
      _currentUserEmail = email;
      _currentUsername = username;

      // Send user info to backend
      await _sendToCustomBackend(
        type: 'user_update',
        userId: id,
        userEmail: email,
        username: username,
        extras: extras,
      );

      if (kDebugMode) {
        AppLogger.debug('User set in crash reporting: $id ($email)', tag: 'CrashReporting');
      }
    } catch (e) {
      AppLogger.error('Failed to set user', error: e, tag: 'CrashReporting');
    }
  }

  /// Clear user information
  Future<void> clearUser() async {
    if (!_initialized) return;

    try {
      _currentUserId = null;
      _currentUserEmail = null;
      _currentUsername = null;

      // Notify backend of user logout
      await _sendToCustomBackend(type: 'user_clear');

      if (kDebugMode) {
        AppLogger.debug('User cleared from crash reporting', tag: 'CrashReporting');
      }
    } catch (e) {
      AppLogger.error('Failed to clear user', error: e, tag: 'CrashReporting');
    }
  }

  /// Add breadcrumb for debugging
  Future<void> addBreadcrumb({
    required String message,
    String? category,
    Map<String, dynamic>? data,
  }) async {
    if (!_initialized) return;

    try {
      final breadcrumb = {
        'message': message,
        'category': category ?? 'default',
        'data': data,
        'timestamp': DateTime.now().toIso8601String(),
      };

      _breadcrumbs.add(breadcrumb);

      // Keep only the last N breadcrumbs
      if (_breadcrumbs.length > _maxBreadcrumbs) {
        _breadcrumbs.removeAt(0);
      }

      if (kDebugMode) {
        AppLogger.debug('Breadcrumb: [$category] $message', tag: 'CrashReporting');
      }
    } catch (e) {
      AppLogger.error('Failed to add breadcrumb', error: e, tag: 'CrashReporting');
    }
  }

  /// Log a custom key-value pair
  Future<void> setCustomKey(String key, dynamic value) async {
    if (!_initialized) return;

    try {
      _customKeys[key] = value;

      if (kDebugMode) {
        AppLogger.debug('Custom key set: $key = $value', tag: 'CrashReporting');
      }
    } catch (e) {
      AppLogger.error('Failed to set custom key', error: e, tag: 'CrashReporting');
    }
  }

  /// Helper method to send to custom backend
  Future<void> _sendToCustomBackend({
    required String type,
    String? message,
    String? stackTrace,
    String? context,
    String? level,
    String? userId,
    String? userEmail,
    String? username,
    Map<String, dynamic>? extras,
  }) async {
    if (_apiService == null) {
      if (kDebugMode) {
        AppLogger.warning('ApiService not configured for crash reporting', tag: 'CrashReporting');
      }
      return;
    }

    try {
      final payload = {
        'type': type,
        'timestamp': DateTime.now().toIso8601String(),
        'platform': defaultTargetPlatform.name,
        'environment': kDebugMode ? 'development' : 'production',
        if (message != null) 'message': message,
        if (stackTrace != null) 'stackTrace': stackTrace,
        if (context != null) 'context': context,
        if (level != null) 'level': level,
        if (userId != null || _currentUserId != null)
          'user': {
            'id': userId ?? _currentUserId,
            'email': userEmail ?? _currentUserEmail,
            'username': username ?? _currentUsername,
          },
        if (_customKeys.isNotEmpty) 'customKeys': _customKeys,
        if (_breadcrumbs.isNotEmpty) 'breadcrumbs': _breadcrumbs,
        if (extras != null) 'extras': extras,
      };

      // Send to backend endpoint
      await _apiService!.useFetch<void>(
        '/api/crash-reports',
        method: 'POST',
        body: payload,
        requiredToken: false, // Don't require auth for crash reports
      );
    } catch (e) {
      // Silently fail to avoid infinite error loops
      if (kDebugMode) {
        AppLogger.error('Failed to send crash report to backend', error: e, tag: 'CrashReporting');
      }
    }
  }

  /// Get current breadcrumbs (for debugging)
  List<Map<String, dynamic>> get breadcrumbs => List.unmodifiable(_breadcrumbs);

  /// Get current custom keys (for debugging)
  Map<String, dynamic> get customKeys => Map.unmodifiable(_customKeys);

  /// Clear all breadcrumbs
  void clearBreadcrumbs() {
    _breadcrumbs.clear();
  }

  /// Clear all custom keys
  void clearCustomKeys() {
    _customKeys.clear();
  }
}
