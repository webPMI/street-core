/// Outbox Service - Patrón Outbox para manejo de scores offline
///
/// CONTINGENCIA 1: "Efecto Estadio"
/// Cuando Wi-Fi/4G colapsa, guarda scores localmente y reintenta envío

import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../../core/storage/hive_service.dart';
import '../../../core/helpers/logger.dart';
import '../models/offline_score.dart';
import '../repositories/judge_score_repository.dart';

/// Status of outbox synchronization
class OutboxStatus {
  final int unsyncedCount;
  final bool isSyncing;

  const OutboxStatus({
    required this.unsyncedCount,
    this.isSyncing = false,
  });

  bool get hasPendingScores => unsyncedCount > 0;

  OutboxStatus copyWith({
    int? unsyncedCount,
    bool? isSyncing,
  }) {
    return OutboxStatus(
      unsyncedCount: unsyncedCount ?? this.unsyncedCount,
      isSyncing: isSyncing ?? this.isSyncing,
    );
  }
}

/// Result of sync operation
enum OutboxSyncResult {
  success,
  failed,
  noConnection,
  maxAttemptsReached,
}

/// Batch retry result
class OutboxBatchResult {
  final int totalAttempted;
  final int successCount;
  final int failedCount;
  final bool noConnection;

  const OutboxBatchResult({
    required this.totalAttempted,
    required this.successCount,
    required this.failedCount,
    this.noConnection = false,
  });

  bool get allSucceeded => successCount == totalAttempted && totalAttempted > 0;
  bool get someSucceeded => successCount > 0 && successCount < totalAttempted;
  bool get allFailed => failedCount == totalAttempted && totalAttempted > 0;
}

/// Outbox Service for offline score management
class OutboxService {
  OutboxService({
    required HiveService hiveService,
    required JudgeScoreRepository repository,
    Connectivity? connectivity,
  })  : _hiveService = hiveService,
        _repository = repository,
        _connectivity = connectivity ?? Connectivity();

  final HiveService _hiveService;
  final JudgeScoreRepository _repository;
  final Connectivity _connectivity;

  final _statusController = StreamController<OutboxStatus>.broadcast();
  Stream<OutboxStatus> get statusStream => _statusController.stream;

  static const int maxSyncAttempts = 5;

  /// Get current status
  OutboxStatus getStatus() {
    final pending = getPendingScores();
    return OutboxStatus(unsyncedCount: pending.length);
  }

  /// Get all pending scores
  List<OfflineScore> getPendingScores() {
    return _hiveService.getAllOfflineScores();
  }

  /// Get pending scores count
  int getPendingCount() {
    return getPendingScores().length;
  }

  /// Retry single score
  Future<OutboxSyncResult> retrySingle(OfflineScore score) async {
    // Check connectivity
    final hasConnection = await _checkConnectivity();
    if (!hasConnection) {
      _emitStatus();
      return OutboxSyncResult.noConnection;
    }

    // Check max attempts
    if (score.maxSyncAttemptsReached) {
      AppLogger.warning(
        'Max sync attempts reached for score ${score.id}',
        tag: 'OutboxService',
      );
      return OutboxSyncResult.maxAttemptsReached;
    }

    // Try to sync
    try {
      await _repository.submitScore(
        score.competitionId,
        score.categoryId,
        score.toApiJson(),
      );

      // Success - delete from outbox
      await _hiveService.deleteOfflineScore(score.id);
      AppLogger.info(
        'Score synced successfully: ${score.id}',
        tag: 'OutboxService',
      );

      _emitStatus();
      return OutboxSyncResult.success;
    } catch (e) {
      // Failed - increment attempt counter
      final updatedScore = score.copyWith(
        syncAttempts: score.syncAttempts + 1,
      );
      await _hiveService.updateOfflineScore(updatedScore);

      AppLogger.error(
        'Failed to sync score ${score.id} (attempt ${updatedScore.syncAttempts}/$maxSyncAttempts)',
        error: e,
        tag: 'OutboxService',
      );

      _emitStatus();
      return updatedScore.maxSyncAttemptsReached
          ? OutboxSyncResult.maxAttemptsReached
          : OutboxSyncResult.failed;
    }
  }

  /// Retry all pending scores
  Future<OutboxBatchResult> retryAll() async {
    // Check connectivity
    final hasConnection = await _checkConnectivity();
    if (!hasConnection) {
      return OutboxBatchResult(
        totalAttempted: 0,
        successCount: 0,
        failedCount: 0,
        noConnection: true,
      );
    }

    final pendingScores = getPendingScores();
    int successCount = 0;
    int failedCount = 0;

    _statusController.add(OutboxStatus(
      unsyncedCount: pendingScores.length,
      isSyncing: true,
    ));

    for (final score in pendingScores) {
      // Skip if max attempts reached
      if (score.maxSyncAttemptsReached) {
        failedCount++;
        continue;
      }

      final result = await retrySingle(score);
      if (result == OutboxSyncResult.success) {
        successCount++;
      } else {
        failedCount++;
      }
    }

    _emitStatus();

    return OutboxBatchResult(
      totalAttempted: pendingScores.length,
      successCount: successCount,
      failedCount: failedCount,
    );
  }

  /// Auto-retry pending scores (call on app resume or connectivity restored)
  Future<void> autoRetry() async {
    final hasConnection = await _checkConnectivity();
    if (!hasConnection) return;

    final pending = getPendingScores();
    if (pending.isEmpty) return;

    AppLogger.info(
      'Auto-retrying ${pending.length} pending scores',
      tag: 'OutboxService',
    );

    await retryAll();
  }

  /// Check connectivity
  Future<bool> _checkConnectivity() async {
    try {
      final result = await _connectivity.checkConnectivity();
      return result.contains(ConnectivityResult.mobile) ||
          result.contains(ConnectivityResult.wifi) ||
          result.contains(ConnectivityResult.ethernet);
    } catch (e) {
      AppLogger.error('Error checking connectivity', error: e, tag: 'OutboxService');
      return false;
    }
  }

  /// Emit current status
  void _emitStatus() {
    if (!_statusController.isClosed) {
      _statusController.add(getStatus());
    }
  }

  /// Dispose
  void dispose() {
    _statusController.close();
  }
}
