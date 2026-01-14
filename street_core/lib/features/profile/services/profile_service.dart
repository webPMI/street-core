// lib/features/profile/services/profile_service.dart

import 'dart:io' show File;

import '../../../core/helpers/logger.dart';
import '../../../core/media/media.dart';
import '../../../core/services/cache_service.dart';
import '../../../data/models/user_model.dart';
import '../../../data/repositories/user_repository.dart';

/// Servicio de Perfil - Lógica de negocio para perfiles de usuario
/// Siguiendo la arquitectura Monolith-by-Features
///
/// Optimizaciones de Rendimiento:
/// - Calentamiento de caché para datos de perfil después del inicio de sesión
/// - Invalidación inteligente de caché en actualizaciones de perfil
/// - Carga por lotes para listas de seguidores/seguidos
class ProfileService {
  ProfileService(this._repository, this._mediaRepository);

  final UserRepository _repository;
  final MediaUploadRepository _mediaRepository;

  /// OPTIMIZACIÓN: Acceso directo a caché para control manual
  CacheService get _cache => CacheService.instance;

  // ===========================================================================
  // OPERACIONES DE PERFIL
  // ===========================================================================

  /// Obtener perfil de usuario por ID
  Future<UserModel> getUserProfile(String userId) async {
    AppLogger.info('Fetching user profile: $userId', tag: 'ProfileService');
    return await _repository.getUserById(userId);
  }

  /// Obtener perfil del usuario actual
  /// OPTIMIZACIÓN: Los resultados son cacheados por la capa de repositorio
  Future<UserModel> getCurrentUserProfile() async {
    AppLogger.info('Fetching current user profile', tag: 'ProfileService');
    return await _repository.getCurrentUser();
  }

  /// Actualizar perfil de usuario
  /// OPTIMIZACIÓN: Invalida la caché de perfil después de la actualización
  Future<UserModel> updateProfile(Map<String, dynamic> updates) async {
    AppLogger.info('Updating profile', tag: 'ProfileService');

    // Validate updates
    if (updates.isEmpty) {
      throw Exception('No updates provided');
    }

    final result = await _repository.updateProfile(updates);

    // OPTIMIZACIÓN: Invalidar cachés de perfil de usuario después de actualizar
    // Esto asegura datos frescos en la siguiente obtención
    _cache.invalidatePattern('item_/profile');
    _cache.invalidatePattern('item_/users/');

    return result;
  }

  /// Subir foto de perfil
  /// OPTIMIZACIÓN: Invalida cachés de perfil y publicaciones (foto de perfil visible en publicaciones)
  Future<String> uploadProfilePicture(File image) async {
    AppLogger.info('Uploading profile picture', tag: 'ProfileService');

    // Upload to media service
    final uploadResponse = await _mediaRepository.uploadAvatar(image);

    // Update user profile with new image URL
    await _repository.updateProfile({'imageUrl': uploadResponse.url});

    // OPTIMIZACIÓN: Invalidación completa de caché
    // La foto de perfil aparece en publicaciones, comentarios, etc.
    _cache.invalidatePattern('item_/profile');
    _cache.invalidatePattern('item_/users/');
    _cache.invalidatePrefix('list_'); // Posts may include user profile pic

    return uploadResponse.url;
  }

  /// OPTIMIZACIÓN: Calentar caché para datos de perfil frecuentemente accedidos
  /// Llamar a esto después de un inicio de sesión exitoso para precargar datos
  Future<void> warmCache(String userId) async {
    AppLogger.info('Warming cache for user: $userId', tag: 'ProfileService');

    try {
      // Pre-fetch profile data in parallel
      await Future.wait([getUserProfile(userId), getUserStats(userId)]);
    } catch (e) {
      // Cache warming is best-effort, don't fail on errors
      AppLogger.warning('Cache warming failed: $e', tag: 'ProfileService');
    }
  }

  /// Obtener estadísticas de usuario (seguidores, seguidos, conteo de publicaciones)
  Future<Map<String, int>> getUserStats(String userId) async {
    AppLogger.info('Fetching user stats: $userId', tag: 'ProfileService');

    final user = await _repository.getUserById(userId);

    return {
      'followersCount': user.followersCount,
      'followingCount': user.followingCount,
      'postsCount': user.postsCount,
    };
  }

  // ===========================================================================
  // SEGUIDORES Y SEGUIDOS
  // ===========================================================================

  /// Obtener seguidores de un usuario
  Future<List<UserModel>> getFollowers(
    String userId, {
    int page = 1,
    int limit = 20,
  }) async {
    AppLogger.info(
      'Fetching followers for user: $userId',
      tag: 'ProfileService',
    );
    return await _repository.getFollowers(userId, page: page, limit: limit);
  }

  /// Obtener seguidos de un usuario
  Future<List<UserModel>> getFollowing(
    String userId, {
    int page = 1,
    int limit = 20,
  }) async {
    AppLogger.info(
      'Fetching following for user: $userId',
      tag: 'ProfileService',
    );
    return await _repository.getFollowing(userId, page: page, limit: limit);
  }

  // ===========================================================================
  // AYUDANTES DE LÓGICA DE NEGOCIO
  // ===========================================================================

  /// Validar datos de perfil antes de actualizar
  bool validateProfileData(Map<String, dynamic> data) {
    // Username validation
    if (data.containsKey('nickName')) {
      final username = data['nickName'] as String?;
      if (username == null || username.isEmpty || username.length < 3) {
        return false;
      }
    }

    // Bio validation
    if (data.containsKey('bio')) {
      final bio = data['bio'] as String?;
      if (bio != null && bio.length > 500) {
        return false;
      }
    }

    return true;
  }

  /// Verificar si el perfil está completo
  bool isProfileComplete(UserModel user) {
    final hasDisplayName =
        (user.nickName != null && user.nickName!.isNotEmpty) ||
        user.firstName.isNotEmpty;
    return hasDisplayName &&
        user.firstName.isNotEmpty &&
        user.imageUrl != null &&
        user.imageUrl!.isNotEmpty;
  }
}
