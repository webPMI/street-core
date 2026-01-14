/// Score Validation Service - Heuristic checks para detectar errores de digitación
///
/// CONTINGENCIA 2: "Dedo Veloz"
/// Previene que un juez ingrese accidentalmente 99 en lugar de 9.9, causando
/// que un atleta salte al primer puesto por error de digitación antes de que
/// el Speaker lo anuncie.
///
/// ESTRATEGIA:
/// - Validación de desviación estándar comparando con otros jueces
/// - Validación de historial del atleta (si disponible)
/// - Alerta al juez cuando la nota es sospechosamente alta/baja

import 'dart:math';
import '../../../core/helpers/logger.dart';
import '../models/judge_score_model.dart';

/// Configuration for score validation thresholds
class ScoreValidationConfig {
  const ScoreValidationConfig({
    this.standardDeviationThreshold = 2.0,
    this.percentageThreshold = 200.0, // 200% above/below average
    this.minScoresForComparison = 2, // Need at least 2 other scores to compare
  });

  /// Number of standard deviations before flagging as suspicious
  final double standardDeviationThreshold;

  /// Percentage above/below average before flagging (e.g., 200 = 2x)
  final double percentageThreshold;

  /// Minimum number of other scores needed for comparison
  final int minScoresForComparison;
}

/// Result of score validation
class ScoreValidationResult {
  const ScoreValidationResult({
    required this.isValid,
    this.warningType,
    this.message,
    this.comparisonData,
  });

  /// Whether the score passes validation
  final bool isValid;

  /// Type of warning if validation failed
  final ScoreWarningType? warningType;

  /// Human-readable warning message
  final String? message;

  /// Data used for comparison (for debugging/UI display)
  final ScoreComparisonData? comparisonData;

  /// Factory for valid score
  factory ScoreValidationResult.valid() {
    return const ScoreValidationResult(isValid: true);
  }

  /// Factory for suspicious score
  factory ScoreValidationResult.suspicious({
    required ScoreWarningType type,
    required String message,
    ScoreComparisonData? comparisonData,
  }) {
    return ScoreValidationResult(
      isValid: false,
      warningType: type,
      message: message,
      comparisonData: comparisonData,
    );
  }
}

/// Type of score warning
enum ScoreWarningType {
  /// Score is significantly higher than average
  tooHigh,

  /// Score is significantly lower than average
  tooLow,

  /// Score deviates too much from standard deviation
  outlier,

  /// Score doesn't match athlete's historical performance
  historicalMismatch,
}

/// Data used for score comparison
class ScoreComparisonData {
  const ScoreComparisonData({
    required this.submittedScore,
    required this.averageScore,
    required this.standardDeviation,
    required this.otherScoresCount,
    required this.percentageDifference,
  });

  final double submittedScore;
  final double averageScore;
  final double standardDeviation;
  final int otherScoresCount;
  final double percentageDifference;

  /// Get deviation in standard deviations
  double get deviationInSigmas {
    if (standardDeviation == 0) return 0;
    return (submittedScore - averageScore).abs() / standardDeviation;
  }
}

/// Service for validating judge scores
class ScoreValidationService {
  ScoreValidationService({
    ScoreValidationConfig? config,
  }) : _config = config ?? const ScoreValidationConfig();

  final ScoreValidationConfig _config;

  /// Validate a score against other judges' scores for the same athlete
  ///
  /// Returns validation result with warning if score is suspicious
  ScoreValidationResult validateAgainstOtherJudges({
    required double submittedScore,
    required List<JudgeScore> otherJudgeScores,
    String? participantId,
  }) {
    // Need at least N other scores for comparison
    if (otherJudgeScores.length < _config.minScoresForComparison) {
      AppLogger.debug(
        'Not enough scores for comparison (need ${_config.minScoresForComparison}, have ${otherJudgeScores.length})',
        tag: 'ScoreValidation',
      );
      return ScoreValidationResult.valid();
    }

    // Calculate average and standard deviation of other scores
    final otherScores = otherJudgeScores.map((s) => s.totalScore).toList();
    final average = _calculateAverage(otherScores);
    final stdDev = _calculateStandardDeviation(otherScores, average);

    // Calculate percentage difference
    final percentageDiff = ((submittedScore - average) / average * 100).abs();

    final comparisonData = ScoreComparisonData(
      submittedScore: submittedScore,
      averageScore: average,
      standardDeviation: stdDev,
      otherScoresCount: otherScores.length,
      percentageDifference: percentageDiff,
    );

    AppLogger.debug(
      'Score validation: submitted=$submittedScore, avg=$average, stdDev=$stdDev, diff=${percentageDiff.toStringAsFixed(1)}%',
      tag: 'ScoreValidation',
    );

    // Check 1: Percentage threshold (e.g., 200% above average = typo likely)
    if (percentageDiff > _config.percentageThreshold) {
      final direction = submittedScore > average ? 'superior' : 'inferior';
      return ScoreValidationResult.suspicious(
        type: submittedScore > average ? ScoreWarningType.tooHigh : ScoreWarningType.tooLow,
        message: 'Esta nota es ${percentageDiff.toStringAsFixed(0)}% $direction al promedio de otros jueces (${average.toStringAsFixed(1)}). ¿Estás seguro?',
        comparisonData: comparisonData,
      );
    }

    // Check 2: Standard deviation threshold (e.g., 2 sigma)
    if (stdDev > 0) {
      final deviationInSigmas = comparisonData.deviationInSigmas;
      if (deviationInSigmas > _config.standardDeviationThreshold) {
        return ScoreValidationResult.suspicious(
          type: ScoreWarningType.outlier,
          message: 'Esta nota difiere significativamente del promedio (${average.toStringAsFixed(1)}). Otros jueces dieron entre ${(average - stdDev).toStringAsFixed(1)} y ${(average + stdDev).toStringAsFixed(1)}.',
          comparisonData: comparisonData,
        );
      }
    }

    // All checks passed
    return ScoreValidationResult.valid();
  }

  /// Validate score against athlete's historical performance
  ///
  /// This would require loading the athlete's previous scores from the database.
  /// For now, this is a placeholder for future enhancement.
  ScoreValidationResult validateAgainstHistory({
    required double submittedScore,
    required String participantId,
    List<double>? historicalScores,
  }) {
    if (historicalScores == null || historicalScores.isEmpty) {
      return ScoreValidationResult.valid();
    }

    final average = _calculateAverage(historicalScores);
    final percentageDiff = ((submittedScore - average) / average * 100).abs();

    // Check if score deviates significantly from athlete's history
    if (percentageDiff > _config.percentageThreshold) {
      return ScoreValidationResult.suspicious(
        type: ScoreWarningType.historicalMismatch,
        message: 'Esta nota es ${percentageDiff.toStringAsFixed(0)}% diferente del desempeño histórico del atleta (promedio: ${average.toStringAsFixed(1)}).',
      );
    }

    return ScoreValidationResult.valid();
  }

  /// Calculate average of scores
  double _calculateAverage(List<double> scores) {
    if (scores.isEmpty) return 0.0;
    return scores.reduce((a, b) => a + b) / scores.length;
  }

  /// Calculate standard deviation
  double _calculateStandardDeviation(List<double> scores, double average) {
    if (scores.length < 2) return 0.0;

    final variance = scores.map((score) => pow(score - average, 2)).reduce((a, b) => a + b) / scores.length;
    return sqrt(variance);
  }
}
