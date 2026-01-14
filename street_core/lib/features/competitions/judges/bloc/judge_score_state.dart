// lib/presentation/dashboard/competitions/judges/bloc/judge_score_state.dart

import 'package:equatable/equatable.dart';
import '../../models/judge_score_model.dart';
import '../../models/heat_model.dart';

/// Base state for judge scores
abstract class JudgeScoreState extends Equatable {
  const JudgeScoreState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class ScoreInitial extends JudgeScoreState {
  const ScoreInitial();
}

/// Loading state
class ScoresLoading extends JudgeScoreState {
  const ScoresLoading();
}

/// Alias for backward compatibility
class JudgeScoreLoading extends ScoresLoading {
  const JudgeScoreLoading();
}

/// Retrying score submission (with retry attempt info)
class ScoreRetrying extends JudgeScoreState {
  const ScoreRetrying({
    required this.attempt,
    required this.maxAttempts,
    required this.message,
  });

  /// Current retry attempt (1-based)
  final int attempt;

  /// Maximum retry attempts
  final int maxAttempts;

  /// Message key for translation
  final String message;

  @override
  List<Object?> get props => [attempt, maxAttempts, message];

  /// Get progress percentage (0-100)
  int get progressPercentage => ((attempt / maxAttempts) * 100).round();
}

/// Category scores loaded
class CategoryScoresLoaded extends JudgeScoreState {

  const CategoryScoresLoaded(this.scores, this.categoryId);
  final List<JudgeScore> scores;
  final String categoryId;

  @override
  List<Object?> get props => [scores, categoryId];
}

/// Alias for backward compatibility
class JudgeScoreListLoaded extends CategoryScoresLoaded {
  const JudgeScoreListLoaded(super.scores, super.categoryId);
}

/// Category ranking loaded
class CategoryRankingLoaded extends JudgeScoreState {

  const CategoryRankingLoaded(this.rankings, this.categoryId);
  final List<CategoryRankingEntry> rankings;
  final String categoryId;

  @override
  List<Object?> get props => [rankings, categoryId];
}

/// Alias for backward compatibility
class JudgeScoreRankingLoaded extends CategoryRankingLoaded {
  const JudgeScoreRankingLoaded(super.rankings, super.categoryId);
}

/// Score submitted/updated successfully
class ScoreActionSuccess extends JudgeScoreState {

  const ScoreActionSuccess(this.message, this.score);
  final String message;
  final JudgeScore score;

  @override
  List<Object?> get props => [message, score];
}

/// Error state
class ScoreError extends JudgeScoreState {

  const ScoreError(this.message);
  final String message;

  @override
  List<Object?> get props => [message];
}

/// Alias for backward compatibility
class JudgeScoreError extends ScoreError {
  const JudgeScoreError(super.message);
}

/// Scoring mode - actively scoring a participant
class ScoringModeActive extends JudgeScoreState {

  const ScoringModeActive({
    required this.categoryId,
    required this.participantId,
    required this.participantName,
    this.existingScore,
    this.currentScores = const {},
  });
  final String categoryId;
  final String participantId;
  final String participantName;
  final JudgeScore? existingScore;
  final Map<String, double> currentScores;

  @override
  List<Object?> get props => [categoryId, participantId, currentScores];

  ScoringModeActive copyWith({Map<String, double>? currentScores}) {
    return ScoringModeActive(
      categoryId: categoryId,
      participantId: participantId,
      participantName: participantName,
      existingScore: existingScore,
      currentScores: currentScores ?? this.currentScores,
    );
  }
}

/// Score saved offline (no internet connection)
class ScoreSavedOffline extends JudgeScoreState {
  const ScoreSavedOffline(this.message);
  final String message;

  @override
  List<Object?> get props => [message];
}

// =============================================================================
// HEAT STATES
// =============================================================================

/// Loading heats for a round
class HeatsLoading extends JudgeScoreState {
  const HeatsLoading();
}

/// Heats loaded for a round
class HeatsLoaded extends JudgeScoreState {
  const HeatsLoaded({
    required this.heats,
    required this.roundId,
    required this.competitionId,
  });

  final List<Heat> heats;
  final String roundId;
  final String competitionId;

  @override
  List<Object?> get props => [heats, roundId, competitionId];

  /// Get active heat (if any)
  Heat? get activeHeat => heats.where((h) => h.isActive).firstOrNull;

  /// Get next pending heat (if any)
  Heat? get nextPendingHeat {
    final pending = heats.where((h) => h.isPending).toList();
    if (pending.isEmpty) return null;
    pending.sort((a, b) => a.order.compareTo(b.order));
    return pending.first;
  }

  /// Get completed heats count
  int get completedCount => heats.where((h) => h.isCompleted).length;

  /// Get total heats count
  int get totalCount => heats.length;

  /// Get completion percentage
  double get completionPercentage {
    if (totalCount == 0) return 0.0;
    return (completedCount / totalCount) * 100;
  }
}

/// Heat selected for scoring
class HeatSelected extends JudgeScoreState {
  const HeatSelected({
    required this.heat,
    required this.competitionId,
    required this.categoryId,
  });

  final Heat heat;
  final String competitionId;
  final String categoryId;

  @override
  List<Object?> get props => [heat, competitionId, categoryId];

  /// Check if heat is closed for scoring
  bool get isHeatClosed => heat.isCompleted;

  /// Check if heat is active
  bool get isHeatActive => heat.isActive;

  /// Check if heat is pending
  bool get isHeatPending => heat.isPending;

  /// Get heat mode display
  String get modeDisplay => heat.modeDisplay;

  /// Get status display
  String get statusDisplay => heat.statusDisplay;
}

/// Heat error state with backend error code for translation
class HeatError extends JudgeScoreState {
  const HeatError({
    required this.message,
    this.code,
    this.details,
  });

  /// User-friendly error message (fallback)
  final String message;

  /// Backend error code for translation (e.g., 'heat.already.closed')
  final String? code;

  /// Additional error details
  final Map<String, dynamic>? details;

  @override
  List<Object?> get props => [message, code, details];

  /// Get translatable error code or fallback message
  String get translatableError => code ?? message;

  /// Check if this is a specific error type
  bool isErrorType(String errorCode) => code == errorCode;
}

/// Heat completed warning (prevents scoring submission)
class HeatCompletedWarning extends JudgeScoreState {
  const HeatCompletedWarning({
    required this.heat,
    required this.message,
  });

  final Heat heat;
  final String message;

  @override
  List<Object?> get props => [heat, message];
}

/// Heat scoring mode active (sequential or simultaneous)
class HeatScoringModeActive extends JudgeScoreState {
  const HeatScoringModeActive({
    required this.heat,
    required this.competitionId,
    required this.categoryId,
    required this.currentAthleteId,
    this.currentAthleteIndex,
    this.existingScore,
    this.currentScores = const {},
  });

  final Heat heat;
  final String competitionId;
  final String categoryId;
  final String currentAthleteId;
  final int? currentAthleteIndex; // For sequential mode navigation
  final JudgeScore? existingScore;
  final Map<String, double> currentScores;

  @override
  List<Object?> get props => [
        heat,
        competitionId,
        categoryId,
        currentAthleteId,
        currentAthleteIndex,
        currentScores,
      ];

  /// Check if heat is completed (disable submit)
  bool get isHeatCompleted => heat.isCompleted;

  /// Check if this is sequential mode
  bool get isSequentialMode => heat.isSequential;

  /// Check if this is simultaneous mode
  bool get isSimultaneousMode => heat.isSimultaneous;

  /// Check if there's a next athlete (sequential mode)
  bool get hasNextAthlete {
    if (!isSequentialMode) return false;
    if (currentAthleteIndex == null) return false;
    return currentAthleteIndex! < heat.athleteOrder.length - 1;
  }

  /// Check if there's a previous athlete (sequential mode)
  bool get hasPreviousAthlete {
    if (!isSequentialMode) return false;
    if (currentAthleteIndex == null) return false;
    return currentAthleteIndex! > 0;
  }

  /// Get current athlete position display (e.g., "3/8")
  String get athletePositionDisplay {
    if (currentAthleteIndex == null) return '';
    return '${currentAthleteIndex! + 1}/${heat.athleteCount}';
  }

  /// Copy with updated scores
  HeatScoringModeActive copyWith({
    Map<String, double>? currentScores,
    String? currentAthleteId,
    int? currentAthleteIndex,
  }) {
    return HeatScoringModeActive(
      heat: heat,
      competitionId: competitionId,
      categoryId: categoryId,
      currentAthleteId: currentAthleteId ?? this.currentAthleteId,
      currentAthleteIndex: currentAthleteIndex ?? this.currentAthleteIndex,
      existingScore: existingScore,
      currentScores: currentScores ?? this.currentScores,
    );
  }
}
