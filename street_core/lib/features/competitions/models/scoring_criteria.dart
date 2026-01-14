/// Scoring Criteria Models - Criteria and rules for competition scoring.
/// Following Monolith-by-Features architecture (ADR-005).

import 'package:equatable/equatable.dart';

// =============================================================================
// SCORING CRITERIA
// =============================================================================

class ScoringCriteria extends Equatable {
  const ScoringCriteria({
    required this.type,
    this.minScore = 0,
    this.maxScore = 100,
    this.criteria,
    this.calculationMethod,
  });

  factory ScoringCriteria.fromJson(Map<String, dynamic> json) {
    return ScoringCriteria(
      type: json['type'] as String? ?? 'points',
      minScore:
          json['minScore'] != null ? (json['minScore'] as num).toDouble() : 0,
      maxScore:
          json['maxScore'] != null ? (json['maxScore'] as num).toDouble() : 100,
      criteria: (json['criteria'] as List<dynamic>?)
          ?.map((e) => ScoreCriterion.fromJson(e as Map<String, dynamic>))
          .toList(),
      calculationMethod: json['calculationMethod'] as String?,
    );
  }

  final String type;
  final double minScore;
  final double maxScore;
  final List<ScoreCriterion>? criteria;
  final String? calculationMethod;

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'minScore': minScore,
      'maxScore': maxScore,
      'criteria': criteria?.map((e) => e.toJson()).toList(),
      'calculationMethod': calculationMethod,
    };
  }

  @override
  List<Object?> get props =>
      [type, minScore, maxScore, criteria, calculationMethod];
}

// =============================================================================
// SCORE CRITERION
// =============================================================================

class ScoreCriterion extends Equatable {
  const ScoreCriterion({
    required this.name,
    this.description,
    this.weight = 1.0,
    this.minScore = 0,
    this.maxScore = 10,
  });

  factory ScoreCriterion.fromJson(Map<String, dynamic> json) {
    return ScoreCriterion(
      name: json['name'] as String,
      description: json['description'] as String?,
      weight:
          json['weight'] != null ? (json['weight'] as num).toDouble() : 1.0,
      minScore:
          json['minScore'] != null ? (json['minScore'] as num).toDouble() : 0,
      maxScore:
          json['maxScore'] != null ? (json['maxScore'] as num).toDouble() : 10,
    );
  }

  final String name;
  final String? description;
  final double weight;
  final double minScore;
  final double maxScore;

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'weight': weight,
      'minScore': minScore,
      'maxScore': maxScore,
    };
  }

  @override
  List<Object?> get props => [name, description, weight, minScore, maxScore];
}
