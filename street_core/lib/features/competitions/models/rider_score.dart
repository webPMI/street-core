/// Rider Score Model - Individual rider scores in a round.
/// Following Monolith-by-Features architecture (ADR-005).

import 'package:equatable/equatable.dart';

// =============================================================================
// RIDER SCORE
// =============================================================================

class RiderScore extends Equatable {
  const RiderScore({
    required this.id,
    required this.riderId,
    required this.riderName,
    this.riderNumber,
    this.clubId,
    this.clubName,
    required this.roundId,
    this.scoresByJudge = const {},
    this.criteriaScoresByJudge,
    this.finalScore = 0,
    this.position = 0,
    this.scoredAt,
    this.notes,
  });

  factory RiderScore.fromJson(Map<String, dynamic> json) {
    return RiderScore(
      id: json['id'] as String,
      riderId: json['riderId'] as String? ?? json['athleteId'] as String,
      riderName: json['riderName'] as String? ??
          json['athleteName'] as String? ??
          '',
      riderNumber: json['riderNumber'] as String?,
      clubId: json['clubId'] as String?,
      clubName: json['clubName'] as String?,
      roundId: json['roundId'] as String,
      scoresByJudge: (json['scoresByJudge'] as Map<String, dynamic>?)?.map(
            (k, v) => MapEntry(k, (v as num).toDouble()),
          ) ??
          {},
      criteriaScoresByJudge:
          (json['criteriaScoresByJudge'] as Map<String, dynamic>?)?.map(
        (judgeId, criteriaMap) => MapEntry(
          judgeId,
          (criteriaMap as Map<String, dynamic>).map(
            (k, v) => MapEntry(k, (v as num).toDouble()),
          ),
        ),
      ),
      finalScore: json['finalScore'] != null
          ? (json['finalScore'] as num).toDouble()
          : json['totalScore'] != null
              ? (json['totalScore'] as num).toDouble()
              : 0,
      position: json['position'] as int? ?? 0,
      scoredAt: json['scoredAt'] != null
          ? DateTime.parse(json['scoredAt'] as String)
          : null,
      notes: json['notes'] as String?,
    );
  }

  final String id;
  final String riderId;
  final String riderName;
  final String? riderNumber;
  final String? clubId;
  final String? clubName;
  final String roundId;
  final Map<String, double> scoresByJudge;
  final Map<String, Map<String, double>>? criteriaScoresByJudge;
  final double finalScore;
  final int position;
  final DateTime? scoredAt;
  final String? notes;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'riderId': riderId,
      'riderName': riderName,
      'riderNumber': riderNumber,
      'clubId': clubId,
      'clubName': clubName,
      'roundId': roundId,
      'scoresByJudge': scoresByJudge,
      'criteriaScoresByJudge': criteriaScoresByJudge,
      'finalScore': finalScore,
      'position': position,
      'scoredAt': scoredAt?.toIso8601String(),
      'notes': notes,
    };
  }

  @override
  List<Object?> get props =>
      [id, riderId, roundId, scoresByJudge, finalScore, position];
}
