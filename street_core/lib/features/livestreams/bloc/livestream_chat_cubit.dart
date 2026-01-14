// lib/features/livestreams/bloc/livestream_chat_cubit.dart

import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:street_core/features/livestreams/models/models.dart';
import 'package:street_core/features/livestreams/services/livestream_service.dart';
import 'package:street_core/features/livestreams/services/livestream_socket_service.dart';
import 'package:street_core/core/helpers/logger.dart';

/// Chat state
abstract class LiveStreamChatState extends Equatable {
  const LiveStreamChatState();

  @override
  List<Object?> get props => [];
}

class LiveStreamChatInitial extends LiveStreamChatState {
  const LiveStreamChatInitial();
}

class LiveStreamChatLoading extends LiveStreamChatState {
  const LiveStreamChatLoading();
}

class LiveStreamChatLoaded extends LiveStreamChatState {
  final List<ChatMessage> messages;
  final ChatMessage? pinnedMessage;
  final bool hasMore;
  final bool isSending;

  const LiveStreamChatLoaded({
    required this.messages,
    this.pinnedMessage,
    this.hasMore = true,
    this.isSending = false,
  });

  LiveStreamChatLoaded copyWith({
    List<ChatMessage>? messages,
    ChatMessage? pinnedMessage,
    bool? hasMore,
    bool? isSending,
  }) {
    return LiveStreamChatLoaded(
      messages: messages ?? this.messages,
      pinnedMessage: pinnedMessage ?? this.pinnedMessage,
      hasMore: hasMore ?? this.hasMore,
      isSending: isSending ?? this.isSending,
    );
  }

  @override
  List<Object?> get props => [messages, pinnedMessage, hasMore, isSending];
}

class LiveStreamChatError extends LiveStreamChatState {
  final String message;

  const LiveStreamChatError({required this.message});

  @override
  List<Object?> get props => [message];
}

/// Cubit for managing livestream chat
class LiveStreamChatCubit extends Cubit<LiveStreamChatState> {
  final LiveStreamService _service;
  final LiveStreamSocketService _socketService;
  final String streamId;

  StreamSubscription? _chatSubscription;
  int _currentPage = 1;
  static const int _pageSize = 50;

  LiveStreamChatCubit({
    required LiveStreamService service,
    required LiveStreamSocketService socketService,
    required this.streamId,
  })  : _service = service,
        _socketService = socketService,
        super(const LiveStreamChatInitial());

  /// Initialize chat
  Future<void> initialize() async {
    try {
      emit(const LiveStreamChatLoading());

      // Load initial messages
      final messages = await _service.getChatMessages(
        streamId: streamId,
        page: _currentPage,
        limit: _pageSize,
      );

      // Subscribe to real-time messages
      _subscribeToMessages();

      emit(LiveStreamChatLoaded(
        messages: messages.reversed.toList(), // Reverse to show newest at bottom
        hasMore: messages.length >= _pageSize,
      ));
    } catch (e) {
      emit(LiveStreamChatError(message: e.toString()));
    }
  }

  /// Subscribe to real-time chat messages
  void _subscribeToMessages() {
    _chatSubscription = _socketService.chatMessages.listen(
      (message) {
        final currentState = state;
        if (currentState is LiveStreamChatLoaded) {
          final updatedMessages = [...currentState.messages, message];

          // Keep only last 100 messages in memory
          if (updatedMessages.length > 100) {
            updatedMessages.removeRange(0, updatedMessages.length - 100);
          }

          emit(currentState.copyWith(messages: updatedMessages));
        }
      },
    );
  }

  /// Send a message
  Future<void> sendMessage(String message) async {
    final currentState = state;
    if (currentState is! LiveStreamChatLoaded) return;

    try {
      // Mark as sending
      emit(currentState.copyWith(isSending: true));

      // Send via Socket.IO (for immediate feedback)
      _socketService.sendChatMessage(message);

      // Also send via API (for persistence)
      await _service.sendChatMessage(
        streamId: streamId,
        message: message,
      );

      // Mark as not sending
      emit(currentState.copyWith(isSending: false));
    } catch (e) {
      emit(currentState.copyWith(isSending: false));
      // Optionally show error
      AppLogger.error('Error sending chat message', error: e, tag: 'LiveStreamChat');
    }
  }

  /// Load more messages (pagination)
  Future<void> loadMore() async {
    final currentState = state;
    if (currentState is! LiveStreamChatLoaded || !currentState.hasMore) return;

    try {
      _currentPage++;
      final messages = await _service.getChatMessages(
        streamId: streamId,
        page: _currentPage,
        limit: _pageSize,
      );

      if (messages.isEmpty) {
        emit(currentState.copyWith(hasMore: false));
        return;
      }

      final updatedMessages = [
        ...messages.reversed,
        ...currentState.messages,
      ];

      emit(currentState.copyWith(
        messages: updatedMessages,
        hasMore: messages.length >= _pageSize,
      ));
    } catch (e) {
      AppLogger.error('Error loading more chat messages', error: e, tag: 'LiveStreamChat');
    }
  }

  @override
  Future<void> close() {
    _chatSubscription?.cancel();
    return super.close();
  }
}
