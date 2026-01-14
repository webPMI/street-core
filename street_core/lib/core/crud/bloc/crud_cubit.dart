import '../../error/error_mapper.dart';
import '../base_repository.dart';
import './crud_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Generic CRUD Cubit that provides common CRUD operations
///
/// Type parameters:
/// - T: The model type (e.g., Club, Product, Event)
/// - R: The repository type (must extend BaseRepository)
///
/// Subclasses must implement:
/// - getEndpoint(): Returns the API endpoint
/// - fromJson(): Converts JSON to model instance
/// - toJson(): Converts model instance to JSON
abstract class CrudCubit<T, R extends BaseRepository>
    extends Cubit<CrudState<T>> {
  CrudCubit({required this.repository, required this.resourceName})
    : super(CrudInitial<T>());
  final R repository;
  final String resourceName;

  // Abstract methods to be implemented by subclasses

  /// Returns the base API endpoint for this resource
  String getEndpoint();

  /// Converts JSON map to model instance
  T Function(Map<String, dynamic>) fromJson();

  /// Converts model instance to JSON map
  Map<String, dynamic> Function(T) toJson();

  // Generic CRUD methods

  /// Fetches all items with pagination and optional filters
  Future<void> fetchAll({
    int page = 1,
    int limit = 20,
    Map<String, dynamic>? filters,
  }) async {
    try {
      emit(CrudLoading<T>());

      final result = await repository.fetchPaginatedList<T>(
        endpoint: getEndpoint(),
        page: page,
        limit: limit,
        filters: filters,
        fromJson: fromJson(),
      );

      emit(
        CrudLoaded<T>(
          result.items,
          currentPage: result.currentPage,
          hasMore: result.hasNext,
        ),
      );
    } catch (e) {
      emit(CrudError<T>(extractErrorMessage(e)));
    }
  }

  /// Loads more items (for infinite scroll)
  Future<void> loadMore() async {
    final currentState = state;
    if (currentState is! CrudLoaded<T> ||
        !currentState.hasMore ||
        currentState.isLoadingMore) {
      return;
    }

    try {
      emit(currentState.copyWith(isLoadingMore: true));

      final result = await repository.fetchPaginatedList<T>(
        endpoint: getEndpoint(),
        page: currentState.currentPage + 1,
        fromJson: fromJson(),
      );

      emit(
        CrudLoaded<T>(
          [...currentState.items, ...result.items],
          currentPage: result.currentPage,
          hasMore: result.hasNext,
        ),
      );
    } catch (e) {
      // Keep current items but show error state with loadMore flag reset
      emit(
        currentState.copyWith(
          isLoadingMore: false,
          loadMoreError: extractErrorMessage(e),
        ),
      );
    }
  }

  /// Extract a localized error message key
  String extractErrorMessage(dynamic error) {
    return ErrorMapper.mapToFailure(error).messageKey;
  }

  /// Fetches a single item by ID
  Future<void> fetchById(String id) async {
    try {
      emit(CrudLoading<T>());

      final item = await repository.fetchById<T>(
        endpoint: '${getEndpoint()}/$id',
        fromJson: fromJson(),
      );

      emit(CrudDetailLoaded<T>(item));
    } catch (e) {
      emit(CrudError<T>(extractErrorMessage(e)));
    }
  }

  /// Creates a new item
  Future<void> create(T item) async {
    try {
      emit(CrudLoading<T>());

      await repository.create<T>(
        endpoint: getEndpoint(),
        data: toJson()(item),
        fromJson: fromJson(),
      );

      emit(CrudActionSuccess<T>('$resourceName.created.successfully'));
      await fetchAll();
    } catch (e) {
      emit(CrudError<T>(extractErrorMessage(e)));
    }
  }

  /// Creates a new item from a map (useful for forms)
  Future<void> createFromMap(Map<String, dynamic> data) async {
    try {
      emit(CrudLoading<T>());

      await repository.create<T>(
        endpoint: getEndpoint(),
        data: data,
        fromJson: fromJson(),
      );

      emit(CrudActionSuccess<T>('$resourceName.created.successfully'));
      await fetchAll();
    } catch (e) {
      emit(CrudError<T>(extractErrorMessage(e)));
    }
  }

  /// Updates an existing item
  Future<void> update(String id, T item) async {
    try {
      emit(CrudLoading<T>());

      await repository.update<T>(
        endpoint: '${getEndpoint()}/$id',
        data: toJson()(item),
        fromJson: fromJson(),
      );

      emit(CrudActionSuccess<T>('$resourceName.updated.successfully'));
      await fetchAll();
    } catch (e) {
      emit(CrudError<T>(extractErrorMessage(e)));
    }
  }

  /// Updates an existing item from a map (useful for forms)
  Future<void> updateFromMap(String id, Map<String, dynamic> data) async {
    try {
      emit(CrudLoading<T>());

      await repository.update<T>(
        endpoint: '${getEndpoint()}/$id',
        data: data,
        fromJson: fromJson(),
      );

      emit(CrudActionSuccess<T>('$resourceName.updated.successfully'));
      await fetchAll();
    } catch (e) {
      emit(CrudError<T>(extractErrorMessage(e)));
    }
  }

  /// Deletes an item by ID
  Future<void> delete(String id) async {
    try {
      emit(CrudLoading<T>());

      await repository.delete(endpoint: '${getEndpoint()}/$id');

      emit(CrudActionSuccess<T>('$resourceName.deleted.successfully'));
      await fetchAll();
    } catch (e) {
      emit(CrudError<T>(extractErrorMessage(e)));
    }
  }

  /// Loads an item for editing
  void loadForEdit(T item) {
    emit(CrudFormState<T>(currentItem: item));
  }

  /// Clears the form state
  void clearFormState() {
    emit(CrudInitial<T>());
  }

  /// Resets to initial state
  void reset() {
    emit(CrudInitial<T>());
  }
}
