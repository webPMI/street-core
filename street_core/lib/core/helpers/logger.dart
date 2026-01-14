// lib/core/helpers/logger.dart

import '/core/services/crash_reporting_service.dart';
import 'package:flutter/foundation.dart';

/// Application logger with timestamps and structured output
class AppLogger {
  static String get _timestamp {
    final now = DateTime.now();
    return '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';
  }

  /// Log informational messages
  static void info(String message, {String? tag}) {
    if (kDebugMode) {
      final t = tag != null ? '[$tag] ' : '';
      debugPrint('$_timestamp ℹ️  $t$message');
    }
  }

  /// Log warning messages
  static void warning(String message, {String? tag}) {
    if (kDebugMode) {
      final t = tag != null ? '[$tag] ' : '';
      debugPrint('$_timestamp ⚠️  $t$message');
    }
  }

  /// Log error messages with full details
  static void error(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    String? tag,
  }) {
    if (kDebugMode) {
      final t = tag != null ? '[$tag] ' : '';
      debugPrint('$_timestamp ❌ $t$message');
      if (error != null) {
        debugPrint('$_timestamp    └─ Error: $error');
      }
      if (stackTrace != null) {
        // Show first 3 lines of stack trace
        final lines = stackTrace.toString().split('\n').take(3);
        for (final line in lines) {
          if (line.trim().isNotEmpty) {
            debugPrint('$_timestamp    │  $line');
          }
        }
      }
    }

    // Send to crash reporting service
    if (error != null) {
      CrashReportingService().reportError(
        error,
        stackTrace,
        context: tag ?? 'AppLogger',
        extras: {'message': message},
      );
    }
  }

  /// Log debug messages for development
  static void debug(String message, {String? tag}) {
    if (kDebugMode) {
      final t = tag != null ? '[$tag] ' : '';
      debugPrint('$_timestamp 🔍 $t$message');
    }
  }

  /// Log API request with full URL
  static void apiRequest(String method, String url, {Map<String, dynamic>? data}) {
    if (kDebugMode) {
      debugPrint('$_timestamp 📤 $method $url');
      if (data != null && data.isNotEmpty) {
        // Truncate large data
        final dataStr = data.toString();
        if (dataStr.length > 200) {
          debugPrint('$_timestamp    └─ Body: ${dataStr.substring(0, 200)}...');
        } else {
          debugPrint('$_timestamp    └─ Body: $dataStr');
        }
      }
    }
  }

  /// Log API response with status
  static void apiResponse(int statusCode, String url, {dynamic data, int? ms}) {
    if (kDebugMode) {
      final icon = statusCode < 400 ? '✅' : '❌';
      final time = ms != null ? ' (${ms}ms)' : '';
      debugPrint('$_timestamp $icon $statusCode $url$time');

      // Show error response body
      if (statusCode >= 400 && data != null) {
        final dataStr = data.toString();
        if (dataStr.length > 300) {
          debugPrint('$_timestamp    └─ Response: ${dataStr.substring(0, 300)}...');
        } else {
          debugPrint('$_timestamp    └─ Response: $dataStr');
        }
      }
    }
  }

  /// Log navigation events
  static void navigation(String action, {String? from, String? to, String? route}) {
    if (kDebugMode) {
      if (from != null && to != null) {
        debugPrint('$_timestamp 🧭 $from → $to');
      } else if (route != null) {
        debugPrint('$_timestamp 🧭 $action: $route');
      } else {
        debugPrint('$_timestamp 🧭 $action');
      }
    }
  }

  /// Log authentication events
  static void auth(String action, {String? userId, String? details}) {
    if (kDebugMode) {
      final user = userId != null ? ' [user: ${userId.substring(0, 8)}...]' : '';
      final det = details != null ? ' - $details' : '';
      debugPrint('$_timestamp 🔐 $action$user$det');
    }
  }

  /// Log state changes (BLoC/Cubit)
  static void state(String bloc, String state, {String? details}) {
    if (kDebugMode) {
      final det = details != null ? ': $details' : '';
      debugPrint('$_timestamp 📊 [$bloc] → $state$det');
    }
  }

  /// Log lifecycle events
  static void lifecycle(String event, {String? details}) {
    if (kDebugMode) {
      final det = details != null ? ': $details' : '';
      debugPrint('$_timestamp 🔄 $event$det');
    }
  }

  /// Log performance metrics
  static void perf(String operation, int ms, {String? details}) {
    if (kDebugMode) {
      final det = details != null ? ' - $details' : '';
      final icon = ms > 1000 ? '🐢' : ms > 500 ? '⏱️' : '⚡';
      debugPrint('$_timestamp $icon $operation: ${ms}ms$det');
    }
  }
}
