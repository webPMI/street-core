import '../../../core/helpers/logger.dart';
import '../../../core/services/api_service.dart';
import '../../../data/models/paginated_result.dart';
import '../competitions_uris.dart';
import '../models/competition.dart';
import '../models/competition_category_model.dart';
import '../models/judge_check_in.dart';

/// Consolidated service for competitions feature.
/// Combines API calls with business logic.
class CompetitionsService {
  CompetitionsService(this._apiService);

  final ApiService _apiService;

  // ===========================================================================
  // COMPETITION CRUD
  // ===========================================================================

  /// Fetch all competitions with pagination
  Future<PaginatedResult<Competition>> fetchCompetitions({
    int page = 1,
    int limit = 20,
    Map<String, dynamic>? filters,
  }) async {
    AppLogger.info('Fetching paginated competitions');

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
      CompetitionsUris.list,
    ).replace(queryParameters: queryParams);

    final response = await _apiService.useFetch<Map<String, dynamic>>(
      uri.toString(),
      method: 'GET',
      fromJsonT: (data) => data as Map<String, dynamic>,
    );

    if (response.status == 'success' && response.data != null) {
      final data = response.data!;
      final items =
          (data['competitions'] as List<dynamic>? ??
                  data['items'] as List<dynamic>? ??
                  data['data'] as List<dynamic>? ??
                  [])
              .map((e) => Competition.fromJson(e as Map<String, dynamic>))
              .toList();

      final currentPageNum = data['page'] as int? ?? page;
      final totalPagesNum = data['totalPages'] as int? ?? 1;

      return PaginatedResult<Competition>(
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
        : 'Error fetching competitions';
    AppLogger.error(
      'Failed to fetch competitions from API (endpoint: ${uri.toString()}, page: $page, limit: $limit, filters: $filters, statusCode: ${response.statusCode}, message: $errorMessage)',
      tag: 'CompetitionsService',
    );
    throw Exception(errorMessage);
  }

  /// Fetch upcoming competitions
  Future<PaginatedResult<Competition>> fetchUpcomingCompetitions({
    int page = 1,
    int limit = 20,
  }) async {
    return fetchCompetitions(
      page: page,
      limit: limit,
      filters: {'status': 'upcoming'},
    );
  }

  /// Fetch live competitions
  Future<PaginatedResult<Competition>> fetchLiveCompetitions({
    int page = 1,
    int limit = 20,
  }) async {
    return fetchCompetitions(
      page: page,
      limit: limit,
      filters: {'status': 'live'},
    );
  }

  /// Fetch my competitions (user's competitions)
  Future<PaginatedResult<Competition>> fetchMyCompetitions({
    int page = 1,
    int limit = 20,
    Map<String, dynamic>? filters,
  }) async {
    AppLogger.info('Fetching my competitions');

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
      CompetitionsUris.myCompetitions,
    ).replace(queryParameters: queryParams);

    final response = await _apiService.useFetch<Map<String, dynamic>>(
      uri.toString(),
      method: 'GET',
      fromJsonT: (data) => data as Map<String, dynamic>,
    );

    if (response.status == 'success' && response.data != null) {
      final data = response.data!;
      final items =
          (data['competitions'] as List<dynamic>? ??
                  data['items'] as List<dynamic>? ??
                  data['data'] as List<dynamic>? ??
                  [])
              .map((e) => Competition.fromJson(e as Map<String, dynamic>))
              .toList();

      final currentPageNum = data['page'] as int? ?? page;
      final totalPagesNum = data['totalPages'] as int? ?? 1;

      return PaginatedResult<Competition>(
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
        : 'Error fetching my competitions';
    AppLogger.error(
      'Failed to fetch my competitions from API (endpoint: ${uri.toString()}, page: $page, limit: $limit, filters: $filters, statusCode: ${response.statusCode}, message: $errorMessage)',
      tag: 'CompetitionsService',
    );
    throw Exception(errorMessage);
  }

  /// Fetch a single competition by ID
  Future<Competition> fetchCompetitionById(String id) async {
    AppLogger.info('Fetching competition: $id');

    final response = await _apiService.useFetch<Map<String, dynamic>>(
      CompetitionsUris.detail(id),
      method: 'GET',
      fromJsonT: (data) => data as Map<String, dynamic>,
    );

    if (response.status == 'success' && response.data != null) {
      return Competition.fromJson(response.data!);
    }

    final errorMessage = response.message.isNotEmpty
        ? response.message
        : 'competition_not_found';
    AppLogger.error(
      'Failed to fetch competition by ID (competitionId: $id, statusCode: ${response.statusCode}, message: $errorMessage)',
      tag: 'CompetitionsService',
    );
    throw Exception(errorMessage);
  }

  /// Create a new competition
  Future<Competition> createCompetition(Map<String, dynamic> data) async {
    AppLogger.info('Creating competition');

    final response = await _apiService.useFetch<Map<String, dynamic>>(
      CompetitionsUris.create,
      method: 'POST',
      body: data,
      fromJsonT: (data) => data as Map<String, dynamic>,
    );

    if (response.status == 'success' && response.data != null) {
      return Competition.fromJson(response.data!);
    }

    final errorMessage = response.message.isNotEmpty
        ? response.message
        : 'error_creating_competition';
    AppLogger.error(
      'Failed to create competition (title: ${data['title']}, competitionType: ${data['competitionType']}, statusCode: ${response.statusCode}, message: $errorMessage)',
      tag: 'CompetitionsService',
    );
    throw Exception(errorMessage);
  }

  /// Update an existing competition
  Future<Competition> updateCompetition(
    String id,
    Map<String, dynamic> data,
  ) async {
    AppLogger.info('Updating competition: $id');

    final response = await _apiService.useFetch<Map<String, dynamic>>(
      CompetitionsUris.update(id),
      method: 'PUT',
      body: data,
      fromJsonT: (data) => data as Map<String, dynamic>,
    );

    if (response.status == 'success' && response.data != null) {
      return Competition.fromJson(response.data!);
    }

    final errorMessage = response.message.isNotEmpty
        ? response.message
        : 'Error updating competition';
    AppLogger.error(
      'Failed to update competition (competitionId: $id, dataKeys: ${data.keys.toList()}, statusCode: ${response.statusCode}, message: $errorMessage)',
      tag: 'CompetitionsService',
    );
    throw Exception(errorMessage);
  }

  /// Delete a competition
  Future<void> deleteCompetition(String id) async {
    AppLogger.info('Deleting competition: $id');

    final response = await _apiService.useFetch<void>(
      CompetitionsUris.delete(id),
      method: 'DELETE',
    );

    if (response.status != 'success') {
      throw Exception(
        response.message.isNotEmpty
            ? response.message
            : 'Error deleting competition',
      );
    }
  }

  // ===========================================================================
  // REGISTRATION
  // ===========================================================================

  /// Register for a competition
  Future<void> registerForCompetition(
    String competitionId, {
    String? riderId,
  }) async {
    AppLogger.info('Registering for competition: $competitionId');

    final response = await _apiService.useFetch<void>(
      CompetitionsUris.register(competitionId),
      method: 'POST',
      body: riderId != null ? {'riderId': riderId} : null,
    );

    if (response.status != 'success') {
      throw Exception(
        response.message.isNotEmpty
            ? response.message
            : 'Error registering for competition',
      );
    }
  }

  /// Unregister from a competition
  Future<void> unregisterFromCompetition(
    String competitionId, {
    String? riderId,
  }) async {
    AppLogger.info('Unregistering from competition: $competitionId');

    final response = await _apiService.useFetch<void>(
      CompetitionsUris.unregister(competitionId),
      method: 'DELETE',
      body: riderId != null ? {'riderId': riderId} : null,
    );

    if (response.status != 'success') {
      throw Exception(
        response.message.isNotEmpty
            ? response.message
            : 'Error unregistering from competition',
      );
    }
  }

  /// Get external registration URL for a competition
  /// Returns the URL if the competition uses external registration, null otherwise
  String? getExternalRegistrationUrl(Competition competition) {
    if (!competition.isExternalRegistration) {
      return null;
    }
    return competition.externalRegistrationUrl;
  }

  // ===========================================================================
  // SCORING
  // ===========================================================================

  /// Submit scores for a competition
  Future<void> submitScores(
    String competitionId,
    Map<String, dynamic> scoreData,
  ) async {
    AppLogger.info('Submitting scores for competition: $competitionId');

    final response = await _apiService.useFetch<void>(
      CompetitionsUris.submitScores(competitionId),
      method: 'POST',
      body: scoreData,
    );

    if (response.status != 'success') {
      throw Exception(
        response.message.isNotEmpty
            ? response.message
            : 'Error submitting scores',
      );
    }
  }

  /// Get scores for a competition
  Future<List<RiderScore>> getScores(String competitionId) async {
    AppLogger.info('Fetching scores for competition: $competitionId');

    final response = await _apiService.useFetch<Map<String, dynamic>>(
      CompetitionsUris.getScores(competitionId),
      method: 'GET',
      fromJsonT: (data) => data as Map<String, dynamic>,
    );

    if (response.status == 'success' && response.data != null) {
      final scores = response.data!['data'] as List<dynamic>? ?? [];
      return scores
          .map((e) => RiderScore.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    throw Exception(response.message);
  }

  // ===========================================================================
  // LEADERBOARD
  // ===========================================================================

  /// Get leaderboard for a competition
  Future<Leaderboard?> getLeaderboard(String competitionId) async {
    AppLogger.info('Fetching leaderboard for competition: $competitionId');

    final response = await _apiService.useFetch<Map<String, dynamic>>(
      CompetitionsUris.leaderboard(competitionId),
      method: 'GET',
      fromJsonT: (data) => data as Map<String, dynamic>,
    );

    if (response.status == 'success' && response.data != null) {
      return Leaderboard.fromJson(
        response.data!['data'] as Map<String, dynamic>,
      );
    }

    return null;
  }

  /// Update leaderboard (admin only)
  Future<Leaderboard> updateLeaderboard(String competitionId) async {
    AppLogger.info('Updating leaderboard for competition: $competitionId');

    final response = await _apiService.useFetch<Map<String, dynamic>>(
      CompetitionsUris.updateLeaderboard(competitionId),
      method: 'POST',
      fromJsonT: (data) => data as Map<String, dynamic>,
    );

    if (response.status == 'success' && response.data != null) {
      return Leaderboard.fromJson(
        response.data!['data'] as Map<String, dynamic>,
      );
    }

    throw Exception(response.message);
  }

  // ===========================================================================
  // CATEGORIES
  // ===========================================================================

  /// Get categories for a competition (public endpoint)
  Future<List<CompetitionCategory>> getCategories(String competitionId) async {
    AppLogger.info('Fetching categories for competition: $competitionId');

    final response = await _apiService.useFetch<List<dynamic>>(
      CompetitionsUris.categories(competitionId),
      method: 'GET',
      requiredToken: false,
      fromJsonT: (data) => data as List<dynamic>,
    );

    if (response.status == 'success' && response.data != null) {
      return response.data!
          .map((e) => CompetitionCategory.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    final errorMessage = response.message.isNotEmpty
        ? response.message
        : 'Error fetching categories';
    AppLogger.error(
      'Failed to fetch categories (competitionId: $competitionId, statusCode: ${response.statusCode}, message: $errorMessage)',
      tag: 'CompetitionsService',
    );
    throw Exception(errorMessage);
  }

  // ===========================================================================
  // STATUS MANAGEMENT
  // ===========================================================================

  /// Start a competition (set to live)
  /// Validate if a competition can be started
  Future<StartValidationResult> validateStartRequirements(String competitionId) async {
    AppLogger.info('Validating start requirements for competition: $competitionId');

    final response = await _apiService.useFetch<Map<String, dynamic>>(
      CompetitionsUris.validateStart(competitionId),
      method: 'GET',
      fromJsonT: (data) => data as Map<String, dynamic>,
    );

    if (response.status == 'success' && response.data != null) {
      return StartValidationResult.fromJson(response.data!);
    }

    throw Exception(response.message.isEmpty ? 'Failed to validate competition' : response.message);
  }

  /// Start a competition
  Future<void> startCompetition(String competitionId) async {
    AppLogger.info('Starting competition: $competitionId');

    final response = await _apiService.useFetch<void>(
      CompetitionsUris.start(competitionId),
      method: 'POST',
    );

    if (response.status != 'success') {
      throw Exception(response.message);
    }
  }

  /// End a competition
  Future<void> endCompetition(String competitionId) async {
    AppLogger.info('Ending competition: $competitionId');

    final response = await _apiService.useFetch<void>(
      CompetitionsUris.end(competitionId),
      method: 'POST',
    );

    if (response.status != 'success') {
      throw Exception(
        response.message.isNotEmpty
            ? response.message
            : 'Error ending competition',
      );
    }
  }

  /// Publish competition results
  Future<void> publishResults(String competitionId) async {
    AppLogger.info('Publishing results for competition: $competitionId');

    final response = await _apiService.useFetch<void>(
      CompetitionsUris.publishResults(competitionId),
      method: 'POST',
    );

    if (response.status != 'success') {
      throw Exception(
        response.message.isNotEmpty
            ? response.message
            : 'Error publishing results',
      );
    }
  }

  /// Postpone a competition
  Future<void> postponeCompetition(String competitionId) async {
    AppLogger.info('Postponing competition: $competitionId');

    final response = await _apiService.useFetch<void>(
      CompetitionsUris.postpone(competitionId),
      method: 'POST',
    );

    if (response.status != 'success') {
      throw Exception(
        response.message.isNotEmpty
            ? response.message
            : 'Error postponing competition',
      );
    }
  }

  // ===========================================================================
  // DEPRECATED - Use Competition model methods instead
  // ===========================================================================

  /// @deprecated Use `competition.canRegisterUser(userId)` instead
  @Deprecated('Use competition.canRegisterUser(userId) instead')
  bool canRegister(Competition competition, String userId) =>
      competition.canRegisterUser(userId);

  /// @deprecated Use `competition.isRegisteredBy(userId)` instead
  @Deprecated('Use competition.isRegisteredBy(userId) instead')
  bool isRegistered(Competition competition, String userId) =>
      competition.isRegisteredBy(userId);

  /// @deprecated Use `competition.isJudgedBy(userId)` instead
  @Deprecated('Use competition.isJudgedBy(userId) instead')
  bool isJudge(Competition competition, String userId) =>
      competition.isJudgedBy(userId);

  /// @deprecated Use `competition.isOrganizedBy(userId)` instead
  @Deprecated('Use competition.isOrganizedBy(userId) instead')
  bool isOrganizer(Competition competition, String userId) =>
      competition.isOrganizedBy(userId);

  /// @deprecated Use `competition.canBeManagedBy(userId)` instead
  @Deprecated('Use competition.canBeManagedBy(userId) instead')
  bool canManage(Competition competition, String userId) =>
      competition.canBeManagedBy(userId);
}
