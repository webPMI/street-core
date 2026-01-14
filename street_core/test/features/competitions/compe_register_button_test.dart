import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';

import 'package:street_core/core/lang/bloc/locale_cubit.dart';
import 'package:street_core/core/lang/bloc/locale_state.dart';
import 'package:street_core/data/models/user_model.dart';
import 'package:street_core/features/auth/bloc/user_cubit.dart';
import 'package:street_core/features/auth/bloc/user_state.dart';
import 'package:street_core/features/competitions/bloc/competitions_cubit.dart';
import 'package:street_core/features/competitions/bloc/competitions_state.dart';
import 'package:street_core/features/competitions/models/competition.dart';
import 'package:street_core/features/competitions/pages/compe_register/compe_register_button.dart';
import 'package:street_core/features/competitions/services/participant_service.dart';

// Mocks
class MockUserCubit extends Mock implements UserCubit {}

class MockCompetitionsCubit extends Mock implements CompetitionsCubit {}

class MockParticipantService extends Mock implements ParticipantService {}

class MockLocaleBloc extends Mock implements LocaleBloc {}

class FakeCompetitionsState extends Fake implements CompetitionsState {}

void main() {
  late MockUserCubit mockUserCubit;
  late MockCompetitionsCubit mockCompetitionsCubit;
  late MockParticipantService mockParticipantService;
  late MockLocaleBloc mockLocaleBloc;
  final sl = GetIt.instance;

  setUpAll(() {
    registerFallbackValue(FakeCompetitionsState());
  });

  setUp(() async {
    await sl.reset();

    mockUserCubit = MockUserCubit();
    mockCompetitionsCubit = MockCompetitionsCubit();
    mockParticipantService = MockParticipantService();
    mockLocaleBloc = MockLocaleBloc();

    // Register mock in GetIt
    sl.registerSingleton<ParticipantService>(mockParticipantService);

    // Default mock behaviors
    when(() => mockCompetitionsCubit.state).thenReturn(CompetitionsInitial());
    when(() => mockCompetitionsCubit.stream)
        .thenAnswer((_) => Stream.value(CompetitionsInitial()));

    // LocaleBloc mock
    when(() => mockLocaleBloc.state)
        .thenReturn(const LocaleState(Locale('es')));
    when(() => mockLocaleBloc.stream)
        .thenAnswer((_) => Stream.value(const LocaleState(Locale('es'))));
  });

  tearDown(() async {
    await sl.reset();
  });

  Competition createTestCompetition({
    String status = 'published',
    List<String> registeredAthleteIds = const [],
  }) {
    return Competition(
      id: 'test-competition-id',
      eventId: 'test-event-id',
      title: 'Test Competition',
      description: 'A test competition',
      organizerId: 'organizer-id',
      organizerName: 'Test Organizer',
      startDate: DateTime.now().add(const Duration(days: 7)),
      endDate: DateTime.now().add(const Duration(days: 8)),
      status: status,
      registeredAthleteIds: registeredAthleteIds,
      scoringCriteria: const ScoringCriteria(type: 'points'),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  UserModel createTestUser({String id = 'test-user-id'}) {
    return UserModel(
      id: id,
      email: 'test@example.com',
      firstName: 'Test User',
      role: 'client',
    );
  }

  Widget createWidgetUnderTest(Competition competition) {
    return MaterialApp(
      home: Scaffold(
        body: MultiBlocProvider(
          providers: [
            BlocProvider<LocaleBloc>.value(value: mockLocaleBloc),
            BlocProvider<UserCubit>.value(value: mockUserCubit),
            BlocProvider<CompetitionsCubit>.value(value: mockCompetitionsCubit),
          ],
          child: CompetRegisterButton(competition: competition),
        ),
      ),
    );
  }

  group('CompetRegisterButton', () {
    group('when user is not logged in', () {
      setUp(() {
        when(() => mockUserCubit.currentUser).thenReturn(null);
        when(() => mockUserCubit.state).thenReturn(UserInitial());
        when(() => mockUserCubit.stream)
            .thenAnswer((_) => Stream.value(UserInitial()));
      });

      testWidgets('shows register button for published competition',
          (tester) async {
        final competition = createTestCompetition(status: 'published');

        await tester.pumpWidget(createWidgetUnderTest(competition));
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.person_add), findsOneWidget);
        expect(find.byType(FloatingActionButton), findsOneWidget);
      });

      testWidgets('shows nothing for live competition', (tester) async {
        final competition = createTestCompetition(status: 'live');

        await tester.pumpWidget(createWidgetUnderTest(competition));
        await tester.pumpAndSettle();

        expect(find.byType(FloatingActionButton), findsNothing);
      });

      testWidgets('shows nothing for completed competition', (tester) async {
        final competition = createTestCompetition(status: 'completed');

        await tester.pumpWidget(createWidgetUnderTest(competition));
        await tester.pumpAndSettle();

        expect(find.byType(FloatingActionButton), findsNothing);
      });
    });

    group('when user is logged in and NOT registered', () {
      setUp(() {
        final user = createTestUser();
        when(() => mockUserCubit.currentUser).thenReturn(user);
        when(() => mockUserCubit.state).thenReturn(UserLoaded(user));
        when(() => mockUserCubit.stream)
            .thenAnswer((_) => Stream.value(UserLoaded(user)));

        // API returns empty participants (user not registered)
        when(() => mockParticipantService.fetchAll(any()))
            .thenAnswer((_) async => []);
      });

      testWidgets('shows register button for published competition',
          (tester) async {
        final competition = createTestCompetition(status: 'published');

        await tester.pumpWidget(createWidgetUnderTest(competition));
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.person_add), findsOneWidget);
      });

      testWidgets('shows register button for upcoming competition',
          (tester) async {
        final competition = createTestCompetition(status: 'upcoming');

        await tester.pumpWidget(createWidgetUnderTest(competition));
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.person_add), findsOneWidget);
      });

      testWidgets('shows nothing for draft competition', (tester) async {
        final competition = createTestCompetition(status: 'draft');

        await tester.pumpWidget(createWidgetUnderTest(competition));
        await tester.pumpAndSettle();

        expect(find.byType(FloatingActionButton), findsNothing);
      });
    });

    group('when user is logged in and IS registered', () {
      setUp(() {
        final user = createTestUser(id: 'registered-user-id');
        when(() => mockUserCubit.currentUser).thenReturn(user);
        when(() => mockUserCubit.state).thenReturn(UserLoaded(user));
        when(() => mockUserCubit.stream)
            .thenAnswer((_) => Stream.value(UserLoaded(user)));

        // API returns participants with user registered
        when(() => mockParticipantService.fetchAll(any())).thenAnswer(
          (_) async => [
            {'athleteId': 'registered-user-id', 'status': 'approved'}
          ],
        );
      });

      testWidgets('shows unregister button for published competition',
          (tester) async {
        final competition = createTestCompetition(
          status: 'published',
          registeredAthleteIds: ['registered-user-id'],
        );

        await tester.pumpWidget(createWidgetUnderTest(competition));
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.person_remove), findsOneWidget);
      });

      testWidgets('shows nothing for live competition (cannot unregister)',
          (tester) async {
        final competition = createTestCompetition(
          status: 'live',
          registeredAthleteIds: ['registered-user-id'],
        );

        await tester.pumpWidget(createWidgetUnderTest(competition));
        await tester.pumpAndSettle();

        expect(find.byType(FloatingActionButton), findsNothing);
      });

      testWidgets('shows nothing for completed competition', (tester) async {
        final competition = createTestCompetition(
          status: 'completed',
          registeredAthleteIds: ['registered-user-id'],
        );

        await tester.pumpWidget(createWidgetUnderTest(competition));
        await tester.pumpAndSettle();

        expect(find.byType(FloatingActionButton), findsNothing);
      });
    });

    group('button interactions', () {
      testWidgets('register button is tappable', (tester) async {
        final user = createTestUser();
        when(() => mockUserCubit.currentUser).thenReturn(user);
        when(() => mockUserCubit.state).thenReturn(UserLoaded(user));
        when(() => mockUserCubit.stream)
            .thenAnswer((_) => Stream.value(UserLoaded(user)));
        when(() => mockParticipantService.fetchAll(any()))
            .thenAnswer((_) async => []);

        final competition = createTestCompetition(status: 'published');

        await tester.pumpWidget(createWidgetUnderTest(competition));
        await tester.pumpAndSettle();

        // Button should be present and tappable
        final button = find.byType(FloatingActionButton);
        expect(button, findsOneWidget);
        expect(tester.widget<FloatingActionButton>(button).onPressed, isNotNull);
      });

      testWidgets('unregister button is tappable', (tester) async {
        final user = createTestUser(id: 'registered-user-id');
        when(() => mockUserCubit.currentUser).thenReturn(user);
        when(() => mockUserCubit.state).thenReturn(UserLoaded(user));
        when(() => mockUserCubit.stream)
            .thenAnswer((_) => Stream.value(UserLoaded(user)));
        when(() => mockParticipantService.fetchAll(any())).thenAnswer(
          (_) async => [
            {'athleteId': 'registered-user-id', 'status': 'approved'}
          ],
        );

        final competition = createTestCompetition(
          status: 'published',
          registeredAthleteIds: ['registered-user-id'],
        );

        await tester.pumpWidget(createWidgetUnderTest(competition));
        await tester.pumpAndSettle();

        // Button should be present and tappable
        final button = find.byType(FloatingActionButton);
        expect(button, findsOneWidget);
        expect(tester.widget<FloatingActionButton>(button).onPressed, isNotNull);
      });
    });
  });
}
