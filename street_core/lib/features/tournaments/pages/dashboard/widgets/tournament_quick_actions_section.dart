import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../core/widgets/my_text.dart';
import '../../../../../core/router/navigation_service.dart';
import '../../../../auth/auth.dart';
import '../../../tournament_routes.dart';
import '../../../../../core/lang/locale_keys.dart';

/// Section with quick action buttons for tournament-related tasks
class TournamentQuickActionsSection extends StatelessWidget {
  const TournamentQuickActionsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authState = context.watch<AuthCubit>().state;
    final bool isAuthenticated = authState is AuthAuthenticated;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Icon(
                Icons.bolt,
                color: theme.colorScheme.secondary,
                size: 24,
              ),
              const SizedBox(width: 8),
              MyText(
                LocaleKeys.tournamentsQuickActions,
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
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              if (isAuthenticated) ...[
                _QuickActionCard(
                  icon: Icons.emoji_events_outlined,
                  label: LocaleKeys.tournamentsMyTournaments,
                  color: theme.colorScheme.primary,
                  onTap: () {
                    NavigationService().push(
                      context,
                      TournamentRoutes.myTournamentsNav,
                    );
                  },
                ),
                _QuickActionCard(
                  icon: Icons.add_circle_outline,
                  label: LocaleKeys.tournamentsCreateNew,
                  color: theme.colorScheme.secondary,
                  onTap: () {
                    NavigationService().push(
                      context,
                      TournamentRoutes.tournamentCreateNav,
                    );
                  },
                ),
              ],
              _QuickActionCard(
                icon: Icons.live_tv,
                label: LocaleKeys.tournamentsStatusLive,
                color: Colors.red,
                onTap: () {
                  // Navigate to list with live filter
                  NavigationService().push(
                    context,
                    '${TournamentRoutes.tournaments}?status=live',
                  );
                },
              ),
              _QuickActionCard(
                icon: Icons.event,
                label: LocaleKeys.tournamentsStatusUpcoming,
                color: Colors.orange,
                onTap: () {
                  // Navigate to list with upcoming filter
                  NavigationService().push(
                    context,
                    '${TournamentRoutes.tournaments}?status=upcoming',
                  );
                },
              ),
              _QuickActionCard(
                icon: Icons.check_circle_outline,
                label: LocaleKeys.tournamentsStatusCompleted,
                color: Colors.green,
                onTap: () {
                  // Navigate to list with completed filter
                  NavigationService().push(
                    context,
                    '${TournamentRoutes.tournaments}?status=completed',
                  );
                },
              ),
              _QuickActionCard(
                icon: Icons.view_list,
                label: LocaleKeys.tournamentsViewAll,
                color: theme.colorScheme.tertiary,
                onTap: () {
                  NavigationService().push(
                    context,
                    TournamentRoutes.tournaments,
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

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 160,
        height: 110,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
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
              size: 28,
              color: color,
            ),
            const SizedBox(height: 6),
            Flexible(
              child: MyText(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
