// lib/presentation/dashboard/competitions/judges/bloc/judge_score_cubit.dart

import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import './judge_score_state.dart';
import '../../repositories/judge_score_repository.dart';
import '../../repositories/heat_repository.dart';
import '../../../../core/storage/hive_service.dart';
import '../../../../core/lang/locale_keys.dart';
import '../../models/offline_score.dart';
import '../../models/heat_model.dart';
import '../../../../core/helpers/logger.dart';
import '../../../../core/crud/exceptions/repository_exception.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// =============================================================================
// RETRY CONFIGURATION
// =============================================================================

/// Configuration for retry logic with exponential backoff
class RetryConfig {
  final int maxAttempts;
  final Duration initialDelay;
  final double backoffMultiplier;
  final Duration maxDelay;

  const RetryConfig({
    this.maxAttempts = 3,
    this.initialDelay = const Duration(milliseconds: 500),
    this.backoffMultiplier = 2.0,
    this.maxDelay = const Duration(seconds: 10),
  });

  /// Calculate delay for specific attempt (exponential backoff)
  Duration delayForAttempt(int attempt) {
    final calculatedDelay = initialDelay * (backoffMultiplier * attempt);
    return calculatedDelay > maxDelay ? maxDelay : calculatedDelay;
  }
}

// =============================================================================
// REPOSITORY EXCEPTION EXTENSIONS
// =============================================================================

/// Extension to identify error types for retry logic and concurrency handling
extension RepositoryExceptionExtensions on RepositoryException {
  /// Check if error is transient (can be retried)
  bool get isTransient {
    // 5xx errors (server errors) - transient
    if (statusCode != null && statusCode! >= 500 && statusCode! < 600) {
      return true;
    }

    // Timeouts - transient
    if (code?.contains('timeout') ?? false) {
      return true;
    }

    // Network errors - transient
    if (code?.contains('network') ?? false) {
      return true;
    }

    return false;
  }

  /// Check if error is a concurrency conflict (HTTP 409)
  bool get isConcurrencyConflict {
    return statusCode == 409 || // HTTP Conflict
        code == 'heat.already.closed' ||
        code == 'score.already.reset' ||
        code == 'concurrent.modification' ||
        code == 'heat.modified';
  }

  /// Check if resource was deleted (HTTP 410 Gone)
  bool get isResourceGone {
    return statusCode == 410 || // HTTP Gone
        code == 'heat.deleted' ||
        code == 'score.deleted';
  }

  /// Check if athlete is not in heat (HTTP 400)
  bool get isAthleteNotInHeat {
    return code == 'athlete.not.in.heat' ||
        code == 'participant.not.found';
  }
}

// =============================================================================
// CUBIT
// =============================================================================

/// Cubit for managing judge scores and rankings with concurrency handling
class JudgeScoreCubit extends Cubit<JudgeScoreState> {

  JudgeScoreCubit(
    this._repository,
    this._heatRepository, {
    HiveService? hiveService,
    Connectivity? connectivity,
    RetryConfig? retryConfig,
  })  : _hiveService = hiveService,
        _connectivity = connectivity ?? Connectivity(),
        _retryConfig = retryConfig ?? const RetryConfig(),
        super(const ScoreInitial());

  final JudgeScoreRepository _repository;
  final HeatRepository _heatRepository;
  final HiveService? _hiveService;
  final Connectivity _connectivity;
  final RetryConfig _retryConfig;

  // Auto-refresh timer for heat updates
  Timer? _autoRefreshTimer;

  // -----------------------------------------------------------------
  // FETCH OPERATIONS
  // -----------------------------------------------------------------

  /// Fetch all scores for a category
  Future<void> fetchCategoryScores(
    String competitionId,
    String categoryId,
  ) async {
    try {
      emit(const ScoresLoading());
      final scores = await _repository.getCategoryScores(
        competitionId,
        categoryId,
      );
      emit(CategoryScoresLoaded(scores, categoryId));
    } catch (e) {
      emit(const ScoreError('error_loading_scores'));
    }
  }

  /// Alias method for backward compatibility
  Future<void> getScoresByCategory(
    String competitionId,
    String categoryId,
  ) async {
    return fetchCategoryScores(competitionId, categoryId);
  }

  /// Fetch category ranking/leaderboard
  Future<void> fetchCategoryRanking(
    String competitionId,
    String categoryId,
  ) async {
    try {
      emit(const ScoresLoading());
      final rankings = await _repository.getCategoryRanking(
        competitionId,
        categoryId,
      );
      emit(CategoryRankingLoaded(rankings, categoryId));
    } catch (e) {
      emit(const ScoreError('error_loading_ranking'));
    }
  }

  /// Alias method for backward compatibility
  Future<void> getCategoryRanking(
    String competitionId,
    String categoryId,
  ) async {
    return fetchCategoryRanking(competitionId, categoryId);
  }

  /// Fetch my scores as a judge for a category
  Future<void> fetchMyScores(
    String competitionId,
    String categoryId,
    String judgeId,
  ) async {
    try {
      emit(const ScoresLoading());
      final scores = await _repository.getMyScoresForCategory(
        competitionId,
        categoryId,
        judgeId,
      );
      emit(CategoryScoresLoaded(scores, categoryId));
    } catch (e) {
      emit(const ScoreError('error_loading_my_scores'));
    }
  }

  // -----------------------------------------------------------------
  // HEAT OPERATIONS
  // -----------------------------------------------------------------

  /// Fetch all heats for a round
  Future<void> loadRoundHeats(
    String competitionId,
    String roundId,
  ) async {
    try {
      emit(const HeatsLoading());
      final heats = await _heatRepository.getRoundHeats(
        competitionId,
        roundId,
      );
      emit(HeatsLoaded(
        heats: heats,
        roundId: roundId,
        competitionId: competitionId,
      ));
    } catch (e) {
      AppLogger.error('Error loading heats', error: e, tag: 'JudgeScore');

      // Capture backend error code for translation
      if (e is RepositoryException) {
        emit(HeatError(
          message: e.message,
          code: e.code,
          details: {'competitionId': competitionId, 'roundId': roundId},
        ));
      } else {
        emit(const HeatError(message: 'error_loading_heats'));
      }
    }
  }

  /// Select a heat for scoring (navigates judge to scoring page)
  Future<void> selectHeat(
    Heat heat,
    String competitionId,
    String categoryId,
  ) async {
    try {
      // Check if heat is completed (closed for scoring)
      if (heat.isCompleted) {
        emit(HeatCompletedWarning(
          heat: heat,
          message: 'heat_already_closed_cannot_score',
        ));
        return;
      }

      // Emit heat selected state
      emit(HeatSelected(
        heat: heat,
        competitionId: competitionId,
        categoryId: categoryId,
      ));

      // Start auto-refresh to detect CurrentHeat changes
      if (heat.isActive) {
        startAutoRefresh(competitionId, heat.roundId);
      }
    } catch (e) {
      AppLogger.error('Error selecting heat', error: e, tag: 'JudgeScore');
      emit(const HeatError(message: 'error_selecting_heat'));
    }
  }

  /// Enter heat scoring mode for a specific athlete
  Future<void> startHeatScoring(
    Heat heat,
    String competitionId,
    String categoryId,
    String athleteId,
    String judgeId,
  ) async {
    try {
      // Validate heat is not completed
      if (heat.isCompleted) {
        emit(HeatCompletedWarning(
          heat: heat,
          message: 'heat_already_closed_cannot_score',
        ));
        return;
      }

      // Validate athlete is in this heat
      if (!heat.hasAthlete(athleteId)) {
        emit(HeatError(
          message: 'athlete_not_in_heat',
          code: 'heat.athlete.not.assigned',
          details: {'athleteId': athleteId, 'heatId': heat.id},
        ));
        return;
      }

      // Load existing score for this athlete (if any)
      final scores = await _repository.getParticipantScores(
        competitionId,
        categoryId,
        athleteId,
      );

      final existingScore = scores.where((s) => s.judgeId == judgeId).firstOrNull;

      // Determine athlete index for sequential mode
      int? athleteIndex;
      if (heat.isSequential) {
        athleteIndex = heat.getAthletePosition(athleteId);
      }

      emit(
        HeatScoringModeActive(
          heat: heat,
          competitionId: competitionId,
          categoryId: categoryId,
          currentAthleteId: athleteId,
          currentAthleteIndex: athleteIndex,
          existingScore: existingScore,
          currentScores: existingScore?.criteriaScores ?? {},
        ),
      );
    } catch (e) {
      AppLogger.error('Error starting heat scoring', error: e, tag: 'JudgeScore');

      if (e is RepositoryException) {
        emit(HeatError(
          message: e.message,
          code: e.code,
        ));
      } else {
        emit(const HeatError(message: 'error_loading_existing_score'));
      }
    }
  }

  /// Navigate to next athlete in sequential mode
  void navigateToNextAthlete(String judgeId) {
    final currentState = state;
    if (currentState is! HeatScoringModeActive) return;
    if (!currentState.isSequentialMode) return;
    if (!currentState.hasNextAthlete) return;

    final nextIndex = currentState.currentAthleteIndex! + 1;
    final nextAthleteId = currentState.heat.athleteOrder[nextIndex];

    // Load scoring for next athlete
    startHeatScoring(
      currentState.heat,
      currentState.competitionId,
      currentState.categoryId,
      nextAthleteId,
      judgeId,
    );
  }

  /// Navigate to previous athlete in sequential mode
  void navigateToPreviousAthlete(String judgeId) {
    final currentState = state;
    if (currentState is! HeatScoringModeActive) return;
    if (!currentState.isSequentialMode) return;
    if (!currentState.hasPreviousAthlete) return;

    final previousIndex = currentState.currentAthleteIndex! - 1;
    final previousAthleteId = currentState.heat.athleteOrder[previousIndex];

    // Load scoring for previous athlete
    startHeatScoring(
      currentState.heat,
      currentState.competitionId,
      currentState.categoryId,
      previousAthleteId,
      judgeId,
    );
  }

  /// Update criteria score in heat scoring mode
  void updateHeatCriteriaScore(String criterionName, double score) {
    final currentState = state;
    if (currentState is HeatScoringModeActive) {
      final updatedScores = Map<String, double>.from(
        currentState.currentScores,
      );
      updatedScores[criterionName] = score;
      emit(currentState.copyWith(currentScores: updatedScores));
    }
  }

  /// Submit score for athlete in heat with retry logic and concurrency handling
  ///
  /// Handles:
  /// - HTTP 409 (Conflict): Heat closed, concurrent modification
  /// - HTTP 410 (Gone): Heat/score deleted
  /// - 5xx errors: Retry with exponential backoff
  /// - Network timeouts: Retry with exponential backoff
  /// - Offline: Save to Hive for later sync
  Future<void> submitHeatScore(
    String competitionId,
    String categoryId,
    String athleteId,
    String heatId,
    Map<String, double> criteriaScores,
    String? comments, {
    String? judgeId,
  }) async {
    try {
      emit(const ScoresLoading());

      final scoreData = {
        'participantId': athleteId,
        'heatId': heatId, // Include heatId for backend validation
        'criteriaScores': criteriaScores,
        if (comments != null && comments.isNotEmpty) 'comments': comments,
      };

      // Check connectivity first
      final hasConnection = await _checkConnectivity();

      if (!hasConnection && _hiveService != null) {
        // No connection - save offline immediately
        await _saveScoreOffline(
          competitionId: competitionId,
          categoryId: categoryId,
          participantId: athleteId,
          judgeId: judgeId ?? '',
          criteriaScores: criteriaScores,
          comments: comments,
        );

        emit(const ScoreSavedOffline(LocaleKeys.scoreSavedOffline));
        return;
      }

      // Submit with retry logic
      final score = await _submitWithRetry(
        () => _repository.submitScore(
          competitionId,
          categoryId,
          scoreData,
        ),
        operation: 'submit_heat_score',
        metadata: {
          'heatId': heatId,
          'athleteId': athleteId,
        },
      );

      // Success
      emit(ScoreActionSuccess(LocaleKeys.scoreSubmittedSuccessfully, score));

      // Reload heats to get updated status
      final currentState = state;
      if (currentState is HeatScoringModeActive) {
        await loadRoundHeats(competitionId, currentState.heat.roundId);
      }
    } on RepositoryException catch (e) {
      // Handle specific concurrency errors
      await _handleRepositoryException(
        e,
        competitionId: competitionId,
        categoryId: categoryId,
        athleteId: athleteId,
        heatId: heatId,
        criteriaScores: criteriaScores,
        comments: comments,
        judgeId: judgeId,
      );
    } catch (e) {
      AppLogger.error(
        'Unexpected error submitting heat score',
        error: e,
        tag: 'JudgeScore',
      );

      // Try offline save as last resort
      if (_hiveService != null && judgeId != null) {
        try {
          await _saveScoreOffline(
            competitionId: competitionId,
            categoryId: categoryId,
            participantId: athleteId,
            judgeId: judgeId,
            criteriaScores: criteriaScores,
            comments: comments,
          );
          emit(const ScoreSavedOffline(LocaleKeys.scoreSavedOffline));
          return;
        } catch (offlineError) {
          AppLogger.error(
            'Failed to save score offline',
            error: offlineError,
            tag: 'JudgeScore',
          );
        }
      }

      emit(const ScoreError('error_submitting_score'));
    }
  }

  /// Start auto-refresh timer (30s) to detect CurrentHeat changes
  void startAutoRefresh(String competitionId, String roundId) {
    stopAutoRefresh(); // Cancel existing timer if any

    _autoRefreshTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) async {
        try {
          // Silent refresh - don't show loading state
          final heats = await _heatRepository.getRoundHeats(
            competitionId,
            roundId,
          );

          // Only emit if state is still heat-related
          final currentState = state;
          if (currentState is HeatsLoaded ||
              currentState is HeatSelected ||
              currentState is HeatScoringModeActive) {
            emit(HeatsLoaded(
              heats: heats,
              roundId: roundId,
              competitionId: competitionId,
            ));

            AppLogger.info('Auto-refreshed heats for round $roundId', tag: 'JudgeScore');
          }
        } catch (e) {
          AppLogger.error('Auto-refresh failed', error: e, tag: 'JudgeScore');
          // Don't emit error during silent refresh
        }
      },
    );

    AppLogger.info('Started auto-refresh for round $roundId (30s interval)', tag: 'JudgeScore');
  }

  /// Stop auto-refresh timer
  void stopAutoRefresh() {
    _autoRefreshTimer?.cancel();
    _autoRefreshTimer = null;
    AppLogger.info('Stopped auto-refresh timer', tag: 'JudgeScore');
  }

  // -----------------------------------------------------------------
  // SCORING MODE
  // -----------------------------------------------------------------

  /// Enter scoring mode for a participant
  Future<void> startScoring(
    String competitionId,
    String categoryId,
    String participantId,
    String participantName,
    String judgeId,
  ) async {
    try {
      // Try to load existing score
      final scores = await _repository.getParticipantScores(
        competitionId,
        categoryId,
        participantId,
      );

      // Find existing score from this judge
      final existingScore = scores.where((s) => s.judgeId == judgeId).firstOrNull;

      emit(
        ScoringModeActive(
          categoryId: categoryId,
          participantId: participantId,
          participantName: participantName,
          existingScore: existingScore,
          currentScores: existingScore?.criteriaScores ?? {},
        ),
      );
    } catch (e) {
      emit(const ScoreError('error_loading_existing_score'));
    }
  }

  /// Update criteria score in scoring mode
  void updateCriteriaScore(String criterionName, double score) {
    final currentState = state;
    if (currentState is ScoringModeActive) {
      final updatedScores = Map<String, double>.from(
        currentState.currentScores,
      );
      updatedScores[criterionName] = score;
      emit(currentState.copyWith(currentScores: updatedScores));
    }
  }

  /// Cancel scoring mode
  void cancelScoring() {
    emit(const ScoreInitial());
  }

  // -----------------------------------------------------------------
  // SUBMIT/UPDATE SCORE
  // -----------------------------------------------------------------

  /// Submit a new score with retry logic and concurrency handling
  ///
  /// Handles:
  /// - HTTP 409 (Conflict): Concurrent modification
  /// - HTTP 410 (Gone): Resource deleted
  /// - 5xx errors: Retry with exponential backoff
  /// - Network timeouts: Retry with exponential backoff
  /// - Offline: Save to Hive for later sync
  Future<void> submitScore(
    String competitionId,
    String categoryId,
    String participantId,
    Map<String, double> criteriaScores,
    String? comments, {
    String? judgeId,
  }) async {
    try {
      emit(const ScoresLoading());

      final scoreData = {
        'participantId': participantId,
        'criteriaScores': criteriaScores,
        if (comments != null && comments.isNotEmpty) 'comments': comments,
      };

      // Check connectivity first
      final hasConnection = await _checkConnectivity();

      if (!hasConnection && _hiveService != null) {
        // No connection - save offline immediately
        await _saveScoreOffline(
          competitionId: competitionId,
          categoryId: categoryId,
          participantId: participantId,
          judgeId: judgeId ?? '',
          criteriaScores: criteriaScores,
          comments: comments,
        );

        emit(const ScoreSavedOffline(LocaleKeys.scoreSavedOffline));
        return;
      }

      // Submit with retry logic
      final score = await _submitWithRetry(
        () => _repository.submitScore(
          competitionId,
          categoryId,
          scoreData,
        ),
        operation: 'submit_score',
        metadata: {
          'participantId': participantId,
        },
      );

      // Success
      emit(ScoreActionSuccess(LocaleKeys.scoreSubmittedSuccessfully, score));

      // Return to scores list
      await fetchCategoryScores(competitionId, categoryId);
    } on RepositoryException catch (e) {
      // Handle specific concurrency errors
      await _handleRepositoryException(
        e,
        competitionId: competitionId,
        categoryId: categoryId,
        athleteId: participantId,
        criteriaScores: criteriaScores,
        comments: comments,
        judgeId: judgeId,
      );
    } catch (e) {
      AppLogger.error(
        'Unexpected error submitting score',
        error: e,
        tag: 'JudgeScore',
      );

      // Try offline save as last resort
      if (_hiveService != null && judgeId != null) {
        try {
          await _saveScoreOffline(
            competitionId: competitionId,
            categoryId: categoryId,
            participantId: participantId,
            judgeId: judgeId,
            criteriaScores: criteriaScores,
            comments: comments,
          );
          emit(const ScoreSavedOffline(LocaleKeys.scoreSavedOffline));
          return;
        } catch (offlineError) {
          AppLogger.error(
            'Failed to save score offline',
            error: offlineError,
            tag: 'JudgeScore',
          );
        }
      }

      emit(const ScoreError('error_submitting_score'));
    }
  }

  /// Update an existing score (with offline support)
  Future<void> updateScore(
    String competitionId,
    String categoryId,
    String scoreId,
    Map<String, double> criteriaScores,
    String? comments, {
    String? judgeId,
    String? participantId,
  }) async {
    try {
      emit(const ScoresLoading());

      final scoreData = {
        'criteriaScores': criteriaScores,
        if (comments != null) 'comments': comments,
      };

      // Check connectivity
      final hasConnection = await _checkConnectivity();

      if (!hasConnection && _hiveService != null && judgeId != null && participantId != null) {
        // Save offline as update
        await _saveScoreOffline(
          competitionId: competitionId,
          categoryId: categoryId,
          participantId: participantId,
          judgeId: judgeId,
          criteriaScores: criteriaScores,
          comments: comments,
          isUpdate: true,
          existingScoreId: scoreId,
        );

        emit(const ScoreSavedOffline('score_update_saved_offline_will_sync'));
        return;
      }

      // Update online
      final score = await _repository.updateScore(
        competitionId,
        categoryId,
        scoreId,
        scoreData,
      );
      emit(ScoreActionSuccess('score_updated_successfully', score));

      // Return to scores list
      await fetchCategoryScores(competitionId, categoryId);
    } catch (e) {
      AppLogger.error('Error updating score', error: e, tag: 'JudgeScore');

      // Try to save offline as fallback
      if (_hiveService != null && judgeId != null && participantId != null) {
        try {
          await _saveScoreOffline(
            competitionId: competitionId,
            categoryId: categoryId,
            participantId: participantId,
            judgeId: judgeId,
            criteriaScores: criteriaScores,
            comments: comments,
            isUpdate: true,
            existingScoreId: scoreId,
          );
          emit(const ScoreSavedOffline('score_update_saved_offline_due_to_error'));
          return;
        } catch (offlineError) {
          AppLogger.error('Error saving offline score update', error: offlineError, tag: 'JudgeScore');
        }
      }

      emit(const ScoreError('error_updating_score'));
    }
  }

  // -----------------------------------------------------------------
  // UTILITY METHODS
  // -----------------------------------------------------------------

  /// Clear state
  void clearState() {
    emit(const ScoreInitial());
  }

  // -----------------------------------------------------------------
  // OFFLINE SUPPORT HELPERS
  // -----------------------------------------------------------------

  /// Check if device has internet connectivity
  Future<bool> _checkConnectivity() async {
    try {
      final results = await _connectivity.checkConnectivity();
      return results.any((result) => result != ConnectivityResult.none);
    } catch (e) {
      AppLogger.error('Error checking connectivity', error: e, tag: 'JudgeScore');
      return true; // Assume online if check fails
    }
  }

  /// Save score offline
  Future<void> _saveScoreOffline({
    required String competitionId,
    required String categoryId,
    required String participantId,
    required String judgeId,
    required Map<String, double> criteriaScores,
    String? comments,
    bool isUpdate = false,
    String? existingScoreId,
  }) async {
    if (_hiveService == null) {
      throw Exception('HiveService not available');
    }

    final offlineScore = OfflineScore.fromSubmission(
      competitionId: competitionId,
      categoryId: categoryId,
      participantId: participantId,
      judgeId: judgeId,
      criteriaScores: criteriaScores,
      comments: comments,
      isUpdate: isUpdate,
      existingScoreId: existingScoreId,
    );

    await _hiveService.saveOfflineScore(offlineScore);

    AppLogger.info('Score saved offline: $participantId (update: $isUpdate)', tag: 'JudgeScore');
  }

  /// Get offline scores count for category
  int getOfflineScoresCount(String competitionId, String categoryId) {
    if (_hiveService == null) return 0;

    return _hiveService
        .getOfflineScoresForCategory(competitionId, categoryId)
        .length;
  }

  // =============================================================================
  // RETRY LOGIC WITH EXPONENTIAL BACKOFF
  // =============================================================================

  /// Execute operation with retry logic for transient errors
  ///
  /// Emits [ScoreRetrying] state during retries to show progress in UI
  Future<T> _submitWithRetry<T>(
    Future<T> Function() operationTask, {
    required String operation,
    Map<String, dynamic>? metadata,
  }) async {
    int attempt = 0;

    while (true) {
      try {
        attempt++;

        if (attempt > 1) {
          // Emit retrying state for UI progress
          emit(ScoreRetrying(
            attempt: attempt,
            maxAttempts: _retryConfig.maxAttempts,
            message: LocaleKeys.retryingSubmission,
          ));

          AppLogger.info(
            'Retry attempt $attempt/${_retryConfig.maxAttempts} for $operation',
            tag: 'JudgeScore',
          );
        }

        // Execute operation
        final result = await operationTask();

        // Success
        if (attempt > 1) {
          AppLogger.info(
            'Operation $operation succeeded on attempt $attempt',
            tag: 'JudgeScore',
          );
        }

        return result;
      } on RepositoryException catch (e) {
        // Check if error is transient and we haven't exceeded max attempts
        if (e.isTransient && attempt < _retryConfig.maxAttempts) {
          // Calculate delay with exponential backoff
          final delay = _retryConfig.delayForAttempt(attempt);

          AppLogger.warning(
            'Transient error on $operation (attempt $attempt/${_retryConfig.maxAttempts}), retrying in ${delay.inMilliseconds}ms',
            tag: 'JudgeScore',
          );

          // Wait before retry
          await Future.delayed(delay);
          continue; // Retry
        }

        // Non-transient error or max attempts reached - rethrow
        if (attempt >= _retryConfig.maxAttempts) {
          AppLogger.error(
            'Max retry attempts (${_retryConfig.maxAttempts}) reached for $operation',
            error: e,
            tag: 'JudgeScore',
          );
          emit(const ScoreError(LocaleKeys.maxRetriesReached));
        }

        rethrow;
      }
    }
  }

  // =============================================================================
  // CONCURRENCY ERROR HANDLING
  // =============================================================================

  /// Handle repository exceptions with specific concurrency logic
  Future<void> _handleRepositoryException(
    RepositoryException e, {
    required String competitionId,
    required String categoryId,
    required String athleteId,
    String? heatId,
    Map<String, double>? criteriaScores,
    String? comments,
    String? judgeId,
  }) async {
    AppLogger.error(
      'Repository exception: ${e.code} (HTTP ${e.statusCode})',
      error: e,
      tag: 'JudgeScore',
    );

    // 1. CONFLICT (409) - Concurrency issues
    if (e.isConcurrencyConflict) {
      _handleConcurrencyConflict(e, heatId);
      return;
    }

    // 2. GONE (410) - Resource deleted
    if (e.isResourceGone) {
      _handleResourceGone(e, heatId);
      return;
    }

    // 3. Athlete not in heat (400)
    if (e.isAthleteNotInHeat) {
      emit(HeatError(
        message: LocaleKeys.errorAthleteNotInHeatMessage,
        code: LocaleKeys.errorAthleteNotInHeat,
        details: {
          if (heatId != null) 'heatId': heatId,
          'athleteId': athleteId,
        },
      ));
      return;
    }

    // 4. Generic error - try offline fallback if available
    if (_hiveService != null && judgeId != null && criteriaScores != null) {
      try {
        await _saveScoreOffline(
          competitionId: competitionId,
          categoryId: categoryId,
          participantId: athleteId,
          judgeId: judgeId,
          criteriaScores: criteriaScores,
          comments: comments,
        );
        emit(const ScoreSavedOffline(LocaleKeys.scoreSavedOffline));
        return;
      } catch (offlineError) {
        AppLogger.error(
          'Failed to save score offline after repository error',
          error: offlineError,
          tag: 'JudgeScore',
        );
      }
    }

    // Final fallback - emit generic error
    emit(ScoreError(e.code ?? 'error_submitting_score'));
  }

  /// Handle concurrency conflict errors (HTTP 409)
  void _handleConcurrencyConflict(RepositoryException e, String? heatId) {
    AppLogger.warning(
      'Concurrency conflict detected: ${e.code}',
      tag: 'JudgeScore',
    );

    // Map specific error codes to user-friendly messages
    String errorKey;
    String messageKey;

    switch (e.code) {
      case 'heat.already.closed':
        errorKey = LocaleKeys.errorHeatClosed;
        messageKey = LocaleKeys.errorHeatClosedMessage;
        break;
      case 'score.already.reset':
        errorKey = LocaleKeys.errorScoreReset;
        messageKey = LocaleKeys.errorScoreResetMessage;
        break;
      case 'concurrent.modification':
      case 'heat.modified':
        errorKey = LocaleKeys.errorConcurrentModification;
        messageKey = LocaleKeys.errorConcurrentModificationMessage;
        break;
      default:
        errorKey = LocaleKeys.errorScoreConflict;
        messageKey = LocaleKeys.errorScoreConflictMessage;
    }

    emit(HeatError(
      message: messageKey,
      code: errorKey,
      details: {
        if (heatId != null) 'heatId': heatId,
        'statusCode': 409,
      },
    ));
  }

  /// Handle resource gone errors (HTTP 410)
  void _handleResourceGone(RepositoryException e, String? heatId) {
    AppLogger.warning(
      'Resource gone: ${e.code}',
      tag: 'JudgeScore',
    );

    // Map specific error codes
    String errorKey;
    String messageKey;

    switch (e.code) {
      case 'heat.deleted':
        errorKey = LocaleKeys.errorHeatDeleted;
        messageKey = LocaleKeys.errorHeatDeletedMessage;
        break;
      case 'score.deleted':
        errorKey = LocaleKeys.errorScoreDeleted;
        messageKey = LocaleKeys.errorScoreDeletedMessage;
        break;
      default:
        errorKey = LocaleKeys.errorResourceGone;
        messageKey = LocaleKeys.errorResourceGoneMessage;
    }

    emit(HeatError(
      message: messageKey,
      code: errorKey,
      details: {
        if (heatId != null) 'heatId': heatId,
        'statusCode': 410,
      },
    ));
  }

  // -----------------------------------------------------------------
  // LIFECYCLE
  // -----------------------------------------------------------------

  @override
  Future<void> close() {
    // Clean up auto-refresh timer
    stopAutoRefresh();
    return super.close();
  }
}
