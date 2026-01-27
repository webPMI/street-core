import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:street_core/core/services/api_response.dart';
import 'package:street_core/core/services/api_service.dart';
import 'package:street_core/features/competitions/services/competitions_service.dart';

// Mocks
class MockApiService extends Mock implements ApiService {}

void main() {
  late CompetitionsService service;
  late MockApiService mockApiService;

  setUp(() {
    mockApiService = MockApiService();
    service = CompetitionsService(mockApiService);
  });

  // Helper to create test competition JSON
  Map<String, dynamic> createCompetitionJson({
    String id = 'comp-1',
    String title = 'Test Competition',
  }) {
    return {
      'id': id,
      'eventId': 'event-1',
      'title': title,
      'description': 'Test description',
      'organizerId': 'org-1',
      'organizerName': 'Test Organizer',
      'startDate': '2026-06-01T10:00:00Z',
      'endDate': '2026-06-02T18:00:00Z',
      'scoringCriteria': {'type': 'points', 'minScore': 0, 'maxScore': 100},
      'createdAt': '2026-01-01T00:00:00Z',
      'updatedAt': '2026-01-01T00:00:00Z',
    };
  }

  group('CompetitionsService', () {
    group('fetchCompetitions', () {
      test('returns paginated result on success', () async {
        final mockResponse = ApiResponse<Map<String, dynamic>>(
          status: 'success',
          data: {
            'competitions': [
              createCompetitionJson(id: '1', title: 'Competition 1'),
              createCompetitionJson(id: '2', title: 'Competition 2'),
            ],
            'total': 2,
            'page': 1,
            'totalPages': 1,
            'limit': 20,
          },
        );

        when(
          () => mockApiService.useFetch<Map<String, dynamic>>(
            any(),
            method: any(named: 'method'),
            fromJsonT: any(named: 'fromJsonT'),
          ),
        ).thenAnswer((_) async => mockResponse);

        final result = await service.fetchCompetitions(page: 1, limit: 20);

        expect(result.items.length, 2);
        expect(result.items.first.title, 'Competition 1');
        expect(result.totalItems, 2);
        expect(result.currentPage, 1);
        expect(result.totalPages, 1);
      });

      test('passes filters to API correctly', () async {
        final mockResponse = ApiResponse<Map<String, dynamic>>(
          status: 'success',
          data: {
            'competitions': [],
            'total': 0,
            'page': 1,
            'totalPages': 1,
            'limit': 20,
          },
        );

        when(
          () => mockApiService.useFetch<Map<String, dynamic>>(
            any(),
            method: any(named: 'method'),
            fromJsonT: any(named: 'fromJsonT'),
          ),
        ).thenAnswer((_) async => mockResponse);

        await service.fetchCompetitions(
          page: 2,
          limit: 10,
          filters: {'status': 'live', 'discipline': 'street'},
        );

        final captured = verify(
          () => mockApiService.useFetch<Map<String, dynamic>>(
            captureAny(),
            method: 'GET',
            fromJsonT: any(named: 'fromJsonT'),
          ),
        ).captured;

        final url = captured.first as String;
        expect(url, contains('page=2'));
        expect(url, contains('limit=10'));
        expect(url, contains('status=live'));
        expect(url, contains('discipline=street'));
      });

      test('handles 404 gracefully', () async {
        final mockResponse = ApiResponse<Map<String, dynamic>>(
          status: 'error',
          message: 'Not found',
          statusCode: 404,
        );

        when(
          () => mockApiService.useFetch<Map<String, dynamic>>(
            any(),
            method: any(named: 'method'),
            fromJsonT: any(named: 'fromJsonT'),
          ),
        ).thenAnswer((_) async => mockResponse);

        expect(
          () => service.fetchCompetitions(),
          throwsA(
            isA<Exception>().having(
              (e) => e.toString(),
              'message',
              contains('Not found'),
            ),
          ),
        );
      });

      test('handles empty result', () async {
        final mockResponse = ApiResponse<Map<String, dynamic>>(
          status: 'success',
          data: {
            'competitions': [],
            'total': 0,
            'page': 1,
            'totalPages': 1,
            'limit': 20,
          },
        );

        when(
          () => mockApiService.useFetch<Map<String, dynamic>>(
            any(),
            method: any(named: 'method'),
            fromJsonT: any(named: 'fromJsonT'),
          ),
        ).thenAnswer((_) async => mockResponse);

        final result = await service.fetchCompetitions();

        expect(result.items, isEmpty);
        expect(result.totalItems, 0);
      });
    });

    group('fetchCompetitionById', () {
      test('returns competition on success', () async {
        final mockResponse = ApiResponse<Map<String, dynamic>>(
          status: 'success',
          data: createCompetitionJson(
            id: 'detail-1',
            title: 'Detail Competition',
          ),
        );

        when(
          () => mockApiService.useFetch<Map<String, dynamic>>(
            any(),
            method: any(named: 'method'),
            fromJsonT: any(named: 'fromJsonT'),
          ),
        ).thenAnswer((_) async => mockResponse);

        final result = await service.fetchCompetitionById('detail-1');

        expect(result.id, 'detail-1');
        expect(result.title, 'Detail Competition');
      });

      test('throws exception on error', () async {
        final mockResponse = ApiResponse<Map<String, dynamic>>(
          status: 'error',
          message: 'competition_not_found',
          statusCode: 404,
        );

        when(
          () => mockApiService.useFetch<Map<String, dynamic>>(
            any(),
            method: any(named: 'method'),
            fromJsonT: any(named: 'fromJsonT'),
          ),
        ).thenAnswer((_) async => mockResponse);

        expect(
          () => service.fetchCompetitionById('not-found'),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('createCompetition', () {
      test('calls API with correct data', () async {
        final inputData = {
          'title': 'New Competition',
          'description': 'Test',
          'competitionType': 'individual',
        };

        final mockResponse = ApiResponse<Map<String, dynamic>>(
          status: 'success',
          data: createCompetitionJson(title: 'New Competition'),
        );

        when(
          () => mockApiService.useFetch<Map<String, dynamic>>(
            any(),
            method: any(named: 'method'),
            body: any(named: 'body'),
            fromJsonT: any(named: 'fromJsonT'),
          ),
        ).thenAnswer((_) async => mockResponse);

        final result = await service.createCompetition(inputData);

        expect(result.title, 'New Competition');

        final captured = verify(
          () => mockApiService.useFetch<Map<String, dynamic>>(
            any(),
            method: 'POST',
            body: captureAny(named: 'body'),
            fromJsonT: any(named: 'fromJsonT'),
          ),
        ).captured;

        expect(captured.first, equals(inputData));
      });

      test('throws on error response', () async {
        final mockResponse = ApiResponse<Map<String, dynamic>>(
          status: 'error',
          message: 'error_creating_competition',
        );

        when(
          () => mockApiService.useFetch<Map<String, dynamic>>(
            any(),
            method: any(named: 'method'),
            body: any(named: 'body'),
            fromJsonT: any(named: 'fromJsonT'),
          ),
        ).thenAnswer((_) async => mockResponse);

        expect(
          () => service.createCompetition({'title': 'Test'}),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('updateCompetition', () {
      test('sends PUT request with correct data', () async {
        final updateData = {'title': 'Updated Title'};

        final mockResponse = ApiResponse<Map<String, dynamic>>(
          status: 'success',
          data: createCompetitionJson(title: 'Updated Title'),
        );

        when(
          () => mockApiService.useFetch<Map<String, dynamic>>(
            any(),
            method: any(named: 'method'),
            body: any(named: 'body'),
            fromJsonT: any(named: 'fromJsonT'),
          ),
        ).thenAnswer((_) async => mockResponse);

        final result = await service.updateCompetition('comp-1', updateData);

        expect(result.title, 'Updated Title');

        verify(
          () => mockApiService.useFetch<Map<String, dynamic>>(
            any(),
            method: 'PUT',
            body: updateData,
            fromJsonT: any(named: 'fromJsonT'),
          ),
        ).called(1);
      });
    });

    group('deleteCompetition', () {
      test('calls DELETE endpoint', () async {
        final mockResponse = ApiResponse<void>(status: 'success');

        when(
          () => mockApiService.useFetch<void>(
            any(),
            method: any(named: 'method'),
          ),
        ).thenAnswer((_) async => mockResponse);

        await service.deleteCompetition('comp-1');

        verify(
          () => mockApiService.useFetch<void>(any(), method: 'DELETE'),
        ).called(1);
      });

      test('throws on error', () async {
        final mockResponse = ApiResponse<void>(
          status: 'error',
          message: 'Competition not found',
        );

        when(
          () => mockApiService.useFetch<void>(
            any(),
            method: any(named: 'method'),
          ),
        ).thenAnswer((_) async => mockResponse);

        expect(
          () => service.deleteCompetition('not-found'),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('submitScores', () {
      test('sends correct payload', () async {
        final scoreData = {
          'participantId': 'athlete-1',
          'criteriaScores': {'technical': 8.5, 'style': 9.0},
        };

        final mockResponse = ApiResponse<void>(status: 'success');

        when(
          () => mockApiService.useFetch<void>(
            any(),
            method: any(named: 'method'),
            body: any(named: 'body'),
          ),
        ).thenAnswer((_) async => mockResponse);

        await service.submitScores('comp-1', scoreData);

        final captured = verify(
          () => mockApiService.useFetch<void>(
            any(),
            method: 'POST',
            body: captureAny(named: 'body'),
          ),
        ).captured;

        expect(captured.first, equals(scoreData));
      });

      test('throws on error', () async {
        final mockResponse = ApiResponse<void>(
          status: 'error',
          message: 'Invalid score data',
        );

        when(
          () => mockApiService.useFetch<void>(
            any(),
            method: any(named: 'method'),
            body: any(named: 'body'),
          ),
        ).thenAnswer((_) async => mockResponse);

        expect(
          () => service.submitScores('comp-1', {}),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('getCategories', () {
      test('returns list of categories', () async {
        final mockResponse = ApiResponse<List<dynamic>>(
          status: 'success',
          data: [
            {
              'id': 'cat-1',
              'competitionId': 'comp-1',
              'name': 'Pro Men',
              'skillLevel': 'professional',
              'createdAt': '2026-01-01T00:00:00Z',
              'updatedAt': '2026-01-01T00:00:00Z',
            },
            {
              'id': 'cat-2',
              'competitionId': 'comp-1',
              'name': 'Pro Women',
              'skillLevel': 'professional',
              'createdAt': '2026-01-01T00:00:00Z',
              'updatedAt': '2026-01-01T00:00:00Z',
            },
          ],
        );

        when(
          () => mockApiService.useFetch<List<dynamic>>(
            any(),
            method: any(named: 'method'),
            requiredToken: any(named: 'requiredToken'),
            fromJsonT: any(named: 'fromJsonT'),
          ),
        ).thenAnswer((_) async => mockResponse);

        final result = await service.getCategories('comp-1');

        expect(result.length, 2);
        expect(result.first.name, 'Pro Men');
        expect(result.last.name, 'Pro Women');
      });

      test('works without authentication', () async {
        final mockResponse = ApiResponse<List<dynamic>>(
          status: 'success',
          data: [],
        );

        when(
          () => mockApiService.useFetch<List<dynamic>>(
            any(),
            method: any(named: 'method'),
            requiredToken: any(named: 'requiredToken'),
            fromJsonT: any(named: 'fromJsonT'),
          ),
        ).thenAnswer((_) async => mockResponse);

        await service.getCategories('comp-1');

        verify(
          () => mockApiService.useFetch<List<dynamic>>(
            any(),
            method: 'GET',
            requiredToken: false, // Public endpoint
            fromJsonT: any(named: 'fromJsonT'),
          ),
        ).called(1);
      });
    });

    group('registerForCompetition', () {
      test('calls POST with empty body when no riderId', () async {
        final mockResponse = ApiResponse<void>(status: 'success');

        when(
          () => mockApiService.useFetch<void>(
            any(),
            method: any(named: 'method'),
            body: any(named: 'body'),
          ),
        ).thenAnswer((_) async => mockResponse);

        await service.registerForCompetition('comp-1');

        verify(
          () =>
              mockApiService.useFetch<void>(any(), method: 'POST', body: null),
        ).called(1);
      });

      test('includes riderId in body when provided', () async {
        final mockResponse = ApiResponse<void>(status: 'success');

        when(
          () => mockApiService.useFetch<void>(
            any(),
            method: any(named: 'method'),
            body: any(named: 'body'),
          ),
        ).thenAnswer((_) async => mockResponse);

        await service.registerForCompetition('comp-1', riderId: 'rider-1');

        final captured = verify(
          () => mockApiService.useFetch<void>(
            any(),
            method: 'POST',
            body: captureAny(named: 'body'),
          ),
        ).captured;

        expect(captured.first, {'riderId': 'rider-1'});
      });
    });

    group('startCompetition', () {
      test('calls POST to start endpoint', () async {
        final mockResponse = ApiResponse<void>(status: 'success');

        when(
          () => mockApiService.useFetch<void>(
            any(),
            method: any(named: 'method'),
          ),
        ).thenAnswer((_) async => mockResponse);

        await service.startCompetition('comp-1');

        verify(
          () => mockApiService.useFetch<void>(any(), method: 'POST'),
        ).called(1);
      });

      test('throws on error', () async {
        final mockResponse = ApiResponse<void>(
          status: 'error',
          message: 'Cannot start competition',
        );

        when(
          () => mockApiService.useFetch<void>(
            any(),
            method: any(named: 'method'),
          ),
        ).thenAnswer((_) async => mockResponse);

        expect(
          () => service.startCompetition('comp-1'),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('validateStartRequirements', () {
      test('returns validation result on success', () async {
        final mockResponse = ApiResponse<Map<String, dynamic>>(
          status: 'success',
          data: {
            'canStart': true,
            'errors': [],
            'warnings': [],
            'hasCategories': true,
            'categoriesCount': 2,
            'categoriesWithCriteria': 2,
            'minParticipants': 5,
            'currentParticipants': 10,
            'requiredJudges': 3,
            'currentJudges': 3,
            'status': 'ready',
          },
        );

        when(
          () => mockApiService.useFetch<Map<String, dynamic>>(
            any(),
            method: any(named: 'method'),
            fromJsonT: any(named: 'fromJsonT'),
          ),
        ).thenAnswer((_) async => mockResponse);

        final result = await service.validateStartRequirements('comp-1');

        expect(result.canStart, true);
        expect(result.errors, isEmpty);
        expect(result.categoriesCount, 2);
        expect(result.currentJudges, 3);
      });

      test('returns validation errors when cannot start', () async {
        final mockResponse = ApiResponse<Map<String, dynamic>>(
          status: 'success',
          data: {
            'canStart': false,
            'errors': ['Not enough judges', 'Missing scoring criteria'],
            'warnings': ['Low participant count'],
            'hasCategories': true,
            'categoriesCount': 1,
            'categoriesWithCriteria': 0,
            'minParticipants': 5,
            'currentParticipants': 3,
            'requiredJudges': 3,
            'currentJudges': 1,
            'status': 'not_ready',
          },
        );

        when(
          () => mockApiService.useFetch<Map<String, dynamic>>(
            any(),
            method: any(named: 'method'),
            fromJsonT: any(named: 'fromJsonT'),
          ),
        ).thenAnswer((_) async => mockResponse);

        final result = await service.validateStartRequirements('comp-1');

        expect(result.canStart, false);
        expect(result.errors.length, 2);
        expect(result.warnings.length, 1);
      });
    });
  });
}
