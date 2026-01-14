import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../core/widgets/my_text.dart';
import '../../../../../core/router/navigation_service.dart';
import '../../../../../core/helpers/responsive/responsive.dart';
import '../../../../auth/auth.dart';
import '../../../competition_routes.dart';
import '../../../../../core/lang/locale_keys.dart';

/// Section with quick action buttons for competition-related tasks
class QuickActionsSection extends StatelessWidget {
  const QuickActionsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authState = context.watch<AuthCubit>().state;
    final bool isAuthenticated = authState is AuthAuthenticated;

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
                Icons.bolt,
                color: theme.colorScheme.secondary,
                size: iconSize,
              ),
              SizedBox(width: context.spacing),
              Flexible(
                child: MyText(
                  LocaleKeys.competitionsQuickActions,
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
          child: Wrap(
            spacing: context.spacing,
            runSpacing: context.spacing,
            children: [
              if (isAuthenticated) ...[
                _QuickActionCard(
                  icon: Icons.emoji_events_outlined,
                  label: LocaleKeys.competitionsMyCompetitions,
                  color: theme.colorScheme.primary,
                  onTap: () {
                    NavigationService().go(
                      context,
                      CompetitionRoutes.myCompetitions,
                    );
                  },
                ),
                _QuickActionCard(
                  icon: Icons.add_circle_outline,
                  label: LocaleKeys.competitionsCreateNew,
                  color: theme.colorScheme.secondary,
                  onTap: () {
                    NavigationService().go(
                      context,
                      CompetitionRoutes.competitionCreateNav,
                    );
                  },
                ),
                _QuickActionCard(
                  icon: Icons.gavel,
                  label: LocaleKeys.competitionsJudgeInvitations,
                  color: theme.colorScheme.tertiary,
                  onTap: () {
                    NavigationService().go(
                      context,
                      CompetitionRoutes.myJudgeInvitationsNav,
                    );
                  },
                ),
              ],
              _QuickActionCard(
                icon: Icons.live_tv,
                label: LocaleKeys.competitionsLiveNow,
                color: Colors.red,
                onTap: () {
                  // Navigate to list with live filter
                  NavigationService().push(
                    context,
                    '${CompetitionRoutes.competitionsList}?status=live',
                  );
                },
              ),
              _QuickActionCard(
                icon: Icons.event,
                label: LocaleKeys.competitionsUpcoming,
                color: Colors.orange,
                onTap: () {
                  // Navigate to list with upcoming filter
                  NavigationService().push(
                    context,
                    '${CompetitionRoutes.competitionsList}?status=upcoming',
                  );
                },
              ),
              _QuickActionCard(
                icon: Icons.check_circle_outline,
                label: LocaleKeys.competitionsCompleted,
                color: Colors.green,
                onTap: () {
                  // Navigate to list with completed filter
                  NavigationService().push(
                    context,
                    '${CompetitionRoutes.competitionsList}?status=completed',
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Responsive sizing
    final cardWidth = context.responsive(
      mobile: 145.0,
      tablet: 160.0,
      desktop: 180.0,
    );

    final cardHeight = context.responsive(
      mobile: 100.0,
      tablet: 110.0,
      desktop: 120.0,
    );

    final iconSize = context.responsive(
      mobile: 24.0,
      tablet: 28.0,
      desktop: 32.0,
    );

    final fontSize = context.responsive(
      mobile: 10.0,
      tablet: 11.0,
      desktop: 12.0,
    );

    final borderRadius = context.responsive(
      mobile: 10.0,
      tablet: 12.0,
      desktop: 14.0,
    );

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(borderRadius),
      child: Container(
        width: cardWidth,
        height: cardHeight,
        padding: EdgeInsets.all(context.spacing),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(borderRadius),
          border: Border.all(
            color: color.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: iconSize,
              color: color,
            ),
            SizedBox(height: context.spacing * 0.5),
            Flexible(
              child: MyText(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                  fontSize: fontSize,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
