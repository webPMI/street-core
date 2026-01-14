// lib/features/livestreams/models/stream_reaction.dart

import 'package:equatable/equatable.dart';

/// Reaction types
enum ReactionType {
  heart,
  fire,
  thumbsup,
  clap,
  star;

  static ReactionType fromString(String type) {
    switch (type.toLowerCase()) {
      case 'heart':
        return ReactionType.heart;
      case 'fire':
        return ReactionType.fire;
      case 'thumbsup':
        return ReactionType.thumbsup;
      case 'clap':
        return ReactionType.clap;
      case 'star':
        return ReactionType.star;
      default:
        return ReactionType.heart;
    }
  }

  String get emoji {
    switch (this) {
      case ReactionType.heart:
        return '❤️';
      case ReactionType.fire:
        return '🔥';
      case ReactionType.thumbsup:
        return '👍';
      case ReactionType.clap:
        return '👏';
      case ReactionType.star:
        return '⭐';
    }
  }

  String get displayName {
    switch (this) {
      case ReactionType.heart:
        return 'Corazón';
      case ReactionType.fire:
        return 'Fuego';
      case ReactionType.thumbsup:
        return 'Me gusta';
      case ReactionType.clap:
        return 'Aplauso';
      case ReactionType.star:
        return 'Estrella';
    }
  }
}

/// Stream reaction model
class StreamReaction extends Equatable {
  final String id;
  final String streamId;
  final String userId;
  final ReactionType type;
  final DateTime createdAt;

  const StreamReaction({
    required this.id,
    required this.streamId,
    required this.userId,
    required this.type,
    required this.createdAt,
  });

  factory StreamReaction.fromJson(Map<String, dynamic> json) {
    return StreamReaction(
      id: json['id'] as String,
      streamId: json['stream_id'] as String,
      userId: json['user_id'] as String,
      type: ReactionType.fromString(json['type'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'stream_id': streamId,
      'user_id': userId,
      'type': type.name,
      'created_at': createdAt.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [id, streamId, userId, type, createdAt];
}

/// Animated reaction for floating animations
class AnimatedReaction {
  final ReactionType type;
  final double x;
  final double y;
  final DateTime createdAt;

  AnimatedReaction({
    required this.type,
    required this.x,
    required this.y,
    required this.createdAt,
  });

  String get emoji => type.emoji;

  bool get isExpired {
    final duration = DateTime.now().difference(createdAt);
    return duration.inSeconds > 5; // Reactions disappear after 5 seconds
  }
}
