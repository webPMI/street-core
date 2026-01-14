// lib/features/social/di/social_injection.dart

import 'package:get_it/get_it.dart';
import '../../../core/services/api_service.dart';
import '../../../core/helpers/logger.dart';
import '../comment/comment_repository.dart';
import '../comment/comment_service.dart';
import '../comment/comments_cubit.dart';
import '../like/like_repository.dart';
import '../like/like_service.dart';
import '../like/like_cubit.dart';

/// ============================================================================
/// SOCIAL MODULE - Dependency Injection
/// ============================================================================
/// Módulo independiente para interacciones sociales (comentarios, likes)
/// Siguiendo el patrón Monolith-by-Features
///
/// Para DESHABILITAR este módulo:
/// 1. Comentar la llamada en profile_injection.dart
///
/// Para MIGRAR a otro proyecto:
/// 1. Copiar carpeta completa: lib/features/social/
/// 2. Copiar este archivo DI
/// 3. Llamar setupSocialModule() en tu nuevo proyecto
/// ============================================================================

/// Setup social module dependencies
void setupSocialModule(GetIt getIt) {
  AppLogger.info('📦 Registrando módulo: Social', tag: 'DI');

  // =========================================
  // REPOSITORIES
  // =========================================

  /// Comment Repository - Handles comment CRUD operations
  if (!getIt.isRegistered<CommentRepository>()) {
    getIt.registerLazySingleton<CommentRepository>(
      () => CommentRepository(getIt<ApiService>()),
    );
  }

  /// Like Repository - Handles like operations
  if (!getIt.isRegistered<LikeRepository>()) {
    getIt.registerLazySingleton<LikeRepository>(
      () => LikeRepository(getIt<ApiService>()),
    );
  }

  // =========================================
  // SERVICES
  // =========================================

  /// Comment Service - Business logic for comments
  if (!getIt.isRegistered<CommentService>()) {
    getIt.registerLazySingleton<CommentService>(
      () => CommentService(getIt<CommentRepository>()),
    );
  }

  /// Like Service - Business logic for likes
  if (!getIt.isRegistered<LikeService>()) {
    getIt.registerLazySingleton<LikeService>(
      () => LikeService(getIt<LikeRepository>()),
    );
  }

  // =========================================
  // CUBITS/BLOCS
  // =========================================

  /// Comments Cubit (Factory - new instance each time)
  if (!getIt.isRegistered<CommentsCubit>(instanceName: 'CommentsFactory')) {
    getIt.registerFactory<CommentsCubit>(
      () => CommentsCubit(getIt<CommentService>()),
    );
  }

  /// Like Cubit (Factory - new instance each time)
  if (!getIt.isRegistered<LikeCubit>(instanceName: 'LikeFactory')) {
    getIt.registerFactory<LikeCubit>(
      () => LikeCubit(getIt<LikeService>()),
    );
  }

  AppLogger.info(
    '   ✅ Social: 2 repositorios + 2 servicios + 2 cubits registrados',
    tag: 'DI',
  );
}
