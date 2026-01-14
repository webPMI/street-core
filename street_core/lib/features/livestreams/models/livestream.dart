// lib/features/livestreams/models/livestream.dart

import 'package:equatable/equatable.dart';

/// LiveStream status enum
enum LiveStreamStatus {
  scheduled,
  live,
  ended,
  cancelled;

  static LiveStreamStatus fromString(String status) {
    switch (status.toLowerCase()) {
      case 'scheduled':
        return LiveStreamStatus.scheduled;
      case 'live':
        return LiveStreamStatus.live;
      case 'ended':
        return LiveStreamStatus.ended;
      case 'cancelled':
        return LiveStreamStatus.cancelled;
      default:
        return LiveStreamStatus.scheduled;
    }
  }

  String get displayName {
    switch (this) {
      case LiveStreamStatus.scheduled:
        return 'Programado';
      case LiveStreamStatus.live:
        return 'En vivo';
      case LiveStreamStatus.ended:
        return 'Finalizado';
      case LiveStreamStatus.cancelled:
        return 'Cancelado';
    }
  }
}

/// LiveStream model
class LiveStream extends Equatable {
  final String id;
  final String title;
  final String description;
  final String? thumbnailUrl;
  final String hostId;
  final String hostName;
  final LiveStreamStatus status;
  final DateTime? scheduledTime;
  final DateTime? startedAt;
  final DateTime? endedAt;
  final int viewerCount;
  final int peakViewers;
  final int totalViews;
  final int reactionCount;
  final int messageCount;
  final List<String> tags;
  final DateTime createdAt;

  const LiveStream({
    required this.id,
    required this.title,
    required this.description,
    this.thumbnailUrl,
    required this.hostId,
    required this.hostName,
    required this.status,
    this.scheduledTime,
    this.startedAt,
    this.endedAt,
    required this.viewerCount,
    required this.peakViewers,
    required this.totalViews,
    required this.reactionCount,
    required this.messageCount,
    required this.tags,
    required this.createdAt,
  });

  /// Create from JSON
  factory LiveStream.fromJson(Map<String, dynamic> json) {
    return LiveStream(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String? ?? '',
      thumbnailUrl: json['thumbnail_url'] as String?,
      hostId: json['host_id'] as String,
      hostName: json['host_name'] as String? ?? 'Unknown',
      status: LiveStreamStatus.fromString(json['status'] as String),
      scheduledTime: json['scheduled_time'] != null
          ? DateTime.parse(json['scheduled_time'] as String)
          : null,
      startedAt: json['started_at'] != null
          ? DateTime.parse(json['started_at'] as String)
          : null,
      endedAt: json['ended_at'] != null
          ? DateTime.parse(json['ended_at'] as String)
          : null,
      viewerCount: json['viewer_count'] as int? ?? 0,
      peakViewers: json['peak_viewers'] as int? ?? 0,
      totalViews: json['total_views'] as int? ?? 0,
      reactionCount: json['reaction_count'] as int? ?? 0,
      messageCount: json['message_count'] as int? ?? 0,
      tags: (json['tags'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'thumbnail_url': thumbnailUrl,
      'host_id': hostId,
      'host_name': hostName,
      'status': status.name,
      'scheduled_time': scheduledTime?.toIso8601String(),
      'started_at': startedAt?.toIso8601String(),
      'ended_at': endedAt?.toIso8601String(),
      'viewer_count': viewerCount,
      'peak_viewers': peakViewers,
      'total_views': totalViews,
      'reaction_count': reactionCount,
      'message_count': messageCount,
      'tags': tags,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// Copy with
  LiveStream copyWith({
    String? id,
    String? title,
    String? description,
    String? thumbnailUrl,
    String? hostId,
    String? hostName,
    LiveStreamStatus? status,
    DateTime? scheduledTime,
    DateTime? startedAt,
    DateTime? endedAt,
    int? viewerCount,
    int? peakViewers,
    int? totalViews,
    int? reactionCount,
    int? messageCount,
    List<String>? tags,
    DateTime? createdAt,
  }) {
    return LiveStream(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      hostId: hostId ?? this.hostId,
      hostName: hostName ?? this.hostName,
      status: status ?? this.status,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      viewerCount: viewerCount ?? this.viewerCount,
      peakViewers: peakViewers ?? this.peakViewers,
      totalViews: totalViews ?? this.totalViews,
      reactionCount: reactionCount ?? this.reactionCount,
      messageCount: messageCount ?? this.messageCount,
      tags: tags ?? this.tags,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Check if stream is live
  bool get isLive => status == LiveStreamStatus.live;

  /// Check if stream is scheduled
  bool get isScheduled => status == LiveStreamStatus.scheduled;

  /// Check if stream is ended
  bool get isEnded => status == LiveStreamStatus.ended;

  /// Check if stream is cancelled
  bool get isCancelled => status == LiveStreamStatus.cancelled;

  /// Get duration in seconds (if ended)
  int? get durationSeconds {
    if (startedAt == null) return null;
    final end = endedAt ?? DateTime.now();
    return end.difference(startedAt!).inSeconds;
  }

  /// Get formatted duration
  String get durationFormatted {
    final duration = durationSeconds;
    if (duration == null) return '--:--:--';

    final hours = duration ~/ 3600;
    final minutes = (duration % 3600) ~/ 60;
    final seconds = duration % 60;

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  List<Object?> get props => [
        id,
        title,
        description,
        thumbnailUrl,
        hostId,
        hostName,
        status,
        scheduledTime,
        startedAt,
        endedAt,
        viewerCount,
        peakViewers,
        totalViews,
        reactionCount,
        messageCount,
        tags,
        createdAt,
      ];
}

/// Join stream response model
class JoinStreamResponse extends Equatable {
  final LiveStream stream;
  final String channelName;
  final String token;
  final int uid;
  final String appId;
  final String? recordingUrl;

  const JoinStreamResponse({
    required this.stream,
    required this.channelName,
    required this.token,
    required this.uid,
    required this.appId,
    this.recordingUrl,
  });

  factory JoinStreamResponse.fromJson(Map<String, dynamic> json) {
    return JoinStreamResponse(
      stream: LiveStream.fromJson(json['stream'] as Map<String, dynamic>),
      channelName: json['channel_name'] as String,
      token: json['token'] as String,
      uid: json['uid'] as int,
      appId: json['app_id'] as String,
      recordingUrl: json['recording_url'] as String?,
    );
  }

  @override
  List<Object?> get props => [stream, channelName, token, uid, appId, recordingUrl];
}

/// Stream statistics model
class StreamStats extends Equatable {
  final String streamId;
  final int currentViewers;
  final int peakViewers;
  final int totalViews;
  final int reactionCount;
  final int messageCount;
  final int duration;

  const StreamStats({
    required this.streamId,
    required this.currentViewers,
    required this.peakViewers,
    required this.totalViews,
    required this.reactionCount,
    required this.messageCount,
    required this.duration,
  });

  factory StreamStats.fromJson(Map<String, dynamic> json) {
    return StreamStats(
      streamId: json['stream_id'] as String,
      currentViewers: json['current_viewers'] as int? ?? 0,
      peakViewers: json['peak_viewers'] as int? ?? 0,
      totalViews: json['total_views'] as int? ?? 0,
      reactionCount: json['reaction_count'] as int? ?? 0,
      messageCount: json['message_count'] as int? ?? 0,
      duration: json['duration'] as int? ?? 0,
    );
  }

  String get durationFormatted {
    final hours = duration ~/ 3600;
    final minutes = (duration % 3600) ~/ 60;
    final seconds = duration % 60;

    if (hours > 0) {
      return '${hours}h ${minutes}m ${seconds}s';
    }
    return '${minutes}m ${seconds}s';
  }

  @override
  List<Object?> get props => [
        streamId,
        currentViewers,
        peakViewers,
        totalViews,
        reactionCount,
        messageCount,
        duration,
      ];
}
