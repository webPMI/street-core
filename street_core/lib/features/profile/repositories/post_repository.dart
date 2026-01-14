// lib/features/profile/repositories/post_repository.dart

import 'package:street_core/features/profile/profile_uris.dart';

import '../../../core/crud/base_repository.dart';
import '../../../core/services/api_response.dart';
import '../../../data/models/paginated_result.dart';
import '../models/post_model.dart';

/// Repositorio de Publicaciones - Llamadas API para gestión de publicaciones
class PostRepository extends BaseRepository {
  PostRepository(super.apiService);

  /// Crear una nueva publicación
  Future<ApiResponse<PostModel>> createPost(Map<String, dynamic> data) async {
    try {
      final response = await apiService.useFetch<PostModel>(
        ProfileUris.createPost,
        method: 'POST',
        body: data,
        fromJsonT: (data) => PostModel.fromJson(data),
      );
      return response;
    } catch (e) {
      return const ApiResponse<PostModel>(
        status: 'error',
        message: 'error.creating.post',
        statusCode: 500,
      );
    }
  }

  /// Obtener publicaciones de usuario con paginación
  Future<ApiResponse<List<Post>>> getUserPosts(
    String userId, {
    int page = 1,
    int limit = 20,
  }) async {
    return apiService.useFetch<List<Post>>(
      '${ProfileUris.getUserPosts(userId)}?page=$page&limit=$limit',
      method: 'GET',
      fromJsonT: (data) {
        // Handle paginated response: {data: [...], pagination: {...}}
        if (data is Map<String, dynamic>) {
          final postsData = data['data'];
          if (postsData is List) {
            return postsData
                .map((e) => Post.fromJson(e as Map<String, dynamic>))
                .toList();
          }
          return <Post>[];
        }
        // Handle direct list response
        if (data is List) {
          return data
              .map((e) => Post.fromJson(e as Map<String, dynamic>))
              .toList();
        }
        return <Post>[];
      },
    );
  }

  /// Obtener publicaciones del feed (de usuarios seguidos)
  Future<ApiResponse<List<Post>>> getFeed({
    int page = 1,
    int limit = 20,
  }) async {
    return apiService.useFetch<List<Post>>(
      '${ProfileUris.postsFeed}?page=$page&limit=$limit',
      method: 'GET',
      fromJsonT: (data) {
        // Handle paginated response: {data: [...], pagination: {...}}
        if (data is Map<String, dynamic>) {
          final postsData = data['data'];
          if (postsData is List) {
            return postsData
                .map((e) => Post.fromJson(e as Map<String, dynamic>))
                .toList();
          }
          return <Post>[];
        }
        // Handle direct list response
        if (data is List) {
          return data
              .map((e) => Post.fromJson(e as Map<String, dynamic>))
              .toList();
        }
        return <Post>[];
      },
    );
  }

  /// Obtener publicación única por ID
  Future<ApiResponse<Post>> getPostById(String postId) async {
    return apiService.useFetch<Post>(
      ProfileUris.getPostDetail(postId),
      method: 'GET',
      fromJsonT: (data) => Post.fromJson(data as Map<String, dynamic>),
    );
  }

  /// Actualizar publicación
  Future<ApiResponse<Post>> updatePost(
    String postId,
    Map<String, dynamic> updates,
  ) async {
    return apiService.useFetch<Post>(
      ProfileUris.updatePost(postId),
      method: 'PUT',
      body: updates,
      fromJsonT: (data) => Post.fromJson(data as Map<String, dynamic>),
    );
  }

  /// Eliminar publicación
  Future<ApiResponse<void>> deletePost(String postId) async {
    return apiService.useFetch<void>(
      ProfileUris.deletePost(postId),
      method: 'DELETE',
    );
  }

  /// Dar me gusta a una publicación
  Future<ApiResponse<void>> likePost(String postId) async {
    return apiService.useFetch<void>(
      ProfileUris.likePost(postId),
      method: 'POST',
    );
  }

  /// Quitar me gusta a una publicación
  Future<ApiResponse<void>> unlikePost(String postId) async {
    return apiService.useFetch<void>(
      ProfileUris.unlikePost(postId),
      method: 'DELETE',
    );
  }

  /// Guardar una publicación
  Future<ApiResponse<void>> savePost(String postId) async {
    return apiService.useFetch<void>(
      ProfileUris.savePost(postId),
      method: 'POST',
    );
  }

  /// Desguardar una publicación
  Future<ApiResponse<void>> unsavePost(String postId) async {
    return apiService.useFetch<void>(
      ProfileUris.unsavePost(postId),
      method: 'DELETE',
    );
  }

  /// Alternar me gusta en publicación (para compatibilidad)
  Future<void> toggleLike(String postId, bool isLiked) async {
    if (isLiked) {
      await unlikePost(postId);
    } else {
      await likePost(postId);
    }
  }

  /// Obtener publicaciones por etiqueta
  Future<PaginatedResult<Post>> getPostsByTag(
    String tag, {
    int page = 1,
    int limit = 20,
  }) async {
    return fetchPaginatedList<Post>(
      endpoint: ProfileUris.postsFeed,
      fromJson: Post.fromJson,
      page: page,
      limit: limit,
      filters: {'tag': tag},
      errorMessage: 'Error fetching posts by tag',
    );
  }

  /// Buscar publicaciones
  Future<PaginatedResult<Post>> searchPosts(
    String query, {
    int page = 1,
    int limit = 20,
  }) async {
    return fetchPaginatedList<Post>(
      endpoint: ProfileUris.postsFeed,
      fromJson: Post.fromJson,
      page: page,
      limit: limit,
      filters: {'search': query},
      errorMessage: 'Error searching posts',
    );
  }

  /// Obtener publicaciones guardadas del usuario actual
  Future<ApiResponse<List<PostModel>>> getSavedPosts({
    int page = 1,
    int limit = 20,
  }) async {
    return apiService.useFetch<List<PostModel>>(
      '${ProfileUris.getSavedPosts}?page=$page&limit=$limit',
      method: 'GET',
      fromJsonT: (data) {
        // Handle paginated response: {data: [...], pagination: {...}}
        if (data is Map<String, dynamic>) {
          final postsData = data['data'];
          if (postsData is List) {
            return postsData
                .map((e) => PostModel.fromJson(e as Map<String, dynamic>))
                .toList();
          }
          return <PostModel>[];
        }
        // Handle direct list response
        if (data is List) {
          return data
              .map((e) => PostModel.fromJson(e as Map<String, dynamic>))
              .toList();
        }
        return <PostModel>[];
      },
    );
  }

  /// Verificar si un post está guardado
  Future<ApiResponse<bool>> getSaveStatus(String postId) async {
    return apiService.useFetch<bool>(
      ProfileUris.getSaveStatus(postId),
      method: 'GET',
      fromJsonT: (data) {
        if (data is Map<String, dynamic> && data.containsKey('saved')) {
          return data['saved'] as bool;
        }
        return false;
      },
    );
  }
}
