import 'package:flutter/material.dart';
import '../../../../../core/widgets/my_text.dart';
import '../../../../../core/router/navigation_service.dart';
import '../../../models/competition.dart';
import '../../../widgets/unified_competition_card.dart';
import '../../../competition_routes.dart';
import '../../../../../core/lang/locale_keys.dart';

/// Section displaying featured/highlighted competitions (live or upcoming)
class FeaturedCompetitionsSection extends StatelessWidget {
  final List<Competition> competitions;
  final bool isLoading;

  const FeaturedCompetitionsSection({
    super.key,
    required this.competitions,
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Icon(
                      Icons.star,
                      color: theme.colorScheme.primary,
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: MyText(
                        LocaleKeys.competitionsFeatured,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: () {
                  NavigationService().push(
                    context,
                    CompetitionRoutes.competitionsList,
                  );
                },
                child: MyText(LocaleKeys.competitionsViewAll),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        if (isLoading)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(),
            ),
          )
        else if (competitions.isEmpty)
          _buildEmptyState(theme)
        else
          SizedBox(
            height: 280,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: competitions.length,
              itemBuilder: (context, index) {
                final competition = competitions[index];
                return Container(
                  width: 300,
                  margin: const EdgeInsets.only(right: 16),
                  child: UnifiedCompetitionCard(
                    competition: competition,
                    layout: CompetitionCardLayout.grid,
                  ),
                );
              },
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
              Icons.event_busy,
              size: 48,
              color: theme.colorScheme.outline,
            ),
            const SizedBox(height: 16),
            MyText(
              LocaleKeys.competitionsNoFeatured,
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
