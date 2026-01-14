// lib/presentation/dashboard/competitions/judges/bloc/judge_invitation_state.dart

import 'package:equatable/equatable.dart';

import '../../models/judge_invitation.dart';

/// Base state for judge invitations
abstract class JudgeInvitationState extends Equatable {
  const JudgeInvitationState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class InvitationInitial extends JudgeInvitationState {
  const InvitationInitial();
}

/// Loading state
class InvitationsLoading extends JudgeInvitationState {
  const InvitationsLoading();
}

/// Alias for backward compatibility
class JudgeInvitationLoading extends InvitationsLoading {
  const JudgeInvitationLoading();
}

/// My invitations loaded
class MyInvitationsLoaded extends JudgeInvitationState {

  MyInvitationsLoaded(this.invitations)
    : pendingCount = invitations.where((i) => i.isPending).length;
  final List<JudgeInvitation> invitations;
  final int pendingCount;

  @override
  List<Object?> get props => [invitations, pendingCount];
}

/// Alias for backward compatibility
class JudgeInvitationListLoaded extends MyInvitationsLoaded {
  JudgeInvitationListLoaded(super.invitations);
}

/// Category invitations loaded (for organizers)
class CategoryInvitationsLoaded extends JudgeInvitationState {

  const CategoryInvitationsLoaded(this.invitations, this.categoryId);
  final List<JudgeInvitation> invitations;
  final String categoryId;

  @override
  List<Object?> get props => [invitations, categoryId];
}

/// Invitation sent successfully
class InvitationSent extends JudgeInvitationState {

  const InvitationSent(this.message);
  final String message;

  @override
  List<Object?> get props => [message];
}

/// Invitation responded (accepted/rejected)
class InvitationResponded extends JudgeInvitationState {

  const InvitationResponded(this.message, this.wasAccepted);
  final String message;
  final bool wasAccepted;

  @override
  List<Object?> get props => [message, wasAccepted];
}

/// Error state
class InvitationError extends JudgeInvitationState {

  const InvitationError(this.message);
  final String message;

  @override
  List<Object?> get props => [message];
}

/// Alias for backward compatibility
class JudgeInvitationError extends InvitationError {
  const JudgeInvitationError(super.message);
}
