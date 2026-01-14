// lib/core/storage/hive_service.dart

import 'package:hive_flutter/hive_flutter.dart';
import '../../features/competitions/models/offline_score.dart';
import '../../features/competitions/models/draft_score.dart';
import '../helpers/logger.dart';
import 'models/guide_progress.dart';

/// Service for managing Hive local storage
/// Replaces SharedPreferences with better performance and type safety
class HiveService {
  static const String _offlineScoresBoxName = 'offline_scores';
  static const String _draftScoresBoxName = 'draft_scores'; // CONTINGENCIA 4
  static const String _preferencesBoxName = 'preferences';
  static const String _cacheBoxName = 'cache';

  Box<OfflineScore>? _scoresBox;
  Box<DraftScore>? _draftsBox; // CONTINGENCIA 4: Auto-save drafts
  Box? _prefsBox;
  Box? _cacheBox;

  /// Initialize Hive and register adapters
  Future<void> init() async {
    try {
      await Hive.initFlutter();

      // Register adapters
      if (!Hive.isAdapterRegistered(1)) {
        Hive.registerAdapter(OfflineScoreAdapter());
      }
      if (!Hive.isAdapterRegistered(4)) {
        Hive.registerAdapter(DraftScoreAdapter()); // CONTINGENCIA 4
      }
      if (!Hive.isAdapterRegistered(6)) {
        Hive.registerAdapter(GuideProgressAdapter()); // Help Guide System
      }

      // Open boxes
      _scoresBox = await Hive.openBox<OfflineScore>(_offlineScoresBoxName);
      _draftsBox = await Hive.openBox<DraftScore>(_draftScoresBoxName); // CONTINGENCIA 4
      _prefsBox = await Hive.openBox(_preferencesBoxName);
      _cacheBox = await Hive.openBox(_cacheBoxName);

      AppLogger.info('HiveService initialized successfully', tag: 'HiveService');
    } catch (e) {
      AppLogger.error('Error initializing HiveService', error: e, tag: 'HiveService');
      rethrow;
    }
  }

  /// Get offline scores box
  Box<OfflineScore> get scoresBox {
    if (_scoresBox == null || !_scoresBox!.isOpen) {
      throw Exception('Hive not initialized. Call init() first.');
    }
    return _scoresBox!;
  }

  /// Get preferences box
  Box get prefsBox {
    if (_prefsBox == null || !_prefsBox!.isOpen) {
      throw Exception('Hive not initialized. Call init() first.');
    }
    return _prefsBox!;
  }

  /// Get cache box
  Box get cacheBox {
    if (_cacheBox == null || !_cacheBox!.isOpen) {
      throw Exception('Hive not initialized. Call init() first.');
    }
    return _cacheBox!;
  }

  /// Save an offline score
  Future<void> saveOfflineScore(OfflineScore score) async {
    try {
      await scoresBox.put(score.id, score);
      AppLogger.info('Offline score saved: ${score.id}', tag: 'HiveService');
    } catch (e) {
      AppLogger.error('Error saving offline score', error: e, tag: 'HiveService');
      rethrow;
    }
  }

  /// Get all offline scores
  List<OfflineScore> getAllOfflineScores() {
    try {
      return scoresBox.values.toList();
    } catch (e) {
      AppLogger.error('Error getting offline scores', error: e, tag: 'HiveService');
      return [];
    }
  }

  /// Get offline scores for a specific competition
  List<OfflineScore> getOfflineScoresForCompetition(String competitionId) {
    try {
      return scoresBox.values
          .where((score) => score.competitionId == competitionId)
          .toList();
    } catch (e) {
      AppLogger.error('Error getting offline scores for competition', error: e, tag: 'HiveService');
      return [];
    }
  }

  /// Get offline scores for a specific category
  List<OfflineScore> getOfflineScoresForCategory(
    String competitionId,
    String categoryId,
  ) {
    try {
      return scoresBox.values
          .where((score) =>
              score.competitionId == competitionId &&
              score.categoryId == categoryId)
          .toList();
    } catch (e) {
      AppLogger.error('Error getting offline scores for category', error: e, tag: 'HiveService');
      return [];
    }
  }

  /// Update an offline score
  Future<void> updateOfflineScore(OfflineScore score) async {
    try {
      await scoresBox.put(score.id, score);
      AppLogger.info('Offline score updated: ${score.id} (attempts: ${score.syncAttempts})', tag: 'HiveService');
    } catch (e) {
      AppLogger.error('Error updating offline score', error: e, tag: 'HiveService');
      rethrow;
    }
  }

  /// Delete an offline score
  Future<void> deleteOfflineScore(String scoreId) async {
    try {
      await scoresBox.delete(scoreId);
      AppLogger.info('Offline score deleted: $scoreId', tag: 'HiveService');
    } catch (e) {
      AppLogger.error('Error deleting offline score', error: e, tag: 'HiveService');
      rethrow;
    }
  }

  /// Delete all offline scores for a competition
  Future<void> deleteOfflineScoresForCompetition(String competitionId) async {
    try {
      final scores = getOfflineScoresForCompetition(competitionId);
      for (final score in scores) {
        await scoresBox.delete(score.id);
      }
      AppLogger.info('Deleted ${scores.length} offline scores for competition: $competitionId', tag: 'HiveService');
    } catch (e) {
      AppLogger.error('Error deleting offline scores for competition', error: e, tag: 'HiveService');
      rethrow;
    }
  }

  /// Get count of pending offline scores
  int getPendingScoresCount() {
    try {
      return scoresBox.values.where((score) => !score.maxSyncAttemptsReached).length;
    } catch (e) {
      AppLogger.error('Error getting pending scores count', error: e, tag: 'HiveService');
      return 0;
    }
  }

  /// Clear all offline scores (use with caution)
  Future<void> clearAllOfflineScores() async {
    try {
      await scoresBox.clear();
      AppLogger.warning('All offline scores cleared', tag: 'HiveService');
    } catch (e) {
      AppLogger.error('Error clearing offline scores', error: e, tag: 'HiveService');
      rethrow;
    }
  }

  // =================================================================
  // PREFERENCES - Replaces SharedPreferences
  // =================================================================

  /// Save preference value (String, int, bool, double, List, Map)
  Future<void> savePref<T>(String key, T value) async {
    try {
      await prefsBox.put(key, value);
      AppLogger.debug('Preference saved: $key', tag: 'HiveService');
    } catch (e) {
      AppLogger.error('Error saving preference', error: e, tag: 'HiveService');
      rethrow;
    }
  }

  /// Read preference value
  T? readPref<T>(String key, {T? defaultValue}) {
    try {
      final value = prefsBox.get(key, defaultValue: defaultValue);
      return value as T?;
    } catch (e) {
      AppLogger.error('Error reading preference', error: e, tag: 'HiveService');
      return defaultValue;
    }
  }

  /// Delete preference
  Future<void> deletePref(String key) async {
    try {
      await prefsBox.delete(key);
      AppLogger.debug('Preference deleted: $key', tag: 'HiveService');
    } catch (e) {
      AppLogger.error('Error deleting preference', error: e, tag: 'HiveService');
      rethrow;
    }
  }

  /// Clear all preferences
  Future<void> clearPrefs() async {
    try {
      await prefsBox.clear();
      AppLogger.warning('All preferences cleared', tag: 'HiveService');
    } catch (e) {
      AppLogger.error('Error clearing preferences', error: e, tag: 'HiveService');
      rethrow;
    }
  }

  /// Check if preference exists
  bool hasPref(String key) {
    try {
      return prefsBox.containsKey(key);
    } catch (e) {
      AppLogger.error('Error checking preference', error: e, tag: 'HiveService');
      return false;
    }
  }

  // =================================================================
  // CACHE - For temporary data with optional TTL
  // =================================================================

  /// Save to cache
  Future<void> saveCache<T>(String key, T value) async {
    try {
      await cacheBox.put(key, value);
      AppLogger.debug('Cache saved: $key', tag: 'HiveService');
    } catch (e) {
      AppLogger.error('Error saving cache', error: e, tag: 'HiveService');
      rethrow;
    }
  }

  /// Read from cache
  T? readCache<T>(String key) {
    try {
      return cacheBox.get(key) as T?;
    } catch (e) {
      AppLogger.error('Error reading cache', error: e, tag: 'HiveService');
      return null;
    }
  }

  /// Delete from cache
  Future<void> deleteCache(String key) async {
    try {
      await cacheBox.delete(key);
      AppLogger.debug('Cache deleted: $key', tag: 'HiveService');
    } catch (e) {
      AppLogger.error('Error deleting cache', error: e, tag: 'HiveService');
      rethrow;
    }
  }

  /// Clear all cache
  Future<void> clearCache() async {
    try {
      await cacheBox.clear();
      AppLogger.info('All cache cleared', tag: 'HiveService');
    } catch (e) {
      AppLogger.error('Error clearing cache', error: e, tag: 'HiveService');
      rethrow;
    }
  }

  // =================================================================
  // CLEANUP
  // =================================================================

  // =============================================================================
  // DRAFT SCORES - CONTINGENCIA 4: Auto-Save
  // =============================================================================

  /// Save or update a draft score (auto-save on every slider change)
  Future<void> saveDraft(DraftScore draft) async {
    try {
      await _draftsBox?.put(draft.id, draft);
      AppLogger.info('Draft saved: ${draft.id}', tag: 'HiveService');
    } catch (e) {
      AppLogger.error('Error saving draft', error: e, tag: 'HiveService');
      rethrow;
    }
  }

  /// Get draft by ID
  DraftScore? getDraft(String draftId) {
    try {
      return _draftsBox?.get(draftId);
    } catch (e) {
      AppLogger.error('Error getting draft', error: e, tag: 'HiveService');
      return null;
    }
  }

  /// Get all drafts
  List<DraftScore> getAllDrafts() {
    try {
      return _draftsBox?.values.toList() ?? [];
    } catch (e) {
      AppLogger.error('Error getting all drafts', error: e, tag: 'HiveService');
      return [];
    }
  }

  /// Get drafts for a specific competition
  List<DraftScore> getDraftsForCompetition(String competitionId) {
    try {
      return _draftsBox?.values
              .where((draft) => draft.competitionId == competitionId)
              .toList() ??
          [];
    } catch (e) {
      AppLogger.error('Error getting drafts for competition', error: e, tag: 'HiveService');
      return [];
    }
  }

  /// Delete a draft by ID
  Future<void> deleteDraft(String draftId) async {
    try {
      await _draftsBox?.delete(draftId);
      AppLogger.info('Draft deleted: $draftId', tag: 'HiveService');
    } catch (e) {
      AppLogger.error('Error deleting draft', error: e, tag: 'HiveService');
      rethrow;
    }
  }

  /// Clear all drafts
  Future<void> clearAllDrafts() async {
    try {
      await _draftsBox?.clear();
      AppLogger.info('All drafts cleared', tag: 'HiveService');
    } catch (e) {
      AppLogger.error('Error clearing all drafts', error: e, tag: 'HiveService');
      rethrow;
    }
  }

  /// Clear stale drafts (older than threshold)
  Future<int> clearStaleDrafts({Duration threshold = const Duration(hours: 24)}) async {
    try {
      final allDrafts = getAllDrafts();
      final staleDrafts = allDrafts.where((draft) => draft.isStale(threshold: threshold));

      int count = 0;
      for (final draft in staleDrafts) {
        await deleteDraft(draft.id);
        count++;
      }

      if (count > 0) {
        AppLogger.info('Cleared $count stale drafts', tag: 'HiveService');
      }

      return count;
    } catch (e) {
      AppLogger.error('Error clearing stale drafts', error: e, tag: 'HiveService');
      return 0;
    }
  }

  /// Close Hive
  Future<void> close() async {
    try {
      await _scoresBox?.close();
      await _draftsBox?.close(); // CONTINGENCIA 4
      await _prefsBox?.close();
      await _cacheBox?.close();
      AppLogger.info('HiveService closed', tag: 'HiveService');
    } catch (e) {
      AppLogger.error('Error closing HiveService', error: e, tag: 'HiveService');
    }
  }

  /// Clear all data (use with caution!)
  Future<void> clearAll() async {
    try {
      await clearPrefs();
      await clearCache();
      await clearAllOfflineScores();
      await clearAllDrafts(); // CONTINGENCIA 4
      AppLogger.warning('ALL Hive data cleared', tag: 'HiveService');
    } catch (e) {
      AppLogger.error('Error clearing all data', error: e, tag: 'HiveService');
      rethrow;
    }
  }

  /// Dispose and cleanup
  Future<void> dispose() async {
    await close();
  }
}
