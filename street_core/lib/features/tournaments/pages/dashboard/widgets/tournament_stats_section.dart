import 'package:flutter/material.dart';
import '../../../../../core/widgets/my_text.dart';
import '../../../../../core/lang/locale_keys.dart';

/// Model for tournament statistics
class TournamentStats {
  final int totalActive;
  final int totalAthletes;
  final int liveNow;
  final int upcoming;

  const TournamentStats({
    required this.totalActive,
    required this.totalAthletes,
    required this.liveNow,
    required this.upcoming,
  });
}

/// Section displaying general statistics about tournaments
class TournamentStatsSection extends StatelessWidget {
  final TournamentStats? stats;
  final bool isLoading;

  const TournamentStatsSection({
    super.key,
    this.stats,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Icon(
                Icons.analytics,
                color: theme.colorScheme.tertiary,
                size: 24,
              ),
              const SizedBox(width: 8),
              MyText(
                LocaleKeys.tournamentsStatistics,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: isLoading
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: CircularProgressIndicator(),
                  ),
                )
              : stats == null
                  ? _buildEmptyState(theme)
                  : GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      childAspectRatio: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      children: [
                        _StatCard(
                          icon: Icons.emoji_events,
                          label: LocaleKeys.tournamentsStatsActive,
                          value: '${stats!.totalActive}',
                          color: theme.colorScheme.primary,
                        ),
                        _StatCard(
                          icon: Icons.people,
                          label: LocaleKeys.tournamentsStatsAthletes,
                          value: '${stats!.totalAthletes}',
                          color: theme.colorScheme.secondary,
                        ),
                        _StatCard(
                          icon: Icons.live_tv,
                          label: LocaleKeys.tournamentsStatsLive,
                          value: '${stats!.liveNow}',
                          color: Colors.red,
                        ),
                        _StatCard(
                          icon: Icons.event,
                          label: LocaleKeys.tournamentsStatsUpcoming,
                          value: '${stats!.upcoming}',
                          color: Colors.orange,
                        ),
                      ],
                    ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.analytics_outlined,
              size: 48,
              color: theme.colorScheme.outline,
            ),
            const SizedBox(height: 16),
            MyText(
              LocaleKeys.tournamentsStatsUnavailable,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

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
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 28,
            color: color,
          ),
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
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
          ),
        ],
      ),
    );
  }
}
