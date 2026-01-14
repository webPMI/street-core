// lib/features/profile/services/post_service.dart

import 'package:image_picker/image_picker.dart';

import '../../../core/helpers/logger.dart';
import '../../../core/media/media.dart';
import '../../../core/services/cache_service.dart';
import '../models/post_model.dart';
import '../repositories/post_repository.dart';

/// Servicio de Publicaciones - Lógica de negocio para operaciones de publicaciones
/// Siguiendo la arquitectura Monolith-by-Features
///
/// Optimizaciones de Rendimiento:
/// - Invalidación agresiva de caché en mutaciones
/// - Calentamiento de caché para datos frecuentemente accedidos
/// - Operaciones por lotes donde sea posible
class PostService {
  PostService(this._repository, this._mediaRepository);

  final PostRepository _repository;
  final MediaUploadRepository _mediaRepository;

  /// OPTIMIZACIÓN: Acceso directo a caché para invalidación manual
  CacheService get _cache => CacheService.instance;

  // ===========================================================================
  // OPERACIONES DE PUBLICACIONES
  // ===========================================================================

  /// Crear una nueva publicación con imágenes opcionales
  /// Uses XFile for cross-platform compatibility (web, mobile, desktop)
  Future<PostModel> createPost({
    required String content,
    List<XFile>? images,
    List<String>? tags,
    List<String>? mentions,
    String visibility = 'public',
  }) async {
    AppLogger.info('Creating post', tag: 'PostService');

    // 1. Validate that we have at least one media file (backend requirement)
    if (images == null || images.isEmpty) {
      throw Exception('post.requires.media');
    }

    // 2. Upload images using XFile (cross-platform)
    AppLogger.debug('Uploading ${images.length} images', tag: 'PostService');
    final uploadResponses = await _mediaRepository.uploadMultipleXFile(images);
    AppLogger.debug('Upload responses: ${uploadResponses.length}', tag: 'PostService');

    final imageUrls = uploadResponses.map((response) => response.url).toList();
    AppLogger.debug('Extracted URLs: $imageUrls', tag: 'PostService');

    if (imageUrls.isEmpty) {
      throw Exception('media_upload_failed');
    }

    // 3. Create post with all required fields for backend
    final postData = {
      'caption': content,
      'mediaUrls': imageUrls,
      'mediaType': _determineMediaType(imageUrls),
      'tags': tags ?? [],
      'mentions': mentions ?? [],
      'visibility': visibility,
    };

    final response = await _repository.createPost(postData);

    if (response.status == 'success' && response.data != null) {
      // OPTIMIZACIÓN: Invalidar caché del feed después de crear publicación
      // Esto asegura que la nueva publicación aparezca en el feed en la próxima actualización
      _cache.invalidatePrefix('list_');
      _cache.invalidatePattern('feed');

      return response.data!;
    } else {
      throw Exception(response.message);
    }
  }

  /// Obtener publicaciones de un usuario específico con paginación
  Future<List<PostModel>> getUserPosts(
    String userId, {
    int page = 1,
    int limit = 20,
  }) async {
    AppLogger.info(
      'Fetching posts for user: $userId (page: $page)',
      tag: 'PostService',
    );

    final response = await _repository.getUserPosts(
      userId,
      page: page,
      limit: limit,
    );

    if (response.status == 'success') {
      return response.data ?? [];
    } else {
      throw Exception(response.message);
    }
  }

  /// Obtener feed (publicaciones de usuarios seguidos)
  Future<List<PostModel>> getFeed({int page = 1, int limit = 20}) async {
    AppLogger.info('Fetching feed', tag: 'PostService');

    final response = await _repository.getFeed(page: page, limit: limit);

    if (response.status == 'success') {
      return response.data ?? [];
    } else {
      throw Exception(response.message);
    }
  }

  /// Obtener una sola publicación por ID
  Future<PostModel> getPostById(String postId) async {
    AppLogger.info('Fetching post: $postId', tag: 'PostService');

    final response = await _repository.getPostById(postId);

    if (response.status == 'success' && response.data != null) {
      return response.data!;
    } else {
      throw Exception(response.message);
    }
  }

  /// Actualizar una publicación
  Future<PostModel> updatePost(
    String postId,
    Map<String, dynamic> updates,
  ) async {
    AppLogger.info('Updating post: $postId', tag: 'PostService');

    final response = await _repository.updatePost(postId, updates);

    if (response.status == 'success' && response.data != null) {
      // OPTIMIZACIÓN: Invalidar caché de publicación específica y listas relacionadas
      _cache.invalidate('item_/posts/$postId');
      _cache.invalidatePrefix('list_');

      return response.data!;
    } else {
      throw Exception(response.message);
    }
  }

  /// Eliminar una publicación
  Future<void> deletePost(String postId) async {
    AppLogger.info('Deleting post: $postId', tag: 'PostService');

    final response = await _repository.deletePost(postId);

    if (response.status != 'success') {
      throw Exception(response.message);
    }

    // OPTIMIZACIÓN: Invalidación agresiva de caché después de eliminación
    // Eliminar la caché específica de la publicación y todas las cachés de listas
    _cache.invalidate('item_/posts/$postId');
    _cache.invalidatePrefix('list_');
    _cache.invalidatePattern('feed');
  }

  /// Dar me gusta a una publicación
  Future<void> likePost(String postId) async {
    final response = await _repository.likePost(postId);

    if (response.status != 'success') {
      throw Exception(response.message);
    }
  }

  /// Quitar me gusta a una publicación
  Future<void> unlikePost(String postId) async {
    final response = await _repository.unlikePost(postId);

    if (response.status != 'success') {
      throw Exception(response.message);
    }
  }

  /// Guardar una publicación
  Future<void> savePost(String postId) async {
    final response = await _repository.savePost(postId);

    if (response.status != 'success') {
      throw Exception(response.message);
    }
  }

  /// Desguardar una publicación
  Future<void> unsavePost(String postId) async {
    final response = await _repository.unsavePost(postId);

    if (response.status != 'success') {
      throw Exception(response.message);
    }
  }

  // ===========================================================================
  // AYUDANTES
  // ===========================================================================

  String _determineMediaType(List<String> imageUrls) {
    if (imageUrls.isEmpty) return 'text';
    if (imageUrls.length > 1) return 'carousel';
    return 'image';
  }
}
