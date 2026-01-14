// lib/features/livestreams/bloc/livestream_reactions_cubit.dart

import 'dart:async';
import 'dart:math';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:street_core/features/livestreams/models/models.dart';
import 'package:street_core/features/livestreams/services/livestream_service.dart';
import 'package:street_core/features/livestreams/services/livestream_socket_service.dart';

import '../../../core/helpers/logger.dart';

/// Reactions state
class LiveStreamReactionsState extends Equatable {
  final List<AnimatedReaction> reactions;
  final bool isSending;

  const LiveStreamReactionsState({
    this.reactions = const [],
    this.isSending = false,
  });

  LiveStreamReactionsState copyWith({
    List<AnimatedReaction>? reactions,
    bool? isSending,
  }) {
    return LiveStreamReactionsState(
      reactions: reactions ?? this.reactions,
      isSending: isSending ?? this.isSending,
    );
  }

  @override
  List<Object?> get props => [reactions, isSending];
}

/// Cubit for managing livestream reactions
class LiveStreamReactionsCubit extends Cubit<LiveStreamReactionsState> {
  final LiveStreamService _service;
  final LiveStreamSocketService _socketService;
  final String streamId;
  final double screenWidth;
  final double screenHeight;

  StreamSubscription? _reactionSubscription;
  Timer? _cleanupTimer;

  LiveStreamReactionsCubit({
    required LiveStreamService service,
    required LiveStreamSocketService socketService,
    required this.streamId,
    required this.screenWidth,
    required this.screenHeight,
  })  : _service = service,
        _socketService = socketService,
        super(const LiveStreamReactionsState()) {
    _initialize();
  }

  /// Initialize reactions
  void _initialize() {
    // Subscribe to real-time reactions
    _reactionSubscription = _socketService.reactions.listen(
      _handleReaction,
    );

    // Cleanup expired reactions periodically
    _cleanupTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _cleanupExpiredReactions();
    });
  }

  /// Handle incoming reaction
  void _handleReaction(StreamReaction reaction) {
    final random = Random();

    // Random position at bottom of screen
    final x = random.nextDouble() * (screenWidth * 0.7);
    final y = screenHeight - 150;

    final animatedReaction = AnimatedReaction(
      type: reaction.type,
      x: x,
      y: y,
      createdAt: DateTime.now(),
    );

    final updatedReactions = [...state.reactions, animatedReaction];
    emit(state.copyWith(reactions: updatedReactions));
  }

  /// Send a reaction
  Future<void> sendReaction(ReactionType type) async {
    try {
      emit(state.copyWith(isSending: true));

      // Send via Socket.IO (for immediate feedback)
      _socketService.sendReaction(type);

      // Also send via API (for persistence and counting)
      await _service.sendReaction(
        streamId: streamId,
        type: type,
      );

      emit(state.copyWith(isSending: false));
    } catch (e) {
      emit(state.copyWith(isSending: false));
    AppLogger.error('Error sending reaction: $e');
    }
  }

  /// Cleanup expired reactions
  void _cleanupExpiredReactions() {
    final activeReactions = state.reactions
        .where((reaction) => !reaction.isExpired)
        .toList();

    if (activeReactions.length != state.reactions.length) {
      emit(state.copyWith(reactions: activeReactions));
    }
  }

  /// Clear all reactions
  void clearReactions() {
    emit(state.copyWith(reactions: []));
  }

  @override
  Future<void> close() {
    _reactionSubscription?.cancel();
    _cleanupTimer?.cancel();
    return super.close();
  }
}
