// lib/core/crud/base_repository.dart

import './exceptions/repository_exception.dart';
import './retry/retry_policy.dart';
import '../helpers/logger.dart';
import '../services/api_service.dart';
import '../services/cache_service.dart';
import '../../data/models/paginated_result.dart';

/// Base repository class to eliminate code duplication
/// Provides common CRUD operations and error handling
abstract class BaseRepository {
  BaseRepository(this.apiService, {this.retryPolicy = const RetryPolicy()});
  final ApiService apiService;
  final RetryPolicy retryPolicy;

  /// Shared cache instance (unified singleton)
  CacheService get cache => CacheService.instance;

  /// Clear all cache
  void clearCache() {
    cache.clearAll();
  }

  /// Clear cache entries matching a pattern
  void clearCachePattern(String pattern) {
    cache.invalidateRegex(pattern);
  }

  /// Clear cache entries starting with a prefix
  void clearCachePrefix(String prefix) {
    cache.invalidatePrefix(prefix);
  }

  /// Generic fetch method with error handling and retry support
  Future<T> executeSafely<T>({
    required Future<T> Function() operation,
    required String errorMessage,
    String? tag,
    bool enableRetry = true,
    Map<String, dynamic>? debugContext,
  }) async {
    final executor = RetryExecutor(
      policy: enableRetry ? retryPolicy : RetryPolicy.noRetry,
    );

    final repoTag = tag ?? runtimeType.toString();

    try {
      return await executor.execute(
        operation: operation,
        onRetry: (attempt, error, nextDelay) {
          AppLogger.warning(
            'Retry attempt $attempt for: $errorMessage',
            tag: repoTag,
          );
        },
      );
    } catch (e, stackTrace) {
      // Enhanced error logging with context
      final errorDetails = StringBuffer()
        ..writeln('❌ Repository Error Details:')
        ..writeln('   Message: $errorMessage')
        ..writeln('   Error: $e');

      if (debugContext != null && debugContext.isNotEmpty) {
        errorDetails.writeln('   Context:');
        debugContext.forEach((key, value) {
          errorDetails.writeln('      $key: $value');
        });
      }

      AppLogger.error(
        errorDetails.toString(),
        error: e,
        stackTrace: stackTrace,
        tag: repoTag,
      );

      // Convert to RepositoryException if not already
      if (e is RepositoryException) {
        rethrow;
      }
      throw RepositoryException(
        errorMessage,
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Fetch list with generic error handling and caching
  Future<List<T>> fetchList<T>({
    required String endpoint,
    required T Function(Map<String, dynamic>) fromJson,
    bool requiredToken = true,
    String errorMessage = 'error.fetching_data',
    bool useCache = true,
    Duration? cacheTTL,
  }) async {
    final cacheKey = 'list.$endpoint';

    // Check cache first
    if (useCache) {
      final cached = cache.get<List<T>>(cacheKey);
      if (cached != null) {
        return cached;
      }
    }

    return executeSafely<List<T>>(
      operation: () async {
        AppLogger.debug(
          'Fetching list from: $endpoint',
          tag: runtimeType.toString(),
        );

        final response = await apiService.useFetch<List<dynamic>>(
          endpoint,
          method: 'GET',
          requiredToken: requiredToken,
          fromJsonT: (data) => data as List<dynamic>,
        );

        if (response.status == 'success' && response.data != null) {
          final result = response.data!
              .map((json) => fromJson(json as Map<String, dynamic>))
              .toList();

          AppLogger.debug(
            'Successfully fetched ${result.length} items from: $endpoint',
            tag: runtimeType.toString(),
          );

          // Cache the result
          if (useCache) {
            cache.set(cacheKey, result, ttl: cacheTTL ?? CacheTTL.listData);
          }

          return result;
        } else {
          throw RepositoryException.server(
            response.message,
            code: response.code ?? response.message,
            statusCode: response.statusCode,
          );
        }
      },
      errorMessage: errorMessage,
      debugContext: {
        'endpoint': endpoint,
        'method': 'GET',
        'requiredToken': requiredToken,
        'useCache': useCache,
      },
    );
  }

  /// Fetch single item with generic error handling and caching
  Future<T> fetchById<T>({
    required String endpoint,
    required T Function(Map<String, dynamic>) fromJson,
    bool requiredToken = true,
    String errorMessage = 'error.fetching_item',
    bool useCache = true,
    Duration? cacheTTL,
  }) async {
    final cacheKey = 'item.$endpoint';

    // Check cache first
    if (useCache) {
      final cached = cache.get<T>(cacheKey);
      if (cached != null) {
        return cached;
      }
    }

    return executeSafely<T>(
      operation: () async {
        AppLogger.debug(
          'Fetching item from: $endpoint',
          tag: runtimeType.toString(),
        );

        final response = await apiService.useFetch<Map<String, dynamic>>(
          endpoint,
          method: 'GET',
          requiredToken: requiredToken,
          fromJsonT: (data) => data as Map<String, dynamic>,
        );

        if (response.status == 'success' && response.data != null) {
          final result = fromJson(response.data!);

          AppLogger.debug(
            'Successfully fetched item from: $endpoint',
            tag: runtimeType.toString(),
          );

          // Cache the result
          if (useCache) {
            cache.set(cacheKey, result, ttl: cacheTTL ?? CacheTTL.detailData);
          }

          return result;
        } else {
          throw RepositoryException.server(
            response.message,
            code: response.code ?? response.message,
            statusCode: response.statusCode,
          );
        }
      },
      errorMessage: errorMessage,
      debugContext: {
        'endpoint': endpoint,
        'method': 'GET',
        'requiredToken': requiredToken,
        'useCache': useCache,
      },
    );
  }

  /// Create item with generic error handling
  /// Automatically invalidates list cache after successful creation
  Future<T> create<T>({
    required String endpoint,
    required Map<String, dynamic> data,
    required T Function(Map<String, dynamic>) fromJson,
    bool requiredToken = true,
    String errorMessage = 'error.creating_item',
  }) async {
    final result = await executeSafely<T>(
      operation: () async {
        AppLogger.debug(
          'Creating item at: $endpoint',
          tag: runtimeType.toString(),
        );

        final response = await apiService.useFetch<Map<String, dynamic>>(
          endpoint,
          method: 'POST',
          requiredToken: requiredToken,
          body: data,
          fromJsonT: (data) => data as Map<String, dynamic>,
        );

        if (response.status == 'success' && response.data != null) {
          AppLogger.debug(
            'Successfully created item at: $endpoint',
            tag: runtimeType.toString(),
          );
          return fromJson(response.data!);
        } else {
          throw RepositoryException.server(
            response.message,
            code: response.code ?? response.message,
            statusCode: response.statusCode,
          );
        }
      },
      errorMessage: errorMessage,
      enableRetry: false, // Don't retry create operations
      debugContext: {
        'endpoint': endpoint,
        'method': 'POST',
        'requiredToken': requiredToken,
        'dataKeys': data.keys.toList(),
      },
    );

    // Invalidate list cache after successful creation
    cache.invalidatePrefix('list.');

    return result;
  }

  /// Update item with generic error handling
  /// Automatically invalidates both list and item cache after successful update
  Future<T> update<T>({
    required String endpoint,
    required Map<String, dynamic> data,
    required T Function(Map<String, dynamic>) fromJson,
    bool requiredToken = true,
    String errorMessage = 'error.updating',
  }) async {
    final result = await executeSafely<T>(
      operation: () async {
        AppLogger.debug(
          'Updating item at: $endpoint',
          tag: runtimeType.toString(),
        );

        final response = await apiService.useFetch<Map<String, dynamic>>(
          endpoint,
          method: 'PUT',
          requiredToken: requiredToken,
          body: data,
          fromJsonT: (data) => data as Map<String, dynamic>,
        );

        if (response.status == 'success' && response.data != null) {
          AppLogger.debug(
            'Successfully updated item at: $endpoint',
            tag: runtimeType.toString(),
          );
          return fromJson(response.data!);
        } else {
          throw RepositoryException.server(
            response.message,
            code: response.code ?? response.message,
            statusCode: response.statusCode,
          );
        }
      },
      errorMessage: errorMessage,
      enableRetry: false, // Don't retry update operations
      debugContext: {
        'endpoint': endpoint,
        'method': 'PUT',
        'requiredToken': requiredToken,
        'dataKeys': data.keys.toList(),
      },
    );

    // Invalidate both list and item cache after successful update
    cache.invalidatePrefix('list.');
    cache.invalidatePattern(endpoint);

    return result;
  }

  /// Delete item with generic error handling
  /// Automatically invalidates both list and item cache after successful deletion
  Future<void> delete({
    required String endpoint,
    bool requiredToken = true,
    String errorMessage = 'error.deleting_item',
  }) async {
    await executeSafely<void>(
      operation: () async {
        AppLogger.debug(
          'Deleting item at: $endpoint',
          tag: runtimeType.toString(),
        );

        final response = await apiService.useFetch<void>(
          endpoint,
          method: 'DELETE',
          requiredToken: requiredToken,
        );

        if (response.status != 'success') {
          throw RepositoryException.server(
            response.message,
            code: response.code ?? response.message,
            statusCode: response.statusCode,
          );
        }

        AppLogger.debug(
          'Successfully deleted item at: $endpoint',
          tag: runtimeType.toString(),
        );
      },
      errorMessage: errorMessage,
      enableRetry: false, // Don't retry delete operations
      debugContext: {
        'endpoint': endpoint,
        'method': 'DELETE',
        'requiredToken': requiredToken,
      },
    );

    // Invalidate both list and item cache after successful deletion
    cache.invalidatePrefix('list.');
    cache.invalidatePattern(endpoint);
  }

  /// Execute action without return value
  Future<void> executeAction({
    required String endpoint,
    required String method,
    Map<String, dynamic>? data,
    bool requiredToken = true,
    String errorMessage = 'error.executing_action',
    bool enableRetry = false,
  }) async {
    return executeSafely<void>(
      operation: () async {
        AppLogger.debug(
          'Executing $method action at: $endpoint',
          tag: runtimeType.toString(),
        );

        final response = await apiService.useFetch<void>(
          endpoint,
          method: method,
          requiredToken: requiredToken,
          body: data,
        );

        if (response.status != 'success') {
          throw RepositoryException.server(
            response.message,
            code: response.code ?? response.message,
            statusCode: response.statusCode,
          );
        }

        AppLogger.debug(
          'Successfully executed $method action at: $endpoint',
          tag: runtimeType.toString(),
        );
      },
      errorMessage: errorMessage,
      enableRetry: enableRetry,
      debugContext: {
        'endpoint': endpoint,
        'method': method,
        'requiredToken': requiredToken,
        'hasData': data != null,
        if (data != null) 'dataKeys': data.keys.toList(),
      },
    );
  }

  /// Fetch paginated list with generic error handling
  ///
  /// Example usage:
  /// ```dart
  /// final result = await fetchPaginatedList<Club>(
  ///   endpoint: '/clubs',
  ///   page: 1,
  ///   limit: 20,
  ///   fromJson: Club.fromJson,
  /// );
  /// ```
  Future<PaginatedResult<T>> fetchPaginatedList<T>({
    required String endpoint,
    required T Function(Map<String, dynamic>) fromJson,
    int page = 1,
    int limit = 20,
    Map<String, dynamic>? filters,
    bool requiredToken = true,
    String errorMessage = 'error.fetching_paginated_data',
  }) async {
    return executeSafely<PaginatedResult<T>>(
      operation: () async {
        // Build query parameters
        final queryParams = <String, dynamic>{
          'page': page,
          'limit': limit,
          if (filters != null) ...filters,
        };

        AppLogger.debug(
          'Fetching paginated list from: $endpoint (page: $page, limit: $limit)',
          tag: runtimeType.toString(),
        );

        final response = await apiService.useFetch<Map<String, dynamic>>(
          endpoint,
          method: 'GET',
          requiredToken: requiredToken,
          queryParameters: queryParams,
          fromJsonT: (data) => data as Map<String, dynamic>,
        );

        if (response.status == 'success' && response.data != null) {
          final result = PaginatedResult.fromJson(response.data!, fromJson);
          AppLogger.debug(
            'Successfully fetched ${result.items.length} items (page $page/${result.totalPages})',
            tag: runtimeType.toString(),
          );
          return result;
        } else {
          throw RepositoryException.server(
            response.message,
            code: response.code ?? response.message,
            statusCode: response.statusCode,
          );
        }
      },
      errorMessage: errorMessage,
      debugContext: {
        'endpoint': endpoint,
        'method': 'GET',
        'page': page,
        'limit': limit,
        'requiredToken': requiredToken,
        if (filters != null) 'filters': filters,
      },
    );
  }
}
