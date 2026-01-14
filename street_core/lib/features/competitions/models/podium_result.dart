/// Podium Result Model - Final competition standings.
/// Following Monolith-by-Features architecture (ADR-005).

import 'package:equatable/equatable.dart';

// =============================================================================
// PODIUM RESULT
// =============================================================================

class PodiumResult extends Equatable {
  const PodiumResult({
    required this.position,
    required this.riderId,
    required this.riderName,
    this.riderNumber,
    this.clubId,
    this.clubName,
    required this.finalScore,
    this.pointsAwarded = 0,
    this.prize,
  });

  factory PodiumResult.fromJson(Map<String, dynamic> json) {
    return PodiumResult(
      position: json['position'] as int,
      riderId: json['riderId'] as String,
      riderName: json['riderName'] as String,
      riderNumber: json['riderNumber'] as String?,
      clubId: json['clubId'] as String?,
      clubName: json['clubName'] as String?,
      finalScore: (json['finalScore'] as num).toDouble(),
      pointsAwarded: json['pointsAwarded'] as int? ?? 0,
      prize: json['prize'] as String?,
    );
  }

  final int position;
  final String riderId;
  final String riderName;
  final String? riderNumber;
  final String? clubId;
  final String? clubName;
  final double finalScore;
  final int pointsAwarded;
  final String? prize;

  Map<String, dynamic> toJson() {
    return {
      'position': position,
      'riderId': riderId,
      'riderName': riderName,
      'riderNumber': riderNumber,
      'clubId': clubId,
      'clubName': clubName,
      'finalScore': finalScore,
      'pointsAwarded': pointsAwarded,
      'prize': prize,
    };
  }

  @override
  List<Object?> get props => [position, riderId, finalScore];
}
