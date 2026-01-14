// lib/domain/competition_category_repository.dart

import '../../../core/crud/base_repository.dart';
import '../competitions_uris.dart';
import '../models/competition_category_model.dart' show CompetitionCategory;

/// Repository for managing competition categories
class CompetitionCategoryRepository extends BaseRepository {
  CompetitionCategoryRepository(super.apiService);

  /// Get all categories for a competition
  Future<List<CompetitionCategory>> getCategories(String competitionId) async {
    return fetchList<CompetitionCategory>(
      endpoint: CompetitionsUris.categories(competitionId),
      fromJson: CompetitionCategory.fromJson,
      requiredToken: false,
      errorMessage: 'Error fetching competition categories',
    );
  }

  /// Get category details by ID
  Future<CompetitionCategory> getCategoryById(
    String competitionId,
    String categoryId,
  ) async {
    return fetchById<CompetitionCategory>(
      endpoint: CompetitionsUris.categoryDetail(competitionId, categoryId),
      fromJson: CompetitionCategory.fromJson,
      requiredToken: false,
      errorMessage: 'Error fetching category details',
    );
  }

  /// Create a new category
  Future<CompetitionCategory> createCategory(
    String competitionId,
    Map<String, dynamic> categoryData,
  ) async {
    return create<CompetitionCategory>(
      endpoint: CompetitionsUris.createCategory(competitionId),
      data: categoryData,
      fromJson: CompetitionCategory.fromJson,
      errorMessage: 'Error creating category',
    );
  }

  /// Update an existing category
  Future<CompetitionCategory> updateCategory(
    String competitionId,
    String categoryId,
    Map<String, dynamic> updates,
  ) async {
    return update<CompetitionCategory>(
      endpoint: CompetitionsUris.updateCategory(competitionId, categoryId),
      data: updates,
      fromJson: CompetitionCategory.fromJson,
      errorMessage: 'Error updating category',
    );
  }

  /// Delete a category
  Future<void> deleteCategory(
    String competitionId,
    String categoryId,
  ) async {
    return delete(
      endpoint: CompetitionsUris.deleteCategory(competitionId, categoryId),
      errorMessage: 'Error deleting category',
    );
  }

  /// Add a participant to a category
  Future<void> addParticipant(
    String competitionId,
    String categoryId,
    String userId,
  ) async {
    return executeAction(
      endpoint: CompetitionsUris.addParticipant(competitionId, categoryId),
      method: 'POST',
      data: {'userId': userId},
      errorMessage: 'Error adding participant to category',
    );
  }

  /// Remove a participant from a category
  Future<void> removeParticipant(
    String competitionId,
    String categoryId,
    String participantId,
  ) async {
    return executeAction(
      endpoint: CompetitionsUris.removeParticipant(
        competitionId,
        categoryId,
        participantId,
      ),
      method: 'DELETE',
      errorMessage: 'Error removing participant from category',
    );
  }

  /// Add a judge to a category
  Future<void> addJudge(
    String competitionId,
    String categoryId,
    String judgeId,
  ) async {
    return executeAction(
      endpoint: CompetitionsUris.addJudge(competitionId, categoryId),
      method: 'POST',
      data: {'judgeId': judgeId},
      errorMessage: 'Error adding judge to category',
    );
  }

  /// Remove a judge from a category
  Future<void> removeJudge(
    String competitionId,
    String categoryId,
    String judgeId,
  ) async {
    return executeAction(
      endpoint: CompetitionsUris.removeJudge(
        competitionId,
        categoryId,
        judgeId,
      ),
      method: 'DELETE',
      errorMessage: 'Error removing judge from category',
    );
  }

  /// Reorder categories
  Future<void> reorderCategories(
    String competitionId,
    List<Map<String, dynamic>> orderedCategories,
  ) async {
    return executeAction(
      endpoint: CompetitionsUris.categories(competitionId),
      method: 'PUT',
      data: {'categories': orderedCategories},
      errorMessage: 'Error reordering categories',
    );
  }
}
