/// Round Model - Competition round structure.
/// Following Monolith-by-Features architecture (ADR-005).

import 'package:equatable/equatable.dart';

import 'rider_score.dart';

// =============================================================================
// ROUND
// =============================================================================

class Round extends Equatable {
  const Round({
    required this.id,
    required this.competitionId,
    required this.name,
    required this.roundNumber,
    this.scores = const [],
    this.isCompleted = false,
    this.startTime,
    this.endTime,
    this.hasHeats = false,
    this.heatIds = const [],
    this.currentHeat = 0,
    this.totalHeats = 0,
  });

  factory Round.fromJson(Map<String, dynamic> json) {
    return Round(
      id: json['id'] as String,
      competitionId: json['competitionId'] as String,
      name: json['name'] as String,
      roundNumber: json['roundNumber'] as int,
      scores: (json['scores'] as List<dynamic>?)
              ?.map((e) => RiderScore.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      isCompleted: json['isCompleted'] as bool? ?? false,
      startTime: json['startTime'] != null
          ? DateTime.parse(json['startTime'] as String)
          : null,
      endTime: json['endTime'] != null
          ? DateTime.parse(json['endTime'] as String)
          : null,
      hasHeats: json['hasHeats'] as bool? ?? false,
      heatIds: (json['heatIds'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      currentHeat: json['currentHeat'] as int? ?? 0,
      totalHeats: json['totalHeats'] as int? ?? 0,
    );
  }

  final String id;
  final String competitionId;
  final String name;
  final int roundNumber;
  final List<RiderScore> scores;
  final bool isCompleted;
  final DateTime? startTime;
  final DateTime? endTime;

  // Heat configuration
  final bool hasHeats;
  final List<String> heatIds;
  final int currentHeat; // Index of currently active heat
  final int totalHeats;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'competitionId': competitionId,
      'name': name,
      'roundNumber': roundNumber,
      'scores': scores.map((e) => e.toJson()).toList(),
      'isCompleted': isCompleted,
      'startTime': startTime?.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'hasHeats': hasHeats,
      'heatIds': heatIds,
      'currentHeat': currentHeat,
      'totalHeats': totalHeats,
    };
  }

  /// Check if this round uses heats
  bool get usesHeats => hasHeats && heatIds.isNotEmpty;

  /// Get heat progress percentage
  double get heatProgress {
    if (totalHeats == 0) return 0.0;
    return (currentHeat / totalHeats) * 100;
  }

  @override
  List<Object?> get props => [
        id,
        competitionId,
        name,
        roundNumber,
        scores,
        isCompleted,
        hasHeats,
        heatIds,
        currentHeat,
        totalHeats,
      ];
}
