/// Competitions Cubit - State management for competitions.
/// Following Monolith-by-Features architecture (ADR-005).

import 'dart:io' show File;

import 'package:flutter/foundation.dart' show kIsWeb, Uint8List;
import 'package:street_core/core/di/injection.dart';
import 'package:street_core/core/helpers/logger.dart';
import 'package:street_core/core/media/services/media_upload_service.dart';

import './competitions_state.dart';
import '../models/competition.dart';
import '../models/judge_check_in.dart';
import '../services/competitions_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Cubit for managing competitions state
class CompetitionsCubit extends Cubit<CompetitionsState> {
  CompetitionsCubit(this._service) : super(const CompetitionsInitial());

  final CompetitionsService _service;

  // Current pagination state
  int _currentPage = 1;
  final int _limit = 20;
  bool _hasMore = true;
  List<Competition> _items = [];

  // ===========================================================================
  // LIST OPERATIONS
  // ===========================================================================

  /// Fetch all competitions (first page)
  Future<void> fetchCompetitions({Map<String, dynamic>? filters}) async {
    emit(const CompetitionsLoading());
    _currentPage = 1;
    _items = [];

    try {
      final result = await _service.fetchCompetitions(
        page: _currentPage,
        limit: _limit,
        filters: filters,
      );

      _items = result.items;
      _hasMore = _currentPage < result.totalPages;

      emit(
        CompetitionsLoaded(
          competitions: _items,
          hasMore: _hasMore,
          currentPage: _currentPage,
        ),
      );
    } catch (e, stackTrace) {
      AppLogger.error(
        'Failed to fetch competitions (page: $_currentPage, limit: $_limit, filters: $filters)',
        tag: 'CompetitionsCubit',
        error: e,
        stackTrace: stackTrace,
      );
      emit(CompetitionsError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  /// Load more competitions (next page)
  Future<void> loadMore({Map<String, dynamic>? filters}) async {
    if (!_hasMore || state is CompetitionsLoadingMore) return;

    emit(
      CompetitionsLoadingMore(competitions: _items, currentPage: _currentPage),
    );

    try {
      _currentPage++;
      final result = await _service.fetchCompetitions(
        page: _currentPage,
        limit: _limit,
        filters: filters,
      );

      _items = [..._items, ...result.items];
      _hasMore = _currentPage < result.totalPages;

      emit(
        CompetitionsLoaded(
          competitions: _items,
          hasMore: _hasMore,
          currentPage: _currentPage,
        ),
      );
    } catch (e, stackTrace) {
      _currentPage--;
      AppLogger.error(
        'Failed to load more competitions (page: $_currentPage, limit: $_limit, filters: $filters)',
        tag: 'CompetitionsCubit',
        error: e,
        stackTrace: stackTrace,
      );
      emit(CompetitionsError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  /// Fetch upcoming competitions
  Future<void> fetchUpcoming() async {
    emit(const CompetitionsLoading());
    _currentPage = 1;
    _items = [];

    try {
      final result = await _service.fetchUpcomingCompetitions(
        page: _currentPage,
        limit: _limit,
      );

      _items = result.items;
      _hasMore = _currentPage < result.totalPages;

      emit(
        CompetitionsLoaded(
          competitions: _items,
          hasMore: _hasMore,
          currentPage: _currentPage,
        ),
      );
    } catch (e, stackTrace) {
      AppLogger.error(
        'Failed to fetch upcoming competitions (page: $_currentPage, limit: $_limit)',
        tag: 'CompetitionsCubit',
        error: e,
        stackTrace: stackTrace,
      );
      emit(CompetitionsError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  /// Fetch live competitions
  Future<void> fetchLive() async {
    emit(const CompetitionsLoading());
    _currentPage = 1;
    _items = [];

    try {
      final result = await _service.fetchLiveCompetitions(
        page: _currentPage,
        limit: _limit,
      );

      _items = result.items;
      _hasMore = _currentPage < result.totalPages;

      emit(
        CompetitionsLoaded(
          competitions: _items,
          hasMore: _hasMore,
          currentPage: _currentPage,
        ),
      );
    } catch (e, stackTrace) {
      AppLogger.error(
        'Failed to fetch live competitions (page: $_currentPage, limit: $_limit)',
        tag: 'CompetitionsCubit',
        error: e,
        stackTrace: stackTrace,
      );
      emit(CompetitionsError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  /// Fetch my competitions
  Future<void> fetchMyCompetitions({Map<String, dynamic>? filters}) async {
    emit(const CompetitionsLoading());
    _currentPage = 1;
    _items = [];

    try {
      final result = await _service.fetchMyCompetitions(
        page: _currentPage,
        limit: _limit,
        filters: filters,
      );

      _items = result.items;
      _hasMore = _currentPage < result.totalPages;

      emit(
        CompetitionsLoaded(
          competitions: _items,
          hasMore: _hasMore,
          currentPage: _currentPage,
        ),
      );
    } catch (e, stackTrace) {
      AppLogger.error(
        'Failed to fetch my competitions (page: $_currentPage, limit: $_limit, filters: $filters)',
        tag: 'CompetitionsCubit',
        error: e,
        stackTrace: stackTrace,
      );
      emit(CompetitionsError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  // ===========================================================================
  // SINGLE ITEM OPERATIONS
  // ===========================================================================

  /// Fetch a single competition by ID
  Future<void> fetchById(String id) async {
    emit(const CompetitionsLoading());

    try {
      final competition = await _service.fetchCompetitionById(id);
      emit(CompetitionDetailLoaded(competition));
    } catch (e, stackTrace) {
      AppLogger.error(
        'Failed to fetch competition by ID (competitionId: $id)',
        tag: 'CompetitionsCubit',
        error: e,
        stackTrace: stackTrace,
      );
      emit(CompetitionsError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  /// Create a new competition
  /// Automatically uploads images before sending data to API
  Future<void> create(Map<String, dynamic> data) async {
    AppLogger.info('Creating competition');

    // Validate dates before proceeding
    final dateError = _validateDates(data);
    if (dateError != null) {
      emit(CompetitionsError(dateError));
      return;
    }

    emit(const CompetitionsLoading());

    try {
      // Process image fields before submission
      final result = await _processImageFields(Map<String, dynamic>.from(data));

      // Log warning if some uploads failed
      if (result.failedUploads.isNotEmpty) {
        AppLogger.warning(
          'Some images failed to upload: ${result.failedUploads.join(", ")}',
          tag: 'CompetitionsCubit',
        );
      }

      // Transform flat form data to backend structure
      final transformedData = _transformFormDataToBackend(result.data);

      final competition = await _service.createCompetition(transformedData);

      // Add to cached list if we have items
      final bool wasInList = _items.isNotEmpty;
      if (wasInList) {
        _items.insert(0, competition); // Add at the beginning
        AppLogger.info(
          'Added new competition to cached list',
          tag: 'CompetitionsCubit',
        );
      }

      // Emit success with optional warning about failed uploads
      if (result.failedUploads.isNotEmpty) {
        emit(
          CompetitionCreatedWithWarning(
            competition,
            'image_upload_partial_failure',
          ),
        );
      } else {
        emit(CompetitionCreated(competition));
      }

      // Re-emit the list state if we had items cached
      // This ensures the UI updates with the new data
      if (wasInList) {
        emit(
          CompetitionsLoaded(
            competitions: _items,
            hasMore: _hasMore,
            currentPage: _currentPage,
          ),
        );
      }
    } catch (e, stackTrace) {
      AppLogger.error(
        'Failed to create competition (title: ${data['title']}, competitionType: ${data['competitionType']}, hasImages: ${data.containsKey('bannerUrl') || data.containsKey('posterUrl')})',
        tag: 'CompetitionsCubit',
        error: e,
        stackTrace: stackTrace,
      );
      emit(CompetitionsError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  /// Validates date fields
  String? _validateDates(Map<String, dynamic> data) {
    final startDateStr = data['startDate']?.toString();
    final endDateStr = data['endDate']?.toString();

    if (startDateStr == null || endDateStr == null) {
      return null; // Let backend handle required validation
    }

    try {
      final startDate = DateTime.parse(startDateStr);
      final endDate = DateTime.parse(endDateStr);

      if (endDate.isBefore(startDate)) {
        return 'end_date_must_be_after_start_date';
      }

      if (endDate.isAtSameMomentAs(startDate)) {
        return 'end_date_must_be_after_start_date';
      }

      // Validate registration deadline if present
      final deadlineStr = data['registrationDeadline']?.toString();
      if (deadlineStr != null && deadlineStr.isNotEmpty) {
        final deadline = DateTime.parse(deadlineStr);
        if (deadline.isAfter(startDate)) {
          return 'registration_deadline_must_be_before_start';
        }
      }
    } catch (e) {
      AppLogger.warning('Date parsing error: $e');
      // Let backend handle format validation
    }

    return null;
  }

  /// Transform flat form data to the nested structure expected by the backend
  Map<String, dynamic> _transformFormDataToBackend(Map<String, dynamic> data) {
    // Parse numeric values safely
    int maxParticipants = _parseIntSafe(data['maxParticipants'], 50);
    int minParticipants = _parseIntSafe(data['minParticipants'], 1);
    int maxScore = _parseIntSafe(data['maxScore'], 100);
    int totalRounds = _parseIntSafe(data['totalRounds'], 1);

    // Ensure min <= max for participants
    if (minParticipants > maxParticipants) {
      minParticipants = 1;
    }

    return {
      'title': data['title'],
      'description': data['description'],
      'competitionType': data['competitionType'] ?? 'individual',
      'format': data['format'],
      'discipline': data['discipline'] ?? 'general',
      if (data['category'] != null && data['category'].toString().isNotEmpty)
        'category': data['category'],
      'schedule': {
        'startDate': data['startDate'],
        'endDate': data['endDate'],
        'venue': data['venue'],
        'city': data['city'],
        'country': data['country'],
      },
      'registration': {
        'maxParticipants': maxParticipants,
        'minParticipants': minParticipants,
        'registrationDeadline': data['registrationDeadline'],
        'requiresApproval': data['requiresApproval'] ?? false,
        'entryFee': data['entryFee'] != null && data['entryFee'] != 0
            ? _parseDoubleSafe(data['entryFee'], 0)
            : null,
        'currency': data['currency'] ?? 'EUR',
      },
      'scoringCriteria': {
        'type': data['scoringType'] ?? 'points',
        'minScore': 0,
        'maxScore': maxScore.toDouble(),
      },
      'totalRounds': totalRounds,
      'rules': data['rules'],
      // Media URLs
      if (data['bannerUrl'] != null) 'bannerUrl': data['bannerUrl'],
      if (data['imageUrls'] != null) 'imageUrls': data['imageUrls'],
      if (data['posterUrl'] != null) 'posterUrl': data['posterUrl'],
      if (data['logoUrl'] != null) 'logoUrl': data['logoUrl'],
      // Tags
      if (data['discipline'] != null) 'tags': [data['discipline']],
    };
  }

  /// Safely parse int from dynamic value
  int _parseIntSafe(dynamic value, int defaultValue) {
    if (value == null) return defaultValue;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? defaultValue;
    return defaultValue;
  }

  /// Safely parse double from dynamic value
  double _parseDoubleSafe(dynamic value, double defaultValue) {
    if (value == null) return defaultValue;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? defaultValue;
    return defaultValue;
  }

  /// Detect image extension from magic bytes
  String _detectImageExtension(Uint8List bytes) {
    if (bytes.length < 4) return 'png';

    // JPEG: FF D8 FF
    if (bytes[0] == 0xFF && bytes[1] == 0xD8 && bytes[2] == 0xFF) {
      return 'jpg';
    }
    // PNG: 89 50 4E 47
    if (bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4E &&
        bytes[3] == 0x47) {
      return 'png';
    }
    // GIF: 47 49 46
    if (bytes[0] == 0x47 && bytes[1] == 0x49 && bytes[2] == 0x46) {
      return 'gif';
    }
    // WebP: 52 49 46 46 (RIFF)
    if (bytes[0] == 0x52 &&
        bytes[1] == 0x49 &&
        bytes[2] == 0x46 &&
        bytes[3] == 0x46) {
      return 'webp';
    }
    // BMP: 42 4D
    if (bytes[0] == 0x42 && bytes[1] == 0x4D) {
      return 'bmp';
    }

    // Default to jpg (most common)
    return 'jpg';
  }

  /// Process image fields - upload local files and replace with URLs
  /// Returns the processed data and a list of failed upload field names
  Future<({Map<String, dynamic> data, List<String> failedUploads})>
  _processImageFields(Map<String, dynamic> data) async {
    final mediaService = getIt<MediaUploadService>();
    final imageFields = ['bannerUrl', 'posterUrl', 'logoUrl', 'imageUrl'];
    final List<String> failedUploads = [];

    for (final field in imageFields) {
      final value = data[field];
      final bytesKey = '${field}_bytes';

      // Skip if no value or already a URL
      if (value == null || value.toString().isEmpty) continue;
      if (value.toString().startsWith('http')) continue;

      try {
        String? uploadedUrl;

        // Handle web upload (bytes)
        if (kIsWeb && data.containsKey(bytesKey) && data[bytesKey] != null) {
          final bytes = data[bytesKey] as Uint8List;
          // Detect image extension from bytes or use original filename
          final nameKey = '${field}_name';
          String filename;
          if (data.containsKey(nameKey) && data[nameKey] != null) {
            filename = data[nameKey] as String;
            data.remove(nameKey);
          } else {
            final extension = _detectImageExtension(bytes);
            filename = '$field.$extension';
          }
          AppLogger.info(
            'Uploading $field from web bytes as $filename',
            tag: 'CompetitionsCubit',
          );
          final response = await mediaService.uploadImageWeb(bytes, filename);
          uploadedUrl = response.url;
          data.remove(bytesKey); // Clean up bytes from data
        }
        // Handle mobile upload (file path)
        else if (!kIsWeb && value is String && !value.startsWith('http')) {
          final file = File(value);
          if (await file.exists()) {
            AppLogger.info(
              'Uploading $field from file: $value',
              tag: 'CompetitionsCubit',
            );
            final response = await mediaService.uploadImage(file);
            uploadedUrl = response.url;
          }
        }

        // Replace local path/indicator with uploaded URL
        if (uploadedUrl != null && uploadedUrl.isNotEmpty) {
          data[field] = uploadedUrl;
          AppLogger.info(
            '$field uploaded: $uploadedUrl',
            tag: 'CompetitionsCubit',
          );
        } else {
          // Remove field if upload failed or no valid data
          data.remove(field);
          failedUploads.add(field);
          AppLogger.warning(
            '$field upload returned empty URL',
            tag: 'CompetitionsCubit',
          );
        }
      } catch (e) {
        AppLogger.error(
          'Failed to upload $field: $e',
          tag: 'CompetitionsCubit',
        );
        // Remove the field so it doesn't send invalid data
        data.remove(field);
        data.remove(bytesKey);
        failedUploads.add(field);
      }
    }

    return (data: data, failedUploads: failedUploads);
  }

  /// Update an existing competition
  /// Automatically uploads new images before sending data to API
  Future<void> update(String id, Map<String, dynamic> data) async {
    // Validate dates before proceeding
    final dateError = _validateDates(data);
    if (dateError != null) {
      emit(CompetitionsError(dateError));
      return;
    }

    emit(const CompetitionsLoading());

    try {
      // Process image fields before submission
      final result = await _processImageFields(Map<String, dynamic>.from(data));

      // Log warning if some uploads failed
      if (result.failedUploads.isNotEmpty) {
        AppLogger.warning(
          'Some images failed to upload: ${result.failedUploads.join(", ")}',
          tag: 'CompetitionsCubit',
        );
      }

      final competition = await _service.updateCompetition(id, result.data);

      // Add cache-busting parameter to image URLs to force reload
      final updatedCompetition = _addCacheBustingToImages(competition);

      // Update the item in the cached list if it exists
      final bool wasInList = _items.isNotEmpty;
      if (wasInList) {
        final index = _items.indexWhere((c) => c.id == id);
        if (index != -1) {
          _items[index] = updatedCompetition;
          AppLogger.info(
            'Updated competition in cached list with cache-busting',
            tag: 'CompetitionsCubit',
          );
        }
      }

      // Emit success with optional warning about failed uploads
      if (result.failedUploads.isNotEmpty) {
        emit(
          CompetitionUpdatedWithWarning(
            updatedCompetition,
            'image_upload_partial_failure',
          ),
        );
      } else {
        emit(CompetitionUpdated(updatedCompetition));
      }

      // Re-emit the list state if we had items cached
      // This ensures the UI updates with the new data
      if (wasInList) {
        emit(
          CompetitionsLoaded(
            competitions: _items,
            hasMore: _hasMore,
            currentPage: _currentPage,
          ),
        );
      }
    } catch (e, stackTrace) {
      AppLogger.error(
        'Failed to update competition (competitionId: $id, dataKeys: ${data.keys.toList()})',
        tag: 'CompetitionsCubit',
        error: e,
        stackTrace: stackTrace,
      );
      emit(CompetitionsError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  /// Delete a competition
  Future<void> delete(String id) async {
    emit(const CompetitionsLoading());

    try {
      await _service.deleteCompetition(id);
      emit(const CompetitionDeleted());
      // Refresh list
      await fetchCompetitions();
    } catch (e, stackTrace) {
      AppLogger.error(
        'Failed to delete competition (competitionId: $id)',
        tag: 'CompetitionsCubit',
        error: e,
        stackTrace: stackTrace,
      );
      emit(CompetitionsError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  // ===========================================================================
  // REGISTRATION OPERATIONS
  // ===========================================================================

  /// Register for a competition
  Future<void> register(String competitionId, {String? riderId}) async {
    emit(const CompetitionsLoading());

    try {
      await _service.registerForCompetition(competitionId, riderId: riderId);
      emit(const CompetitionRegistrationSuccess());
      // Refresh competition details
      await fetchById(competitionId);
    } catch (e, stackTrace) {
      AppLogger.error(
        'Failed to register for competition (competitionId: $competitionId, riderId: $riderId)',
        tag: 'CompetitionsCubit',
        error: e,
        stackTrace: stackTrace,
      );
      emit(CompetitionsError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  /// Unregister from a competition
  Future<void> unregister(String competitionId, {String? riderId}) async {
    emit(const CompetitionsLoading());

    try {
      await _service.unregisterFromCompetition(competitionId, riderId: riderId);
      emit(const CompetitionUnregistrationSuccess());
      // Refresh competition details
      await fetchById(competitionId);
    } catch (e, stackTrace) {
      AppLogger.error(
        'Failed to unregister from competition (competitionId: $competitionId, riderId: $riderId)',
        tag: 'CompetitionsCubit',
        error: e,
        stackTrace: stackTrace,
      );
      emit(CompetitionsError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  // ===========================================================================
  // SCORING OPERATIONS
  // ===========================================================================

  /// Submit scores
  Future<void> submitScores(
    String competitionId,
    Map<String, dynamic> scoreData,
  ) async {
    emit(const CompetitionsLoading());

    try {
      await _service.submitScores(competitionId, scoreData);
      emit(const CompetitionScoresSubmitted());
      // Refresh competition details
      await fetchById(competitionId);
    } catch (e, stackTrace) {
      AppLogger.error(
        'Failed to submit scores (competitionId: $competitionId, scoreDataKeys: ${scoreData.keys.toList()})',
        tag: 'CompetitionsCubit',
        error: e,
        stackTrace: stackTrace,
      );
      emit(CompetitionsError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  /// Enter judging mode
  void enterJudgingMode(Competition competition, {String? roundId}) {
    emit(CompetitionJudgingMode(competition, currentRoundId: roundId));
  }

  /// Exit judging mode
  void exitJudgingMode() {
    emit(const CompetitionsInitial());
  }

  // ===========================================================================
  // LEADERBOARD OPERATIONS
  // ===========================================================================

  /// Get leaderboard
  Future<void> getLeaderboard(String competitionId) async {
    try {
      final leaderboard = await _service.getLeaderboard(competitionId);
      if (leaderboard != null) {
        emit(CompetitionLeaderboardLoaded(leaderboard));
      }
    } catch (e, stackTrace) {
      AppLogger.error(
        'Failed to get leaderboard (competitionId: $competitionId)',
        tag: 'CompetitionsCubit',
        error: e,
        stackTrace: stackTrace,
      );
      emit(CompetitionsError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  /// Update leaderboard
  Future<void> updateLeaderboard(String competitionId) async {
    emit(const CompetitionsLoading());

    try {
      final leaderboard = await _service.updateLeaderboard(competitionId);
      emit(CompetitionLeaderboardLoaded(leaderboard));
    } catch (e, stackTrace) {
      AppLogger.error(
        'Failed to update leaderboard (competitionId: $competitionId)',
        tag: 'CompetitionsCubit',
        error: e,
        stackTrace: stackTrace,
      );
      emit(CompetitionsError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  // ===========================================================================
  // STATUS OPERATIONS
  // ===========================================================================

  /// Validate if a competition can be started
  Future<StartValidationResult> validateStartRequirements(String competitionId) async {
    try {
      return await _service.validateStartRequirements(competitionId);
    } catch (e, stackTrace) {
      AppLogger.error(
        'Failed to validate start requirements (competitionId: $competitionId)',
        tag: 'CompetitionsCubit',
        error: e,
        stackTrace: stackTrace,
      );
      // Return a failed validation result
      return StartValidationResult(
        canStart: false,
        errors: [e.toString().replaceAll('Exception: ', '')],
        warnings: [],
        hasCategories: false,
        categoriesCount: 0,
        categoriesWithCriteria: 0,
        minParticipants: 0,
        currentParticipants: 0,
        requiredJudges: 0,
        currentJudges: 0,
        status: 'error',
      );
    }
  }

  /// Start a competition
  Future<void> startCompetition(String competitionId) async {
    emit(const CompetitionsLoading());

    try {
      await _service.startCompetition(competitionId);
      emit(const CompetitionStatusChanged('live'));
      await fetchById(competitionId);
    } catch (e, stackTrace) {
      AppLogger.error(
        'Failed to start competition (competitionId: $competitionId)',
        tag: 'CompetitionsCubit',
        error: e,
        stackTrace: stackTrace,
      );
      emit(CompetitionsError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  /// End a competition
  Future<void> endCompetition(String competitionId) async {
    emit(const CompetitionsLoading());

    try {
      await _service.endCompetition(competitionId);
      emit(const CompetitionStatusChanged('completed'));
      await fetchById(competitionId);
    } catch (e, stackTrace) {
      AppLogger.error(
        'Failed to end competition (competitionId: $competitionId)',
        tag: 'CompetitionsCubit',
        error: e,
        stackTrace: stackTrace,
      );
      emit(CompetitionsError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  /// Publish results
  Future<void> publishResults(String competitionId) async {
    emit(const CompetitionsLoading());

    try {
      await _service.publishResults(competitionId);
      emit(const CompetitionResultsPublished());
      await fetchById(competitionId);
    } catch (e, stackTrace) {
      AppLogger.error(
        'Failed to publish results (competitionId: $competitionId)',
        tag: 'CompetitionsCubit',
        error: e,
        stackTrace: stackTrace,
      );
      emit(CompetitionsError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  /// Postpone a competition
  Future<void> postponeCompetition(String competitionId) async {
    emit(const CompetitionsLoading());

    try {
      await _service.postponeCompetition(competitionId);
      emit(const CompetitionStatusChanged('postponed'));
      await fetchById(competitionId);
    } catch (e, stackTrace) {
      AppLogger.error(
        'Failed to postpone competition (competitionId: $competitionId)',
        tag: 'CompetitionsCubit',
        error: e,
        stackTrace: stackTrace,
      );
      emit(CompetitionsError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  // ===========================================================================
  // UTILITY
  // ===========================================================================

  /// Add cache-busting query parameter to image URLs
  /// This forces the image cache to reload when the image is updated
  Competition _addCacheBustingToImages(Competition competition) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;

    String? addCacheBusting(String? url) {
      if (url == null || url.isEmpty) return url;
      if (!url.startsWith('http')) return url;

      final uri = Uri.parse(url);
      final newParams = Map<String, dynamic>.from(uri.queryParameters);
      newParams['t'] = timestamp.toString();

      return uri.replace(queryParameters: newParams).toString();
    }

    return Competition(
      id: competition.id,
      eventId: competition.eventId,
      title: competition.title,
      description: competition.description,
      organizerId: competition.organizerId,
      organizerName: competition.organizerName,
      clubId: competition.clubId,
      clubName: competition.clubName,
      competitionType: competition.competitionType,
      format: competition.format,
      category: competition.category,
      discipline: competition.discipline,
      startDate: competition.startDate,
      endDate: competition.endDate,
      venue: competition.venue,
      city: competition.city,
      country: competition.country,
      latitude: competition.latitude,
      longitude: competition.longitude,
      maxParticipants: competition.maxParticipants,
      minParticipants: competition.minParticipants,
      currentParticipants: competition.currentParticipants,
      registrationDeadline: competition.registrationDeadline,
      requiresApproval: competition.requiresApproval,
      entryFee: competition.entryFee,
      currency: competition.currency,
      registeredAthleteIds: competition.registeredAthleteIds,
      waitlistAthleteIds: competition.waitlistAthleteIds,
      participantStatus: competition.participantStatus,
      judgeIds: competition.judgeIds,
      requiredJudges: competition.requiredJudges,
      scoringCriteria: competition.scoringCriteria,
      dropHighestScore: competition.dropHighestScore,
      dropLowestScore: competition.dropLowestScore,
      totalRounds: competition.totalRounds,
      currentRound: competition.currentRound,
      rounds: competition.rounds,
      hasQualifying: competition.hasQualifying,
      hasSemiFinals: competition.hasSemiFinals,
      hasFinals: competition.hasFinals,
      status: competition.status,
      isLive: competition.isLive,
      allowLiveScoring: competition.allowLiveScoring,
      showLiveResults: competition.showLiveResults,
      liveStreamUrl: competition.liveStreamUrl,
      leaderboard: competition.leaderboard,
      podium: competition.podium,
      isResultsPublished: competition.isResultsPublished,
      resultsPublishedAt: competition.resultsPublishedAt,
      prizePool: competition.prizePool,
      sponsors: competition.sponsors,
      hasPointsForRanking: competition.hasPointsForRanking,
      rules: competition.rules,
      requirements: competition.requirements,
      requiredDocuments: competition.requiredDocuments,
      equipmentRules: competition.equipmentRules,
      // Add cache-busting to all image URLs
      bannerUrl: addCacheBusting(competition.bannerUrl),
      imageUrls: competition.imageUrls
          ?.map((url) => addCacheBusting(url) ?? url)
          .toList(),
      videoUrl: competition.videoUrl,
      highlightUrls: competition.highlightUrls,
      customFields: competition.customFields,
      tags: competition.tags,
      notes: competition.notes,
      createdAt: competition.createdAt,
      updatedAt: competition.updatedAt,
    );
  }

  /// Reset to initial state
  void reset() {
    _currentPage = 1;
    _items = [];
    _hasMore = true;
    emit(const CompetitionsInitial());
  }
}
