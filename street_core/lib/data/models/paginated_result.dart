// lib/data/models/paginated_result.dart

/// Generic paginated result wrapper for list responses
/// Used for implementing pagination and infinite scroll in the app
class PaginatedResult<T> {

  PaginatedResult({
    required this.items,
    required this.currentPage,
    required this.totalPages,
    required this.totalItems,
    required this.itemsPerPage,
    required this.hasNext,
    required this.hasPrevious,
  });

  /// Create a PaginatedResult from JSON response
  ///
  /// Expected API response format:
  /// ```json
  /// {
  ///   "data": [...],
  ///   "pagination": {
  ///     "currentPage": 1,
  ///     "totalPages": 10,
  ///     "totalItems": 100,
  ///     "itemsPerPage": 10,
  ///     "hasNext": true,
  ///     "hasPrevious": false
  ///   }
  /// }
  /// ```
  factory PaginatedResult.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromJsonT,
  ) {
    final pagination = json['pagination'] as Map<String, dynamic>? ?? {};
    final data = json['data'] as List<dynamic>? ?? [];

    return PaginatedResult<T>(
      items: data.map((item) => fromJsonT(item as Map<String, dynamic>)).toList(),
      currentPage: pagination['currentPage'] as int? ?? 1,
      totalPages: pagination['totalPages'] as int? ?? 1,
      totalItems: pagination['totalItems'] as int? ?? data.length,
      itemsPerPage: pagination['itemsPerPage'] as int? ?? data.length,
      hasNext: pagination['hasNext'] as bool? ?? false,
      hasPrevious: pagination['hasPrevious'] as bool? ?? false,
    );
  }
  /// The list of items for the current page
  final List<T> items;

  /// Current page number (1-based)
  final int currentPage;

  /// Total number of pages available
  final int totalPages;

  /// Total number of items across all pages
  final int totalItems;

  /// Number of items per page
  final int itemsPerPage;

  /// Whether there is a next page available
  final bool hasNext;

  /// Whether there is a previous page available
  final bool hasPrevious;

  /// Check if this is the first page
  bool get isFirstPage => currentPage == 1;

  /// Check if this is the last page
  bool get isLastPage => currentPage == totalPages;

  /// Check if there are any items
  bool get isEmpty => items.isEmpty;

  /// Check if there are items
  bool get isNotEmpty => items.isNotEmpty;

  /// Get the number of items in the current page
  int get itemCount => items.length;

  /// Copy with new values
  PaginatedResult<T> copyWith({
    List<T>? items,
    int? currentPage,
    int? totalPages,
    int? totalItems,
    int? itemsPerPage,
    bool? hasNext,
    bool? hasPrevious,
  }) {
    return PaginatedResult<T>(
      items: items ?? this.items,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      totalItems: totalItems ?? this.totalItems,
      itemsPerPage: itemsPerPage ?? this.itemsPerPage,
      hasNext: hasNext ?? this.hasNext,
      hasPrevious: hasPrevious ?? this.hasPrevious,
    );
  }

  /// Append items from another paginated result (useful for infinite scroll)
  PaginatedResult<T> append(PaginatedResult<T> other) {
    return PaginatedResult<T>(
      items: [...items, ...other.items],
      currentPage: other.currentPage,
      totalPages: other.totalPages,
      totalItems: other.totalItems,
      itemsPerPage: other.itemsPerPage,
      hasNext: other.hasNext,
      hasPrevious: other.hasPrevious,
    );
  }

  @override
  String toString() {
    return 'PaginatedResult(items: ${items.length}, currentPage: $currentPage, '
        'totalPages: $totalPages, totalItems: $totalItems, hasNext: $hasNext)';
  }
}
