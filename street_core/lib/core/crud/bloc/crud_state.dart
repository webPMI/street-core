import 'package:equatable/equatable.dart';

/// Base abstract class for all CRUD states
abstract class CrudState<T> extends Equatable {
  const CrudState();

  @override
  List<Object?> get props => [];
}

/// Initial state when the cubit is created
class CrudInitial<T> extends CrudState<T> {
  const CrudInitial();
}

/// Loading state when fetching data
class CrudLoading<T> extends CrudState<T> {
  const CrudLoading();
}

/// Loaded state with paginated data
class CrudLoaded<T> extends CrudState<T> {

  const CrudLoaded(
    this.items, {
    this.currentPage = 1,
    this.hasMore = false,
    this.isLoadingMore = false,
    this.loadMoreError,
  });
  final List<T> items;
  final int currentPage;
  final bool hasMore;
  final bool isLoadingMore;
  final String? loadMoreError;

  /// Check if there's a loadMore error
  bool get hasLoadMoreError => loadMoreError != null;

  /// Create a copy with modified fields
  CrudLoaded<T> copyWith({
    List<T>? items,
    int? currentPage,
    bool? hasMore,
    bool? isLoadingMore,
    String? loadMoreError,
    bool clearLoadMoreError = false,
  }) {
    return CrudLoaded<T>(
      items ?? this.items,
      currentPage: currentPage ?? this.currentPage,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      loadMoreError: clearLoadMoreError ? null : (loadMoreError ?? this.loadMoreError),
    );
  }

  @override
  List<Object?> get props => [items, currentPage, hasMore, isLoadingMore, loadMoreError];
}

/// Error state with error message
class CrudError<T> extends CrudState<T> {

  const CrudError(this.message);
  final String message;

  @override
  List<Object> get props => [message];
}

/// Success state after a CRUD action (create, update, delete)
class CrudActionSuccess<T> extends CrudState<T> {

  const CrudActionSuccess(this.message);
  final String message;

  @override
  List<Object> get props => [message];
}

/// Form state for create/edit forms
class CrudFormState<T> extends CrudState<T> {

  const CrudFormState({
    this.isLoading = false,
    this.successMessage,
    this.errorMessage,
    this.currentItem,
  });
  final bool isLoading;
  final String? successMessage;
  final String? errorMessage;
  final T? currentItem;

  /// Create a copy with modified fields
  CrudFormState<T> copyWith({
    bool? isLoading,
    String? successMessage,
    String? errorMessage,
    T? currentItem,
    bool clearMessages = false,
  }) {
    return CrudFormState<T>(
      isLoading: isLoading ?? this.isLoading,
      successMessage: clearMessages ? null : (successMessage ?? this.successMessage),
      errorMessage: clearMessages ? null : (errorMessage ?? this.errorMessage),
      currentItem: currentItem ?? this.currentItem,
    );
  }

  @override
  List<Object?> get props => [isLoading, successMessage, errorMessage, currentItem];
}

/// Detail loaded state for viewing a single item
class CrudDetailLoaded<T> extends CrudState<T> {

  const CrudDetailLoaded(this.item);
  final T item;

  @override
  List<Object?> get props => [item];
}
