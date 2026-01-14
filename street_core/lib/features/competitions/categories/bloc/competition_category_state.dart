// lib/presentation/dashboard/competitions/categories/bloc/competition_category_state.dart

import 'package:equatable/equatable.dart';

import '../../models/competition_category_model.dart';

/// Base state for competition categories
abstract class CompetitionCategoryState extends Equatable {
  const CompetitionCategoryState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class CategoryInitial extends CompetitionCategoryState {
  const CategoryInitial();
}

/// Loading state
class CategoriesLoading extends CompetitionCategoryState {
  const CategoriesLoading();
}

/// Categories loaded successfully
class CategoriesLoaded extends CompetitionCategoryState {

  const CategoriesLoaded(this.categories, this.competitionId);
  final List<CompetitionCategory> categories;
  final String competitionId;

  @override
  List<Object?> get props => [categories, competitionId];
}

/// Single category detail loaded
class CategoryDetailLoaded extends CompetitionCategoryState {

  const CategoryDetailLoaded(this.category);
  final CompetitionCategory category;

  @override
  List<Object?> get props => [category];
}

/// Category action successful (create/update/delete)
class CategoryActionSuccess extends CompetitionCategoryState {

  const CategoryActionSuccess(this.message);
  final String message;

  @override
  List<Object?> get props => [message];
}

/// Category error state
class CategoryError extends CompetitionCategoryState {

  const CategoryError(this.message);
  final String message;

  @override
  List<Object?> get props => [message];
}

/// Participant added/removed successfully
class ParticipantActionSuccess extends CompetitionCategoryState {

  const ParticipantActionSuccess(this.message, this.updatedCategory);
  final String message;
  final CompetitionCategory updatedCategory;

  @override
  List<Object?> get props => [message, updatedCategory];
}

// ============================================================
// ALIAS STATES FOR BACKWARD COMPATIBILITY
// ============================================================

/// Alias for CategoriesLoading
class CompetitionCategoryLoading extends CategoriesLoading {
  const CompetitionCategoryLoading();
}

/// Alias for CategoryError
class CompetitionCategoryError extends CategoryError {
  const CompetitionCategoryError(super.message);
}

/// Alias for CategoryDetailLoaded with nullable category
class CompetitionCategoryLoaded extends CompetitionCategoryState {

  const CompetitionCategoryLoaded(this.category);
  final CompetitionCategory? category;

  @override
  List<Object?> get props => [category];
}
