/// Modelo de Puntuación - Representa la puntuación de un juez para un participante.
/// Following Monolith-by-Features architecture (ADR-005).

import 'package:equatable/equatable.dart';

/// Puntuación dada por un juez a un participante.
class Score extends Equatable {
  const Score({
    required this.id,
    required this.competitionId,
    required this.participantId,
    required this.judgeId,
    required this.categoryId,
    this.roundId,
    required this.criteriaScores,
    required this.totalScore,
    this.notes,
    this.scoredAt,
    this.updatedAt,
  });

  factory Score.fromJson(Map<String, dynamic> json) {
    return Score(
      id: json['id'] as String,
      competitionId: json['competitionId'] as String,
      participantId: json['participantId'] as String,
      judgeId: json['judgeId'] as String,
      categoryId: json['categoryId'] as String,
      roundId: json['roundId'] as String?,
      criteriaScores: (json['criteriaScores'] as Map<String, dynamic>).map(
        (k, v) => MapEntry(k, (v as num).toDouble()),
      ),
      totalScore: (json['totalScore'] as num).toDouble(),
      notes: json['notes'] as String?,
      scoredAt: json['scoredAt'] != null
          ? DateTime.parse(json['scoredAt'] as String)
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
    );
  }

  final String id;
  final String competitionId;
  final String participantId;
  final String judgeId;
  final String categoryId;
  final String? roundId;
  final Map<String, double> criteriaScores;
  final double totalScore;
  final String? notes;
  final DateTime? scoredAt;
  final DateTime? updatedAt;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'competitionId': competitionId,
      'participantId': participantId,
      'judgeId': judgeId,
      'categoryId': categoryId,
      'roundId': roundId,
      'criteriaScores': criteriaScores,
      'totalScore': totalScore,
      'notes': notes,
      'scoredAt': scoredAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [
    id,
    competitionId,
    participantId,
    judgeId,
    totalScore,
  ];
}
