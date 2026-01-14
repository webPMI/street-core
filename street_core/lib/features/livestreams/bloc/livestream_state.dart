// lib/features/livestreams/bloc/livestream_state.dart

import 'package:equatable/equatable.dart';
import 'package:street_core/features/livestreams/models/models.dart';

/// LiveStream state
abstract class LiveStreamState extends Equatable {
  const LiveStreamState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class LiveStreamInitial extends LiveStreamState {
  const LiveStreamInitial();
}

/// Loading state
class LiveStreamLoading extends LiveStreamState {
  const LiveStreamLoading();
}

/// Loaded state (viewing a stream)
class LiveStreamLoaded extends LiveStreamState {
  final LiveStream stream;
  final JoinStreamResponse? joinResponse;
  final int viewerCount;
  final Duration duration;
  final bool isHost;

  const LiveStreamLoaded({
    required this.stream,
    this.joinResponse,
    required this.viewerCount,
    required this.duration,
    this.isHost = false,
  });

  LiveStreamLoaded copyWith({
    LiveStream? stream,
    JoinStreamResponse? joinResponse,
    int? viewerCount,
    Duration? duration,
    bool? isHost,
  }) {
    return LiveStreamLoaded(
      stream: stream ?? this.stream,
      joinResponse: joinResponse ?? this.joinResponse,
      viewerCount: viewerCount ?? this.viewerCount,
      duration: duration ?? this.duration,
      isHost: isHost ?? this.isHost,
    );
  }

  @override
  List<Object?> get props => [stream, joinResponse, viewerCount, duration, isHost];
}

/// Error state
class LiveStreamError extends LiveStreamState {
  final String message;
  final String? errorCode;

  const LiveStreamError({
    required this.message,
    this.errorCode,
  });

  @override
  List<Object?> get props => [message, errorCode];
}

/// Stream ended state
class LiveStreamEnded extends LiveStreamState {
  final LiveStream stream;
  final StreamStats? stats;

  const LiveStreamEnded({
    required this.stream,
    this.stats,
  });

  @override
  List<Object?> get props => [stream, stats];
}
