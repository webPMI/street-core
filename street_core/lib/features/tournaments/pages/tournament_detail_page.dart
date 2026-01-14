import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/lang/context_tr.dart';
import '../../../core/lang/locale_keys.dart';
import '../../../core/widgets/my_text.dart';
import '../../../core/widgets/error_card.dart';
import '../../../core/router/navigation_service.dart';
import '../../../core/di/injection.dart';
import '../bloc/tournaments_cubit.dart';
import '../bloc/tournaments_state.dart';
import '../models/tournament.dart';
import '../models/tournament_standing.dart';
import '../../competitions/competition_routes.dart';
import '../../competitions/models/competition.dart';
import '../../competitions/services/competitions_service.dart';
import '../../profile/repositories/user_repository.dart';
import '../../auth/bloc/auth_cubit.dart';
import '../../auth/bloc/auth_state.dart';
import '../../auth/bloc/user_cubit.dart';
import '../../auth/bloc/user_state.dart';

/// Tournament detail page showing comprehensive tournament information
class TournamentDetailPage extends StatefulWidget {
  final String tournamentId;

  const TournamentDetailPage({super.key, required this.tournamentId});

  @override
  State<TournamentDetailPage> createState() => _TournamentDetailPageState();
}

class _TournamentDetailPageState extends State<TournamentDetailPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadTournamentData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadTournamentData() {
    final cubit = context.read<TournamentsCubit>();
    cubit.fetchTournamentById(widget.tournamentId);
    cubit.fetchTopStandings(widget.tournamentId, limit: 50);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: MyText(
          LocaleKeys.tournamentsDetail,
        
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadTournamentData,
            tooltip: context.tr(LocaleKeys.refresh),
          ),
          PopupMenuButton<String>(
            onSelected: (value) => _handleMenuAction(value),
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'share',
                child: Row(
                  children: [
                    const Icon(Icons.share),
                    const SizedBox(width: 8),
                    MyText(LocaleKeys.share, selectable: false),
                  ],
                ),
              ),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              icon: const Icon(Icons.info_outline),
              text: context.tr(LocaleKeys.tournamentsInfo),
            ),
            Tab(
              icon: const Icon(Icons.leaderboard),
              text: context.tr(LocaleKeys.tournamentsStandings),
            ),
            Tab(
              icon: const Icon(Icons.emoji_events),
              text: context.tr(LocaleKeys.tournamentsCompetitions),
            ),
          ],
        ),
      ),
      body: BlocBuilder<TournamentsCubit, TournamentsState>(
        builder: (context, state) {
          if (state is TournamentsLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is TournamentsError) {
            return Center(
              child: ErrorCard(
                message: state.message,
                onRetry: _loadTournamentData,
              ),
            );
          }

          if (state is TournamentDetailLoaded) {
            final tournament = state.tournament;
            final standings = state.standings ?? [];

            return TabBarView(
              controller: _tabController,
              children: [
                _TournamentInfoTab(tournament: tournament),
                _StandingsTab(standings: standings),
                _CompetitionsTab(tournament: tournament),
              ],
            );
          }

          return Center(
            child: MyText(LocaleKeys.tournamentsNoTournaments),
          );
        },
      ),
      floatingActionButton: BlocBuilder<TournamentsCubit, TournamentsState>(
        builder: (context, state) {
          if (state is! TournamentDetailLoaded) return const SizedBox.shrink();

          final tournament = state.tournament;
          final authState = context.watch<AuthCubit>().state;
          final userState = context.watch<UserCubit>().state;

          if (authState is! AuthAuthenticated) return const SizedBox.shrink();
          if (userState is! UserLoaded) return const SizedBox.shrink();

          final userId = userState.user.id;
          final isRegistered =
              tournament.registeredAthleteIds.contains(userId);

          // Don't show button if user is the organizer
          if (tournament.organizerId == userId) return const SizedBox.shrink();

          // Don't show button if registration is closed
          if (tournament.registration.registrationStatus != 'open') {
            return const SizedBox.shrink();
          }

          return FloatingActionButton.extended(
            onPressed: () => _handleRegistration(tournament, isRegistered),
            icon: Icon(isRegistered ? Icons.cancel : Icons.app_registration),
            label: MyText(
              isRegistered
                  ? LocaleKeys.tournamentsUnregister
                  : LocaleKeys.tournamentsRegister,
            ),
            backgroundColor:
                isRegistered ? Colors.red : Theme.of(context).colorScheme.primary,
          );
        },
      ),
    );
  }

  void _handleRegistration(Tournament tournament, bool isRegistered) async {
    final cubit = context.read<TournamentsCubit>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: MyText(
          isRegistered
              ? LocaleKeys.tournamentsUnregisterConfirm
              : LocaleKeys.tournamentsRegisterConfirm,
        ),
        content: MyText(
          isRegistered
              ? LocaleKeys.tournamentsUnregisterMessage
              : LocaleKeys.tournamentsRegisterMessage,
          args: {'tournament': tournament.title},
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: MyText(LocaleKeys.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: MyText(LocaleKeys.confirm),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    if (isRegistered) {
      await cubit.unregisterFromTournament(tournament.id);
    } else {
      await cubit.registerInTournament(tournament.id);
    }

    // Reload tournament data
    _loadTournamentData();
  }

  void _handleMenuAction(String action) {
    final state = context.read<TournamentsCubit>().state;
    if (state is! TournamentDetailLoaded) return;

    final tournament = state.tournament;

    switch (action) {
      case 'share':
        _shareTournament(tournament);
        break;
    }
  }

  void _shareTournament(Tournament tournament) {
    final url = 'https://streetcore.com/tournaments/${tournament.id}';
    Share.share(
      '${tournament.title}\n\n${tournament.description}\n\n$url',
      subject: tournament.title,
    );
  }
}

/// Tournament information tab
class _TournamentInfoTab extends StatelessWidget {
  final Tournament tournament;

  const _TournamentInfoTab({required this.tournament});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with title and status
          _buildHeader(context, theme),
          const SizedBox(height: 24),

          // Description
          _buildSection(
            context,
            theme,
            Icons.description,
            LocaleKeys.tournamentsDescription,
            tournament.description,
          ),
          const SizedBox(height: 16),

          // Schedule
          _buildScheduleSection(context, theme),
          const SizedBox(height: 16),

          // Registration
          _buildRegistrationSection(context, theme),
          const SizedBox(height: 16),

          // Scoring System
          _buildScoringSection(context, theme),
          const SizedBox(height: 16),

          // Stats
          _buildStatsSection(context, theme),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: MyText(
                tournament.title,
                noTranslation: true,
              
                style: theme.textTheme.headlineMedium?.copyWith(
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
              Icons.sports,
              size: 16,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
            const SizedBox(width: 4),
             MyText(
              'disciplines.${tournament.discipline.toLowerCase()}',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            MyText(
              ' • ',
              noTranslation: true,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
             MyText(
              'formats.${tournament.format.toLowerCase()}',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSection(
    BuildContext context,
    ThemeData theme,
    IconData icon,
    String title,
    String content,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
             MyText(
              title,
            
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
         const SizedBox(height: 8),
        MyText(
          content,
        
          selectable: true,
          style: theme.textTheme.bodyMedium,
          noTranslation: true,
        ),
      ],
    );
  }

  Widget _buildScheduleSection(BuildContext context, ThemeData theme) {
    final schedule = tournament.schedule;
    return _buildInfoCard(
      theme,
      Icons.calendar_today,
      LocaleKeys.tournamentsSchedule,
      [
        _InfoRow(
          LocaleKeys.tournamentsStartDate,
          _formatDate(schedule.startDate),
          valueNoTranslation: true,
        ),
        _InfoRow(
          LocaleKeys.tournamentsEndDate,
          _formatDate(schedule.endDate),
          valueNoTranslation: true,
        ),
        if (schedule.venue != null)
          _InfoRow(
            LocaleKeys.tournamentsVenue,
            schedule.venue!,
            valueNoTranslation: true,
          ),
        if (schedule.country != null)
          _InfoRow(
            LocaleKeys.tournamentsCountry,
            schedule.country!,
            valueNoTranslation: true,
          ),
      ],
    );
  }

  Widget _buildRegistrationSection(BuildContext context, ThemeData theme) {
    final registration = tournament.registration;
    return _buildInfoCard(
      theme,
      Icons.app_registration,
      LocaleKeys.tournamentsRegistration,
      [
        _InfoRow(
          LocaleKeys.tournamentsStatus,
          '${LocaleKeys.tournamentsRegistration}.${registration.registrationStatus}',
        ),
        if (registration.maxParticipants != null)
          _InfoRow(
            LocaleKeys.tournamentsMaxParticipants,
            '${registration.maxParticipants}',
            valueNoTranslation: true,
          ),
        if (registration.registrationDeadline != null)
          _InfoRow(
            LocaleKeys.tournamentsDeadline,
            _formatDate(registration.registrationDeadline!),
            valueNoTranslation: true,
          ),
        if (registration.entryFee != null)
          _InfoRow(
            LocaleKeys.tournamentsEntryFee,
            '${registration.entryFee} ${registration.currency ?? ''}',
            valueNoTranslation: true,
          ),
      ],
    );
  }

  Widget _buildScoringSection(BuildContext context, ThemeData theme) {
    return _buildInfoCard(
      theme,
      Icons.score,
      LocaleKeys.tournamentsScoringSystem,
      [
        _InfoRow(
          LocaleKeys.tournamentsSystem,
          '${LocaleKeys.tournamentsScoring}.${tournament.scoringSystem}',
        ),
        if (tournament.scoringConfig.countBestOf != null)
          _InfoRow(
            LocaleKeys.tournamentsCountBest,
            '${tournament.scoringConfig.countBestOf}',
            valueNoTranslation: true,
          ),
        if (tournament.scoringConfig.dropWorst != null)
          _InfoRow(
            LocaleKeys.tournamentsDropWorst,
            '${tournament.scoringConfig.dropWorst}',
            valueNoTranslation: true,
          ),
      ],
    );
  }

  Widget _buildStatsSection(BuildContext context, ThemeData theme) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            icon: Icons.emoji_events,
            label: LocaleKeys.tournamentsCompetitions,
            value: '${tournament.totalCompetitions}',
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            icon: Icons.people,
            label: LocaleKeys.tournamentsAthletes,
            value: '${tournament.totalAthletes}',
            color: theme.colorScheme.secondary,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard(
    ThemeData theme,
    IconData icon,
    String title,
    List<Widget> children,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              MyText(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

/// Information row widget
class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final bool valueNoTranslation;

  const _InfoRow(
    this.label,
    this.value, {
    this.valueNoTranslation = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: MyText(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: MyText(
              value,
              noTranslation: valueNoTranslation,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Stat card widget
class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 32, color: color),
          const SizedBox(height: 8),
          MyText(
            value,
            noTranslation: true,
            style: theme.textTheme.headlineSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          MyText(
            label,
            style: theme.textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// Status badge widget
class _StatusBadge extends StatelessWidget {
  final String status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = _getStatusColor(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: MyText(
        '${LocaleKeys.tournamentsStatus}.${status.toLowerCase()}',
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 12,
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

/// Standings tab
class _StandingsTab extends StatefulWidget {
  final List<TournamentStanding> standings;

  const _StandingsTab({required this.standings});

  @override
  State<_StandingsTab> createState() => _StandingsTabState();
}

class _StandingsTabState extends State<_StandingsTab> {
  final UserRepository _userRepository = getIt<UserRepository>();
  final Map<String, String> _athleteNames = {};
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadAthleteNames();
  }

  Future<void> _loadAthleteNames() async {
    if (widget.standings.isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Get unique athlete IDs
      final athleteIds = widget.standings
          .map((s) => s.athleteId)
          .toSet()
          .toList();

      // Load athlete data for each ID
      for (final athleteId in athleteIds) {
        try {
          final user = await _userRepository.getUserById(athleteId);
          if (mounted) {
            setState(() {
              // Prefer nickName or userName, fallback to full name
              _athleteNames[athleteId] =
                  user.nickName ??
                  user.userName ??
                  '${user.firstName} ${user.lastName ?? ''}'.trim();
            });
          }
        } catch (e) {
          // If fetching fails, use ID as fallback
          if (mounted) {
            setState(() {
              _athleteNames[athleteId] = athleteId;
            });
          }
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (widget.standings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.leaderboard, size: 64, color: theme.colorScheme.outline),
            const SizedBox(height: 16),
             MyText(
              LocaleKeys.tournamentsNoStandings,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
          ],
        ),
      );
    }

    if (_isLoading && _athleteNames.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: _loadAthleteNames,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: widget.standings.length,
        itemBuilder: (context, index) {
          final standing = widget.standings[index];
          final athleteName =
              _athleteNames[standing.athleteId] ?? standing.athleteId;
          return _StandingCard(
            standing: standing,
            rank: index + 1,
            athleteName: athleteName,
          );
        },
      ),
    );
  }
}

/// Standing card widget
class _StandingCard extends StatelessWidget {
  final TournamentStanding standing;
  final int rank;
  final String athleteName;

  const _StandingCard({
    required this.standing,
    required this.rank,
    required this.athleteName,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getRankColor(rank),
           child: MyText(
            '$rank',
            noTranslation: true,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
         title: MyText(
          athleteName,
          noTranslation: true,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
         subtitle: MyText(
          LocaleKeys.tournamentsPoints,
          args: {'points': standing.totalPoints.toStringAsFixed(1)},
        ),
        trailing: _buildPositionChange(standing.positionChange),
      ),
    );
  }

  Color _getRankColor(int rank) {
    switch (rank) {
      case 1:
        return Colors.amber;
      case 2:
        return Colors.grey;
      case 3:
        return Colors.brown;
      default:
        return Colors.blue;
    }
  }

  Widget? _buildPositionChange(String change) {
    IconData icon;
    Color color;

    switch (change) {
      case 'up':
        icon = Icons.arrow_upward;
        color = Colors.green;
        break;
      case 'down':
        icon = Icons.arrow_downward;
        color = Colors.red;
        break;
      case 'new':
        icon = Icons.new_releases;
        color = Colors.blue;
        break;
      default:
        return null;
    }

    return Icon(icon, color: color, size: 20);
  }
}

/// Competitions tab
class _CompetitionsTab extends StatefulWidget {
  final Tournament tournament;

  const _CompetitionsTab({required this.tournament});

  @override
  State<_CompetitionsTab> createState() => _CompetitionsTabState();
}

class _CompetitionsTabState extends State<_CompetitionsTab> {
  final CompetitionsService _competitionsService = getIt<CompetitionsService>();
  List<Competition>? _competitions;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadCompetitions();
  }

  Future<void> _loadCompetitions() async {
    if (widget.tournament.competitionIds.isEmpty) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final competitions = <Competition>[];
      for (final id in widget.tournament.competitionIds) {
        try {
          final competition = await _competitionsService.fetchCompetitionById(
            id,
          );
          competitions.add(competition);
        } catch (e) {
          // Continue loading other competitions even if one fails
        }
      }

      if (mounted) {
        setState(() {
          _competitions = competitions;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (widget.tournament.competitionIds.isEmpty) {
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
              LocaleKeys.tournamentsNoCompetitions,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
          ],
        ),
      );
    }

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
            const SizedBox(height: 16),
            MyText(_errorMessage!),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadCompetitions,
              child: MyText(LocaleKeys.retry),
            ),
          ],
        ),
      );
    }

    if (_competitions == null || _competitions!.isEmpty) {
      return Center(child: MyText(LocaleKeys.tournamentsNoCompetitions));
    }

    return RefreshIndicator(
      onRefresh: _loadCompetitions,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _competitions!.length,
        itemBuilder: (context, index) {
          final competition = _competitions![index];
          return _CompetitionCard(competition: competition);
        },
      ),
    );
  }
}

/// Competition card widget showing competition details
class _CompetitionCard extends StatelessWidget {
  final Competition competition;

  const _CompetitionCard({required this.competition});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          NavigationService().push(
            context,
            CompetitionRoutes.getCompetitionDetail(competition.id),
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
                      competition.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  _CompetitionStatusBadge(status: competition.status),
                ],
              ),
              const SizedBox(height: 8),
              if (competition.discipline != null) ...[
                Row(
                  children: [
                    Icon(
                      Icons.sports,
                      size: 14,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                    const SizedBox(width: 4),
                    MyText(
                      competition.discipline!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.6,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
              ],
              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 14,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                  const SizedBox(width: 4),
                  MyText(
                    _formatDateRange(
                      competition.startDate,
                      competition.endDate,
                    ),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
              if (competition.venue != null) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.location_on,
                      size: 14,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: MyText(
                        competition.venue!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.6,
                          ),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  _CompetitionInfoChip(
                    icon: Icons.people,
                    label:
                        '${competition.currentParticipants}/${competition.maxParticipants}',
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  if (competition.category != null)
                    _CompetitionInfoChip(
                      icon: Icons.category,
                      label: competition.category!,
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

  String _formatDateRange(DateTime start, DateTime end) {
    if (start.year == end.year &&
        start.month == end.month &&
        start.day == end.day) {
      return '${start.day}/${start.month}/${start.year}';
    }
    return '${start.day}/${start.month} - ${end.day}/${end.month}/${end.year}';
  }
}

class _CompetitionStatusBadge extends StatelessWidget {
  final String status;

  const _CompetitionStatusBadge({required this.status});

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
        'competitions.status.${status.toLowerCase()}',
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

class _CompetitionInfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _CompetitionInfoChip({
    required this.icon,
    required this.label,
    required this.color,
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
