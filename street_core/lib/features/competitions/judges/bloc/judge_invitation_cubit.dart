// lib/presentation/dashboard/competitions/judges/bloc/judge_invitation_cubit.dart

import '../../models/judge_invitation.dart';
import './judge_invitation_state.dart';
import '../../repositories/judge_invitation_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Cubit for managing judge invitations
class JudgeInvitationCubit extends Cubit<JudgeInvitationState> {
  JudgeInvitationCubit(this._repository) : super(const InvitationInitial());
  final JudgeInvitationRepository _repository;

  // -----------------------------------------------------------------
  // FETCH OPERATIONS
  // -----------------------------------------------------------------

  /// Fetch my judge invitations
  Future<void> fetchMyInvitations() async {
    try {
      emit(const InvitationsLoading());
      final invitations = await _repository.getMyInvitations();
      emit(MyInvitationsLoaded(invitations));
    } catch (e) {
      emit(const InvitationError('error_loading_invitations'));
    }
  }

  /// Alias method for backward compatibility
  Future<void> getMyInvitations() async {
    return fetchMyInvitations();
  }

  /// Fetch invitations for a category (for organizers)
  Future<void> fetchCategoryInvitations(
    String competitionId,
    String categoryId,
  ) async {
    try {
      emit(const InvitationsLoading());
      final invitations = await _repository.getCategoryInvitations(
        competitionId,
        categoryId,
      );
      emit(CategoryInvitationsLoaded(invitations, categoryId));
    } catch (e) {
      emit(const InvitationError('error_loading_category_invitations'));
    }
  }

  // -----------------------------------------------------------------
  // SEND INVITATION
  // -----------------------------------------------------------------

  /// Invite a judge to a category
  Future<void> inviteJudge(
    String competitionId,
    String categoryId, {
    required String userId,
    required String userEmail,
    String? message,
  }) async {
    try {
      emit(const InvitationsLoading());

      final invitationData = {
        'invitedUserId': userId,
        'invitedUserEmail': userEmail,
        if (message != null && message.isNotEmpty) 'message': message,
      };

      await _repository.inviteJudge(competitionId, categoryId, invitationData);
      emit(const InvitationSent('judge_invited_successfully'));

      // Reload category invitations
      await fetchCategoryInvitations(competitionId, categoryId);
    } catch (e) {
      emit(const InvitationError('error_inviting_judge'));
    }
  }

  // -----------------------------------------------------------------
  // RESPOND TO INVITATION
  // -----------------------------------------------------------------

  /// Accept a judge invitation
  Future<void> acceptInvitation(
    String invitationId, {
    String? responseMessage,
  }) async {
    try {
      emit(const InvitationsLoading());
      await _repository.acceptInvitation(
        invitationId,
        responseMessage: responseMessage,
      );
      emit(const InvitationResponded('invitation_accepted_successfully', true));

      // Reload my invitations
      await fetchMyInvitations();
    } catch (e) {
      emit(const InvitationError('error_accepting_invitation'));
    }
  }

  /// Reject a judge invitation
  Future<void> rejectInvitation(
    String invitationId, {
    String? responseMessage,
  }) async {
    try {
      emit(const InvitationsLoading());
      await _repository.rejectInvitation(
        invitationId,
        responseMessage: responseMessage,
      );
      emit(
        const InvitationResponded('invitation_rejected_successfully', false),
      );

      // Reload my invitations
      await fetchMyInvitations();
    } catch (e) {
      emit(const InvitationError('error_rejecting_invitation'));
    }
  }

  /// Generic respond to invitation method
  Future<void> respondToInvitation(
    String invitationId,
    String response, [
    String? responseMessage,
  ]) async {
    if (response == InvitationStatus.accepted) {
      return acceptInvitation(invitationId, responseMessage: responseMessage);
    } else if (response == InvitationStatus.rejected) {
      return rejectInvitation(invitationId, responseMessage: responseMessage);
    } else {
      emit(const InvitationError('invalid_response_type'));
    }
  }

  // -----------------------------------------------------------------
  // UTILITY METHODS
  // -----------------------------------------------------------------

  /// Get pending invitations count (for badge)
  int getPendingCount() {
    final currentState = state;
    if (currentState is MyInvitationsLoaded) {
      return currentState.pendingCount;
    }
    return 0;
  }

  /// Clear state
  void clearState() {
    emit(const InvitationInitial());
  }
}
