// lib/features/profile/repositories/profile_repository.dart

import '../../../core/crud/base_repository.dart';
import '../../../core/services/api_uris.dart';
import '../../../core/services/cache_service.dart';
import '../../../data/models/user_model.dart';

/// Repositorio de Perfil - Llamadas API para gestión de perfiles de usuario
///
/// Optimizaciones de Rendimiento:
/// - Datos de perfil: Caché de 5 minutos (frecuencia de actualización moderada)
/// - Estadísticas: Caché de 5 minutos (actualizado cuando el usuario publica/sigue)
/// - Usuario actual: Caché de 15 minutos (raramente cambia durante la sesión)
class ProfileRepository extends BaseRepository {
  ProfileRepository(super.apiService);

  /// Obtener usuario por ID
  /// Backend returns: {status: "success", data: {user: {...}}}
  /// OPTIMIZACIÓN: Caché de 5 minutos para perfiles de usuario
  Future<UserModel> getUserById(String userId) async {
    final cacheKey = 'item_user_$userId';

    // Check cache first
    final cached = cache.get<UserModel>(cacheKey);
    if (cached != null) {
      return cached;
    }

    return executeSafely<UserModel>(
      operation: () async {
        final response = await apiService.useFetch<Map<String, dynamic>>(
          ApiUris.getUserById(userId),
          method: 'GET',
          requiredToken: true,
          fromJsonT: (data) => data as Map<String, dynamic>,
        );

        if (response.status == 'success' && response.data != null) {
          // Backend returns user inside 'user' key
          final userData = response.data!['user'] as Map<String, dynamic>?;
          UserModel user;
          if (userData != null) {
            user = UserModel.fromJson(userData);
          } else {
            // Fallback: try parsing data directly
            user = UserModel.fromJson(response.data!);
          }

          // Cache the result
          cache.set(cacheKey, user, ttl: CacheTTL.userProfile);
          return user;
        }
        throw Exception(response.message);
      },
      errorMessage: 'error_fetching_user',
    );
  }

  /// Actualizar perfil de usuario
  /// Backend returns: {status: "success", data: {user: {...}}}
  Future<UserModel> updateUser(
    String userId,
    Map<String, dynamic> updates,
  ) async {
    return executeSafely<UserModel>(
      operation: () async {
        final response = await apiService.useFetch<Map<String, dynamic>>(
          ApiUris.updateProfile,
          method: 'PUT',
          requiredToken: true,
          body: updates,
          fromJsonT: (data) => data as Map<String, dynamic>,
        );

        if (response.status == 'success' && response.data != null) {
          // Backend returns user inside 'user' key
          final userData = response.data!['user'] as Map<String, dynamic>?;
          if (userData != null) {
            // Invalidate user cache
            cache.invalidatePattern('user');
            cache.invalidatePattern('profile');
            return UserModel.fromJson(userData);
          }
          // Fallback: try parsing data directly
          return UserModel.fromJson(response.data!);
        }
        throw Exception(response.message);
      },
      errorMessage: 'error_updating_user_profile',
      enableRetry: false,
    );
  }

  /// Obtener estadísticas de usuario (seguidores, seguidos, conteo de publicaciones)
  /// OPTIMIZACIÓN: Caché de 5 minutos para estadísticas
  Future<Map<String, int>> getUserStats(String userId) async {
    // OPTIMIZACIÓN: Cachear estadísticas para reducir llamadas a API
    final cacheKey = 'user_stats_$userId';
    final cached = cache.get<Map<String, int>>(cacheKey);
    if (cached != null) {
      return cached;
    }

    final result = await executeSafely<Map<String, int>>(
      operation: () async {
        final response = await apiService.get(
          '${ApiUris.getUserById(userId)}/stats',
          requiredToken: true,
        );

        if (response.status == 'success' && response.data != null) {
          return Map<String, int>.from(response.data!);
        }

        throw Exception(response.message);
      },
      errorMessage: 'Error fetching user statistics',
    );

    cache.set(cacheKey, result, ttl: CacheTTL.userProfile);
    return result;
  }

  /// Obtener perfil del usuario actual
  /// Backend returns: {status: "success", data: {user: {...}}}
  /// OPTIMIZACIÓN: Caché de 15 minutos (raramente cambia durante la sesión)
  Future<UserModel> getCurrentUser() async {
    final cacheKey = 'item_current_user';

    // Check cache first
    final cached = cache.get<UserModel>(cacheKey);
    if (cached != null) {
      return cached;
    }

    return executeSafely<UserModel>(
      operation: () async {
        final response = await apiService.useFetch<Map<String, dynamic>>(
          ApiUris.profile,
          method: 'GET',
          requiredToken: true,
          fromJsonT: (data) => data as Map<String, dynamic>,
        );

        if (response.status == 'success' && response.data != null) {
          // Backend returns user inside 'user' key
          final userData = response.data!['user'] as Map<String, dynamic>?;
          UserModel user;
          if (userData != null) {
            user = UserModel.fromJson(userData);
          } else {
            // Fallback: try parsing data directly
            user = UserModel.fromJson(response.data!);
          }

          // Cache the result
          cache.set(cacheKey, user, ttl: CacheTTL.userData);
          return user;
        }
        throw Exception(response.message);
      },
      errorMessage: 'Error fetching current user',
    );
  }

  /// Actualizar configuración del usuario actual
  Future<void> updateSettings(Map<String, dynamic> settings) async {
    await executeAction(
      endpoint: ApiUris.updateSettings,
      method: 'PUT',
      data: settings,
      errorMessage: 'Error updating settings',
    );
  }

  /// Cambiar contraseña
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await executeAction(
      endpoint: ApiUris.changePassword,
      method: 'PUT',
      data: {'currentPassword': currentPassword, 'newPassword': newPassword},
      errorMessage: 'Error changing password',
    );
  }

  /// Eliminar cuenta
  Future<void> deleteAccount() async {
    await delete(
      endpoint: ApiUris.deleteAccount,
      errorMessage: 'Error deleting account',
    );
  }
}
