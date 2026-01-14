// lib/features/profile/services/privacy_service.dart

import '../../../core/services/cache_service.dart';
import '../../../data/models/privacy_settings_model.dart';
import '../../../data/models/user_model.dart';
import '../repositories/privacy_repository.dart';

/// Servicio de Privacidad
/// Maneja la lógica de negocio para configuración de privacidad y bloqueos
class PrivacyService {
  PrivacyService(this._repository);

  final PrivacyRepository _repository;

  /// Obtener instancia del servicio de caché
  CacheService get _cache => CacheService.instance;

  /// Obtener configuración de privacidad para un usuario
  /// TTL de caché: 15 minutos (datos de usuario)
  Future<PrivacySettings> getSettings(String userId) async {
    try {
      // Check cache first
      final cacheKey = 'privacy_settings_$userId';
      final cached = _cache.get<PrivacySettings>(cacheKey);
      if (cached != null) {
        return cached;
      }

      // Fetch from API
      final settings = await _repository.getSettings(userId);

      // Cache result
      _cache.set(cacheKey, settings, ttl: CacheTTL.userData);

      return settings;
    } catch (e) {
      rethrow;
    }
  }

  /// Actualizar configuración de privacidad
  /// Invalida caché después de una actualización exitosa
  Future<PrivacySettings> updateSettings(
    String userId,
    PrivacySettings settings,
  ) async {
    try {
      // Validate settings
      _validateSettings(settings);

      // Update settings
      final updatedSettings = await _repository.updateSettings(
        userId,
        settings,
      );

      // Invalidate cache
      _cache.invalidate('privacy_settings_$userId');

      return updatedSettings;
    } catch (e) {
      rethrow;
    }
  }

  /// Actualizar configuración de privacidad específica
  Future<PrivacySettings> updateSetting(
    String userId,
    String key,
    dynamic value,
  ) async {
    try {
      // Get current settings
      final currentSettings = await getSettings(userId);

      // Update the specific field
      final updatedSettings = _updateSettingField(currentSettings, key, value);

      // Save updated settings
      return await updateSettings(userId, updatedSettings);
    } catch (e) {
      rethrow;
    }
  }

  /// Bloquear a un usuario
  Future<void> blockUser({
    required String blockerId,
    required String blockedId,
  }) async {
    try {
      // Validation: Cannot block yourself
      if (blockerId == blockedId) {
        throw Exception('You cannot block yourself');
      }

      // Check if already blocked
      final isBlocked = await isUserBlocked(blockedId: blockedId);

      if (isBlocked) {
        throw Exception('User is already blocked');
      }

      await _repository.blockUser(blockedId: blockerId, blockerId: blockedId);
    } catch (e) {
      rethrow;
    }
  }

  /// Desbloquear a un usuario
  Future<void> unblockUser({
    required String blockerId,
    required String blockedId,
  }) async {
    try {
      // Check if actually blocked
      final isBlocked = await isUserBlocked(blockedId: blockedId);

      if (!isBlocked) {
        throw Exception('User is not blocked');
      }

      await _repository.unblockUser(blockedId: blockerId, blockerId: blockedId);
    } catch (e) {
      rethrow;
    }
  }

  /// Verificar si un usuario está bloqueado
  Future<bool> isUserBlocked({required String blockedId}) async {
    try {
      final List<UserModel> blockedUsers = await _repository.getBlockedUsers();
      for (final blockedUser in blockedUsers) {
        if (blockedUser.id == blockedId) {
          return true;
        }
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Obtener lista de usuarios bloqueados
  Future<List<User>> getBlockedUsers() async {
    try {
      return await _repository.getBlockedUsers();
    } catch (e) {
      rethrow;
    }
  }

  /// Alternar privacidad de la cuenta (pública/privada)
  Future<PrivacySettings> toggleAccountPrivacy(String userId) async {
    try {
      final settings = await getSettings(userId);
      final newVisibility = settings.profileVisibility == 'private'
          ? 'public'
          : 'private';
      final newSettings = settings.copyWith(profileVisibility: newVisibility);
      return await updateSettings(userId, newSettings);
    } catch (e) {
      rethrow;
    }
  }

  /// Establecer cuenta como privada
  Future<PrivacySettings> setAccountPrivate(String userId) async {
    try {
      return await updateSetting(userId, 'profileVisibility', 'private');
    } catch (e) {
      rethrow;
    }
  }

  /// Establecer cuenta como pública
  Future<PrivacySettings> setAccountPublic(String userId) async {
    try {
      return await updateSetting(userId, 'profileVisibility', 'public');
    } catch (e) {
      rethrow;
    }
  }

  /// Limpiar caché de privacidad
  void clearCache(String userId) {
    _cache.invalidate('privacy_settings_$userId');
  }

  /// Validar configuración de privacidad
  void _validateSettings(PrivacySettings settings) {
    // Add any validation logic here
    // For example, check for conflicting settings

    // If account is private, certain features should be restricted
    if (settings.profileVisibility == 'private' && settings.showOnlineStatus) {
      // This is just an example - adjust based on your business rules
      throw Exception('Cannot show online status on a private account');
    }
  }

  /// Actualizar un campo específico en la configuración de privacidad
  PrivacySettings _updateSettingField(
    PrivacySettings settings,
    String key,
    dynamic value,
  ) {
    switch (key) {
      case 'profileVisibility':
        return settings.copyWith(profileVisibility: value as String);
      case 'showEmail':
        return settings.copyWith(showEmail: value as bool);
      case 'showPhone':
        return settings.copyWith(showPhone: value as bool);
      case 'showBirthdate':
        return settings.copyWith(showBirthdate: value as bool);
      case 'showOnlineStatus':
        return settings.copyWith(showOnlineStatus: value as bool);
      case 'showLastSeen':
        return settings.copyWith(showLastSeen: value as bool);
      case 'showActivityFeed':
        return settings.copyWith(showActivityFeed: value as bool);
      case 'allowTagging':
        return settings.copyWith(allowTagging: value as bool);
      case 'allowMentions':
        return settings.copyWith(allowMentions: value as bool);
      case 'whoCanMessage':
        return settings.copyWith(whoCanMessage: value as String);
      case 'whoCanComment':
        return settings.copyWith(whoCanComment: value as String);
      case 'whoCanFollow':
        return settings.copyWith(whoCanFollow: value as String);
      case 'requireFollowApproval':
        return settings.copyWith(requireFollowApproval: value as bool);
      case 'allowDataCollection':
        return settings.copyWith(allowDataCollection: value as bool);
      case 'allowPersonalizedAds':
        return settings.copyWith(allowPersonalizedAds: value as bool);
      case 'allowThirdPartySharing':
        return settings.copyWith(allowThirdPartySharing: value as bool);
      default:
        throw Exception('Unknown privacy setting: $key');
    }
  }
}
