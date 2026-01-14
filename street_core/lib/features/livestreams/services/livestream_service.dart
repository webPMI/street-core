// lib/features/livestreams/services/livestream_service.dart

import 'package:street_core/core/crud/base_repository.dart';
import 'package:street_core/data/models/paginated_result.dart';
import 'package:street_core/features/livestreams/models/models.dart';

/// Livestream API service
class LiveStreamService extends BaseRepository {
  LiveStreamService(super.apiService);

  // ============================================================================
  // Stream Management
  // ============================================================================

  /// Create a new livestream
  Future<LiveStream> createLiveStream({
    required String title,
    required String description,
    String? thumbnailUrl,
    DateTime? scheduledTime,
    bool recordingEnabled = false,
    List<String> tags = const [],
  }) async {
    final response = await apiService.useFetch(
      '/livestreams',
      method: 'POST',
      body: {
        'title': title,
        'description': description,
        if (thumbnailUrl != null) 'thumbnail_url': thumbnailUrl,
        if (scheduledTime != null)
          'scheduled_time': scheduledTime.toIso8601String(),
        'recording_enabled': recordingEnabled,
        'tags': tags,
      },
    );

    return LiveStream.fromJson(response.data);
  }

  /// Get a livestream by ID
  Future<LiveStream> getLiveStream(String streamId) async {
    final response = await apiService.useFetch('/livestreams/$streamId', method: 'GET');
    return LiveStream.fromJson(response.data);
  }

  /// Update a livestream
  Future<LiveStream> updateLiveStream({
    required String streamId,
    String? title,
    String? description,
    String? thumbnailUrl,
    List<String>? tags,
  }) async {
    final response = await apiService.useFetch(
      '/livestreams/$streamId',
      method: 'PATCH',
      body: {
        if (title != null) 'title': title,
        if (description != null) 'description': description,
        if (thumbnailUrl != null) 'thumbnail_url': thumbnailUrl,
        if (tags != null) 'tags': tags,
      },
    );

    return LiveStream.fromJson(response.data);
  }

  /// Delete a livestream
  Future<void> deleteLiveStream(String streamId) async {
    await apiService.useFetch(
      '/livestreams/$streamId',
      method: 'DELETE',
    );
  }

  // ============================================================================
  // Stream Lifecycle
  // ============================================================================

  /// Start a scheduled livestream
  Future<void> startLiveStream(String streamId) async {
    await apiService.useFetch(
      '/livestreams/$streamId/start',
      method: 'POST',
    );
  }

  /// End a live livestream
  Future<void> endLiveStream(String streamId, {bool saveRecording = false}) async {
    await apiService.useFetch(
      '/livestreams/$streamId/end',
      method: 'POST',
      body: {
        'save_recording': saveRecording,
      },
    );
  }

  /// Cancel a scheduled livestream
  Future<void> cancelLiveStream(String streamId) async {
    await apiService.useFetch(
      '/livestreams/$streamId/cancel',
      method: 'POST',
    );
  }

  // ============================================================================
  // Stream Discovery
  // ============================================================================

  /// Get all live streams
  Future<PaginatedResult<LiveStream>> getLiveStreams({
    int page = 1,
    int limit = 20,
  }) async {
    return fetchPaginatedList<LiveStream>(
      endpoint: '/livestreams/live',
      fromJson: LiveStream.fromJson,
      page: page,
      limit: limit,
    );
  }

  /// Get scheduled streams
  Future<PaginatedResult<LiveStream>> getScheduledStreams({
    int page = 1,
    int limit = 20,
  }) async {
    return fetchPaginatedList<LiveStream>(
      endpoint: '/livestreams/scheduled',
      fromJson: LiveStream.fromJson,
      page: page,
      limit: limit,
    );
  }

  /// Get user's streams
  Future<PaginatedResult<LiveStream>> getMyStreams({
    int page = 1,
    int limit = 20,
  }) async {
    return fetchPaginatedList<LiveStream>(
      endpoint: '/livestreams/my-streams',
      fromJson: LiveStream.fromJson,
      page: page,
      limit: limit,
    );
  }

  /// Search streams
  Future<PaginatedResult<LiveStream>> searchStreams({
    required String query,
    int page = 1,
    int limit = 20,
  }) async {
    return fetchPaginatedList<LiveStream>(
      endpoint: '/livestreams/search',
      fromJson: LiveStream.fromJson,
      page: page,
      limit: limit,
      filters: {'q': query},
    );
  }

  // ============================================================================
  // Viewer Management
  // ============================================================================

  /// Join a livestream
  Future<JoinStreamResponse> joinStream(String streamId) async {
    final response = await apiService.useFetch(
      '/livestreams/$streamId/join',
      method: 'POST',
    );

    return JoinStreamResponse.fromJson(response.data);
  }

  /// Leave a livestream
  Future<void> leaveStream(String streamId) async {
    await apiService.useFetch(
      '/livestreams/$streamId/leave',
      method: 'POST',
    );
  }

  /// Get stream viewers
  Future<List<StreamViewer>> getStreamViewers(String streamId) async {
    final response = await apiService.useFetch('/livestreams/$streamId/viewers', method: 'GET');
    final viewers = (response.data['viewers'] as List<dynamic>)
        .map((json) => StreamViewer.fromJson(json as Map<String, dynamic>))
        .toList();

    return viewers;
  }

  // ============================================================================
  // Chat Management
  // ============================================================================

  /// Send a chat message
  Future<ChatMessage> sendChatMessage({
    required String streamId,
    required String message,
  }) async {
    final response = await apiService.useFetch(
      '/livestreams/$streamId/chat',
      method: 'POST',
      body: {
        'message': message,
      },
    );

    return ChatMessage.fromJson(response.data);
  }

  /// Get chat messages
  Future<List<ChatMessage>> getChatMessages({
    required String streamId,
    int page = 1,
    int limit = 50,
  }) async {
    final response = await apiService.useFetch(
      '/livestreams/$streamId/chat',
      method: 'GET',
      queryParameters: {
        'page': page.toString(),
        'limit': limit.toString(),
      },
    );

    return (response.data as List<dynamic>)
        .map((json) => ChatMessage.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  // ============================================================================
  // Reactions
  // ============================================================================

  /// Send a reaction
  Future<StreamReaction> sendReaction({
    required String streamId,
    required ReactionType type,
  }) async {
    final response = await apiService.useFetch(
      '/livestreams/$streamId/react',
      method: 'POST',
      body: {
        'type': type.name,
      },
    );

    return StreamReaction.fromJson(response.data);
  }

  // ============================================================================
  // Statistics
  // ============================================================================

  /// Get stream statistics
  Future<StreamStats> getStreamStats(String streamId) async {
    final response = await apiService.useFetch('/livestreams/$streamId/stats', method: 'GET');
    return StreamStats.fromJson(response.data);
  }
}
