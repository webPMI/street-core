// lib/features/livestreams/models/chat_message.dart

import 'package:equatable/equatable.dart';

/// Chat message in a livestream
class ChatMessage extends Equatable {
  final String id;
  final String streamId;
  final String userId;
  final String username;
  final String? avatarUrl;
  final String message;
  final DateTime createdAt;
  final bool isPinned;

  const ChatMessage({
    required this.id,
    required this.streamId,
    required this.userId,
    required this.username,
    this.avatarUrl,
    required this.message,
    required this.createdAt,
    this.isPinned = false,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] as String,
      streamId: json['stream_id'] as String,
      userId: json['user_id'] as String,
      username: json['username'] as String,
      avatarUrl: json['avatar_url'] as String?,
      message: json['message'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      isPinned: json['is_pinned'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'stream_id': streamId,
      'user_id': userId,
      'username': username,
      'avatar_url': avatarUrl,
      'message': message,
      'created_at': createdAt.toIso8601String(),
      'is_pinned': isPinned,
    };
  }

  ChatMessage copyWith({
    String? id,
    String? streamId,
    String? userId,
    String? username,
    String? avatarUrl,
    String? message,
    DateTime? createdAt,
    bool? isPinned,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      streamId: streamId ?? this.streamId,
      userId: userId ?? this.userId,
      username: username ?? this.username,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      message: message ?? this.message,
      createdAt: createdAt ?? this.createdAt,
      isPinned: isPinned ?? this.isPinned,
    );
  }

  @override
  List<Object?> get props => [
        id,
        streamId,
        userId,
        username,
        avatarUrl,
        message,
        createdAt,
        isPinned,
      ];
}
