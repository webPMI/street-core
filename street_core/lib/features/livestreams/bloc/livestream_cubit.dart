// lib/features/livestreams/bloc/livestream_cubit.dart

import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:street_core/features/livestreams/bloc/livestream_state.dart';
import 'package:street_core/features/livestreams/services/livestream_service.dart';
import 'package:street_core/features/livestreams/services/livestream_socket_service.dart';

/// Cubit for managing livestream state
class LiveStreamCubit extends Cubit<LiveStreamState> {
  final LiveStreamService _service;
  final LiveStreamSocketService _socketService;

  StreamSubscription? _viewerCountSubscription;
  StreamSubscription? _streamStatusSubscription;
  Timer? _durationTimer;

  LiveStreamCubit({
    required LiveStreamService service,
    required LiveStreamSocketService socketService,
  })  : _service = service,
        _socketService = socketService,
        super(const LiveStreamInitial());

  /// Load and join a stream as viewer
  Future<void> joinStream(String streamId) async {
    try {
      emit(const LiveStreamLoading());

      // Join via API
      final joinResponse = await _service.joinStream(streamId);

      // Connect to Socket.IO
      await _socketService.connect(streamId);

      // Subscribe to real-time updates
      _subscribeToUpdates();

      // Start duration timer
      _startDurationTimer();

      emit(LiveStreamLoaded(
        stream: joinResponse.stream,
        joinResponse: joinResponse,
        viewerCount: joinResponse.stream.viewerCount,
        duration: Duration.zero,
        isHost: false,
      ));
    } catch (e) {
      emit(LiveStreamError(message: e.toString()));
    }
  }

  /// Load stream as host
  Future<void> loadStreamAsHost(String streamId) async {
    try {
      emit(const LiveStreamLoading());

      // Get stream
      final stream = await _service.getLiveStream(streamId);

      // Connect to Socket.IO
      await _socketService.connect(streamId);

      // Subscribe to real-time updates
      _subscribeToUpdates();

      // Start duration timer
      _startDurationTimer();

      emit(LiveStreamLoaded(
        stream: stream,
        viewerCount: stream.viewerCount,
        duration: stream.durationSeconds != null
            ? Duration(seconds: stream.durationSeconds!)
            : Duration.zero,
        isHost: true,
      ));
    } catch (e) {
      emit(LiveStreamError(message: e.toString()));
    }
  }

  /// Start a scheduled stream
  Future<void> startStream(String streamId) async {
    try {
      await _service.startLiveStream(streamId);

      // Reload stream
      await loadStreamAsHost(streamId);
    } catch (e) {
      emit(LiveStreamError(message: e.toString()));
    }
  }

  /// End a live stream
  Future<void> endStream({bool saveRecording = false}) async {
    final currentState = state;
    if (currentState is! LiveStreamLoaded) return;

    try {
      await _service.endLiveStream(
        currentState.stream.id,
        saveRecording: saveRecording,
      );

      // Get final stats
      final stats = await _service.getStreamStats(currentState.stream.id);

      // Disconnect
      await _socketService.disconnect();

      emit(LiveStreamEnded(
        stream: currentState.stream,
        stats: stats,
      ));
    } catch (e) {
      emit(LiveStreamError(message: e.toString()));
    }
  }

  /// Leave stream as viewer
  Future<void> leaveStream() async {
    final currentState = state;
    if (currentState is! LiveStreamLoaded) return;

    try {
      await _service.leaveStream(currentState.stream.id);
      await _socketService.disconnect();

      emit(const LiveStreamInitial());
    } catch (e) {
      // Even on error, disconnect and reset
      await _socketService.disconnect();
      emit(const LiveStreamInitial());
    }
  }

  /// Subscribe to real-time updates
  void _subscribeToUpdates() {
    // Viewer count updates
    _viewerCountSubscription = _socketService.viewerCount.listen(
      (count) {
        final currentState = state;
        if (currentState is LiveStreamLoaded) {
          emit(currentState.copyWith(viewerCount: count));
        }
      },
    );

    // Stream status updates
    _streamStatusSubscription = _socketService.streamStatus.listen(
      (status) async {
        if (status == 'ended') {
          final currentState = state;
          if (currentState is LiveStreamLoaded) {
            // Get final stats
            final stats = await _service.getStreamStats(currentState.stream.id);

            emit(LiveStreamEnded(
              stream: currentState.stream,
              stats: stats,
            ));
          }
        }
      },
    );
  }

  /// Start duration timer
  void _startDurationTimer() {
    _durationTimer?.cancel();
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final currentState = state;
      if (currentState is LiveStreamLoaded) {
        emit(currentState.copyWith(
          duration: currentState.duration + const Duration(seconds: 1),
        ));
      }
    });
  }

  @override
  Future<void> close() {
    _viewerCountSubscription?.cancel();
    _streamStatusSubscription?.cancel();
    _durationTimer?.cancel();
    _socketService.disconnect();
    return super.close();
  }
}
