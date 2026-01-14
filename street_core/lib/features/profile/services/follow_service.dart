// lib/features/profile/services/follow_service.dart

import '../../../core/helpers/logger.dart';
import '../../../data/models/user_model.dart';
import '../repositories/follow_repository.dart';
import '../../../data/repositories/user_repository.dart';

/// Servicio de Seguimiento - Lógica de negocio para operaciones de seguir/dejar de seguir
/// Siguiendo la arquitectura Monolith-by-Features
class FollowService {
  FollowService(this._followRepository, this._userRepository);

  final FollowRepository _followRepository;
  final UserRepository _userRepository;

  /// Seguir a un usuario
  Future<void> followUser(String userId) async {
    AppLogger.info('Following user: $userId', tag: 'FollowService');
    await _followRepository.followUser(userId);
  }

  /// Dejar de seguir a un usuario
  Future<void> unfollowUser(String userId) async {
    AppLogger.info('Unfollowing user: $userId', tag: 'FollowService');
    await _followRepository.unfollowUser(userId);
  }

  /// Verificar si el usuario actual está siguiendo a un usuario específico
  Future<bool> isFollowing(String userId) async {
    return await _followRepository.isFollowing(userId);
  }

  /// Obtener seguidores de un usuario (paginado)
  Future<List<UserModel>> getFollowers(
    String userId, {
    int page = 1,
    int limit = 20,
  }) async {
    AppLogger.info(
      'Fetching followers for user: $userId',
      tag: 'FollowService',
    );
    return await _userRepository.getFollowers(userId, page: page, limit: limit);
  }

  /// Obtener usuarios que un usuario está siguiendo (paginado)
  Future<List<UserModel>> getFollowing(
    String userId, {
    int page = 1,
    int limit = 20,
  }) async {
    AppLogger.info(
      'Fetching following for user: $userId',
      tag: 'FollowService',
    );
    return await _userRepository.getFollowing(userId, page: page, limit: limit);
  }
}
