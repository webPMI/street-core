// competition_routes.dart
//
// Centralized competition routes configuration.
// All competition-related routes are defined here and exported to public_routes and private_routes.

import '../../core/di/injection.dart';
import '../../core/router/app_routes.dart';
import './bloc/competitions_cubit.dart';
import './categories/bloc/competition_category_cubit.dart';
import './categories/pages/category_detail_page.dart';
import './categories/pages/category_ranking_page.dart';
import 'pages/compe_list/competitions_list_page.dart';
import 'pages/compe_dashboard/competitions_page.dart';
import 'pages/competitions_documentation_page.dart';
import './judges/bloc/judge_invitation_cubit.dart';
import './judges/bloc/judge_score_cubit.dart';
import './judges/pages/judge_scoring_page.dart';
import './judges/pages/my_judge_invitations_page.dart';
import 'pages/compe_detail/competition_detail_page.dart';
import 'pages/my_competitions_page.dart';
import 'widgets/compe_create/competition_create.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'competition_routes.dart';

/// Public competition routes (no authentication required)
///
/// These routes are accessible to all users without login.
/// Include: competition listing, competition detail view, leaderboard.
final List<GoRoute> publicCompetitionRoutes = [
  // Public competitions dashboard
  GoRoute(
    path: CompetitionRoutes.competitions,
    builder: (context, state) => BlocProvider(
      create: (_) => getIt<CompetitionsCubit>(),
      child: const CompetitionsPage(),
    ),
  ),

  // Public competitions list view
  GoRoute(
    path: CompetitionRoutes.competitionsList,
    builder: (context, state) => BlocProvider(
      create: (_) => getIt<CompetitionsCubit>(),
      child: const CompetitionsListPage(),
    ),
  ),

  // Public competitions documentation
  GoRoute(
    path: CompetitionRoutes.competitionsDocumentation,
    builder: (context, state) => const CompetitionsDocumentationPage(),
  ),

  // Public competition detail
  GoRoute(
    path: CompetitionRoutes.competitionDetail,
    builder: (context, state) {
      final competitionId = state.pathParameters['id'] ?? '';
      return BlocProvider(
        create: (_) => getIt<CompetitionsCubit>(),
        child: CompetitionDetailPage(competitionId: competitionId),
      );
    },
  ),

  // Public category detail (view category information)
  GoRoute(
    path: CompetitionRoutes.categoryDetail,
    builder: (context, state) {
      final competitionId = state.pathParameters['competitionId'] ?? '';
      final categoryId = state.pathParameters['categoryId'] ?? '';
      return BlocProvider(
        create: (_) => getIt<CompetitionCategoryCubit>(),
        child: CategoryDetailPage(
          competitionId: competitionId,
          categoryId: categoryId,
        ),
      );
    },
  ),

  // Public category ranking/leaderboard
  GoRoute(
    path: CompetitionRoutes.categoryRanking,
    builder: (context, state) {
      final competitionId = state.pathParameters['competitionId'] ?? '';
      final categoryId = state.pathParameters['categoryId'] ?? '';
      return BlocProvider(
        create: (_) => getIt<CompetitionCategoryCubit>(),
        child: CategoryRankingPage(
          competitionId: competitionId,
          categoryId: categoryId,
        ),
      );
    },
  ),

  // Public live competitions (same page, users can filter)
  GoRoute(
    path: AppRoutes.liveCompetitions,
    builder: (context, state) => BlocProvider(
      create: (_) => getIt<CompetitionsCubit>(),
      child: const CompetitionsListPage(),
    ),
  ),
];

/// Private competition routes (authentication required)
///
/// These routes are only accessible to authenticated users.
/// Include: competition management (create, edit), judge functions, category management.
///
/// NOTE: These routes use RELATIVE paths (no leading /) because they are nested
/// under /dashboard in the route hierarchy.
final List<GoRoute> privateCompetitionRoutes = [
  // My competitions: /dashboard/my-competitions
  GoRoute(
    path: 'my-competitions', // 'create'
    builder: (context, state) => BlocProvider(
      create: (_) => getIt<CompetitionsCubit>(),
      child: const MyCompetitionsPage(),
    ),
  ),

  // Dashboard competitions: /dashboard/competitions (Dashboard with tabs)
  GoRoute(
    path: CompetitionRoutes.dashboardCompetitions, // 'competitions'
    builder: (context, state) => BlocProvider(
      create: (_) => getIt<CompetitionsCubit>(),
      child: const CompetitionsPage(),
    ),
    routes: [
      // Competitions list view: /dashboard/competitions/list
      GoRoute(
        path: 'list',
        builder: (context, state) => BlocProvider(
          create: (_) => getIt<CompetitionsCubit>(),
          child: const CompetitionsListPage(),
        ),
      ),

      // Create competition: /dashboard/competitions/create
      GoRoute(
        path: CompetitionRoutes.competitionCreate, // 'create'
        builder: (context, state) => BlocProvider(
          create: (_) => getIt<CompetitionsCubit>(),
          child: const CompetitionCreate(),
        ),
      ),

      // Edit competition: /dashboard/competitions/edit/:id
      GoRoute(
        path: CompetitionRoutes.competitionEdit, // 'edit/:id'
        builder: (context, state) {
          final competitionId = state.pathParameters['id'] ?? '';
          return BlocProvider(
            create: (_) => getIt<CompetitionsCubit>(),
            child: CompetitionCreate(competitionId: competitionId),
          );
        },
      ),
    ],
  ),

  // Judge invitations: /dashboard/judge/invitations
  GoRoute(
    path: CompetitionRoutes.myJudgeInvitations, // 'judge/invitations'
    builder: (context, state) => BlocProvider(
      create: (_) => getIt<JudgeInvitationCubit>(),
      child: const MyJudgeInvitationsPage(),
    ),
  ),

  // Judge scoring: /dashboard/competitions/:competitionId/categories/:categoryId/scoring
  GoRoute(
    path: CompetitionRoutes
        .judgeScoring, // 'competitions/:competitionId/categories/:categoryId/scoring'
    builder: (context, state) {
      final competitionId = state.pathParameters['competitionId'] ?? '';
      final categoryId = state.pathParameters['categoryId'] ?? '';
      return BlocProvider(
        create: (_) => getIt<JudgeScoreCubit>(),
        child: JudgeScoringPage(
          competitionId: competitionId,
          categoryId: categoryId,
        ),
      );
    },
  ),
];
