/// Competitions State - All states for competitions cubit.
/// Following Monolith-by-Features architecture (ADR-005).

import 'package:equatable/equatable.dart';
import '../models/competition.dart';

/// Base state for competitions
abstract class CompetitionsState extends Equatable {
  const CompetitionsState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class CompetitionsInitial extends CompetitionsState {
  const CompetitionsInitial();
}

/// Loading state
class CompetitionsLoading extends CompetitionsState {
  const CompetitionsLoading();
}

/// Loading more items state (for pagination)
class CompetitionsLoadingMore extends CompetitionsState {
  const CompetitionsLoadingMore({
    required this.competitions,
    required this.currentPage,
  });

  final List<Competition> competitions;
  final int currentPage;

  @override
  List<Object?> get props => [competitions, currentPage];
}

/// Competitions list loaded state
class CompetitionsLoaded extends CompetitionsState {
  const CompetitionsLoaded({
    required this.competitions,
    this.hasMore = false,
    this.currentPage = 1,
  });

  final List<Competition> competitions;
  final bool hasMore;
  final int currentPage;

  @override
  List<Object?> get props => [competitions, hasMore, currentPage];
}

/// Single competition detail loaded state
class CompetitionDetailLoaded extends CompetitionsState {
  const CompetitionDetailLoaded(this.competition);

  final Competition competition;

  @override
  List<Object?> get props => [competition];
}

/// Competition created successfully
class CompetitionCreated extends CompetitionsState {
  const CompetitionCreated(this.competition);

  final Competition competition;

  @override
  List<Object?> get props => [competition];
}

/// Competition created with warning (e.g., some images failed to upload)
class CompetitionCreatedWithWarning extends CompetitionsState {
  const CompetitionCreatedWithWarning(this.competition, this.warning);

  final Competition competition;
  final String warning;

  @override
  List<Object?> get props => [competition, warning];
}

/// Competition updated successfully
class CompetitionUpdated extends CompetitionsState {
  const CompetitionUpdated(this.competition);

  final Competition competition;

  @override
  List<Object?> get props => [competition];
}

/// Competition updated with warning (e.g., some images failed to upload)
class CompetitionUpdatedWithWarning extends CompetitionsState {
  const CompetitionUpdatedWithWarning(this.competition, this.warning);

  final Competition competition;
  final String warning;

  @override
  List<Object?> get props => [competition, warning];
}

/// Competition deleted successfully
class CompetitionDeleted extends CompetitionsState {
  const CompetitionDeleted();
}

/// Registration success state
class CompetitionRegistrationSuccess extends CompetitionsState {
  const CompetitionRegistrationSuccess();
}

/// Unregistration success state
class CompetitionUnregistrationSuccess extends CompetitionsState {
  const CompetitionUnregistrationSuccess();
}

/// Scores submitted successfully
class CompetitionScoresSubmitted extends CompetitionsState {
  const CompetitionScoresSubmitted();
}

/// Judging mode state
class CompetitionJudgingMode extends CompetitionsState {
  const CompetitionJudgingMode(this.competition, {this.currentRoundId});

  final Competition competition;
  final String? currentRoundId;

  @override
  List<Object?> get props => [competition, currentRoundId];
}

/// Leaderboard loaded state
class CompetitionLeaderboardLoaded extends CompetitionsState {
  const CompetitionLeaderboardLoaded(this.leaderboard);

  final Leaderboard leaderboard;

  @override
  List<Object?> get props => [leaderboard];
}

/// Competition status changed state
class CompetitionStatusChanged extends CompetitionsState {
  const CompetitionStatusChanged(this.newStatus);

  final String newStatus;

  @override
  List<Object?> get props => [newStatus];
}

/// Results published state
class CompetitionResultsPublished extends CompetitionsState {
  const CompetitionResultsPublished();
}

/// Error state
class CompetitionsError extends CompetitionsState {
  const CompetitionsError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
