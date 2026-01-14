// lib/features/competitions/services/offline_sync_service.dart

import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

import '../../../core/storage/hive_service.dart';
import '../../../core/helpers/logger.dart';
import '../models/offline_score.dart';
import '../repositories/judge_score_repository.dart';

/// Service for syncing offline scores when connectivity is restored
class OfflineSyncService {
  final HiveService _hiveService;
  final JudgeScoreRepository _scoreRepository;
  final Connectivity _connectivity;

  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  Timer? _syncTimer;

  bool _isSyncing = false;
  int _pendingCount = 0;
  String? _lastError;

  /// Stream controller for sync status
  final _syncStatusController = StreamController<SyncStatus>.broadcast();

  /// Stream of sync status updates
  Stream<SyncStatus> get syncStatus => _syncStatusController.stream;

  /// Get current pending count
  int get pendingCount => _pendingCount;

  /// Get last sync error
  String? get lastError => _lastError;

  /// Check if currently syncing
  bool get isSyncing => _isSyncing;

  OfflineSyncService({
    required HiveService hiveService,
    required JudgeScoreRepository scoreRepository,
    Connectivity? connectivity,
  })  : _hiveService = hiveService,
        _scoreRepository = scoreRepository,
        _connectivity = connectivity ?? Connectivity();

  /// Initialize the sync service
  Future<void> init() async {
    try {
      // Update pending count
      _updatePendingCount();

      // Listen to connectivity changes
      _connectivitySubscription =
          _connectivity.onConnectivityChanged.listen(_onConnectivityChanged);

      // Check current connectivity
      final result = await _connectivity.checkConnectivity();
      _onConnectivityChanged(result);

      AppLogger.info('OfflineSyncService initialized (pending: $_pendingCount)', tag: 'OfflineSync');
    } catch (e) {
      AppLogger.error('Error initializing OfflineSyncService', error: e, tag: 'OfflineSync');
    }
  }

  /// Handle connectivity changes
  void _onConnectivityChanged(List<ConnectivityResult> results) {
    final hasConnection = results.any((result) =>
      result != ConnectivityResult.none
    );

    AppLogger.info('Connectivity changed: $hasConnection', tag: 'OfflineSync');

    if (hasConnection && _pendingCount > 0) {
      // Delay sync a bit to ensure stable connection
      _scheduleSyncRetry(const Duration(seconds: 2));
    }
  }

  /// Update pending count
  void _updatePendingCount() {
    _pendingCount = _hiveService.getPendingScoresCount();
    _emitStatus();
  }

  /// Emit current sync status
  void _emitStatus() {
    _syncStatusController.add(
      SyncStatus(
        isSyncing: _isSyncing,
        pendingCount: _pendingCount,
        lastError: _lastError,
      ),
    );
  }

  /// Schedule a sync retry
  void _scheduleSyncRetry(Duration delay) {
    _syncTimer?.cancel();
    _syncTimer = Timer(delay, () => syncPendingScores());
  }

  /// Sync all pending offline scores
  Future<SyncResult> syncPendingScores() async {
    if (_isSyncing) {
      AppLogger.warning('Sync already in progress');
      return SyncResult(
        success: false,
        syncedCount: 0,
        failedCount: 0,
        error: 'Sync already in progress',
      );
    }

    try {
      _isSyncing = true;
      _lastError = null;
      _emitStatus();

      final offlineScores = _hiveService.getAllOfflineScores();
      final scoresToSync =
          offlineScores.where((s) => !s.maxSyncAttemptsReached).toList();

      if (scoresToSync.isEmpty) {
        AppLogger.info('No offline scores to sync');
        _isSyncing = false;
        _updatePendingCount();
        return SyncResult(
          success: true,
          syncedCount: 0,
          failedCount: 0,
        );
      }

      AppLogger.info('Starting sync (${scoresToSync.length} scores)', tag: 'OfflineSync');

      int syncedCount = 0;
      int failedCount = 0;
      final errors = <String>[];

      for (final offlineScore in scoresToSync) {
        try {
          await _syncSingleScore(offlineScore);
          await _hiveService.deleteOfflineScore(offlineScore.id);
          syncedCount++;
        } catch (e) {
          failedCount++;
          final errorMsg = e.toString();
          errors.add(errorMsg);

          // Update sync attempts
          final updatedScore = offlineScore.copyWith(
            syncAttempts: offlineScore.syncAttempts + 1,
            lastSyncError: errorMsg,
          );
          await _hiveService.updateOfflineScore(updatedScore);

          AppLogger.error('Error syncing score ${offlineScore.id} (attempt ${updatedScore.syncAttempts})', error: e, tag: 'OfflineSync');
        }
      }

      _lastError = errors.isNotEmpty ? errors.first : null;

      AppLogger.info('Sync completed (synced: $syncedCount, failed: $failedCount)', tag: 'OfflineSync');

      return SyncResult(
        success: failedCount == 0,
        syncedCount: syncedCount,
        failedCount: failedCount,
        error: _lastError,
      );
    } catch (e) {
      _lastError = e.toString();
      AppLogger.error('Error during sync', error: e, tag: 'OfflineSync');

      return SyncResult(
        success: false,
        syncedCount: 0,
        failedCount: _pendingCount,
        error: _lastError,
      );
    } finally {
      _isSyncing = false;
      _updatePendingCount();

      // Schedule retry if there are still pending scores
      if (_pendingCount > 0) {
        _scheduleSyncRetry(_getRetryDelay());
      }
    }
  }

  /// Sync a single offline score
  Future<void> _syncSingleScore(OfflineScore offlineScore) async {
    if (offlineScore.isUpdate && offlineScore.existingScoreId != null) {
      // Update existing score
      await _scoreRepository.updateScore(
        offlineScore.competitionId,
        offlineScore.categoryId,
        offlineScore.existingScoreId!,
        offlineScore.toApiJson(),
      );
    } else {
      // Submit new score
      await _scoreRepository.submitScore(
        offlineScore.competitionId,
        offlineScore.categoryId,
        offlineScore.toApiJson(),
      );
    }

    AppLogger.info('Score synced: ${offlineScore.id}', tag: 'OfflineSync');
  }

  /// Get retry delay with exponential backoff
  Duration _getRetryDelay() {
    // Start with 30 seconds, max 5 minutes
    final baseDelay = const Duration(seconds: 30);
    final maxDelay = const Duration(minutes: 5);

    // Simple exponential backoff based on pending count
    final delay = Duration(
      seconds: (baseDelay.inSeconds * (1 + (_pendingCount ~/ 5))).clamp(
        baseDelay.inSeconds,
        maxDelay.inSeconds,
      ),
    );

    return delay;
  }

  /// Manually trigger sync
  Future<SyncResult> forceSyncNow() async {
    AppLogger.info('Manual sync triggered', tag: 'OfflineSync');
    return syncPendingScores();
  }

  /// Clear all failed scores (use with caution)
  Future<void> clearFailedScores() async {
    try {
      final scores = _hiveService.getAllOfflineScores();
      final failedScores = scores.where((s) => s.maxSyncAttemptsReached);

      for (final score in failedScores) {
        await _hiveService.deleteOfflineScore(score.id);
      }

      _updatePendingCount();

      AppLogger.info('Failed scores cleared (${failedScores.length})', tag: 'OfflineSync');
    } catch (e) {
      AppLogger.error('Error clearing failed scores', error: e, tag: 'OfflineSync');
      rethrow;
    }
  }

  /// Dispose and cleanup
  Future<void> dispose() async {
    _syncTimer?.cancel();
    await _connectivitySubscription?.cancel();
    await _syncStatusController.close();
    AppLogger.info('OfflineSyncService disposed', tag: 'OfflineSync');
  }
}

/// Sync status for UI
@immutable
class SyncStatus {
  final bool isSyncing;
  final int pendingCount;
  final String? lastError;

  const SyncStatus({
    required this.isSyncing,
    required this.pendingCount,
    this.lastError,
  });

  bool get hasPendingScores => pendingCount > 0;
  bool get hasError => lastError != null;
}

/// Result of a sync operation
@immutable
class SyncResult {
  final bool success;
  final int syncedCount;
  final int failedCount;
  final String? error;

  const SyncResult({
    required this.success,
    required this.syncedCount,
    required this.failedCount,
    this.error,
  });

  int get totalAttempted => syncedCount + failedCount;
}
