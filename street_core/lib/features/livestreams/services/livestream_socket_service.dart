// lib/features/livestreams/services/livestream_socket_service.dart

import 'dart:async';

import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:street_core/core/services/api_service.dart';
import 'package:street_core/core/helpers/logger.dart';
import 'package:street_core/features/livestreams/models/models.dart';

/// Socket.IO service for real-time livestream events
///
/// Handles:
/// - Chat messages
/// - Reactions
/// - Viewer updates
/// - Stream status changes
class LiveStreamSocketService {
  io.Socket? _socket;
  final ApiService _apiService;
  String? _currentStreamId;

  // Stream controllers for events
  final _chatMessageController = StreamController<ChatMessage>.broadcast();
  final _reactionController = StreamController<StreamReaction>.broadcast();
  final _viewerCountController = StreamController<int>.broadcast();
  final _streamStatusController = StreamController<String>.broadcast();

  // Public streams
  Stream<ChatMessage> get chatMessages => _chatMessageController.stream;
  Stream<StreamReaction> get reactions => _reactionController.stream;
  Stream<int> get viewerCount => _viewerCountController.stream;
  Stream<String> get streamStatus => _streamStatusController.stream;

  LiveStreamSocketService(this._apiService);

  /// Connect to a livestream
  Future<void> connect(String streamId) async {
    if (_socket != null && _socket!.connected) {
      if (_currentStreamId == streamId) return; // Already connected
      await disconnect(); // Disconnect from previous stream
    }

    _currentStreamId = streamId;

    // Get base URL from API service
    final baseUrl = await _apiService.baseUrl;
    final token = await _apiService.token;

    // Create socket connection
    _socket = io.io(
      baseUrl,
      io.OptionBuilder()
          .setTransports(['websocket']) // Use WebSocket transport
          .enableAutoConnect()
          .setAuth({'token': token}) // Send auth token
          .build(),
    );

    // Setup event listeners
    _setupEventListeners();

    // Join stream room
    _socket!.emit('join_stream', {'stream_id': streamId});
  }

  /// Disconnect from current livestream
  Future<void> disconnect() async {
    if (_socket != null && _currentStreamId != null) {
      _socket!.emit('leave_stream', {'stream_id': _currentStreamId});
      _socket!.disconnect();
      _socket!.dispose();
      _socket = null;
      _currentStreamId = null;
    }
  }

  /// Setup event listeners
  void _setupEventListeners() {
    if (_socket == null) return;

    // Connection events
    _socket!.on('connect', (_) {
      AppLogger.info('Socket connected', tag: 'LiveStreamSocket');
    });

    _socket!.on('disconnect', (_) {
      AppLogger.info('Socket disconnected', tag: 'LiveStreamSocket');
    });

    _socket!.on('error', (error) {
      AppLogger.error('Socket error', error: error, tag: 'LiveStreamSocket');
    });

    // Chat message received
    _socket!.on('chat_message', (data) {
      try {
        final message = ChatMessage.fromJson(data as Map<String, dynamic>);
        _chatMessageController.add(message);
      } catch (e) {
        AppLogger.error('Error parsing chat message', error: e, tag: 'LiveStreamSocket');
      }
    });

    // Reaction received
    _socket!.on('reaction', (data) {
      try {
        final reaction = StreamReaction.fromJson(data as Map<String, dynamic>);
        _reactionController.add(reaction);
      } catch (e) {
        AppLogger.error('Error parsing reaction', error: e, tag: 'LiveStreamSocket');
      }
    });

    // Viewer count update
    _socket!.on('viewer_count', (data) {
      try {
        final count = data as int;
        _viewerCountController.add(count);
      } catch (e) {
        AppLogger.error('Error parsing viewer count', error: e, tag: 'LiveStreamSocket');
      }
    });

    // Stream status change
    _socket!.on('stream_status', (data) {
      try {
        final status = data['status'] as String;
        _streamStatusController.add(status);
      } catch (e) {
        AppLogger.error('Error parsing stream status', error: e, tag: 'LiveStreamSocket');
      }
    });

    // User joined
    _socket!.on('user_joined', (data) {
      AppLogger.debug('User joined: ${data['username']}', tag: 'LiveStreamSocket');
    });

    // User left
    _socket!.on('user_left', (data) {
      AppLogger.debug('User left: ${data['username']}', tag: 'LiveStreamSocket');
    });
  }

  /// Send a chat message
  void sendChatMessage(String message) {
    if (_socket == null || !_socket!.connected) {
      throw Exception('Socket not connected');
    }

    _socket!.emit('chat_message', {
      'stream_id': _currentStreamId,
      'message': message,
    });
  }

  /// Send a reaction
  void sendReaction(ReactionType type) {
    if (_socket == null || !_socket!.connected) {
      throw Exception('Socket not connected');
    }

    _socket!.emit('reaction', {
      'stream_id': _currentStreamId,
      'type': type.name,
    });
  }

  /// Check if connected
  bool get isConnected => _socket != null && _socket!.connected;

  /// Get current stream ID
  String? get currentStreamId => _currentStreamId;

  /// Dispose resources
  void dispose() {
    disconnect();
    _chatMessageController.close();
    _reactionController.close();
    _viewerCountController.close();
    _streamStatusController.close();
  }
}
