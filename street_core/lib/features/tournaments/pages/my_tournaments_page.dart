import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/lang/context_tr.dart';
import '../../../core/lang/locale_keys.dart';
import '../../../core/widgets/my_text.dart';
import '../../../core/router/navigation_service.dart';
import '../../auth/bloc/user_cubit.dart';
import '../bloc/tournaments_cubit.dart';
import '../bloc/tournaments_state.dart';
import '../models/tournament.dart';
import '../tournament_routes.dart';

/// Page showing tournaments created by or involving the current user
class MyTournamentsPage extends StatefulWidget {
  const MyTournamentsPage({super.key});

  @override
  State<MyTournamentsPage> createState() => _MyTournamentsPageState();
}

class _MyTournamentsPageState extends State<MyTournamentsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _currentUserId = context.read<UserCubit>().currentUser?.id;
    _loadMyTournaments();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadMyTournaments() {
    if (_currentUserId == null) return;

    final cubit = context.read<TournamentsCubit>();

    // Load tournaments organized by me
    cubit.fetchTournaments(filters: {'organizerId': _currentUserId});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: MyText(
          LocaleKeys.tournamentsMyTournaments,
        
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              NavigationService().push(
                context,
                TournamentRoutes.tournamentCreateNav,
              );
            },
            tooltip: context.tr(LocaleKeys.tournamentsCreateNew),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              icon: const Icon(Icons.emoji_events),
              text: context.tr(LocaleKeys.tournamentsOrganized),
            ),
            Tab(
              icon: const Icon(Icons.person),
              text: context.tr(LocaleKeys.tournamentsParticipating),
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _OrganizedTournamentsTab(userId: _currentUserId),
          _ParticipatingTournamentsTab(userId: _currentUserId),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          NavigationService().push(
            context,
            TournamentRoutes.tournamentCreateNav,
          );
        },
        icon: const Icon(Icons.add),
        label: MyText(LocaleKeys.tournamentsCreateNew, selectable: false),
      ),
    );
  }
}

/// Tab showing tournaments organized by the user
class _OrganizedTournamentsTab extends StatefulWidget {
  final String? userId;

  const _OrganizedTournamentsTab({this.userId});

  @override
  State<_OrganizedTournamentsTab> createState() =>
      _OrganizedTournamentsTabState();
}

class _OrganizedTournamentsTabState extends State<_OrganizedTournamentsTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadTournaments();
  }

  void _loadTournaments() {
    if (widget.userId == null) return;
    context.read<TournamentsCubit>().fetchTournaments(
      filters: {'organizerId': widget.userId},
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);

    return RefreshIndicator(
      onRefresh: () async => _loadTournaments(),
      child: BlocBuilder<TournamentsCubit, TournamentsState>(
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
                    Icon(
                      Icons.emoji_events_outlined,
                      size: 64,
                      color: theme.colorScheme.outline,
                    ),
                    const SizedBox(height: 16),
                     MyText(
                      LocaleKeys.tournamentsNoOrganized,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.outline,
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () {
                        NavigationService().push(
                          context,
                          TournamentRoutes.tournamentCreateNav,
                        );
                      },
                      icon: const Icon(Icons.add),
                       label: MyText(LocaleKeys.tournamentsCreateFirst, selectable: false),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: tournaments.length,
              itemBuilder: (context, index) {
                final tournament = tournaments[index];
                return _TournamentCard(tournament: tournament);
              },
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }
}

/// Tab showing tournaments where user is participating
class _ParticipatingTournamentsTab extends StatefulWidget {
  final String? userId;

  const _ParticipatingTournamentsTab({this.userId});

  @override
  State<_ParticipatingTournamentsTab> createState() =>
      _ParticipatingTournamentsTabState();
}

class _ParticipatingTournamentsTabState
    extends State<_ParticipatingTournamentsTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadTournaments();
  }

  void _loadTournaments() {
    if (widget.userId == null) return;
    context.read<TournamentsCubit>().fetchTournaments(
      filters: {'athleteId': widget.userId},
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);

    return RefreshIndicator(
      onRefresh: () async => _loadTournaments(),
      child: BlocBuilder<TournamentsCubit, TournamentsState>(
        builder: (context, state) {
          if (state is TournamentsLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is TournamentsError) {
             return Center(
              child: MyText(state.message),
            );
          }

          if (state is TournamentsLoaded) {
            final tournaments = state.result.items;

            if (tournaments.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.person_outline,
                      size: 64,
                      color: theme.colorScheme.outline,
                    ),
                    const SizedBox(height: 16),
                     MyText(
                      LocaleKeys.tournamentsNoParticipating,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.outline,
                      ),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: tournaments.length,
              itemBuilder: (context, index) {
                final tournament = tournaments[index];
                return _TournamentCard(tournament: tournament);
              },
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }
}

/// Card widget for tournament in list
class _TournamentCard extends StatelessWidget {
  final Tournament tournament;

  const _TournamentCard({required this.tournament});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          NavigationService().push(
            context,
            TournamentRoutes.getTournamentDetail(tournament.id),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                   Expanded(
                    child: MyText(
                      tournament.title,
                      noTranslation: true,
                  
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  _StatusBadge(status: tournament.status),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 14,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                  const SizedBox(width: 4),
                   MyText(
                    _formatDateRange(tournament.schedule),
                    noTranslation: true,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _InfoChip(
                    icon: Icons.emoji_events,
                    label: '${tournament.totalCompetitions}',
                    noTranslation: true,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  _InfoChip(
                    icon: Icons.people,
                    label: '${tournament.totalAthletes}',
                    noTranslation: true,
                    color: theme.colorScheme.secondary,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDateRange(TournamentSchedule schedule) {
    final start = schedule.startDate;
    final end = schedule.endDate;

    if (start.year == end.year &&
        start.month == end.month &&
        start.day == end.day) {
      return '${start.day}/${start.month}/${start.year}';
    }

    return '${start.day}/${start.month} - ${end.day}/${end.month}/${end.year}';
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = _getStatusColor(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
      ),
       child: MyText(
        '${LocaleKeys.tournamentsStatus}.${status.toLowerCase()}',
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 10,
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'live':
        return Colors.green;
      case 'upcoming':
        return Colors.blue;
      case 'completed':
        return Colors.grey;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool noTranslation;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.color,
    this.noTranslation = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
           MyText(
            label,
            noTranslation: noTranslation,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
