// lib/features/profile/repositories/story_repository.dart

import '../../../core/crud/base_repository.dart';
import '../models/story_model.dart';

/// Repositorio de Historias - Llamadas API para historias (contenido efímero de 24h)
class StoryRepository extends BaseRepository {
  StoryRepository(super.apiService);

  /// Crear una nueva historia
  Future<Story> createStory({
    required String userId,
    required String mediaUrl,
    String? caption,
    String mediaType = 'image',
  }) async {
    return create<Story>(
      endpoint: '/stories',
      data: {
        'userId': userId,
        'mediaUrl': mediaUrl,
        'mediaType': mediaType,
        if (caption != null) 'caption': caption,
      },
      fromJson: Story.fromJson,
      errorMessage: 'Error creating story',
    );
  }

  /// Obtener historias activas de un usuario (no expiradas)
  Future<List<Story>> getActiveStories(String userId) async {
    return fetchList<Story>(
      endpoint: '/users/$userId/stories/active',
      fromJson: Story.fromJson,
      errorMessage: 'Error fetching active stories',
      useCache: false, // Don't cache stories (they expire)
    );
  }

  /// Obtener todas las historias de usuarios seguidos (feed)
  Future<List<Story>> getStoriesFeed() async {
    return fetchList<Story>(
      endpoint: '/stories/feed',
      fromJson: Story.fromJson,
      errorMessage: 'Error fetching stories feed',
      useCache: false,
    );
  }

  /// Obtener historia única por ID
  Future<Story> getStoryById(String storyId) async {
    return fetchById<Story>(
      endpoint: '/stories/$storyId',
      fromJson: Story.fromJson,
      errorMessage: 'Error fetching story',
      useCache: false,
    );
  }

  /// Marcar una historia como vista por el usuario actual
  Future<void> markStoryAsViewed({
    required String storyId,
    required String viewerId,
  }) async {
    await executeAction(
      endpoint: '/stories/$storyId/view',
      method: 'POST',
      data: {'viewerId': viewerId},
      errorMessage: 'Error marking story as viewed',
      enableRetry: false,
    );
  }

  /// Eliminar una historia
  Future<void> deleteStory(String storyId) async {
    await delete(
      endpoint: '/stories/$storyId',
      errorMessage: 'Error deleting story',
    );
  }

  /// Obtener espectadores de la historia
  Future<List<Map<String, dynamic>>> getStoryViewers(String storyId) async {
    return executeSafely<List<Map<String, dynamic>>>(
      operation: () async {
        final response = await apiService.get('/stories/$storyId/viewers');

        if (response.status == 'success' && response.data != null) {
          final viewers = response.data!['viewers'] as List<dynamic>? ?? [];
          return viewers
              .map((viewer) => viewer as Map<String, dynamic>)
              .toList();
        }

        return [];
      },
      errorMessage: 'Error fetching story viewers',
    );
  }

  /// Obtener las propias historias del usuario
  Future<List<Story>> getMyStories(String userId) async {
    return fetchList<Story>(
      endpoint: '/users/$userId/stories',
      fromJson: Story.fromJson,
      errorMessage: 'Error fetching my stories',
      useCache: false,
    );
  }

  /// Verificar si el usuario tiene historias activas
  Future<bool> hasActiveStories(String userId) async {
    return executeSafely<bool>(
      operation: () async {
        final stories = await getActiveStories(userId);
        return stories.isNotEmpty;
      },
      errorMessage: 'Error checking active stories',
    );
  }

  /// Obtener conteo de historias para un usuario
  Future<int> getStoriesCount(String userId) async {
    return executeSafely<int>(
      operation: () async {
        final response = await apiService.get('/users/$userId/stories/count');

        if (response.status == 'success' && response.data != null) {
          return response.data!['count'] as int? ?? 0;
        }

        return 0;
      },
      errorMessage: 'Error fetching stories count',
    );
  }
}
