// lib/presentation/dashboard/competitions/categories/bloc/competition_category_cubit.dart

import '../../../../core/lang/locale_keys.dart';
import './competition_category_state.dart';
import '../../models/competition_category_model.dart';
import '../../repositories/competition_category_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Cubit for managing competition categories
class CompetitionCategoryCubit extends Cubit<CompetitionCategoryState> {
  CompetitionCategoryCubit(this._repository) : super(const CategoryInitial());
  final CompetitionCategoryRepository _repository;

  // -----------------------------------------------------------------
  // FETCH OPERATIONS
  // -----------------------------------------------------------------

  /// Fetch all categories for a competition
  Future<void> fetchCategories(String competitionId) async {
    try {
      emit(const CategoriesLoading());
      final categories = await _repository.getCategories(competitionId);

      /*     // Sort by order
      categories.sort((a, b) => a!.order.compareTo(b?.order));
 */
      emit(CategoriesLoaded(categories, competitionId));
    } catch (e) {//TODO
      emit(const CategoryError(LocaleKeys.errorLoading));
    }
  }

  /// Fetch category details by ID
  Future<void> fetchCategoryById(
    String competitionId,
    String categoryId,
  ) async {
    try {
      emit(const CategoriesLoading());
      final category = await _repository.getCategoryById(
        competitionId,
        categoryId,
      );
      emit(CategoryDetailLoaded(category));
    } catch (e) {
      emit(const CategoryError(LocaleKeys.errorLoading));
    }
  }

  /// Get category by ID
  Future<CompetitionCategory?> getCategoryById(
    String competitionId,
    String categoryId,
  ) async {
    try {
      final category = await _repository.getCategoryById(
        competitionId,
        categoryId,
      );
      return category;
    } catch (e) {
      return null;
    }
  }

  // -----------------------------------------------------------------
  // CREATE/UPDATE/DELETE OPERATIONS
  // -----------------------------------------------------------------

  /// Create a new category
  Future<void> createCategory(
    String competitionId,
    Map<String, dynamic> categoryData,
  ) async {
    try {
      emit(const CategoriesLoading());
      await _repository.createCategory(competitionId, categoryData);
      emit(const CategoryActionSuccess('category_created_successfully'));

      // Reload categories list
      await fetchCategories(competitionId);
    } catch (e) {
      emit(const CategoryError(LocaleKeys.errorCreating));
    }
  }

  /// Update an existing category
  Future<void> updateCategory(
    String competitionId,
    String categoryId,
    Map<String, dynamic> updates,
  ) async {
    try {
      emit(const CategoriesLoading());
      await _repository.updateCategory(competitionId, categoryId, updates);
      emit(const CategoryActionSuccess(LocaleKeys.categoryUpdatedSuccessfully));

      // Reload categories list
      await fetchCategories(competitionId);
    } catch (e) {
      emit(const CategoryError(LocaleKeys.errorUpdating));
    }
  }

  /// Delete a category
  Future<void> deleteCategory(String competitionId, String categoryId) async {
    try {
      emit(const CategoriesLoading());
      await _repository.deleteCategory(competitionId, categoryId);
      emit(const CategoryActionSuccess(LocaleKeys.deletedSuccessfully));

      // Reload categories list
      await fetchCategories(competitionId);
    } catch (e) {
      emit(const CategoryError(LocaleKeys.errorDeleting));
    }
  }

  // -----------------------------------------------------------------
  // PARTICIPANT MANAGEMENT
  // -----------------------------------------------------------------

  /// Add a participant to a category
  Future<void> addParticipant(
    String competitionId,
    String categoryId,
    String userId,
  ) async {
    try {
      emit(const CategoriesLoading());
      await _repository.addParticipant(competitionId, categoryId, userId);

      // Reload category details
      final category = await _repository.getCategoryById(
        competitionId,
        categoryId,
      );
      emit(
        ParticipantActionSuccess(LocaleKeys.addedSuccessfully, category),
      );
    } catch (e) {
      emit(const CategoryError(LocaleKeys.errorAdding));
    }
  }

  /// Remove a participant from a category
  Future<void> removeParticipant(
    String competitionId,
    String categoryId,
    String participantId,
  ) async {
    try {
      emit(const CategoriesLoading());
      await _repository.removeParticipant(
        competitionId,
        categoryId,
        participantId,
      );

      // Reload category details
      final category = await _repository.getCategoryById(
        competitionId,
        categoryId,
      );
      emit(
        ParticipantActionSuccess(LocaleKeys.removedSuccessfully, category),
      );
    } catch (e) {
      emit(const CategoryError(LocaleKeys.errorRemoving));
    }
  }

  // -----------------------------------------------------------------
  // JUDGE MANAGEMENT
  // -----------------------------------------------------------------

  /// Add a judge to a category
  Future<void> addJudge(
    String competitionId,
    String categoryId,
    String judgeId,
  ) async {
    try {
      emit(const CategoriesLoading());
      await _repository.addJudge(competitionId, categoryId, judgeId);

      // Reload category details
      final category = await _repository.getCategoryById(
        competitionId,
        categoryId,
      );
      emit(ParticipantActionSuccess(LocaleKeys.judgeAssignedSuccessfully, category));
    } catch (e) {
      emit(const CategoryError(LocaleKeys.errorAssigningJudge));
    }
  }

  /// Remove a judge from a category
  Future<void> removeJudge(
    String competitionId,
    String categoryId,
    String judgeId,
  ) async {
    try {
      emit(const CategoriesLoading());
      await _repository.removeJudge(competitionId, categoryId, judgeId);

      // Reload category details
      final category = await _repository.getCategoryById(
        competitionId,
        categoryId,
      );
      emit(ParticipantActionSuccess (LocaleKeys.judgeRemovedSuccessfully, category));
    } catch (e) {
      emit(const CategoryError(LocaleKeys.errorRemovingJudge));
    }
  }

  // -----------------------------------------------------------------
  // REORDER CATEGORIES
  // -----------------------------------------------------------------

  /// Reorder categories
  Future<void> reorderCategories(
    String competitionId,
    List<CompetitionCategory> categories,
  ) async {
    try {
      // Update local order first for immediate feedback
      final orderedCategories = categories
          .asMap()
          .entries
          .map((entry) => {'id': entry.value.id, 'order': entry.key})
          .toList();

      emit(CategoriesLoaded(categories, competitionId));

      // Then save to backend
      await _repository.reorderCategories(competitionId, orderedCategories);
    } catch (e) {
      emit(const CategoryError(LocaleKeys.errorReorderingCategories));
      // Reload to revert changes
      await fetchCategories(competitionId);
    }
  }

  // -----------------------------------------------------------------
  // UTILITY METHODS
  // -----------------------------------------------------------------

  /// Clear state
  void clearState() {
    emit(const CategoryInitial());
  }
}
