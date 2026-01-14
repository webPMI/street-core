import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/lang/locale_keys.dart';
import '../../../core/widgets/my_text.dart';
import '../../../core/router/navigation_service.dart';
import '../bloc/tournaments_cubit.dart';
import '../bloc/tournaments_state.dart';
import '../models/tournament.dart';
import '../tournament_routes.dart';
import '../widgets/tournament_filters_dialog.dart';

/// Page to display a list of tournaments
class TournamentsListPage extends StatefulWidget {
  const TournamentsListPage({super.key});

  @override
  State<TournamentsListPage> createState() => _TournamentsListPageState();
}

class _TournamentsListPageState extends State<TournamentsListPage> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadTournaments();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _loadTournaments() {
    context.read<TournamentsCubit>().fetchTournaments();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.9) {
      context.read<TournamentsCubit>().loadNextPage();
    }
  }

  Future<void> _showFiltersDialog(BuildContext context) async {
    final state = context.read<TournamentsCubit>().state;
    final currentFilters =
        state is TournamentsLoaded ? state.filters : <String, dynamic>{};

    final filters = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => TournamentFiltersDialog(
        currentFilters: currentFilters,
      ),
    );

    if (filters != null && context.mounted) {
      context.read<TournamentsCubit>().fetchTournaments(
            page: 1,
            filters: filters,
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: MyText(
          LocaleKeys.tournamentsTitle,
       
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFiltersDialog(context),
          ),
        ],
      ),
      body: BlocBuilder<TournamentsCubit, TournamentsState>(
        builder: (context, state) {
          if (state is TournamentsLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is TournamentsError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                  const SizedBox(height: 16),
                   MyText(state.message),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadTournaments,
                    child: MyText(LocaleKeys.retry, selectable: false),
                  ),
                ],
              ),
            );
          }

          if (state is TournamentsLoaded) {
            final tournaments = state.result.items;

            if (tournaments.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.emoji_events_outlined, size: 64, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    MyText(LocaleKeys.tournamentsNoTournaments),
                  ],
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: () async {
                _loadTournaments();
              },
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                itemCount: tournaments.length + (state.result.hasNext ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index >= tournaments.length) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: CircularProgressIndicator(),
                      ),
                    );
                  }

                  final tournament = tournaments[index];
                  return _TournamentCard(tournament: tournament);
                },
              ),
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }
}

/// Card widget to display a tournament
class _TournamentCard extends StatelessWidget {
  final Tournament tournament;

  const _TournamentCard({required this.tournament});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          NavigationService().push(
            context,
            TournamentRoutes.getTournamentDetail(tournament.id),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Expanded(
                    child: MyText(
                      tournament.title,
                      noTranslation: true,
                   
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  _StatusBadge(status: tournament.status),
                ],
              ),
              const SizedBox(height: 8),

              // Discipline & Format
              Row(
                children: [
                  Icon(Icons.sports, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  MyText(
                    tournament.discipline.toLowerCase(), // This will map to 'bmx', 'skateboarding', etc.
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.format_list_bulleted, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  MyText(
                    'formats.${tournament.format.toLowerCase()}',
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Schedule
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                   MyText(
                    '${_formatDate(tournament.schedule.startDate)} - ${_formatDate(tournament.schedule.endDate)}',
                    noTranslation: true,
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Stats
              Row(
                children: [
                  Icon(Icons.emoji_events, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                   MyText(
                    LocaleKeys.tournamentsCompetitions,
                    args: {'count': '${tournament.totalCompetitions}'},
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.people, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                   MyText(
                    LocaleKeys.tournamentsAthletes,
                    args: {'count': '${tournament.totalAthletes}'},
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

/// Status badge widget
class _StatusBadge extends StatelessWidget {
  final String status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color backgroundColor;
    Color textColor;
    switch (status) {
      case 'upcoming':
        backgroundColor = Colors.blue.shade100;
        textColor = Colors.blue.shade900;
        break;
      case 'live':
        backgroundColor = Colors.green.shade100;
        textColor = Colors.green.shade900;
        break;
      case 'completed':
        backgroundColor = Colors.grey.shade200;
        textColor = Colors.grey.shade900;
        break;
      default:
        backgroundColor = Colors.grey.shade100;
        textColor = Colors.grey.shade700;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: MyText(
        'tournaments.status.${status.toLowerCase()}',
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: textColor,
      ),
    );
  }
}
