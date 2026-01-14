// lib/features/competitions/repositories/heat_repository.dart

import '../../../core/crud/crud.dart';
import '../competitions_uris.dart';
import '../models/heat_model.dart';

/// Repository for managing competition heats
/// Heats organize athletes into groups for scoring
class HeatRepository extends BaseRepository {
  HeatRepository(super.apiService);

  // ==========================================================================
  // PUBLIC GET OPERATIONS (no auth required)
  // ==========================================================================

  /// Get all heats for a competition
  Future<List<Heat>> getCompetitionHeats(String competitionId) async {
    return fetchList<Heat>(
      endpoint: CompetitionsUris.getCompetitionHeats(competitionId),
      fromJson: Heat.fromJson,
      errorMessage: 'Error fetching competition heats',
      requiredToken: false, // Public endpoint
      useCache: false, // Don't cache as heats update frequently
    );
  }

  /// Get a single heat by ID
  Future<Heat> getHeat(String competitionId, String heatId) async {
    return fetchById<Heat>(
      endpoint: CompetitionsUris.getHeat(competitionId, heatId),
      fromJson: Heat.fromJson,
      errorMessage: 'Error fetching heat',
      requiredToken: false, // Public endpoint
      useCache: false,
    );
  }

  /// Get all heats for a specific round
  Future<List<Heat>> getRoundHeats(
    String competitionId,
    String roundId,
  ) async {
    return fetchList<Heat>(
      endpoint: CompetitionsUris.getRoundHeats(competitionId, roundId),
      fromJson: Heat.fromJson,
      errorMessage: 'Error fetching round heats',
      requiredToken: false, // Public endpoint
      useCache: false,
    );
  }

  /// Get heats for a specific category and round
  Future<List<Heat>> getCategoryHeats(
    String competitionId,
    String roundId,
    String categoryId,
  ) async {
    return fetchList<Heat>(
      endpoint: CompetitionsUris.getCategoryHeats(
        competitionId,
        roundId,
        categoryId,
      ),
      fromJson: Heat.fromJson,
      errorMessage: 'Error fetching category heats',
      requiredToken: false, // Public endpoint
      useCache: false,
    );
  }

  // ==========================================================================
  // PROTECTED OPERATIONS (require auth - admin/organizer)
  // ==========================================================================

  /// Generate heats for a round
  ///
  /// Request body example:
  /// ```dart
  /// {
  ///   'categoryId': 'optional-category-id',
  ///   'heatSize': 5,
  ///   'mode': 'sequential', // or 'simultaneous'
  ///   'enableSeeding': true,
  ///   'seedingSource': 'manual',
  ///   'seedingType': 'snake',
  ///   'athleteRankings': {'athleteId': 1, ...}
  /// }
  /// ```
  ///
  /// Throws [RepositoryException] with backend error code for translation:
  /// - `heat.round.not.found` - Round doesn't exist
  /// - `heat.exceeds.round.max` - Too many athletes for round capacity
  /// - `heat.invalid.mode` - Invalid mode value
  /// - etc. (see backend heat_messages.go)
  Future<List<Heat>> generateHeats(
    String competitionId,
    String roundId,
    Map<String, dynamic> heatConfig,
  ) async {
    return executeSafely<List<Heat>>(
      operation: () async {
        final response = await apiService.useFetch<List<dynamic>>(
          CompetitionsUris.generateHeats(competitionId, roundId),
          method: 'POST',
          requiredToken: true,
          body: heatConfig,
          fromJsonT: (data) => data as List<dynamic>,
        );

        if (response.status == 'success' && response.data != null) {
          final heats = response.data!
              .map((json) => Heat.fromJson(json as Map<String, dynamic>))
              .toList();

          // Invalidate cache after generating heats
          cache.invalidatePrefix('list.');

          return heats;
        } else {
          throw RepositoryException.server(
            response.message,
            code: response.message,
          );
        }
      },
      errorMessage: 'Error generating heats',
      enableRetry: false,
    );
  }

  /// Mark a heat as completed
  ///
  /// This will auto-advance Round.currentHeat to the next heat
  ///
  /// Throws [RepositoryException] with backend error code:
  /// - `heat.not.found` - Heat doesn't exist
  /// - `heat.already.closed` - Heat is already completed
  /// - `heat.not.active` - Heat must be active to complete
  Future<void> completeHeat(String competitionId, String heatId) async {
    await executeAction(
      endpoint: CompetitionsUris.completeHeat(competitionId, heatId),
      method: 'POST',
      requiredToken: true,
      errorMessage: 'Error completing heat',
      enableRetry: false,
    );

    // Invalidate cache after completing heat
    cache.invalidatePrefix('list.');
  }

  /// Reset (delete) all heats for a round - DESTRUCTIVE operation
  ///
  /// Requires double confirmation from frontend
  ///
  /// Request body:
  /// ```dart
  /// {
  ///   'confirmationText': 'RESET HEATS'  // Must match exactly
  /// }
  /// ```
  ///
  /// Throws [RepositoryException] with backend error code:
  /// - `heat.reset.no.confirmation` - Missing or incorrect confirmation
  /// - `heat.reset.no.heats` - No heats to reset
  /// - `heat.round.not.found` - Round doesn't exist
  Future<void> resetHeats(
    String competitionId,
    String roundId,
    String confirmationText,
  ) async {
    await executeAction(
      endpoint: CompetitionsUris.resetHeats(competitionId, roundId),
      method: 'POST',
      requiredToken: true,
      data: {'confirmationText': confirmationText},
      errorMessage: 'Error resetting heats',
      enableRetry: false,
    );

    // Invalidate cache after resetting heats
    cache.invalidatePrefix('list.');
  }

  // ==========================================================================
  // HELPER METHODS
  // ==========================================================================

  /// Get heats for a round and filter by status
  Future<List<Heat>> getRoundHeatsByStatus(
    String competitionId,
    String roundId,
    HeatStatus status,
  ) async {
    final heats = await getRoundHeats(competitionId, roundId);
    return heats.where((heat) => heat.status == status).toList();
  }

  /// Get active heat for a round (if any)
  Future<Heat?> getActiveHeat(String competitionId, String roundId) async {
    final heats = await getRoundHeatsByStatus(
      competitionId,
      roundId,
      HeatStatus.active,
    );
    return heats.isEmpty ? null : heats.first;
  }

  /// Get next pending heat for a round (if any)
  Future<Heat?> getNextPendingHeat(
    String competitionId,
    String roundId,
  ) async {
    final heats = await getRoundHeatsByStatus(
      competitionId,
      roundId,
      HeatStatus.pending,
    );
    if (heats.isEmpty) return null;

    // Return heat with lowest order number
    heats.sort((a, b) => a.order.compareTo(b.order));
    return heats.first;
  }

  /// Check if a specific athlete is in any heat for a round
  Future<bool> isAthleteInRoundHeats(
    String competitionId,
    String roundId,
    String athleteId,
  ) async {
    final heats = await getRoundHeats(competitionId, roundId);
    return heats.any((heat) => heat.hasAthlete(athleteId));
  }

  /// Find which heat an athlete is assigned to in a round
  Future<Heat?> findAthleteHeat(
    String competitionId,
    String roundId,
    String athleteId,
  ) async {
    final heats = await getRoundHeats(competitionId, roundId);
    try {
      return heats.firstWhere((heat) => heat.hasAthlete(athleteId));
    } catch (e) {
      return null; // Athlete not in any heat
    }
  }

  /// Get completion statistics for a round's heats
  Future<HeatCompletionStats> getCompletionStats(
    String competitionId,
    String roundId,
  ) async {
    final heats = await getRoundHeats(competitionId, roundId);

    return HeatCompletionStats(
      total: heats.length,
      completed: heats.where((h) => h.isCompleted).length,
      active: heats.where((h) => h.isActive).length,
      pending: heats.where((h) => h.isPending).length,
    );
  }
}

/// Heat completion statistics
class HeatCompletionStats {
  const HeatCompletionStats({
    required this.total,
    required this.completed,
    required this.active,
    required this.pending,
  });

  final int total;
  final int completed;
  final int active;
  final int pending;

  /// Get completion percentage
  double get percentage {
    if (total == 0) return 0.0;
    return (completed / total) * 100;
  }

  /// Check if all heats are completed
  bool get isFullyCompleted => total > 0 && completed == total;

  /// Check if no heats have started
  bool get isNotStarted => active == 0 && completed == 0;
}
