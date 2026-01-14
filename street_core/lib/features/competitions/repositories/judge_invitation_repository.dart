// lib/domain/judge_invitation_repository.dart

import '../../../core/crud/crud.dart';
import '../competitions_uris.dart';
import '../models/judge_invitation.dart';

/// Repository for managing judge invitations
class JudgeInvitationRepository extends BaseRepository {
  JudgeInvitationRepository(super.apiService);

  /// Create a judge invitation for a competition
  Future<JudgeInvitation> createInvitation(
    String competitionId,
    Map<String, dynamic> invitationData,
  ) async {
    return create<JudgeInvitation>(
      endpoint: CompetitionsUris.createJudgeInvitation(competitionId),
      data: invitationData,
      fromJson: JudgeInvitation.fromJson,
      errorMessage: 'Error creating judge invitation',
    );
  }

  /// Get my pending judge invitations
  Future<List<JudgeInvitation>> getMyInvitations() async {
    return executeSafely<List<JudgeInvitation>>(
      operation: () async {
        final response = await apiService.useFetch<Map<String, dynamic>>(
          CompetitionsUris.myJudgeInvitations,
          method: 'GET',
          requiredToken: true,
          fromJsonT: (data) => data as Map<String, dynamic>,
        );

        if (response.status == 'success' && response.data != null) {
          // Handle Map response from backend - look for common list keys
          final data = response.data!;
          final listData = data['invitations'] ??
                          data['data'] ??
                          data['items'] ??
                          [];

          if (listData is List) {
            return listData
                .map((json) => JudgeInvitation.fromJson(json as Map<String, dynamic>))
                .toList();
          }

          // If no list found, return empty list
          return [];
        }

        return [];
      },
      errorMessage: 'Error fetching judge invitations',
      debugContext: {
        'endpoint': CompetitionsUris.myJudgeInvitations,
        'method': 'GET',
        'requiredToken': true,
      },
    );
  }

  /// Accept a judge invitation
  Future<void> acceptInvitation(
    String invitationId, {
    String? responseMessage,
  }) async {
    return executeAction(
      endpoint: CompetitionsUris.respondToInvitation(invitationId),
      method: 'POST',
      data: {
        'accept': true,
        if (responseMessage != null) 'response': responseMessage,
      },
      errorMessage: 'Error accepting invitation',
    );
  }

  /// Reject a judge invitation
  Future<void> rejectInvitation(
    String invitationId, {
    String? responseMessage,
  }) async {
    return executeAction(
      endpoint: CompetitionsUris.respondToInvitation(invitationId),
      method: 'POST',
      data: {
        'accept': false,
        if (responseMessage != null) 'response': responseMessage,
      },
      errorMessage: 'Error rejecting invitation',
    );
  }

  /// Get invitations for a specific competition (for organizers)
  Future<List<JudgeInvitation>> getCompetitionInvitations(
    String competitionId,
  ) async {
    return fetchList<JudgeInvitation>(
      endpoint: CompetitionsUris.judgeInvitations(competitionId),
      fromJson: JudgeInvitation.fromJson,
      errorMessage: 'Error fetching competition invitations',
      useCache: false,
    );
  }

  /// Cancel a judge invitation
  Future<void> cancelInvitation(
    String competitionId,
    String invitationId,
  ) async {
    return executeAction(
      endpoint: CompetitionsUris.cancelJudgeInvitation(
        competitionId,
        invitationId,
      ),
      method: 'DELETE',
      errorMessage: 'Error cancelling invitation',
    );
  }

  /// Get invitations for a specific category (for organizers)
  Future<List<JudgeInvitation>> getCategoryInvitations(
    String competitionId,
    String categoryId,
  ) async {
    return fetchList<JudgeInvitation>(
      endpoint: CompetitionsUris.categoryJudgeInvitations(
        competitionId,
        categoryId,
      ),
      fromJson: JudgeInvitation.fromJson,
      errorMessage: 'Error fetching category invitations',
      useCache: false,
    );
  }

  /// Invite a judge to a category
  Future<JudgeInvitation> inviteJudge(
    String competitionId,
    String categoryId,
    Map<String, dynamic> invitationData,
  ) async {
    return create<JudgeInvitation>(
      endpoint: CompetitionsUris.inviteJudgeToCategory(
        competitionId,
        categoryId,
      ),
      data: invitationData,
      fromJson: JudgeInvitation.fromJson,
      errorMessage: 'Error inviting judge',
    );
  }
}
