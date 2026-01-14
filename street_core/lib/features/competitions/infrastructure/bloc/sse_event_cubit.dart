// SSE Event Cubit - Manages SSE events for Speaker Dashboard
// Connects to SSE service and updates UI state

import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

import '../../models/sse_events.dart';
import '../services/sse_event_service.dart';
import '../../../../core/helpers/logger.dart';

/// SSE Event State
class SSEEventState extends Equatable {
  final SSEConnectionState connectionState;
  final List<SSEEvent> recentEvents;
  final SSEEvent? latestEvent;
  final SSEError? lastError;
  final int totalEventsReceived;
  final Map<String, int> eventCounts; // Count by event type

  const SSEEventState({
    this.connectionState = SSEConnectionState.disconnected,
    this.recentEvents = const [],
    this.latestEvent,
    this.lastError,
    this.totalEventsReceived = 0,
    this.eventCounts = const {},
  });

  SSEEventState copyWith({
    SSEConnectionState? connectionState,
    List<SSEEvent>? recentEvents,
    SSEEvent? latestEvent,
    SSEError? lastError,
    int? totalEventsReceived,
    Map<String, int>? eventCounts,
  }) {
    return SSEEventState(
      connectionState: connectionState ?? this.connectionState,
      recentEvents: recentEvents ?? this.recentEvents,
      latestEvent: latestEvent ?? this.latestEvent,
      lastError: lastError ?? this.lastError,
      totalEventsReceived: totalEventsReceived ?? this.totalEventsReceived,
      eventCounts: eventCounts ?? this.eventCounts,
    );
  }

  bool get isConnected => connectionState == SSEConnectionState.connected;
  bool get isConnecting =>
      connectionState == SSEConnectionState.connecting ||
      connectionState == SSEConnectionState.reconnecting;
  bool get hasError => connectionState == SSEConnectionState.error;

  @override
  List<Object?> get props => [
        connectionState,
        recentEvents,
        latestEvent,
        lastError,
        totalEventsReceived,
        eventCounts,
      ];
}

/// SSE Event Cubit - Manages SSE connection and events
class SSEEventCubit extends Cubit<SSEEventState> {
  final SSEEventService _sseService;
  StreamSubscription<SSEEvent>? _eventSubscription;
  StreamSubscription<SSEConnectionState>? _stateSubscription;
  StreamSubscription<SSEError>? _errorSubscription;

  String? _currentCompetitionId;

  SSEEventCubit(this._sseService) : super(const SSEEventState()) {
    _listenToStreams();
  }

  /// Listen to SSE service streams
  void _listenToStreams() {
    // Listen to connection state changes
    _stateSubscription = _sseService.stateStream.listen(
      (connectionState) {
        emit(state.copyWith(connectionState: connectionState));
      },
    );

    // Listen to events
    _eventSubscription = _sseService.eventStream.listen(
      _handleEvent,
      onError: (error) {
        AppLogger.error('SSE Event stream error', error: error, tag: 'SSEEventCubit');
      },
    );

    // Listen to errors
    _errorSubscription = _sseService.errorStream.listen(
      (error) {
        emit(state.copyWith(lastError: error));
      },
    );
  }

  /// Handle incoming SSE event
  void _handleEvent(SSEEvent event) {
    // Update recent events (keep last 50)
    final recentEvents = [event, ...state.recentEvents].take(50).toList();

    // Update event counts
    final eventCounts = Map<String, int>.from(state.eventCounts);
    eventCounts[event.type] = (eventCounts[event.type] ?? 0) + 1;

    emit(state.copyWith(
      recentEvents: recentEvents,
      latestEvent: event,
      totalEventsReceived: state.totalEventsReceived + 1,
      eventCounts: eventCounts,
    ));

    // Log event for debugging
    AppLogger.debug('SSE Event received: ${event.type} - ${event.message}', tag: 'SSEEventCubit');
  }

  /// Connect to competition SSE stream
  Future<void> connect(String competitionId) async {
    if (_currentCompetitionId == competitionId && state.isConnected) {
      AppLogger.debug('Already connected to competition $competitionId', tag: 'SSEEventCubit');
      return;
    }

    _currentCompetitionId = competitionId;

    try {
      await _sseService.connect(competitionId);
    } catch (e) {
      AppLogger.error('Failed to connect to SSE', error: e, tag: 'SSEEventCubit');
      emit(state.copyWith(
        connectionState: SSEConnectionState.error,
        lastError: SSEError(
          message: 'Failed to connect: $e',
          code: 'CONNECTION_FAILED',
          timestamp: DateTime.now(),
        ),
      ));
    }
  }

  /// Disconnect from SSE stream
  Future<void> disconnect() async {
    await _sseService.disconnect();
    _currentCompetitionId = null;

    // Reset state
    emit(const SSEEventState());
  }

  /// Manually trigger reconnection
  Future<void> reconnect() async {
    if (_currentCompetitionId != null) {
      await _sseService.reconnect();
    }
  }

  /// Clear recent events
  void clearEvents() {
    emit(state.copyWith(
      recentEvents: [],
      latestEvent: null,
      totalEventsReceived: 0,
      eventCounts: {},
    ));
  }

  /// Get events of a specific type
  List<SSEEvent> getEventsByType(String type) {
    return state.recentEvents.where((event) => event.type == type).toList();
  }

  /// Get count for a specific event type
  int getEventCount(String type) {
    return state.eventCounts[type] ?? 0;
  }

  @override
  Future<void> close() async {
    await _eventSubscription?.cancel();
    await _stateSubscription?.cancel();
    await _errorSubscription?.cancel();
    await disconnect();
    return super.close();
  }
}
