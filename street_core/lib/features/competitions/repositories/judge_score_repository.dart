// lib/domain/judge_score_repository.dart

import '../../../core/crud/crud.dart';
import '../competitions_uris.dart';
import '../models/judge_score_model.dart';

/// Repository for managing judge scores
/// Note: Scores are managed at competition level, not category level
class JudgeScoreRepository extends BaseRepository {
  JudgeScoreRepository(super.apiService);

  /// Get all scores for a competition
  Future<List<JudgeScore>> getCompetitionScores(String competitionId) async {
    return fetchList<JudgeScore>(
      endpoint: CompetitionsUris.getScores(competitionId),
      fromJson: JudgeScore.fromJson,
      errorMessage: 'Error fetching competition scores',
      useCache: false, // Don't cache scores as they update frequently
    );
  }

  /// Submit a score for a competition (legacy - competition level)
  Future<JudgeScore> submitCompetitionScore(
    String competitionId,
    Map<String, dynamic> scoreData,
  ) async {
    return create<JudgeScore>(
      endpoint: CompetitionsUris.submitScores(competitionId),
      data: scoreData,
      fromJson: JudgeScore.fromJson,
      errorMessage: 'Error submitting score',
    );
  }

  /// Get scores for a specific athlete in a competition
  Future<List<JudgeScore>> getAthleteScores(
    String competitionId,
    String athleteId,
  ) async {
    return fetchList<JudgeScore>(
      endpoint: CompetitionsUris.getScoresByAthlete(competitionId, athleteId),
      fromJson: JudgeScore.fromJson,
      errorMessage: 'Error fetching athlete scores',
      useCache: false,
    );
  }

  /// Get scores for a specific round in a competition
  Future<List<JudgeScore>> getRoundScores(
    String competitionId,
    String roundId,
  ) async {
    return fetchList<JudgeScore>(
      endpoint: CompetitionsUris.getScoresByRound(competitionId, roundId),
      fromJson: JudgeScore.fromJson,
      errorMessage: 'Error fetching round scores',
      useCache: false,
    );
  }

  /// Get competition leaderboard/ranking
  Future<List<CategoryRankingEntry>> getLeaderboard(
    String competitionId,
  ) async {
    return fetchList<CategoryRankingEntry>(
      endpoint: CompetitionsUris.leaderboard(competitionId),
      fromJson: CategoryRankingEntry.fromJson,
      requiredToken: false, // Public endpoint
      errorMessage: 'Error fetching leaderboard',
      cacheTTL: const Duration(minutes: 2), // Short cache for live results
    );
  }

  /// Get my scores as a judge for a competition
  Future<List<JudgeScore>> getMyScoresForCompetition(
    String competitionId,
    String judgeId,
  ) async {
    final allScores = await getCompetitionScores(competitionId);
    return allScores.where((score) => score.judgeId == judgeId).toList();
  }

  /// Get scores for a specific participant in a competition
  Future<List<JudgeScore>> getParticipantScores(
    String competitionId,
    String categoryId,
    String participantId,
  ) async {
    final allScores = await getCategoryScores(competitionId, categoryId);
    return allScores
        .where((score) => score.participantId == participantId)
        .toList();
  }

  // ============================================================================
  // CATEGORY-LEVEL OPERATIONS
  // ============================================================================

  /// Get all scores for a category
  Future<List<JudgeScore>> getCategoryScores(
    String competitionId,
    String categoryId,
  ) async {
    return fetchList<JudgeScore>(
      endpoint: CompetitionsUris.categoryScores(competitionId, categoryId),
      fromJson: JudgeScore.fromJson,
      errorMessage: 'Error fetching category scores',
      useCache: false,
    );
  }

  /// Get category ranking/leaderboard
  Future<List<CategoryRankingEntry>> getCategoryRanking(
    String competitionId,
    String categoryId,
  ) async {
    return fetchList<CategoryRankingEntry>(
      endpoint: CompetitionsUris.categoryLeaderboard(competitionId, categoryId),
      fromJson: CategoryRankingEntry.fromJson,
      requiredToken: false,
      errorMessage: 'Error fetching category ranking',
      cacheTTL: const Duration(minutes: 2),
    );
  }

  /// Get my scores as a judge for a category
  Future<List<JudgeScore>> getMyScoresForCategory(
    String competitionId,
    String categoryId,
    String judgeId,
  ) async {
    final allScores = await getCategoryScores(competitionId, categoryId);
    return allScores.where((score) => score.judgeId == judgeId).toList();
  }

  /// Submit a score for a category
  Future<JudgeScore> submitScore(
    String competitionId,
    String categoryId,
    Map<String, dynamic> scoreData,
  ) async {
    return create<JudgeScore>(
      endpoint: CompetitionsUris.submitCategoryScore(competitionId, categoryId),
      data: scoreData,
      fromJson: JudgeScore.fromJson,
      errorMessage: 'Error submitting score',
    );
  }

  /// Update an existing score
  Future<JudgeScore> updateScore(
    String competitionId,
    String categoryId,
    String scoreId,
    Map<String, dynamic> scoreData,
  ) async {
    return update<JudgeScore>(
      endpoint: CompetitionsUris.updateScore(competitionId, categoryId, scoreId),
      data: scoreData,
      fromJson: JudgeScore.fromJson,
      errorMessage: 'Error updating score',
    );
  }
}
