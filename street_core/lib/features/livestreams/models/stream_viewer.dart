// lib/features/livestreams/models/stream_viewer.dart

import 'package:equatable/equatable.dart';

/// Stream viewer model
class StreamViewer extends Equatable {
  final String userId;
  final String username;
  final String? avatarUrl;
  final DateTime joinedAt;
  final int duration; // in seconds

  const StreamViewer({
    required this.userId,
    required this.username,
    this.avatarUrl,
    required this.joinedAt,
    required this.duration,
  });

  factory StreamViewer.fromJson(Map<String, dynamic> json) {
    return StreamViewer(
      userId: json['user_id'] as String,
      username: json['username'] as String,
      avatarUrl: json['avatar_url'] as String?,
      joinedAt: DateTime.parse(json['joined_at'] as String),
      duration: json['duration'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'username': username,
      'avatar_url': avatarUrl,
      'joined_at': joinedAt.toIso8601String(),
      'duration': duration,
    };
  }

  /// Get formatted duration
  String get durationFormatted {
    final hours = duration ~/ 3600;
    final minutes = (duration % 3600) ~/ 60;
    final seconds = duration % 60;

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    }
    return '${seconds}s';
  }

  @override
  List<Object?> get props => [userId, username, avatarUrl, joinedAt, duration];
}
