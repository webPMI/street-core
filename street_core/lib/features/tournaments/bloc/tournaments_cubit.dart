import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/helpers/logger.dart';
import '../services/tournaments_service.dart';
import 'tournaments_state.dart';

/// Cubit for managing tournaments state
class TournamentsCubit extends Cubit<TournamentsState> {
  TournamentsCubit(this._tournamentsService) : super(const TournamentsInitial());

  final TournamentsService _tournamentsService;

  /// Fetch tournaments with filters and pagination
  Future<void> fetchTournaments({
    int page = 1,
    int limit = 20,
    Map<String, dynamic>? filters,
  }) async {
    try {
      emit(const TournamentsLoading());

      final result = await _tournamentsService.fetchTournaments(
        page: page,
        limit: limit,
        filters: filters,
      );

      emit(TournamentsLoaded(result, filters: filters));
    } catch (e, stackTrace) {
      AppLogger.error(
        'Error fetching tournaments: $e',
        error: e,
        stackTrace: stackTrace,
        tag: 'TournamentsCubit',
      );
      emit(TournamentsError(e.toString()));
    }
  }

  /// Fetch upcoming tournaments
  Future<void> fetchUpcomingTournaments({
    int page = 1,
    int limit = 20,
    Map<String, dynamic>? filters,
  }) async {
    try {
      emit(const TournamentsLoading());

      final result = await _tournamentsService.fetchUpcomingTournaments(
        page: page,
        limit: limit,
        filters: filters,
      );

      emit(TournamentsLoaded(result, filters: filters));
    } catch (e, stackTrace) {
      AppLogger.error(
        'Error fetching upcoming tournaments: $e',
        error: e,
        stackTrace: stackTrace,
        tag: 'TournamentsCubit',
      );
      emit(TournamentsError(e.toString()));
    }
  }

  /// Fetch live tournaments
  Future<void> fetchLiveTournaments({
    int page = 1,
    int limit = 20,
    Map<String, dynamic>? filters,
  }) async {
    try {
      emit(const TournamentsLoading());

      final result = await _tournamentsService.fetchLiveTournaments(
        page: page,
        limit: limit,
        filters: filters,
      );

      emit(TournamentsLoaded(result, filters: filters));
    } catch (e, stackTrace) {
      AppLogger.error(
        'Error fetching live tournaments: $e',
        error: e,
        stackTrace: stackTrace,
        tag: 'TournamentsCubit',
      );
      emit(TournamentsError(e.toString()));
    }
  }

  /// Fetch tournament by ID
  Future<void> fetchTournamentById(String tournamentId, {bool fetchStandings = false}) async {
    try {
      emit(const TournamentsLoading());

      final tournament = await _tournamentsService.fetchTournamentById(tournamentId);

      if (fetchStandings) {
        try {
          final standings = await _tournamentsService.fetchTopStandings(tournamentId, limit: 10);
          emit(TournamentDetailLoaded(tournament, standings: standings));
        } catch (e) {
          // If standings fail, still show tournament
          AppLogger.warning('Failed to fetch standings: $e', tag: 'TournamentsCubit');
          emit(TournamentDetailLoaded(tournament));
        }
      } else {
        emit(TournamentDetailLoaded(tournament));
      }
    } catch (e, stackTrace) {
      AppLogger.error(
        'Error fetching tournament detail: $e',
        error: e,
        stackTrace: stackTrace,
        tag: 'TournamentsCubit',
      );
      emit(TournamentsError(e.toString()));
    }
  }

  /// Fetch tournament standings
  Future<void> fetchStandings(String tournamentId) async {
    try {
      emit(const TournamentsLoading());

      final standings = await _tournamentsService.fetchStandings(tournamentId);

      emit(TournamentStandingsLoaded(tournamentId, standings));
    } catch (e, stackTrace) {
      AppLogger.error(
        'Error fetching tournament standings: $e',
        error: e,
        stackTrace: stackTrace,
        tag: 'TournamentsCubit',
      );
      emit(TournamentsError(e.toString()));
    }
  }

  /// Fetch top N standings
  Future<void> fetchTopStandings(String tournamentId, {int limit = 10}) async {
    try {
      emit(const TournamentsLoading());

      final standings = await _tournamentsService.fetchTopStandings(tournamentId, limit: limit);

      emit(TournamentStandingsLoaded(tournamentId, standings));
    } catch (e, stackTrace) {
      AppLogger.error(
        'Error fetching top standings: $e',
        error: e,
        stackTrace: stackTrace,
        tag: 'TournamentsCubit',
      );
      emit(TournamentsError(e.toString()));
    }
  }

  /// Load next page of tournaments
  Future<void> loadNextPage() async {
    final currentState = state;
    if (currentState is! TournamentsLoaded) return;
    if (!currentState.result.hasNext) return;

    try {
      final nextPage = currentState.result.currentPage + 1;
      await fetchTournaments(
        page: nextPage,
        limit: currentState.result.itemsPerPage,
        filters: currentState.filters,
      );
    } catch (e) {
      AppLogger.error('Error loading next page: $e', tag: 'TournamentsCubit');
    }
  }

  /// Reset to initial state
  void reset() {
    emit(const TournamentsInitial());
  }

  // ===========================================================================
  // TOURNAMENT MANAGEMENT (CREATE, UPDATE, DELETE)
  // ===========================================================================

  /// Create a new tournament
  Future<void> createTournament(Map<String, dynamic> tournamentData) async {
    try {
      emit(const TournamentOperationLoading());

      final tournament = await _tournamentsService.createTournament(tournamentData);

      emit(TournamentOperationSuccess(
        tournament: tournament,
        message: 'Tournament created successfully',
      ));
    } catch (e, stackTrace) {
      AppLogger.error(
        'Error creating tournament: $e',
        error: e,
        stackTrace: stackTrace,
        tag: 'TournamentsCubit',
      );
      emit(TournamentsError(e.toString()));
    }
  }

  /// Update an existing tournament
  Future<void> updateTournament(
    String tournamentId,
    Map<String, dynamic> tournamentData,
  ) async {
    try {
      emit(const TournamentOperationLoading());

      final tournament = await _tournamentsService.updateTournament(
        tournamentId,
        tournamentData,
      );

      emit(TournamentOperationSuccess(
        tournament: tournament,
        message: 'Tournament updated successfully',
      ));
    } catch (e, stackTrace) {
      AppLogger.error(
        'Error updating tournament: $e',
        error: e,
        stackTrace: stackTrace,
        tag: 'TournamentsCubit',
      );
      emit(TournamentsError(e.toString()));
    }
  }

  /// Delete a tournament
  Future<void> deleteTournament(String tournamentId) async {
    try {
      emit(const TournamentOperationLoading());

      await _tournamentsService.deleteTournament(tournamentId);

      emit(const TournamentOperationSuccess(
        message: 'Tournament deleted successfully',
      ));
    } catch (e, stackTrace) {
      AppLogger.error(
        'Error deleting tournament: $e',
        error: e,
        stackTrace: stackTrace,
        tag: 'TournamentsCubit',
      );
      emit(TournamentsError(e.toString()));
    }
  }

  // ===========================================================================
  // TOURNAMENT REGISTRATION
  // ===========================================================================

  /// Register current user in a tournament
  Future<void> registerInTournament(String tournamentId) async {
    try {
      emit(const TournamentOperationLoading());

      final tournament = await _tournamentsService.registerInTournament(tournamentId);

      emit(TournamentOperationSuccess(
        tournament: tournament,
        message: 'Successfully registered in tournament',
      ));
    } catch (e, stackTrace) {
      AppLogger.error(
        'Error registering in tournament: $e',
        error: e,
        stackTrace: stackTrace,
        tag: 'TournamentsCubit',
      );
      emit(TournamentsError(e.toString()));
    }
  }

  /// Unregister current user from a tournament
  Future<void> unregisterFromTournament(String tournamentId) async {
    try {
      emit(const TournamentOperationLoading());

      final tournament = await _tournamentsService.unregisterFromTournament(tournamentId);

      emit(TournamentOperationSuccess(
        tournament: tournament,
        message: 'Successfully unregistered from tournament',
      ));
    } catch (e, stackTrace) {
      AppLogger.error(
        'Error unregistering from tournament: $e',
        error: e,
        stackTrace: stackTrace,
        tag: 'TournamentsCubit',
      );
      emit(TournamentsError(e.toString()));
    }
  }
}
