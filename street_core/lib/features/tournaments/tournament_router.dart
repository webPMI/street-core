// tournament_router.dart
//
// Centralized tournament routes configuration.
// All tournament-related routes are defined here and exported to public_routes.

import 'package:flutter/material.dart';

import '../../core/di/injection.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import './bloc/tournaments_cubit.dart';
import './bloc/tournaments_state.dart';
import './pages/tournaments_list_page.dart';
import './pages/tournament_detail_page.dart';
import './pages/my_tournaments_page.dart';
import './pages/tournament_form_page.dart';
import './tournament_routes.dart';
import '../../core/lang/locale_keys.dart';
import '../../core/widgets/my_text.dart';

/// Public tournament routes (no authentication required)
///
/// These routes are accessible to all users without login.
final List<GoRoute> publicTournamentRoutes = [
  // Public tournaments list
  GoRoute(
    path: TournamentRoutes.tournaments,
    builder: (context, state) => BlocProvider(
      create: (_) => getIt<TournamentsCubit>(),
      child: const TournamentsListPage(),
    ),
  ),

  // Tournament detail page
  GoRoute(
    path: TournamentRoutes.tournamentDetail,
    builder: (context, state) {
      final tournamentId = state.pathParameters['id'] ?? '';
      return BlocProvider(
        create: (_) => getIt<TournamentsCubit>(),
        child: TournamentDetailPage(tournamentId: tournamentId),
      );
    },
  ),
];

/// Private tournament routes (authentication required)
///
/// These routes require the user to be authenticated.
final List<GoRoute> privateTournamentRoutes = [
  // My tournaments: /dashboard/my-tournaments
  GoRoute(
    path: TournamentRoutes.myTournaments, // 'my-tournaments'
    builder: (context, state) => BlocProvider(
      create: (_) => getIt<TournamentsCubit>(),
      child: const MyTournamentsPage(),
    ),
  ),

  // Dashboard tournaments list: /dashboard/tournaments
  GoRoute(
    path: TournamentRoutes.dashboardTournaments, // 'tournaments'
    builder: (context, state) => BlocProvider(
      create: (_) => getIt<TournamentsCubit>(),
      child: const TournamentsListPage(),
    ),
    routes: [
      // Create tournament: /dashboard/tournaments/create
      GoRoute(
        path: TournamentRoutes.tournamentCreate, // 'create'
        builder: (context, state) => BlocProvider(
          create: (_) => getIt<TournamentsCubit>(),
          child: const TournamentFormPage(),
        ),
      ),

      // Edit tournament: /dashboard/tournaments/edit/:id
      GoRoute(
        path: TournamentRoutes.tournamentEdit, // 'edit/:id'
        builder: (context, state) {
          final tournamentId = state.pathParameters['id'] ?? '';
          return BlocProvider(
            create: (_) => getIt<TournamentsCubit>(),
            child: _TournamentEditLoader(tournamentId: tournamentId),
          );
        },
      ),
    ],
  ),
];

/// Loader widget for tournament edit page
/// Fetches tournament data before showing the form
class _TournamentEditLoader extends StatefulWidget {
  final String tournamentId;

  const _TournamentEditLoader({required this.tournamentId});

  @override
  State<_TournamentEditLoader> createState() => _TournamentEditLoaderState();
}

class _TournamentEditLoaderState extends State<_TournamentEditLoader> {
  @override
  void initState() {
    super.initState();
    // Load tournament data
    context.read<TournamentsCubit>().fetchTournamentById(widget.tournamentId);
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TournamentsCubit, TournamentsState>(
      builder: (context, state) {
        if (state is TournamentsLoading) {
          return Scaffold(
            appBar: AppBar(title: const MyText(LocaleKeys.tournamentsEdit)),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        if (state is TournamentsError) {
          return Scaffold(
            appBar: AppBar(title: const MyText(LocaleKeys.tournamentsEdit)),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                  const SizedBox(height: 16),
                  MyText(state.message, noTranslation: true),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      context
                          .read<TournamentsCubit>()
                          .fetchTournamentById(widget.tournamentId);
                    },
                    child: const MyText(LocaleKeys.retry),
                  ),
                ],
              ),
            ),
          );
        }

        if (state is TournamentDetailLoaded) {
          return TournamentFormPage(
            tournamentId: widget.tournamentId,
            existingTournament: state.tournament,
          );
        }

        return Scaffold(
          appBar: AppBar(title: const MyText(LocaleKeys.tournamentsEdit)),
          body: const Center(child: CircularProgressIndicator()),
        );
      },
    );
  }
}
