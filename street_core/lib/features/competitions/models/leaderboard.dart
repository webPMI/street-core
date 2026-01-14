/// Leaderboard Models - Competition rankings and standings.
/// Following Monolith-by-Features architecture (ADR-005).

import 'package:equatable/equatable.dart';

// =============================================================================
// LEADERBOARD
// =============================================================================

class Leaderboard extends Equatable {
  const Leaderboard({
    required this.competitionId,
    required this.entries,
    required this.updatedAt,
  });

  factory Leaderboard.fromJson(Map<String, dynamic> json) {
    return Leaderboard(
      competitionId: json['competitionId'] as String,
      entries: (json['entries'] as List<dynamic>)
          .map((e) => LeaderboardEntry.fromJson(e as Map<String, dynamic>))
          .toList(),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  final String competitionId;
  final List<LeaderboardEntry> entries;
  final DateTime updatedAt;

  Map<String, dynamic> toJson() {
    return {
      'competitionId': competitionId,
      'entries': entries.map((e) => e.toJson()).toList(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [competitionId, entries, updatedAt];
}

// =============================================================================
// LEADERBOARD ENTRY
// =============================================================================

class LeaderboardEntry extends Equatable {
  const LeaderboardEntry({
    required this.position,
    required this.riderId,
    required this.riderName,
    this.riderNumber,
    this.clubId,
    this.clubName,
    required this.totalScore,
    this.roundScores = const [],
    this.pointsAwarded = 0,
  });

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) {
    return LeaderboardEntry(
      position: json['position'] as int,
      riderId: json['riderId'] as String? ?? json['athleteId'] as String,
      riderName: json['riderName'] as String? ??
          json['athleteName'] as String? ??
          '',
      riderNumber: json['riderNumber'] as String?,
      clubId: json['clubId'] as String?,
      clubName: json['clubName'] as String?,
      totalScore: (json['totalScore'] as num).toDouble(),
      roundScores: (json['roundScores'] as List<dynamic>?)
              ?.map((e) => (e as num).toDouble())
              .toList() ??
          [],
      pointsAwarded: json['pointsAwarded'] as int? ?? 0,
    );
  }

  final int position;
  final String riderId;
  final String riderName;
  final String? riderNumber;
  final String? clubId;
  final String? clubName;
  final double totalScore;
  final List<double> roundScores;
  final int pointsAwarded;

  Map<String, dynamic> toJson() {
    return {
      'position': position,
      'riderId': riderId,
      'riderName': riderName,
      'riderNumber': riderNumber,
      'clubId': clubId,
      'clubName': clubName,
      'totalScore': totalScore,
      'roundScores': roundScores,
      'pointsAwarded': pointsAwarded,
    };
  }

  @override
  List<Object?> get props => [position, riderId, totalScore, pointsAwarded];
}
