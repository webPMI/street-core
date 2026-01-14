// lib/features/profile/repositories/privacy_repository.dart

import '../../../core/crud/base_repository.dart';
import '../../../core/services/api_uris.dart';
import '../../../data/models/privacy_settings_model.dart';
import '../../../data/models/user_model.dart';

/// Repositorio de Privacidad - Llamadas API para gestión de configuración de privacidad
class PrivacyRepository extends BaseRepository {
  PrivacyRepository(super.apiService);

  /// Obtener configuración de privacidad de un usuario
  Future<PrivacySettings> getSettings(String userId) async {
    return fetchById<PrivacySettings>(
      endpoint: ApiUris.userPrivacySettings,
      fromJson: PrivacySettings.fromJson,
      errorMessage: 'Error fetching privacy settings',
    );
  }

  /// Actualizar configuración de privacidad
  Future<PrivacySettings> updateSettings(
    String userId,
    PrivacySettings settings,
  ) async {
    return update<PrivacySettings>(
      endpoint: ApiUris.updateUserPrivacy,
      data: settings.toJson(),
      fromJson: PrivacySettings.fromJson,
      errorMessage: 'Error updating privacy settings',
    );
  }

  /// Actualizar configuración de privacidad parcial
  Future<PrivacySettings> updatePartialSettings(
    String userId,
    Map<String, dynamic> updates,
  ) async {
    return update<PrivacySettings>(
      endpoint: ApiUris.updateUserPrivacy,
      data: updates,
      fromJson: PrivacySettings.fromJson,
      errorMessage: 'Error updating privacy settings',
    );
  }

  /// Bloquear a un usuario
  Future<void> blockUser({
    required String blockerId,
    required String blockedId,
  }) async {
    await executeAction(
      endpoint: ApiUris.blockUser,
      method: 'POST',
      data: {'userId': blockedId},
      errorMessage: 'Error blocking user',
      enableRetry: false,
    );

    // Clear cache
    clearCachePattern('blocked_users');
  }

  /// Desbloquear a un usuario
  Future<void> unblockUser({
    required String blockerId,
    required String blockedId,
  }) async {
    await executeAction(
      endpoint: ApiUris.unblockUser(blockedId),
      method: 'DELETE',
      errorMessage: 'Error unblocking user',
      enableRetry: false,
    );

    // Clear cache
    clearCachePattern('blocked_users');
  }

  /// Obtener lista de usuarios bloqueados
  Future<List<User>> getBlockedUsers() async {
    return fetchList<User>(
      endpoint: ApiUris.getBlockedUsers,
      fromJson: User.fromJson,
      errorMessage: 'Error fetching blocked users',
    );
  }

  /// Verificar si un usuario está bloqueado
  Future<bool> isUserBlocked(String userId) async {
    return executeSafely<bool>(
      operation: () async {
        final blockedUsers = await getBlockedUsers();
        return blockedUsers.any((user) => user.id == userId);
      },
      errorMessage: 'Error checking blocked status',
    );
  }

  /// Actualizar visibilidad del perfil
  Future<PrivacySettings> updateProfileVisibility(
    String userId,
    String visibility,
  ) async {
    return updatePartialSettings(userId, {'profileVisibility': visibility});
  }

  /// Alternar privacidad de la cuenta (pública/privada)
  Future<PrivacySettings> toggleAccountPrivacy(
    String userId,
    bool isPrivate,
  ) async {
    return updatePartialSettings(userId, {
      'profileVisibility': isPrivate ? 'private' : 'public',
    });
  }

  /// Actualizar configuración de quién puede enviar mensajes
  Future<PrivacySettings> updateWhoCanMessage(
    String userId,
    String whoCanMessage,
  ) async {
    return updatePartialSettings(userId, {'whoCanMessage': whoCanMessage});
  }

  /// Actualizar configuración de quién puede comentar
  Future<PrivacySettings> updateWhoCanComment(
    String userId,
    String whoCanComment,
  ) async {
    return updatePartialSettings(userId, {'whoCanComment': whoCanComment});
  }

  /// Actualizar requisito de aprobación de seguidores
  Future<PrivacySettings> updateFollowApproval(
    String userId,
    bool requireApproval,
  ) async {
    return updatePartialSettings(userId, {
      'requireFollowApproval': requireApproval,
    });
  }

  /// Obtener configuración de privacidad predeterminada
  PrivacySettings getDefaultSettings(String userId) {
    return PrivacySettings(
      id: '',
      userId: userId,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      profileVisibility: 'public',
      showEmail: false,
      showPhone: false,
      showBirthdate: false,
      showOnlineStatus: true,
      showLastSeen: true,
      showActivityFeed: true,
      allowTagging: true,
      allowMentions: true,
      whoCanMessage: 'everyone',
      whoCanComment: 'everyone',
      whoCanFollow: 'everyone',
      requireFollowApproval: false,
      allowDataCollection: true,
      allowPersonalizedAds: true,
      allowThirdPartySharing: false,
      blockedUserIds: const [],
    );
  }
}
