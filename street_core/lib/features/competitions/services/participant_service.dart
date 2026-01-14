/// Participant Service - Manage competition participants.
/// Following Monolith-by-Features architecture (ADR-005).

import '../../../core/helpers/logger.dart';
import '../../../core/services/api_service.dart';
import '../competitions_uris.dart';
import '../models/participant.dart';

/// Service for managing competition participants.
/// Extracted from CompetitionsService for better separation of concerns.
class ParticipantService {
  ParticipantService(this._apiService);

  final ApiService _apiService;

  // ===========================================================================
  // FETCH OPERATIONS
  // ===========================================================================

  /// Fetch pending participants (awaiting approval)
  Future<List<Map<String, dynamic>>> fetchPending(String competitionId) async {
    AppLogger.info('Fetching pending participants for competition: $competitionId');

    final response = await _apiService.useFetch<Map<String, dynamic>>(
      '${CompetitionsUris.detail(competitionId)}/participants/pending',
      method: 'GET',
      fromJsonT: (data) => data as Map<String, dynamic>,
    );

    if (response.status == 'success' && response.data != null) {
      return (response.data!['participants'] as List<dynamic>? ?? [])
          .map((e) => e as Map<String, dynamic>)
          .toList();
    }

    return [];
  }

  /// Fetch all participants
  Future<List<Map<String, dynamic>>> fetchAll(String competitionId) async {
    AppLogger.info('Fetching participants for competition: $competitionId');

    final response = await _apiService.useFetch<Map<String, dynamic>>(
      CompetitionsUris.participants(competitionId),
      method: 'GET',
      fromJsonT: (data) => data as Map<String, dynamic>,
    );

    if (response.status == 'success' && response.data != null) {
      final participants = (response.data!['participants'] as List<dynamic>? ?? [])
          .map((e) => e as Map<String, dynamic>)
          .toList();
      AppLogger.info('Fetched ${participants.length} participants for competition: $competitionId');
      return participants;
    }

    AppLogger.warning('No participants found or failed to fetch for competition: $competitionId');
    return [];
  }

  /// Fetch participant counts
  Future<ParticipantCounts> fetchCounts(String competitionId) async {
    AppLogger.info('Fetching participant counts for competition: $competitionId');

    final response = await _apiService.useFetch<Map<String, dynamic>>(
      '${CompetitionsUris.detail(competitionId)}/participants/counts',
      method: 'GET',
      fromJsonT: (data) => data as Map<String, dynamic>,
    );

    if (response.status == 'success' && response.data != null) {
      return ParticipantCounts.fromJson(response.data!);
    }

    return const ParticipantCounts();
  }

  // ===========================================================================
  // APPROVAL OPERATIONS
  // ===========================================================================

  /// Approve a participant
  Future<void> approve(String competitionId, String participantId) async {
    AppLogger.info('Approving participant $participantId for competition: $competitionId');

    final response = await _apiService.useFetch<void>(
      '${CompetitionsUris.detail(competitionId)}/participants/$participantId/approve',
      method: 'POST',
    );

    if (response.status != 'success') {
      throw Exception(response.message.isNotEmpty ? response.message : 'Error approving participant');
    }
  }

  /// Reject a participant
  Future<void> reject(String competitionId, String participantId) async {
    AppLogger.info('Rejecting participant $participantId for competition: $competitionId');

    final response = await _apiService.useFetch<void>(
      '${CompetitionsUris.detail(competitionId)}/participants/$participantId/reject',
      method: 'POST',
    );

    if (response.status != 'success') {
      throw Exception(response.message.isNotEmpty ? response.message : 'Error rejecting participant');
    }
  }

  // ===========================================================================
  // BULK OPERATIONS
  // ===========================================================================

  /// Bulk approve participants
  Future<void> bulkApprove(String competitionId, List<String> participantIds) async {
    AppLogger.info('Bulk approving ${participantIds.length} participants for competition: $competitionId');

    final response = await _apiService.useFetch<void>(
      '${CompetitionsUris.detail(competitionId)}/participants/bulk-approve',
      method: 'POST',
      body: {'participantIds': participantIds},
    );

    if (response.status != 'success') {
      throw Exception(response.message.isNotEmpty ? response.message : 'Error bulk approving participants');
    }
  }

  /// Bulk reject participants
  Future<void> bulkReject(String competitionId, List<String> participantIds) async {
    AppLogger.info('Bulk rejecting ${participantIds.length} participants for competition: $competitionId');

    final response = await _apiService.useFetch<void>(
      '${CompetitionsUris.detail(competitionId)}/participants/bulk-reject',
      method: 'POST',
      body: {'participantIds': participantIds},
    );

    if (response.status != 'success') {
      throw Exception(response.message.isNotEmpty ? response.message : 'Error bulk rejecting participants');
    }
  }
}
