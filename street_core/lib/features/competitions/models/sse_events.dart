// SSE Event Models for Real-Time Speaker Dashboard
// Maps to backend SSE payloads from BLOQUE 3

import 'package:equatable/equatable.dart';

/// SSE Event Type Constants
/// Prevents magic strings in code
class SSEEventTypes {
  SSEEventTypes._();

  static const String connected = 'connected';
  static const String emergency = 'emergency';
  static const String scoreReset = 'score_reset';
  static const String scoreSwap = 'score_swap';
  static const String scoreOverride = 'score_override';
  static const String scoreUnderReview = 'score_under_review';
  static const String heatOrderChange = 'heat_order_change';
  static const String athleteRemoved = 'athlete_removed';
}

/// Base class for all SSE events
abstract class SSEEvent extends Equatable {
  final String type;
  final String priority;
  final String competitionId;
  final String? heatId;
  final String message;
  final DateTime timestamp;

  const SSEEvent({
    required this.type,
    required this.priority,
    required this.competitionId,
    this.heatId,
    required this.message,
    required this.timestamp,
  });

  /// Factory to create the appropriate SSEEvent subclass from JSON
  factory SSEEvent.fromJson(Map<String, dynamic> json) {
    final type = json['type'] as String;

    switch (type) {
      case SSEEventTypes.connected:
        return ConnectedEvent.fromJson(json);
      case SSEEventTypes.emergency:
        return EmergencyEvent.fromJson(json);
      case SSEEventTypes.scoreReset:
        return ScoreResetEvent.fromJson(json);
      case SSEEventTypes.scoreSwap:
        return ScoreSwapEvent.fromJson(json);
      case SSEEventTypes.scoreOverride:
        return ScoreOverrideEvent.fromJson(json);
      case SSEEventTypes.scoreUnderReview:
        return ScoreUnderReviewEvent.fromJson(json);
      case SSEEventTypes.heatOrderChange:
        return HeatOrderChangeEvent.fromJson(json);
      case SSEEventTypes.athleteRemoved:
        return AthleteRemovedEvent.fromJson(json);
      default:
        return GenericSSEEvent.fromJson(json);
    }
  }

  @override
  List<Object?> get props => [type, priority, competitionId, heatId, message, timestamp];
}

/// Connected event - initial handshake
class ConnectedEvent extends SSEEvent {
  const ConnectedEvent({
    required super.competitionId,
    required super.message,
    required super.timestamp,
  }) : super(
          type: SSEEventTypes.connected,
          priority: 'INFO',
        );

  factory ConnectedEvent.fromJson(Map<String, dynamic> json) {
    return ConnectedEvent(
      competitionId: json['competitionId'] as String,
      message: json['message'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }
}

/// Emergency broadcast (CRITICAL priority)
class EmergencyEvent extends SSEEvent {
  final String subject;
  final String targetRole;
  final bool actionNeeded;

  const EmergencyEvent({
    required super.priority,
    required super.competitionId,
    super.heatId,
    required super.message,
    required super.timestamp,
    required this.subject,
    required this.targetRole,
    required this.actionNeeded,
  }) : super(type: SSEEventTypes.emergency);

  factory EmergencyEvent.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? {};

    return EmergencyEvent(
      priority: json['priority'] as String,
      competitionId: json['competitionId'] as String,
      heatId: json['heatId'] as String?,
      message: json['message'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      subject: data['subject'] as String? ?? '',
      targetRole: data['targetRole'] as String? ?? '',
      actionNeeded: data['actionNeeded'] as bool? ?? false,
    );
  }

  @override
  List<Object?> get props => [...super.props, subject, targetRole, actionNeeded];
}

/// Score reset event (athlete re-run authorized)
class ScoreResetEvent extends SSEEvent {
  final String athleteId;
  final String action;

  const ScoreResetEvent({
    required super.competitionId,
    required super.heatId,
    required super.message,
    required super.timestamp,
    required this.athleteId,
    required this.action,
  }) : super(
          type: SSEEventTypes.scoreReset,
          priority: 'CRITICAL',
        );

  factory ScoreResetEvent.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? {};

    return ScoreResetEvent(
      competitionId: json['competitionId'] as String,
      heatId: json['heatId'] as String,
      message: json['message'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      athleteId: data['athleteId'] as String,
      action: data['action'] as String,
    );
  }

  @override
  List<Object?> get props => [...super.props, athleteId, action];
}

/// Score swap event (scores swapped between athletes)
class ScoreSwapEvent extends SSEEvent {
  final String athlete1Id;
  final String athlete2Id;
  final String reason;
  final String action;

  const ScoreSwapEvent({
    required super.competitionId,
    required super.heatId,
    required super.message,
    required super.timestamp,
    required this.athlete1Id,
    required this.athlete2Id,
    required this.reason,
    required this.action,
  }) : super(
          type: SSEEventTypes.scoreSwap,
          priority: 'CRITICAL',
        );

  factory ScoreSwapEvent.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? {};

    return ScoreSwapEvent(
      competitionId: json['competitionId'] as String,
      heatId: json['heatId'] as String,
      message: json['message'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      athlete1Id: data['athlete1Id'] as String,
      athlete2Id: data['athlete2Id'] as String,
      reason: data['reason'] as String? ?? '',
      action: data['action'] as String,
    );
  }

  @override
  List<Object?> get props => [...super.props, athlete1Id, athlete2Id, reason, action];
}

/// Score override event (admin manual entry)
class ScoreOverrideEvent extends SSEEvent {
  final String scoreId;
  final String athleteId;
  final double originalScore;
  final double newScore;
  final String reason;
  final String action;

  const ScoreOverrideEvent({
    required super.competitionId,
    required super.heatId,
    required super.message,
    required super.timestamp,
    required this.scoreId,
    required this.athleteId,
    required this.originalScore,
    required this.newScore,
    required this.reason,
    required this.action,
  }) : super(
          type: SSEEventTypes.scoreOverride,
          priority: 'CRITICAL',
        );

  factory ScoreOverrideEvent.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? {};

    return ScoreOverrideEvent(
      competitionId: json['competitionId'] as String,
      heatId: json['heatId'] as String,
      message: json['message'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      scoreId: data['scoreId'] as String,
      athleteId: data['athleteId'] as String,
      originalScore: (data['originalScore'] as num).toDouble(),
      newScore: (data['newScore'] as num).toDouble(),
      reason: data['reason'] as String? ?? '',
      action: data['action'] as String,
    );
  }

  @override
  List<Object?> get props => [
        ...super.props,
        scoreId,
        athleteId,
        originalScore,
        newScore,
        reason,
        action
      ];
}

/// Score under review event (protest filed)
class ScoreUnderReviewEvent extends SSEEvent {
  final String scoreId;
  final String action;

  const ScoreUnderReviewEvent({
    required super.competitionId,
    required super.message,
    required super.timestamp,
    required this.scoreId,
    required this.action,
  }) : super(
          type: SSEEventTypes.scoreUnderReview,
          priority: 'WARNING',
        );

  factory ScoreUnderReviewEvent.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? {};

    return ScoreUnderReviewEvent(
      competitionId: json['competitionId'] as String,
      message: json['message'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      scoreId: data['scoreId'] as String,
      action: data['action'] as String,
    );
  }

  @override
  List<Object?> get props => [...super.props, scoreId, action];
}

/// Heat order change event
class HeatOrderChangeEvent extends SSEEvent {
  final List<String> newOrder;
  final String action;

  const HeatOrderChangeEvent({
    required super.competitionId,
    required super.heatId,
    required super.message,
    required super.timestamp,
    required this.newOrder,
    required this.action,
  }) : super(
          type: SSEEventTypes.heatOrderChange,
          priority: 'WARNING',
        );

  factory HeatOrderChangeEvent.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? {};
    final newOrderData = data['newOrder'] as List<dynamic>? ?? [];

    return HeatOrderChangeEvent(
      competitionId: json['competitionId'] as String,
      heatId: json['heatId'] as String,
      message: json['message'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      newOrder: newOrderData.map((e) => e.toString()).toList(),
      action: data['action'] as String,
    );
  }

  @override
  List<Object?> get props => [...super.props, newOrder, action];
}

/// Athlete removed from heat event
class AthleteRemovedEvent extends SSEEvent {
  final String athleteId;
  final String reason;
  final String action;

  const AthleteRemovedEvent({
    required super.competitionId,
    required super.heatId,
    required super.message,
    required super.timestamp,
    required this.athleteId,
    required this.reason,
    required this.action,
  }) : super(
          type: SSEEventTypes.athleteRemoved,
          priority: 'CRITICAL',
        );

  factory AthleteRemovedEvent.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? {};

    return AthleteRemovedEvent(
      competitionId: json['competitionId'] as String,
      heatId: json['heatId'] as String,
      message: json['message'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      athleteId: data['athleteId'] as String,
      reason: data['reason'] as String? ?? '',
      action: data['action'] as String,
    );
  }

  @override
  List<Object?> get props => [...super.props, athleteId, reason, action];
}

/// Generic SSE event for unknown types
class GenericSSEEvent extends SSEEvent {
  final Map<String, dynamic> data;

  const GenericSSEEvent({
    required super.type,
    required super.priority,
    required super.competitionId,
    super.heatId,
    required super.message,
    required super.timestamp,
    required this.data,
  });

  factory GenericSSEEvent.fromJson(Map<String, dynamic> json) {
    return GenericSSEEvent(
      type: json['type'] as String,
      priority: json['priority'] as String? ?? 'INFO',
      competitionId: json['competitionId'] as String,
      heatId: json['heatId'] as String?,
      message: json['message'] as String? ?? '',
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'] as String)
          : DateTime.now(),
      data: json['data'] as Map<String, dynamic>? ?? {},
    );
  }

  @override
  List<Object?> get props => [...super.props, data];
}

/// SSE connection state
enum SSEConnectionState {
  disconnected,
  connecting,
  connected,
  reconnecting,
  error,
}

/// SSE error types
class SSEError extends Equatable {
  final String message;
  final String? code;
  final DateTime timestamp;

  const SSEError({
    required this.message,
    this.code,
    required this.timestamp,
  });

  @override
  List<Object?> get props => [message, code, timestamp];
}
