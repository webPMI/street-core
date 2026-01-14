import 'package:flutter/material.dart';
import '../../../../../core/widgets/my_text.dart';
import '../../../../../core/router/navigation_service.dart';
import '../../../competition_routes.dart';
import '../../../../../core/lang/locale_keys.dart';

/// Discipline/Category model for filtering
class DisciplineFilter {
  final String key;
  final String labelKey;
  final IconData icon;
  final Color color;

  const DisciplineFilter({
    required this.key,
    required this.labelKey,
    required this.icon,
    required this.color,
  });
}

/// Section with category/discipline filters for quick navigation
class CategoryFiltersSection extends StatelessWidget {
  const CategoryFiltersSection({super.key});

  // Urban sports disciplines
  static const List<DisciplineFilter> _disciplines = [
    DisciplineFilter(
      key: 'inline',
      labelKey: LocaleKeys.disciplineInline,
      icon: Icons.sports_hockey, // Closest to inline skates
      color: Colors.blue,
    ),
    DisciplineFilter(
      key: 'bmx',
      labelKey: LocaleKeys.bmx,
      icon: Icons.pedal_bike,
      color: Colors.orange,
    ),
    DisciplineFilter(
      key: 'skateboard',
      labelKey: LocaleKeys.skateboarding,
      icon: Icons.skateboarding,
      color: Colors.purple,
    ),
    DisciplineFilter(
      key: 'scooter',
      labelKey: LocaleKeys.scooter,
      icon: Icons.electric_scooter,
      color: Colors.green,
    ),
  ];

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
                Icons.category,
                color: theme.colorScheme.primary,
                size: 24,
              ),
              const SizedBox(width: 8),
              MyText(
                LocaleKeys.competitionsDisciplines,
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
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 2.5,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: _disciplines.length,
            itemBuilder: (context, index) {
              final discipline = _disciplines[index];
              return _DisciplineCard(
                discipline: discipline,
                onTap: () {
                  // Navigate to competitions list with discipline filter
                  NavigationService().push(
                    context,
                    '${CompetitionRoutes.competitionsList}?discipline=${discipline.key}',
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _DisciplineCard extends StatelessWidget {
  final DisciplineFilter discipline;
  final VoidCallback onTap;

  const _DisciplineCard({
    required this.discipline,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              discipline.color.withValues(alpha: 0.2),
              discipline.color.withValues(alpha: 0.1),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: discipline.color.withValues(alpha: 0.4),
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              discipline.icon,
              size: 28,
              color: discipline.color,
            ),
            const SizedBox(width: 12),
            Flexible(
              child: MyText(
                discipline.labelKey,
                style: theme.textTheme.titleSmall?.copyWith(
                  color: discipline.color,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
