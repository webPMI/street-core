// lib/features/profile/services/story_service.dart

import 'dart:io' show File;

import '../../../core/media/media.dart';
import '../models/story_model.dart';
import '../repositories/story_repository.dart';

/// Servicio de Historias
/// Maneja la lógica de negocio para operaciones de historias de 24 horas
class StoryService {
  StoryService(this._repository, this._mediaRepository);

  final StoryRepository _repository;
  final MediaUploadRepository _mediaRepository;

  /// Crear una nueva historia
  /// Sube archivo multimedia y crea la historia
  /// Las historias expiran después de 24 horas
  Future<Story> createStory({
    required String userId,
    required File media,
    String? caption,
  }) async {
    try {
      // 1. Upload media file
      final uploadResponse = await _mediaRepository.uploadImage(media);

      // 2. Determine media type (image or video)
      final extension = media.path.split('.').last.toLowerCase();
      final mediaType = _isVideoExtension(extension) ? 'video' : 'image';

      // 3. Create story
      final story = await _repository.createStory(
        userId: userId,
        mediaUrl: uploadResponse.url,
        mediaType: mediaType,
        caption: caption,
      );

      return story;
    } catch (e) {
      rethrow;
    }
  }

  /// Obtener historias activas para un usuario
  /// Devuelve solo historias que tienen menos de 24 horas
  Future<List<Story>> getActiveStories(String userId) async {
    try {
      return await _repository.getActiveStories(userId);
    } catch (e) {
      rethrow;
    }
  }

  /// Obtener historias activas de usuarios seguidos
  /// Devuelve historias de todos los usuarios que el usuario actual sigue
  Future<List<Story>> getFollowingStories(String userId) async {
    try {
      return await _repository.getStoriesFeed();
    } catch (e) {
      rethrow;
    }
  }

  /// Ver una historia
  /// Registra que un usuario ha visto una historia
  Future<void> viewStory({
    required String storyId,
    required String viewerId,
  }) async {
    try {
      await _repository.markStoryAsViewed(storyId: storyId, viewerId: viewerId);
    } catch (e) {
      // Don't throw error for view tracking failures
      // It's not critical functionality
    }
  }

  /// Obtener historia por ID
  Future<Story> getStoryById(String storyId) async {
    try {
      return await _repository.getStoryById(storyId);
    } catch (e) {
      rethrow;
    }
  }

  /// Obtener espectadores de una historia
  /// Devuelve lista de IDs de usuarios que han visto la historia
  Future<List<String>> getStoryViewers(String storyId) async {
    try {
      final viewersData = await _repository.getStoryViewers(storyId);
      // Extract user IDs from the viewer data
      return viewersData
          .map((viewer) => viewer['userId'] as String? ?? '')
          .where((id) => id.isNotEmpty)
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Eliminar una historia
  /// Solo el creador de la historia puede eliminarla
  Future<void> deleteStory(String storyId, String userId) async {
    try {
      await _repository.deleteStory(storyId);
    } catch (e) {
      rethrow;
    }
  }

  /// Verificar si el usuario ha visto una historia
  Future<bool> hasViewedStory({
    required String storyId,
    required String userId,
  }) async {
    try {
      final viewers = await getStoryViewers(storyId);
      return viewers.contains(userId);
    } catch (e) {
      return false;
    }
  }

  /// Obtener conteo de historias para un usuario
  Future<int> getStoryCount(String userId) async {
    try {
      final stories = await getActiveStories(userId);
      return stories.length;
    } catch (e) {
      return 0;
    }
  }

  /// Ayudante: Verificar si la extensión del archivo es video
  bool _isVideoExtension(String extension) {
    const videoExtensions = ['mp4', 'mov', 'avi', 'mkv', 'webm', 'm4v'];
    return videoExtensions.contains(extension);
  }
}
