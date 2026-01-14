// lib/features/profile/di/profile_injection.dart
import 'package:flutter/material.dart';
import 'package:street_core/core/widgets/drawer/drawer_item.dart';
import 'package:street_core/features/dashboard/dashboard_layout/dashboard_drawer.dart';

import '../../../core/media/media.dart';
import '../profile_routes.dart';

import '../../../core/services/api_service.dart';
import '../../../core/helpers/logger.dart'; // Import AppLogger
import 'package:get_it/get_it.dart';
import '../../../data/repositories/user_repository.dart';
import '../../social/di/social_injection.dart'; // Social module DI
import '../repositories/follow_repository.dart';
import '../repositories/post_repository.dart';
import '../repositories/privacy_repository.dart';
import '../repositories/profile_repository.dart';
import '../repositories/story_repository.dart';
import '../services/follow_service.dart';
import '../services/post_service.dart';
import '../services/privacy_service.dart';
import '../services/profile_service.dart';
import '../services/story_service.dart';
import '../bloc/user_posts_cubit.dart';
import '../bloc/user_profile_cubit.dart';
import '../posts/bloc/create_post_cubit.dart';
import '../posts/bloc/post_detail_cubit.dart';
import '../posts/bloc/posts_feed_cubit.dart';

/// ============================================================================
/// PROFILE MODULE - Dependency Injection (ADR-005 Compliant)
/// ============================================================================
/// Módulo independiente para perfiles de usuario, posts y seguimiento
/// Siguiendo el patrón Monolith-by-Features
///
/// Para DESHABILITAR este módulo:
/// 1. En feature_flags.dart, cambiar: profileModule = false
/// 2. Comentar la llamada en feature_modules.dart
///
/// Para MIGRAR a otro proyecto:
/// 1. Copiar carpeta completa: lib/features/profile/
/// 2. Copiar este archivo DI
/// 3. Llamar setupProfileModule() en tu nuevo proyecto
/// ============================================================================

void setupProfileModule(GetIt getIt) {
  AppLogger.info('📦 Registrando módulo: Profile', tag: 'DI');

  // Setup social module first (comments, likes)
  setupSocialModule(getIt);

  // Routes are now registered in dashboard_routes.dart (compile-time)
  DashboardDrawer.baseElements.add(
    DrawerItem(
      icon: Icons.person,
      labelKey: 'profile',
      route: ProfileRoutes.profile,
    ),
  );

  // ============== REPOSITORIES ==============

  /// User Repository - Handles user profile operations (shared with Auth)
  if (!getIt.isRegistered<UserRepository>()) {
    getIt.registerLazySingleton<UserRepository>(
      () => UserRepository(getIt<ApiService>()),
    );
  }

  /// Profile Repository - Handles profile-specific operations
  getIt.registerLazySingleton<ProfileRepository>(
    () => ProfileRepository(getIt<ApiService>()),
  );

  /// Post Repository - Handles post CRUD operations (COMPLETE version from features/)
  getIt.registerLazySingleton<PostRepository>(
    () => PostRepository(getIt<ApiService>()),
  );

  /// Follow Repository - Handles follow/unfollow operations (COMPLETE version)
  getIt.registerLazySingleton<FollowRepository>(
    () => FollowRepository(getIt<ApiService>()),
  );

  /// Privacy Repository - Handles privacy settings (shared with other modules)
  if (!getIt.isRegistered<PrivacyRepository>()) {
    getIt.registerLazySingleton<PrivacyRepository>(
      () => PrivacyRepository(getIt<ApiService>()),
    );
  }

  /// Story Repository - Handles stories
  getIt.registerLazySingleton<StoryRepository>(
    () => StoryRepository(getIt<ApiService>()),
  );

  // ============== SERVICES ==============

  /// Profile Service - Business logic for user profiles
  getIt.registerLazySingleton<ProfileService>(
    () =>
        ProfileService(getIt<UserRepository>(), getIt<MediaUploadRepository>()),
  );

  /// Post Service - Business logic for posts (wraps PostRepository)
  getIt.registerLazySingleton<PostService>(
    () => PostService(getIt<PostRepository>(), getIt<MediaUploadRepository>()),
  );

  /// Follow Service - Business logic for follow/unfollow
  getIt.registerLazySingleton<FollowService>(
    () => FollowService(getIt<FollowRepository>(), getIt<UserRepository>()),
  );

  /// Privacy Service - Business logic for privacy settings
  getIt.registerLazySingleton<PrivacyService>(
    () => PrivacyService(getIt<PrivacyRepository>()),
  );

  /// Story Service - Business logic for stories
  getIt.registerLazySingleton<StoryService>(
    () =>
        StoryService(getIt<StoryRepository>(), getIt<MediaUploadRepository>()),
  );

  // ============== CUBITS ==============

  /// User Profile Cubit - Manages viewing other user's profiles
  getIt.registerFactory<UserProfileCubit>(
    () =>
        UserProfileCubit(getIt<ProfileRepository>(), getIt<FollowRepository>()),
  );

  /// User Posts Cubit - Manages user's posts for profile page
  getIt.registerFactory<UserPostsCubit>(
    () => UserPostsCubit(getIt<PostService>()),
  );

  /// Create Post Cubit - Manages post creation with media upload
  getIt.registerFactory<CreatePostCubit>(
    () => CreatePostCubit(getIt<PostService>()),
  );

  /// Posts Feed Cubit - Manages user feed
  getIt.registerFactory<PostsFeedCubit>(
    () => PostsFeedCubit(getIt<PostService>()),
  );

  /// Post Detail Cubit - Manages single post details
  getIt.registerFactory<PostDetailCubit>(
    () => PostDetailCubit(getIt<PostService>()),
  );

  AppLogger.info(
    '   ✅ Profile: 6 repositorios + 5 servicios + 5 cubits registrados',
    tag: 'DI',
  );
}
