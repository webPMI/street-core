import '../../../core/services/cache_service.dart';
import '../../profile/repositories/profile_repository.dart';
import '/core/services/api_service.dart';
import '/features/auth/auth.dart';
import '/core/helpers/device_storage.dart';
import 'package:get_it/get_it.dart';

/// Setup auth feature dependencies.
/// Call this from the main DI setup.

void setupAuthFeature(GetIt getIt) {
  // User Cubit (depends on AuthService) - Singleton for global user state
  if (!getIt.isRegistered<UserCubit>()) {
    getIt.registerLazySingleton<UserCubit>(
      () => UserCubit(getIt<AuthService>(), getIt<ProfileRepository>()),
    );
  }
  // Auth Service
  getIt.registerLazySingleton<AuthService>(
    () => AuthService(
      getIt<ApiService>(),
      getIt<StorageService>(),
      getIt<CacheService>(),
    ),
  );

  // Auth Cubit (depends on AuthService and UserCubit)
  if (!getIt.isRegistered<AuthCubit>()) {
    getIt.registerLazySingleton<AuthCubit>(
      () => AuthCubit(getIt<AuthService>(), getIt<UserCubit>()),
    );
  }
}
