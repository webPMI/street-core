/// REFACTORED: judge_score_cubit.dart - Con manejo de concurrencia
///
/// MEJORAS EN FASE 1:
/// - Manejo específico de HTTP 409 (Conflict) y 410 (Gone)
/// - Retry logic con exponential backoff
/// - Mejor detección de errores transitorios vs permanentes
/// - Códigos de error granulares para UI

import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import './judge_score_state.dart';
import '../../repositories/judge_score_repository.dart';
import '../../../../core/storage/hive_service.dart';
import '../../../../core/lang/locale_keys.dart';
import '../../models/offline_score.dart';
// import '../../models/heat_model.dart';
import '../../../../core/helpers/logger.dart';
import '../../../../core/crud/exceptions/repository_exception.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Configuration for retry logic
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

  /// Calculate delay for specific attempt
  Duration delayForAttempt(int attempt) {
    final calculatedDelay = initialDelay * (backoffMultiplier * attempt);
    return calculatedDelay > maxDelay ? maxDelay : calculatedDelay;
  }
}

/// Extension para identificar errores transitorios
extension RepositoryExceptionExtensions on RepositoryException {
  /// Check if error is transient (can be retried)
  bool get isTransient {
    // 5xx errors (server errors) - transitorios
    if (statusCode != null && statusCode! >= 500 && statusCode! < 600) {
      return true;
    }

    // Timeouts - transitorios
    if (code?.contains('timeout') ?? false) {
      return true;
    }

    // Network errors - transitorios
    if (code?.contains('network') ?? false) {
      return true;
    }

    return false;
  }

  /// Check if error is a concurrency conflict
  bool get isConcurrencyConflict {
    return statusCode == 409 || // HTTP Conflict
        code == 'heat.already.closed' ||
        code == 'score.already.reset' ||
        code == 'concurrent.modification' ||
        code == 'heat.modified';
  }

  /// Check if resource was deleted/gone
  bool get isResourceGone {
    return statusCode == 410 || // HTTP Gone
        code == 'heat.deleted' ||
        code == 'score.deleted';
  }

  /// Check if athlete is not in heat
  bool get isAthleteNotInHeat {
    return code == 'athlete.not.in.heat' ||
        code == 'participant.not.found';
  }
}

/// Cubit for managing judge scores with concurrency handling
class JudgeScoreCubitRefactored extends Cubit<JudgeScoreState> {
  JudgeScoreCubitRefactored(
    this._repository, {
    HiveService? hiveService,
    Connectivity? connectivity,
    RetryConfig? retryConfig,
  })  : _hiveService = hiveService,
        _connectivity = connectivity ?? Connectivity(),
        _retryConfig = retryConfig ?? const RetryConfig(),
        super(const ScoreInitial());

  final JudgeScoreRepository _repository;
  final HiveService? _hiveService;
  final Connectivity _connectivity;
  final RetryConfig _retryConfig;

  // Auto-refresh timer for heat updates
  Timer? _autoRefreshTimer;

  // ==========================================================================
  // SUBMIT SCORE WITH CONCURRENCY HANDLING
  // ==========================================================================

  /// Submit score for athlete in heat with retry logic and concurrency handling
  ///
  /// Handles:
  /// - HTTP 409 (Conflict): Heat closed, score already submitted, concurrent modification
  /// - HTTP 410 (Gone): Heat/score deleted
  /// - 5xx (Server errors): Retry with exponential backoff
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
        'heatId': heatId,
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

  // ==========================================================================
  // RETRY LOGIC
  // ==========================================================================

  /// Execute operation with retry logic for transient errors
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
          // Emit retrying state
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

  // ==========================================================================
  // CONCURRENCY ERROR HANDLING
  // ==========================================================================

  /// Handle repository exceptions with specific concurrency logic
  Future<void> _handleRepositoryException(
    RepositoryException e, {
    required String competitionId,
    required String categoryId,
    required String athleteId,
    required String heatId,
    required Map<String, double> criteriaScores,
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
          'heatId': heatId,
          'athleteId': athleteId,
        },
      ));
      return;
    }

    // 4. Generic heat errors
    if (e.code == 'heat.already.closed' || e.code == 'heat.not.active') {
      emit(HeatError(
        message: LocaleKeys.errorHeatClosedMessage,
        code: LocaleKeys.errorHeatClosed,
        details: {'heatId': heatId},
      ));
      return;
    }

    // 5. Fallback to offline save for other errors
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
          'Failed to save score offline after error',
          error: offlineError,
          tag: 'JudgeScore',
        );
      }
    }

    // 6. Final fallback - generic error
    emit(ScoreError(e.message));
  }

  /// Handle HTTP 409 Conflict errors
  void _handleConcurrencyConflict(RepositoryException e, String heatId) {
    String errorCode;
    String errorMessage;

    if (e.code == 'heat.already.closed') {
      errorCode = LocaleKeys.errorHeatClosed;
      errorMessage = LocaleKeys.errorHeatClosedMessage;
    } else if (e.code == 'score.already.reset') {
      errorCode = LocaleKeys.errorScoreAlreadyReset;
      errorMessage = LocaleKeys.errorScoreAlreadyResetMessage;
    } else if (e.code == 'concurrent.modification' || e.code == 'heat.modified') {
      errorCode = LocaleKeys.errorConcurrentModification;
      errorMessage = LocaleKeys.errorConcurrentModificationMessage;
    } else {
      errorCode = LocaleKeys.errorScoreConflict;
      errorMessage = LocaleKeys.errorScoreConflictMessage;
    }

    emit(HeatError(
      message: errorMessage,
      code: errorCode,
      details: {
        'heatId': heatId,
        'statusCode': e.statusCode,
        'backendCode': e.code,
      },
    ));
  }

  /// Handle HTTP 410 Gone errors
  void _handleResourceGone(RepositoryException e, String heatId) {
    emit(HeatError(
      message: LocaleKeys.errorHeatModifiedMessage,
      code: LocaleKeys.errorHeatModified,
      details: {
        'heatId': heatId,
        'statusCode': e.statusCode,
        'backendCode': e.code,
        'isDeleted': true,
      },
    ));
  }

  // ==========================================================================
  // HELPER METHODS (from original cubit)
  // ==========================================================================

  /// Check network connectivity
  Future<bool> _checkConnectivity() async {
    try {
      final result = await _connectivity.checkConnectivity();
      return result.contains(ConnectivityResult.mobile) ||
          result.contains(ConnectivityResult.wifi) ||
          result.contains(ConnectivityResult.ethernet);
    } catch (e) {
      AppLogger.error('Error checking connectivity', error: e, tag: 'JudgeScore');
      return false;
    }
  }

  /// Save score offline for later sync
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
    if (_hiveService == null) return;

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

    AppLogger.info(
      'Score saved offline for participant $participantId',
      tag: 'JudgeScore',
    );
  }

  /// Load round heats (placeholder - implement from original cubit)
  Future<void> loadRoundHeats(String competitionId, String roundId) async {
    // TODO: Implement from original cubit
    AppLogger.info('loadRoundHeats called', tag: 'JudgeScore');
  }

  @override
  Future<void> close() {
    _autoRefreshTimer?.cancel();
    return super.close();
  }
}
