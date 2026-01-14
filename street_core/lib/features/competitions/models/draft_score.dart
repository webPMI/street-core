/// Draft Score Model - Stores partial scoring progress for auto-save
///
/// CONTINGENCIA 4: "Batería/Cierre"
/// Si la tablet se apaga o la app se cierra, el progreso se recupera automáticamente.

import 'package:hive/hive.dart';

part 'draft_score.g.dart';

@HiveType(typeId: 4) // Adjust typeId as needed based on existing Hive types
class DraftScore extends HiveObject {
  @HiveField(0)
  final String id; // Unique ID: competitionId_categoryId_athleteId

  @HiveField(1)
  final String competitionId;

  @HiveField(2)
  final String categoryId;

  @HiveField(3)
  final String athleteId;

  @HiveField(4)
  final String? heatId; // Optional for heat mode

  @HiveField(5)
  final String? judgeId; // Optional judge ID

  @HiveField(6)
  final Map<String, double> criteriaScores; // Partial scores

  @HiveField(7)
  final DateTime lastModified; // Timestamp of last auto-save

  @HiveField(8)
  final int version; // Incremental version for conflict detection

  DraftScore({
    required this.id,
    required this.competitionId,
    required this.categoryId,
    required this.athleteId,
    this.heatId,
    this.judgeId,
    required this.criteriaScores,
    required this.lastModified,
    this.version = 1,
  });

  /// Generate unique ID for draft
  static String generateId({
    required String competitionId,
    required String categoryId,
    required String athleteId,
    String? heatId,
  }) {
    if (heatId != null) {
      return '${competitionId}_${categoryId}_${heatId}_$athleteId';
    }
    return '${competitionId}_${categoryId}_$athleteId';
  }

  /// Create a copy with updated fields
  DraftScore copyWith({
    String? id,
    String? competitionId,
    String? categoryId,
    String? athleteId,
    String? heatId,
    String? judgeId,
    Map<String, double>? criteriaScores,
    DateTime? lastModified,
    int? version,
  }) {
    return DraftScore(
      id: id ?? this.id,
      competitionId: competitionId ?? this.competitionId,
      categoryId: categoryId ?? this.categoryId,
      athleteId: athleteId ?? this.athleteId,
      heatId: heatId ?? this.heatId,
      judgeId: judgeId ?? this.judgeId,
      criteriaScores: criteriaScores ?? this.criteriaScores,
      lastModified: lastModified ?? this.lastModified,
      version: version ?? this.version,
    );
  }

  /// Check if draft is stale (older than threshold)
  bool isStale({Duration threshold = const Duration(hours: 24)}) {
    return DateTime.now().difference(lastModified) > threshold;
  }

  /// Calculate total score from criteria
  double get totalScore {
    return criteriaScores.values.fold(0.0, (sum, score) => sum + score);
  }

  /// Check if any criteria has been scored
  bool get hasAnyScores {
    return criteriaScores.values.any((score) => score > 0);
  }

  /// Get completion percentage (0-100)
  double completionPercentage(int totalCriteria) {
    if (totalCriteria == 0) return 0;
    final scoredCriteria = criteriaScores.values.where((score) => score > 0).length;
    return (scoredCriteria / totalCriteria) * 100;
  }

  @override
  String toString() {
    return 'DraftScore(id: $id, athleteId: $athleteId, scores: ${criteriaScores.length}, lastModified: $lastModified)';
  }
}
