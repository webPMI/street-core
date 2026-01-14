library;

// Cache (from unified service)
export '../services/cache_service.dart' show CacheService, CacheTTL, CacheStats;
/// CRUD Module
///
/// Generic CRUD infrastructure for Flutter applications.
/// Provides reusable components for repository, state management, and caching.
///
/// ## Usage
///
/// ```dart
/// import 'crud.dart';
/// ///
/// /// // Create a repository
/// /// class MyRepository extends BaseRepository {
/// ///   MyRepository(ApiService api) : super(api);
/// /// }
/// ///
/// /// // Create a cubit
/// /// class MyCubit extends CrudCubit<MyModel, MyRepository> {
/// ///   MyCubit(MyRepository repo) : super(repository: repo, resourceName: 'my.model');
/// ///
/// ///   @override
/// ///   String getEndpoint() => '/api/my-models';
/// ///
/// ///   @override
/// ///   MyModel Function(Map<String, dynamic>) fromJson() => MyModel.fromJson;
/// ///
/// ///   @override
/// ///   Map<String, dynamic> Function(MyModel) toJson() => (m) => m.toJson();
/// /// }
/// ```

// Base repository
export 'base_repository.dart';
// BLoC/Cubit
export 'bloc/crud_cubit.dart';
export 'bloc/crud_state.dart';
// Exceptions
export 'exceptions/repository_exception.dart';
// Retry
export 'retry/retry_policy.dart';
