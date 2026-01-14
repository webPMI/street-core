// lib/core/media/di/media_injection.dart
//
// Dependency injection for the Media module.

import 'package:get_it/get_it.dart';

import '../../services/api_media_service.dart';
import '../bloc/media_upload_cubit.dart';
import '../services/media_upload_service.dart';

/// Setup media module dependencies
///
/// MediaUploadService is a cross-cutting concern used by:
/// - Profile (avatar upload)
/// - Posts (image upload)
/// - Stories (media upload)
/// - Market (product images)
/// - Clubs (logo, banner)
void setupMediaDependencies(GetIt getIt) {
  // ApiMediaService - Low-level HTTP operations for media
  if (!getIt.isRegistered<ApiMediaService>()) {
    getIt.registerLazySingleton<ApiMediaService>(
      () => ApiMediaService(
        localeService: getIt(),
        storageService: getIt(),
      ),
    );
  }

  // MediaUploadService (also aliased as MediaUploadRepository)
  if (!getIt.isRegistered<MediaUploadService>()) {
    getIt.registerLazySingleton<MediaUploadService>(
      () => MediaUploadService(getIt<ApiMediaService>()),
    );
  }

  // Backward compatibility: Register with alias
  if (!getIt.isRegistered<MediaUploadRepository>()) {
    getIt.registerLazySingleton<MediaUploadRepository>(
      () => getIt<MediaUploadService>(),
    );
  }

  // MediaUploadCubit - State management for media uploads
  // Factory: New instance for each request (non-singleton)
  if (!getIt.isRegistered<MediaUploadCubit>()) {
    getIt.registerFactory<MediaUploadCubit>(
      () => MediaUploadCubit(getIt<MediaUploadService>()),
    );
  }
}
