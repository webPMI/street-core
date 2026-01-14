import 'package:flutter/material.dart';
import '../../../../../core/widgets/my_text.dart';
import '../../../../../core/helpers/responsive/responsive.dart';
import '../../../../../core/lang/locale_keys.dart';

/// Model for competition statistics
class CompetitionStats {
  final int totalActive;
  final int totalParticipants;
  final int liveNow;
  final int upcoming;

  const CompetitionStats({
    required this.totalActive,
    required this.totalParticipants,
    required this.liveNow,
    required this.upcoming,
  });
}

/// Section displaying general statistics about competitions
class StatsSection extends StatelessWidget {
  final CompetitionStats? stats;
  final bool isLoading;

  const StatsSection({
    super.key,
    this.stats,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final horizontalPadding = context.responsive(
      mobile: 16.0,
      tablet: 24.0,
      desktop: 32.0,
    );

    final iconSize = context.responsive(
      mobile: 22.0,
      tablet: 24.0,
      desktop: 26.0,
    );

    // Responsive grid columns
    final crossAxisCount = context.responsive(
      mobile: 2,
      tablet: 4,
      desktop: 4,
    );

    // Responsive aspect ratio
    final childAspectRatio = context.responsive(
      mobile: 1.8,
      tablet: 1.5,
      desktop: 1.6,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: horizontalPadding,
            vertical: 8,
          ),
          child: Row(
            children: [
              Icon(
                Icons.analytics,
                color: theme.colorScheme.tertiary,
                size: iconSize,
              ),
              SizedBox(width: context.spacing),
              Flexible(
                child: MyText(
                  LocaleKeys.competitionsStatistics,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: context.spacing),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
          child: isLoading
              ? Center(
                  child: Padding(
                    padding: EdgeInsets.all(context.spacing * 3),
                    child: const CircularProgressIndicator(),
                  ),
                )
              : stats == null
                  ? _buildEmptyState(theme, context)
                  : GridView.count(
                      crossAxisCount: crossAxisCount,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      childAspectRatio: childAspectRatio,
                      crossAxisSpacing: context.spacing,
                      mainAxisSpacing: context.spacing,
                      children: [
                        _StatCard(
                          icon: Icons.emoji_events,
                          label: LocaleKeys.competitionsStatsActive,
                          value: '${stats!.totalActive}',
                          color: theme.colorScheme.primary,
                        ),
                        _StatCard(
                          icon: Icons.people,
                          label: LocaleKeys.competitionsStatsParticipants,
                          value: '${stats!.totalParticipants}',
                          color: theme.colorScheme.secondary,
                        ),
                        _StatCard(
                          icon: Icons.live_tv,
                          label: LocaleKeys.competitionsStatsLive,
                          value: '${stats!.liveNow}',
                          color: Colors.red,
                        ),
                        _StatCard(
                          icon: Icons.event,
                          label: LocaleKeys.competitionsStatsUpcoming,
                          value: '${stats!.upcoming}',
                          color: Colors.orange,
                        ),
                      ],
                    ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(ThemeData theme, BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(context.spacing * 3),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.analytics_outlined,
              size: context.responsive(mobile: 40.0, tablet: 48.0, desktop: 56.0),
              color: theme.colorScheme.outline,
            ),
            SizedBox(height: context.spacing * 2),
            MyText(
              LocaleKeys.competitionsStatsUnavailable,
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

    final iconSize = context.responsive(
      mobile: 24.0,
      tablet: 28.0,
      desktop: 32.0,
    );

    final padding = context.responsive(
      mobile: 12.0,
      tablet: 14.0,
      desktop: 16.0,
    );

    final borderRadius = context.responsive(
      mobile: 10.0,
      tablet: 12.0,
      desktop: 14.0,
    );

    final valueFontSize = context.responsive(
      mobile: 20.0,
      tablet: 22.0,
      desktop: 24.0,
    );

    return Container(
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(borderRadius),
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
            size: iconSize,
            color: color,
          ),
          SizedBox(height: context.spacing * 0.75),
          Text(
            value,
            style: theme.textTheme.headlineSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: valueFontSize,
            ),
          ),
          SizedBox(height: context.spacing * 0.5),
          MyText(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
