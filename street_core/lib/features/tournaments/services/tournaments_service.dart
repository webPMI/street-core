import '../../../core/helpers/logger.dart';
import '../../../core/services/api_service.dart';
import '../../../data/models/paginated_result.dart';
import '../tournaments_uris.dart';
import '../models/tournament.dart';
import '../models/tournament_standing.dart';

/// Service for tournament-related API calls and business logic
class TournamentsService {
  TournamentsService(this._apiService);

  final ApiService _apiService;

  // ===========================================================================
  // TOURNAMENT CRUD
  // ===========================================================================

  /// Fetch all tournaments with pagination
  Future<PaginatedResult<Tournament>> fetchTournaments({
    int page = 1,
    int limit = 20,
    Map<String, dynamic>? filters,
  }) async {
    AppLogger.info('Fetching paginated tournaments');

    final queryParams = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
    };

    if (filters != null) {
      filters.forEach((key, value) {
        if (value != null) {
          queryParams[key] = value.toString();
        }
      });
    }

    final uri = Uri.parse(
      TournamentsUris.list,
    ).replace(queryParameters: queryParams);

    final response = await _apiService.useFetch<Map<String, dynamic>>(
      uri.toString(),
      method: 'GET',
      fromJsonT: (data) => data as Map<String, dynamic>,
    );

    if (response.status == 'success' && response.data != null) {
      final data = response.data!;
      final items =
          (data['tournaments'] as List<dynamic>? ??
                  data['items'] as List<dynamic>? ??
                  data['data'] as List<dynamic>? ??
                  [])
              .map((e) => Tournament.fromJson(e as Map<String, dynamic>))
              .toList();

      final currentPageNum = data['page'] as int? ?? page;
      final totalPagesNum = data['totalPages'] as int? ?? 1;

      return PaginatedResult<Tournament>(
        items: items,
        totalItems: data['total'] as int? ?? items.length,
        currentPage: currentPageNum,
        totalPages: totalPagesNum,
        itemsPerPage: data['limit'] as int? ?? limit,
        hasNext: currentPageNum < totalPagesNum,
        hasPrevious: currentPageNum > 1,
      );
    }

    final errorMessage = response.message.isNotEmpty
        ? response.message
        : 'Error fetching tournaments';
    AppLogger.error(
      'Failed to fetch tournaments from API (endpoint: ${uri.toString()}, page: $page, limit: $limit, filters: $filters, statusCode: ${response.statusCode}, message: $errorMessage)',
      tag: 'TournamentsService',
    );
    throw Exception(errorMessage);
  }

  /// Fetch upcoming tournaments
  Future<PaginatedResult<Tournament>> fetchUpcomingTournaments({
    int page = 1,
    int limit = 20,
    Map<String, dynamic>? filters,
  }) async {
    AppLogger.info('Fetching upcoming tournaments');

    final queryParams = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
    };

    if (filters != null) {
      filters.forEach((key, value) {
        if (value != null) {
          queryParams[key] = value.toString();
        }
      });
    }

    final uri = Uri.parse(
      TournamentsUris.upcoming,
    ).replace(queryParameters: queryParams);

    final response = await _apiService.useFetch<Map<String, dynamic>>(
      uri.toString(),
      method: 'GET',
      fromJsonT: (data) => data as Map<String, dynamic>,
    );

    if (response.status == 'success' && response.data != null) {
      final data = response.data!;
      final items =
          (data['tournaments'] as List<dynamic>? ?? [])
              .map((e) => Tournament.fromJson(e as Map<String, dynamic>))
              .toList();

      final currentPageNum = data['page'] as int? ?? page;
      final totalPagesNum = data['totalPages'] as int? ?? 1;

      return PaginatedResult<Tournament>(
        items: items,
        totalItems: data['total'] as int? ?? items.length,
        currentPage: currentPageNum,
        totalPages: totalPagesNum,
        itemsPerPage: data['limit'] as int? ?? limit,
        hasNext: currentPageNum < totalPagesNum,
        hasPrevious: currentPageNum > 1,
      );
    }

    throw Exception(response.message.isEmpty ? 'Error fetching upcoming tournaments' : response.message);
  }

  /// Fetch live tournaments
  Future<PaginatedResult<Tournament>> fetchLiveTournaments({
    int page = 1,
    int limit = 20,
    Map<String, dynamic>? filters,
  }) async {
    AppLogger.info('Fetching live tournaments');

    final queryParams = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
    };

    if (filters != null) {
      filters.forEach((key, value) {
        if (value != null) {
          queryParams[key] = value.toString();
        }
      });
    }

    final uri = Uri.parse(
      TournamentsUris.live,
    ).replace(queryParameters: queryParams);

    final response = await _apiService.useFetch<Map<String, dynamic>>(
      uri.toString(),
      method: 'GET',
      fromJsonT: (data) => data as Map<String, dynamic>,
    );

    if (response.status == 'success' && response.data != null) {
      final data = response.data!;
      final items =
          (data['tournaments'] as List<dynamic>? ?? [])
              .map((e) => Tournament.fromJson(e as Map<String, dynamic>))
              .toList();

      final currentPageNum = data['page'] as int? ?? page;
      final totalPagesNum = data['totalPages'] as int? ?? 1;

      return PaginatedResult<Tournament>(
        items: items,
        totalItems: data['total'] as int? ?? items.length,
        currentPage: currentPageNum,
        totalPages: totalPagesNum,
        itemsPerPage: data['limit'] as int? ?? limit,
        hasNext: currentPageNum < totalPagesNum,
        hasPrevious: currentPageNum > 1,
      );
    }

    throw Exception(response.message.isEmpty ? 'Error fetching live tournaments' : response.message);
  }

  /// Fetch tournament by ID
  Future<Tournament> fetchTournamentById(String tournamentId) async {
    AppLogger.info('Fetching tournament by ID: $tournamentId');

    final response = await _apiService.useFetch<Map<String, dynamic>>(
      TournamentsUris.detail(tournamentId),
      method: 'GET',
      fromJsonT: (data) => data as Map<String, dynamic>,
    );

    if (response.status == 'success' && response.data != null) {
      return Tournament.fromJson(response.data!);
    }

    final errorMessage = response.message.isNotEmpty
        ? response.message
        : 'Error fetching tournament';
    AppLogger.error(
      'Failed to fetch tournament from API (id: $tournamentId, statusCode: ${response.statusCode}, message: $errorMessage)',
      tag: 'TournamentsService',
    );
    throw Exception(errorMessage);
  }

  // ===========================================================================
  // STANDINGS
  // ===========================================================================

  /// Fetch tournament standings
  Future<List<TournamentStanding>> fetchStandings(String tournamentId) async {
    AppLogger.info('Fetching standings for tournament: $tournamentId');

    final response = await _apiService.useFetch<List<dynamic>>(
      TournamentsUris.standings(tournamentId),
      method: 'GET',
      fromJsonT: (data) => data as List<dynamic>,
    );

    if (response.status == 'success' && response.data != null) {
      return response.data!
          .map((e) => TournamentStanding.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    final errorMessage = response.message.isNotEmpty
        ? response.message
        : 'Error fetching standings';
    AppLogger.error(
      'Failed to fetch standings from API (tournamentId: $tournamentId, statusCode: ${response.statusCode}, message: $errorMessage)',
      tag: 'TournamentsService',
    );
    throw Exception(errorMessage);
  }

  /// Fetch top N standings
  Future<List<TournamentStanding>> fetchTopStandings(String tournamentId, {int limit = 10}) async {
    AppLogger.info('Fetching top $limit standings for tournament: $tournamentId');

    final uri = Uri.parse(
      TournamentsUris.topStandings(tournamentId),
    ).replace(queryParameters: {'limit': limit.toString()});

    final response = await _apiService.useFetch<List<dynamic>>(
      uri.toString(),
      method: 'GET',
      fromJsonT: (data) => data as List<dynamic>,
    );

    if (response.status == 'success' && response.data != null) {
      return response.data!
          .map((e) => TournamentStanding.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    throw Exception(response.message.isEmpty ? 'Error fetching top standings' : response.message);
  }

  // ===========================================================================
  // TOURNAMENT MANAGEMENT (CREATE, UPDATE, DELETE)
  // ===========================================================================

  /// Create a new tournament
  Future<Tournament> createTournament(Map<String, dynamic> tournamentData) async {
    AppLogger.info('Creating new tournament');

    final response = await _apiService.useFetch<Map<String, dynamic>>(
      TournamentsUris.create,
      method: 'POST',
      body: tournamentData,
      fromJsonT: (data) => data as Map<String, dynamic>,
    );

    if (response.status == 'success' && response.data != null) {
      AppLogger.info('Tournament created successfully');
      return Tournament.fromJson(response.data!);
    }

    final errorMessage = response.message.isNotEmpty
        ? response.message
        : 'Error creating tournament';
    AppLogger.error(
      'Failed to create tournament (statusCode: ${response.statusCode}, message: $errorMessage)',
      tag: 'TournamentsService',
    );
    throw Exception(errorMessage);
  }

  /// Update an existing tournament
  Future<Tournament> updateTournament(
    String tournamentId,
    Map<String, dynamic> tournamentData,
  ) async {
    AppLogger.info('Updating tournament: $tournamentId');

    final response = await _apiService.useFetch<Map<String, dynamic>>(
      TournamentsUris.update(tournamentId),
      method: 'PUT',
      body: tournamentData,
      fromJsonT: (data) => data as Map<String, dynamic>,
    );

    if (response.status == 'success' && response.data != null) {
      AppLogger.info('Tournament updated successfully');
      return Tournament.fromJson(response.data!);
    }

    final errorMessage = response.message.isNotEmpty
        ? response.message
        : 'Error updating tournament';
    AppLogger.error(
      'Failed to update tournament (id: $tournamentId, statusCode: ${response.statusCode}, message: $errorMessage)',
      tag: 'TournamentsService',
    );
    throw Exception(errorMessage);
  }

  /// Delete a tournament
  Future<void> deleteTournament(String tournamentId) async {
    AppLogger.info('Deleting tournament: $tournamentId');

    final response = await _apiService.useFetch<Map<String, dynamic>>(
      TournamentsUris.delete(tournamentId),
      method: 'DELETE',
      fromJsonT: (data) => data as Map<String, dynamic>,
    );

    if (response.status == 'success') {
      AppLogger.info('Tournament deleted successfully');
      return;
    }

    final errorMessage = response.message.isNotEmpty
        ? response.message
        : 'Error deleting tournament';
    AppLogger.error(
      'Failed to delete tournament (id: $tournamentId, statusCode: ${response.statusCode}, message: $errorMessage)',
      tag: 'TournamentsService',
    );
    throw Exception(errorMessage);
  }

  // ===========================================================================
  // TOURNAMENT REGISTRATION
  // ===========================================================================

  /// Register current user in a tournament
  Future<Tournament> registerInTournament(String tournamentId) async {
    AppLogger.info('Registering in tournament: $tournamentId');

    final response = await _apiService.useFetch<Map<String, dynamic>>(
      TournamentsUris.register(tournamentId),
      method: 'POST',
      fromJsonT: (data) => data as Map<String, dynamic>,
    );

    if (response.status == 'success' && response.data != null) {
      AppLogger.info('Successfully registered in tournament');
      return Tournament.fromJson(response.data!);
    }

    final errorMessage = response.message.isNotEmpty
        ? response.message
        : 'Error registering in tournament';
    AppLogger.error(
      'Failed to register in tournament (id: $tournamentId, statusCode: ${response.statusCode}, message: $errorMessage)',
      tag: 'TournamentsService',
    );
    throw Exception(errorMessage);
  }

  /// Unregister current user from a tournament
  Future<Tournament> unregisterFromTournament(String tournamentId) async {
    AppLogger.info('Unregistering from tournament: $tournamentId');

    final response = await _apiService.useFetch<Map<String, dynamic>>(
      TournamentsUris.unregister(tournamentId),
      method: 'DELETE',
      fromJsonT: (data) => data as Map<String, dynamic>,
    );

    if (response.status == 'success' && response.data != null) {
      AppLogger.info('Successfully unregistered from tournament');
      return Tournament.fromJson(response.data!);
    }

    final errorMessage = response.message.isNotEmpty
        ? response.message
        : 'Error unregistering from tournament';
    AppLogger.error(
      'Failed to unregister from tournament (id: $tournamentId, statusCode: ${response.statusCode}, message: $errorMessage)',
      tag: 'TournamentsService',
    );
    throw Exception(errorMessage);
  }
}
