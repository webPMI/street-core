/// SSE Event Service for Speaker Dashboard Real-Time Updates
/// Handles connection, reconnection, and event streaming

import 'dart:async';
import 'dart:convert';

import 'package:flutter_client_sse/flutter_client_sse.dart';
import 'package:flutter_client_sse/constants/sse_request_type_enum.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../models/sse_events.dart';
import '../../../../core/helpers/logger.dart';

/// Configuration for SSE connection
class SSEConfig {
  final String baseUrl;
  final Duration reconnectDelay;
  final Duration connectionTimeout;
  final int maxReconnectAttempts;

  const SSEConfig({
    required this.baseUrl,
    this.reconnectDelay = const Duration(seconds: 3),
    this.connectionTimeout = const Duration(seconds: 30),
    this.maxReconnectAttempts = 5,
  });
}

/// SSE Event Service - Manages real-time event streaming for Speaker Dashboard
///
/// Features:
/// - Automatic reconnection with exponential backoff
/// - Event type mapping to Dart objects
/// - Connection state management
/// - Proper cleanup on disposal
///
/// Usage:
/// ```dart
/// final service = SSEEventService(config: SSEConfig(baseUrl: 'http://localhost:3000'));
/// await service.connect('673d1f2e8b5c4a1d2e3f4a5b');
///
/// service.eventStream.listen((event) {
///   if (event is ScoreResetEvent) {
///     // Handle score reset
///   }
/// });
///
/// // When done
/// await service.disconnect();
/// ```
class SSEEventService {
  final SSEConfig config;
  final FlutterSecureStorage _secureStorage;

  // SSE subscription
  StreamSubscription? _sseSubscription;

  // Stream controllers
  final _eventController = StreamController<SSEEvent>.broadcast();
  final _stateController = StreamController<SSEConnectionState>.broadcast();
  final _errorController = StreamController<SSEError>.broadcast();

  // State
  String? _currentCompetitionId;
  SSEConnectionState _state = SSEConnectionState.disconnected;
  int _reconnectAttempts = 0;
  Timer? _reconnectTimer;
  bool _disposed = false;

  SSEEventService({
    required this.config,
    FlutterSecureStorage? secureStorage,
  }) : _secureStorage = secureStorage ?? const FlutterSecureStorage();

  /// Stream of SSE events
  Stream<SSEEvent> get eventStream => _eventController.stream;

  /// Stream of connection state changes
  Stream<SSEConnectionState> get stateStream => _stateController.stream;

  /// Stream of errors
  Stream<SSEError> get errorStream => _errorController.stream;

  /// Current connection state
  SSEConnectionState get state => _state;

  /// Whether currently connected
  bool get isConnected => _state == SSEConnectionState.connected;

  /// Connect to SSE endpoint for a competition
  Future<void> connect(String competitionId) async {
    if (_disposed) {
      throw StateError('SSEEventService has been disposed');
    }

    if (_currentCompetitionId == competitionId && isConnected) {
      AppLogger.debug('Already connected to competition $competitionId', tag: 'SSEEventService');
      return;
    }

    // Disconnect existing connection
    if (_sseSubscription != null) {
      await disconnect();
    }

    _currentCompetitionId = competitionId;
    _reconnectAttempts = 0;
    await _establishConnection();
  }

  /// Establish SSE connection
  Future<void> _establishConnection() async {
    if (_disposed || _currentCompetitionId == null) return;

    try {
      _updateState(SSEConnectionState.connecting);

      // Get JWT token
      final token = await _secureStorage.read(key: 'access_token');
      if (token == null) {
        _handleError('No authentication token found', code: 'AUTH_ERROR');
        return;
      }

      // Build SSE URL
      final url =
          '${config.baseUrl}/api/v1/competitions/$_currentCompetitionId/events';

      AppLogger.info('Connecting to SSE: $url', tag: 'SSEEventService');

      // Subscribe to SSE stream with JWT authentication
      _sseSubscription = SSEClient.subscribeToSSE(
        method: SSERequestType.GET,
        url: url,
        header: {
          'Authorization': 'Bearer $token',
          'Accept': 'text/event-stream',
        },
      ).listen(
        (event) {
          _handleRawEvent(event);
        },
        onError: (error) {
          AppLogger.error('SSE Stream error', error: error, tag: 'SSEEventService');
          _handleError(error.toString(), code: 'STREAM_ERROR');
          _scheduleReconnect();
        },
        onDone: () {
          AppLogger.info('SSE Stream closed', tag: 'SSEEventService');
          if (!_disposed && _currentCompetitionId != null) {
            _scheduleReconnect();
          }
        },
        cancelOnError: false,
      );

      // Mark as connected
      _updateState(SSEConnectionState.connected);
      _reconnectAttempts = 0;
      AppLogger.info('SSE Connected to competition $_currentCompetitionId', tag: 'SSEEventService');
    } catch (e) {
      AppLogger.error('SSE Connection error', error: e, tag: 'SSEEventService');
      _handleError(e.toString(), code: 'CONNECTION_ERROR');
      _scheduleReconnect();
    }
  }

  /// Handle raw SSE event
  void _handleRawEvent(SSEModel rawEvent) {
    try {
      // Parse event data as JSON
      final data = rawEvent.data;
      if (data == null || data.isEmpty) {
        return;
      }

      final Map<String, dynamic> json = jsonDecode(data);

      // Create typed event
      final event = SSEEvent.fromJson(json);

      // Emit event
      _eventController.add(event);

      AppLogger.debug('SSE Event: ${event.type} - ${event.message}', tag: 'SSEEventService');
    } catch (e) {
      AppLogger.warning('Failed to parse SSE event: $e. Raw data: ${rawEvent.data}', tag: 'SSEEventService');
      _handleError('Failed to parse event: $e', code: 'PARSE_ERROR');
    }
  }

  /// Schedule reconnection with exponential backoff
  void _scheduleReconnect() {
    if (_disposed || _currentCompetitionId == null) return;

    if (_reconnectAttempts >= config.maxReconnectAttempts) {
      _handleError(
        'Max reconnection attempts reached (${config.maxReconnectAttempts})',
        code: 'MAX_RECONNECT',
      );
      _updateState(SSEConnectionState.error);
      return;
    }

    _updateState(SSEConnectionState.reconnecting);
    _reconnectAttempts++;

    // Exponential backoff: 3s, 6s, 12s, 24s, 48s
    final delay = config.reconnectDelay * (1 << (_reconnectAttempts - 1));

    AppLogger.info('Reconnecting in ${delay.inSeconds}s (attempt $_reconnectAttempts)', tag: 'SSEEventService');

    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(delay, () {
      _establishConnection();
    });
  }

  /// Disconnect from SSE
  Future<void> disconnect() async {
    AppLogger.info('Disconnecting SSE', tag: 'SSEEventService');

    _reconnectTimer?.cancel();
    _reconnectTimer = null;

    await _sseSubscription?.cancel();
    _sseSubscription = null;

    // Unsubscribe from SSE
    SSEClient.unsubscribeFromSSE();

    _currentCompetitionId = null;
    _reconnectAttempts = 0;
    _updateState(SSEConnectionState.disconnected);
  }

  /// Update connection state and notify listeners
  void _updateState(SSEConnectionState newState) {
    if (_state != newState) {
      _state = newState;
      if (!_stateController.isClosed) {
        _stateController.add(newState);
      }
    }
  }

  /// Handle error
  void _handleError(String message, {String? code}) {
    final error = SSEError(
      message: message,
      code: code,
      timestamp: DateTime.now(),
    );

    if (!_errorController.isClosed) {
      _errorController.add(error);
    }
  }

  /// Dispose service and clean up resources
  Future<void> dispose() async {
    if (_disposed) return;

    AppLogger.info('Disposing SSEEventService', tag: 'SSEEventService');
    _disposed = true;

    await disconnect();

    await _eventController.close();
    await _stateController.close();
    await _errorController.close();
  }

  /// Manually trigger reconnection (for testing)
  Future<void> reconnect() async {
    if (_currentCompetitionId != null) {
      await disconnect();
      await connect(_currentCompetitionId!);
    }
  }
}

/// SSE Event Service Provider (Singleton for global access)
///
/// Usage in dependency injection:
/// ```dart
/// final sseService = SSEEventServiceProvider.instance;
/// await sseService.connect(competitionId);
/// ```
class SSEEventServiceProvider {
  static SSEEventService? _instance;

  /// Get singleton instance
  static SSEEventService get instance {
    if (_instance == null) {
      throw StateError(
        'SSEEventService not initialized. Call SSEEventServiceProvider.initialize() first.',
      );
    }
    return _instance!;
  }

  /// Initialize singleton with config
  static void initialize(SSEConfig config) {
    _instance?.dispose();
    _instance = SSEEventService(config: config);
  }

  /// Dispose singleton
  static Future<void> dispose() async {
    await _instance?.dispose();
    _instance = null;
  }
}
