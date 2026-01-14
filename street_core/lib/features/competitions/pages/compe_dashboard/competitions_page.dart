import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:street_core/core/lang/locale_keys.dart';
import '../../../../core/lang/context_tr.dart';
import '../../../../core/widgets/my_text.dart';
import '../../../../core/widgets/drawer/my_drawer.dart';
import '../../../../core/widgets/app_logo.dart';
import '../../../../core/helpers/responsive/responsive.dart';
import '../../../../core/di/injection.dart';
import '../../bloc/competitions_cubit.dart';
import '../../bloc/competitions_state.dart';
import '../../models/competition.dart';
import 'widgets/featured_competitions_section.dart';
import 'widgets/quick_actions_section.dart';
import 'widgets/stats_section.dart';
import 'widgets/category_filters_section.dart';
import '../../../tournaments/bloc/tournaments_cubit.dart';
import '../../../tournaments/bloc/tournaments_state.dart';
import '../../../tournaments/models/tournament.dart';
import '../../../tournaments/pages/dashboard/widgets/tournament_quick_actions_section.dart';
import '../../../tournaments/pages/dashboard/widgets/tournament_stats_section.dart';
import '../../../tournaments/pages/dashboard/widgets/featured_tournaments_section.dart';

/// Main competitions and tournaments dashboard page
///
/// Displays with tabs:
/// - Competitions tab: Featured competitions, quick actions, stats, filters
/// - Tournaments tab: Featured tournaments, quick actions, stats
class CompetitionsPage extends StatefulWidget {
  const CompetitionsPage({super.key});

  @override
  State<CompetitionsPage> createState() => _CompetitionsPageState();
}

class _CompetitionsPageState extends State<CompetitionsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadDashboardData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadDashboardData() {
    // Load featured competitions (live + upcoming, limited to 10)
    context.read<CompetitionsCubit>().fetchCompetitions(
      filters: {'status': 'live,upcoming', 'limit': 10},
    );
  }

  TournamentStats? _calculateTournamentStats(List<Tournament> tournaments) {
    if (tournaments.isEmpty) return null;

    int totalActive = 0;
    int totalAthletes = 0;
    int liveNow = 0;
    int upcoming = 0;

    for (final tournament in tournaments) {
      // Count active tournaments (not cancelled)
      if (tournament.status != 'cancelled') {
        totalActive++;
      }

      // Count total athletes
      totalAthletes += tournament.totalAthletes;

      // Count live tournaments
      if (tournament.status == 'live') {
        liveNow++;
      }

      // Count upcoming tournaments
      if (tournament.status == 'upcoming') {
        upcoming++;
      }
    }

    return TournamentStats(
      totalActive: totalActive,
      totalAthletes: totalAthletes,
      liveNow: liveNow,
      upcoming: upcoming,
    );
  }

  CompetitionStats? _calculateStats(List<Competition> competitions) {
    if (competitions.isEmpty) return null;

    final now = DateTime.now();
    int totalActive = 0;
    int totalParticipants = 0;
    int liveNow = 0;
    int upcoming = 0;

    for (final competition in competitions) {
      // Count active competitions (not draft or cancelled)
      if (competition.status != 'draft' && competition.status != 'cancelled') {
        totalActive++;
      }

      // Count participants
      totalParticipants += competition.registeredAthleteIds.length;

      // Count live competitions
      if (competition.status == 'live') {
        liveNow++;
      }

      // Count upcoming competitions
      if (competition.status == 'upcoming' ||
          (competition.startDate.isAfter(now) &&
              competition.status != 'completed')) {
        upcoming++;
      }
    }

    return CompetitionStats(
      totalActive: totalActive,
      totalParticipants: totalParticipants,
      liveNow: liveNow,
      upcoming: upcoming,
    );
  }

  @override
  Widget build(BuildContext context) {
    Theme.of(context);

    // Determine icon size based on screen size
    final iconSize = context.responsive(
      mobile: 20.0,
      tablet: 24.0,
      desktop: 28.0,
    );

    return BlocProvider(
      create: (_) => getIt<TournamentsCubit>(),
      child: Scaffold(
        appBar: AppBar(
          title: Row(
            children: [
              AppLogo(
                icon: Icons.emoji_events,
                margin: context.isMobile ? 5 : null,
                padding: context.isMobile ? 5 : null,
                animate: true,
                variant: LogoVariant.full,
              ),
              SizedBox(width: context.responsive(mobile: 4.0, tablet: 8.0)),
              if (!context.isMobile)
                Flexible(
                  child: const MyText(
                    LocaleKeys.competitionsDashboard,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
          ),
          actions: [
            Builder(
              builder: (context) {
                return IconButton(
                  icon: Icon(
                    Icons.refresh,
                    size: iconSize,
                  ),
                  onPressed: () {
                    final currentTab = _tabController.index;
                    if (currentTab == 0) {
                      _loadDashboardData();
                    } else {
                      // Use Builder context which has access to TournamentsCubit
                      context.read<TournamentsCubit>().fetchTournaments(
                        page: 1,
                        limit: 10,
                        filters: {'status': 'live,upcoming'},
                      );
                    }
                  },
                  tooltip: context.tr(LocaleKeys.refresh),
                );
              },
            ),
          ],
          bottom: TabBar(
            controller: _tabController,
            indicatorSize: TabBarIndicatorSize.tab,
            indicatorWeight: 3,
            tabs: [
              Tab(
                icon: Icon(
                  Icons.emoji_events,
                  size: iconSize,
                ),
                iconMargin: EdgeInsets.only(
                  bottom: context.responsive(mobile: 4.0, tablet: 6.0),
                ),
                text: context.tr(LocaleKeys.competitionsTitle),
              ),
              Tab(
                icon: Icon(
                  Icons.emoji_events_outlined,
                  size: iconSize,
                ),
                iconMargin: EdgeInsets.only(
                  bottom: context.responsive(mobile: 4.0, tablet: 6.0),
                ),
                text: context.tr(LocaleKeys.tournamentsTitle),
              ),
            ],
          ),
        ),
        drawer: MyDrawer(),
        body: TabBarView(
          controller: _tabController,
          children: [
            // Competitions Tab
            _CompetitionsTabView(
              onRefresh: _loadDashboardData,
              calculateStats: _calculateStats,
            ),
            // Tournaments Tab
            _TournamentsTabView(calculateStats: _calculateTournamentStats),
          ],
        ),
      ),
    );
  }
}

/// Competitions tab view widget
class _CompetitionsTabView extends StatelessWidget {
  final VoidCallback onRefresh;
  final CompetitionStats? Function(List<Competition>) calculateStats;

  const _CompetitionsTabView({
    required this.onRefresh,
    required this.calculateStats,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      child: BlocBuilder<CompetitionsCubit, CompetitionsState>(
        builder: (context, state) {
          final bool isLoading = state is CompetitionsLoading;
          final List<Competition> competitions = state is CompetitionsLoaded
              ? state.competitions
              : [];
          final stats = calculateStats(competitions);

          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),

                // Welcome header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      MyText(
                        LocaleKeys.competitionsWelcome,
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      MyText(
                        LocaleKeys.competitionsDashboardSubtitle,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.7,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Quick Actions Section
                const QuickActionsSection(),

                const SizedBox(height: 24),

                // Statistics Section
                StatsSection(stats: stats, isLoading: isLoading),

                const SizedBox(height: 24),

                // Category Filters Section
                const CategoryFiltersSection(),

                const SizedBox(height: 24),

                // Featured Competitions Section
                FeaturedCompetitionsSection(
                  competitions: competitions,
                  isLoading: isLoading,
                ),

                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Tournaments tab view widget
class _TournamentsTabView extends StatefulWidget {
  final TournamentStats? Function(List<Tournament>) calculateStats;

  const _TournamentsTabView({required this.calculateStats});

  @override
  State<_TournamentsTabView> createState() => _TournamentsTabViewState();
}

class _TournamentsTabViewState extends State<_TournamentsTabView>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    // Load tournaments when tab is first created
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadTournaments();
    });
  }

  void _loadTournaments() {
    context.read<TournamentsCubit>().fetchTournaments(
      page: 1,
      limit: 10,
      filters: {'status': 'live,upcoming'},
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    final theme = Theme.of(context);

    return RefreshIndicator(
      onRefresh: () async => _loadTournaments(),
      child: BlocBuilder<TournamentsCubit, TournamentsState>(
        builder: (context, state) {
          final bool isLoading = state is TournamentsLoading;
          final List<Tournament> tournaments = state is TournamentsLoaded
              ? state.result.items
              : [];
          final stats = widget.calculateStats(tournaments);

          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),

                // Welcome header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      MyText(
                        LocaleKeys.tournamentsWelcome,
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      MyText(
                        LocaleKeys.tournamentsDashboardSubtitle,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.7,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Quick Actions Section
                const TournamentQuickActionsSection(),

                const SizedBox(height: 24),

                // Statistics Section
                TournamentStatsSection(stats: stats, isLoading: isLoading),

                const SizedBox(height: 24),

                // Featured Tournaments Section
                FeaturedTournamentsSection(
                  tournaments: tournaments,
                  isLoading: isLoading,
                ),

                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }
}
