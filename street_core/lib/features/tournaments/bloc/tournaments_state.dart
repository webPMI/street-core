import 'package:equatable/equatable.dart';
import '../../../data/models/paginated_result.dart';
import '../models/tournament.dart';
import '../models/tournament_standing.dart';

/// Base state for tournaments
abstract class TournamentsState extends Equatable {
  const TournamentsState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class TournamentsInitial extends TournamentsState {
  const TournamentsInitial();
}

/// Loading state
class TournamentsLoading extends TournamentsState {
  const TournamentsLoading();
}

/// Loaded state with tournaments list
class TournamentsLoaded extends TournamentsState {
  final PaginatedResult<Tournament> result;
  final Map<String, dynamic>? filters;

  const TournamentsLoaded(this.result, {this.filters});

  @override
  List<Object?> get props => [result, filters];
}

/// Tournament detail loaded
class TournamentDetailLoaded extends TournamentsState {
  final Tournament tournament;
  final List<TournamentStanding>? standings;

  const TournamentDetailLoaded(this.tournament, {this.standings});

  @override
  List<Object?> get props => [tournament, standings];
}

/// Standings loaded
class TournamentStandingsLoaded extends TournamentsState {
  final String tournamentId;
  final List<TournamentStanding> standings;

  const TournamentStandingsLoaded(this.tournamentId, this.standings);

  @override
  List<Object?> get props => [tournamentId, standings];
}

/// Error state
class TournamentsError extends TournamentsState {
  final String message;
  final String? errorCode;

  const TournamentsError(this.message, {this.errorCode});

  @override
  List<Object?> get props => [message, errorCode];
}

/// Tournament operation success (create, update, delete, register)
class TournamentOperationSuccess extends TournamentsState {
  final Tournament? tournament;
  final String message;

  const TournamentOperationSuccess({this.tournament, required this.message});

  @override
  List<Object?> get props => [tournament, message];
}

/// Tournament operation loading
class TournamentOperationLoading extends TournamentsState {
  const TournamentOperationLoading();
}
