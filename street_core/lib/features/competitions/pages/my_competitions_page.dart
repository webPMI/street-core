import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/lang/context_tr.dart';
import '../../../core/router/navigation_service.dart';
import '../../../core/widgets/drawer/my_drawer.dart';
import '../../../core/widgets/my_text.dart';
import '../bloc/competitions_cubit.dart';
import '../bloc/competitions_state.dart';
import '../competition_routes.dart';
import '../models/competition.dart';
import '../widgets/competition_status_badge.dart';
import '../../../core/lang/locale_keys.dart';

class MyCompetitionsPage extends StatefulWidget {
  const MyCompetitionsPage({super.key});

  @override
  State<MyCompetitionsPage> createState() => _MyCompetitionsPageState();
}

class _MyCompetitionsPageState extends State<MyCompetitionsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _statusFilter = 'all';

  final List<_FilterOption> _filters = const [
    _FilterOption(key: 'all', labelKey: LocaleKeys.all, icon: Icons.list),
    _FilterOption(key: 'draft', labelKey: LocaleKeys.draft, icon: Icons.edit_note),
    _FilterOption(key: 'upcoming', labelKey: LocaleKeys.tournamentsStatusUpcoming, icon: Icons.event),
    _FilterOption(key: 'live', labelKey: LocaleKeys.tournamentsStatusLive, icon: Icons.live_tv),
    _FilterOption(
      key: 'completed',
      labelKey: LocaleKeys.tournamentsStatusCompleted,
      icon: Icons.check_circle,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _filters.length, vsync: this);
    _tabController.addListener(_onTabChange);
    _loadCompetitions();
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChange);
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChange() {
    if (!_tabController.indexIsChanging) {
      setState(() {
        _statusFilter = _filters[_tabController.index].key;
      });
      _loadCompetitions();
    }
  }

  void _loadCompetitions() {
    final filters = _statusFilter != 'all' ? {'status': _statusFilter} : null;
    context.read<CompetitionsCubit>().fetchMyCompetitions(filters: filters);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.emoji_events),
            const SizedBox(width: 8),
            const MyText(LocaleKeys.myCompetitions),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadCompetitions,
            tooltip: context.tr(LocaleKeys.update),
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _goToCreate,
            tooltip: context.tr(LocaleKeys.createCompetition),
          ),
        ],
      ),
      drawer: MyDrawer(),
      body: Column(
        children: [
          Material(
            color: theme.colorScheme.surface,
            elevation: 1,
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              tabs: _filters
                  .map(
                    (f) => Tab(
                      icon: Icon(f.icon, size: 20),
                      text: context.tr(f.labelKey),
                      // Tab text is already non-selectable usually, but let's be explicit if we used MyText
                      // Here Tab() takes a String text, so it's managed by TabBar.
                    ),
                  )
                  .toList(),
            ),
          ),
          Expanded(
            child: BlocBuilder<CompetitionsCubit, CompetitionsState>(
              builder: (context, state) {
                if (state is CompetitionsLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (state is CompetitionsError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: theme.colorScheme.error,
                        ),
                        const SizedBox(height: 16),
                        const MyText(LocaleKeys.error),
                        const SizedBox(height: 8),
                        MyText(state.message, style: theme.textTheme.bodySmall),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _loadCompetitions,
                          icon: const Icon(Icons.refresh),
                          label: const MyText(LocaleKeys.retry),
                        ),
                      ],
                    ),
                  );
                }

                if (state is CompetitionsLoaded) {
                  final competitions = state.competitions;

                  if (competitions.isEmpty) {
                    return _buildEmptyState(theme);
                  }

                  return RefreshIndicator(
                    onRefresh: () async => _loadCompetitions(),
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: competitions.length,
                      itemBuilder: (context, index) {
                        final competition = competitions[index];
                        return _CompetitionManagementCard(
                          competition: competition,
                          onTap: () => _goToDetail(competition.id),
                          onEdit: () => _goToEdit(competition.id),
                          onManage: () => _goToManagement(competition.id),
                        );
                      },
                    ),
                  );
                }

                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    String messageKey;
    IconData icon;

    switch (_statusFilter) {
      case 'draft':
        messageKey = LocaleKeys.noDraftCompetitions;
        icon = Icons.edit_note;
        break;
      case 'upcoming':
        messageKey = LocaleKeys.noUpcomingCompetitions;
        icon = Icons.event;
        break;
      case 'live':
        messageKey = LocaleKeys.noLiveCompetitions;
        icon = Icons.live_tv;
        break;
      case 'completed':
        messageKey = LocaleKeys.noCompletedCompetitions;
        icon = Icons.check_circle;
        break;
      default:
        messageKey = LocaleKeys.noCompetitionsCreated;
        icon = Icons.emoji_events_outlined;
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 80, color: theme.colorScheme.outline),
          const SizedBox(height: 24),
          MyText(messageKey, textAlign: TextAlign.center),
          const SizedBox(height: 24),
          if (_statusFilter == 'all')
            ElevatedButton.icon(
              onPressed: _goToCreate,
              icon: const Icon(Icons.add),
              label: const MyText(LocaleKeys.createFirstCompetition),
            ),
        ],
      ),
    );
  }

  void _goToCreate() {
    NavigationService().push(context, CompetitionRoutes.competitionCreateNav);
  }

  void _goToDetail(String id) {
    NavigationService().push(
      context,
      CompetitionRoutes.getCompetitionDetail(id),
    );
  }

  void _goToEdit(String id) {
    NavigationService().push(context, CompetitionRoutes.competitionEditNav(id));
  }

  void _goToManagement(String id) {
    // Go to detail page and switch to management tab
    NavigationService().push(
      context,
      '${CompetitionRoutes.competitionDetail.replaceAll(':id', id)}?tab=management',
    );
  }
}

class _FilterOption {
  final String key; // Used for filtering logic
  final String labelKey; // Used for translation
  final IconData icon;

  const _FilterOption({
    required this.key,
    required this.labelKey,
    required this.icon,
  });
}

class _CompetitionManagementCard extends StatelessWidget {
  final Competition competition;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onManage;

  const _CompetitionManagementCard({
    required this.competition,
    required this.onTap,
    required this.onEdit,
    required this.onManage,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final registeredCount = competition.registeredAthleteIds.length;
    final maxParticipants = competition.maxParticipants;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        MyText(
                          competition.title,
                          istitle: true,
                       
                          selectable: false,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        MyText(
                          competition.discipline ??
                              context.tr(LocaleKeys.noDiscipline),
                          selectable: false,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.outline,
                          ),
                        ),
                      ],
                    ),
                  ),
                  CompetitionStatusBadge(
                    status: competition.status,
                    compact: true,
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Stats row
              Row(
                children: [
                  _StatChip(
                    icon: Icons.people,
                    label: maxParticipants > 0
                        ? '$registeredCount / $maxParticipants'
                        : '$registeredCount',
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  _StatChip(
                    icon: Icons.gavel,
                    label: '${competition.judgeIds.length}',
                    color: theme.colorScheme.secondary,
                  ),
                  const SizedBox(width: 8),
                  _StatChip(
                    icon: Icons.calendar_today,
                    label: _formatDate(competition.startDate),
                    color: theme.colorScheme.tertiary,
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Actions row
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit, size: 18),
                    label: const MyText(LocaleKeys.edit),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    onPressed: onManage,
                    icon: const Icon(Icons.settings, size: 18),
                    label: const MyText(LocaleKeys.manageCompetition),
                  ),
                ],
              ),

              // Pending approvals indicator
              if (competition.requiresApproval) ...[
                const Divider(height: 24),
                Row(
                  children: [
                    Icon(
                      Icons.pending_actions,
                      size: 16,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    MyText(
                      LocaleKeys.requiresParticipantApproval,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ],
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

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _StatChip({
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
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          MyText(
            label,
            selectable: false,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
