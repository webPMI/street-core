import 'package:street_core/core/lang/context_tr.dart';
import 'package:street_core/core/lang/locale_keys.dart';

import '../../../../core/widgets/my_text.dart';
import '../../models/competition_category_model.dart';
import 'package:flutter/material.dart';

/// Widget for displaying category information card
class CategoryInfoCard extends StatelessWidget {
  const CategoryInfoCard({super.key, required this.category});
  final CompetitionCategory category;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.category, color: theme.colorScheme.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: MyText(category.name, istitle: true, fontSize: 24),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (category.description.isNotEmpty) ...[
              MyText(category.description),
              const SizedBox(height: 16),
            ],
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _InfoChip(
                  icon: Icons.signal_cellular_alt,
                  label: LocaleKeys.skillLevel,
                  value: _getSkillLevelTranslation(context, category.skillLevel),
                  theme: theme,
                ),
                _InfoChip(
                  icon: Icons.gavel,
                  label: LocaleKeys.maxJudges,
                  value: '${category.judgeCount}/${category.maxJudges}',
                  theme: theme,
                ),
                _InfoChip(
                  icon: Icons.people,
                  label: LocaleKeys.participants,
                  value: '${category.participantCount}',
                  theme: theme,
                ),
                if (category.minAge != null || category.maxAge != null)
                  _InfoChip(
                    icon: Icons.calendar_today,
                    label: LocaleKeys.ageRange,
                    value: category.ageRangeDisplay,
                    theme: theme,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getSkillLevelTranslation(BuildContext context, String skillLevel) {
    switch (skillLevel) {
      case 'beginner':
        return context.tr(LocaleKeys.skillLevelBeginner);
      case 'intermediate':
        return context.tr(LocaleKeys.skillLevelIntermediate);
      case 'advanced':
        return context.tr(LocaleKeys.skillLevelAdvanced);
      case 'pro':
        return context.tr(LocaleKeys.skillLevelPro);
      default:
        return skillLevel;
    }
  }
}

/// Internal widget for info chips
class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.theme,
  });
  final IconData icon;
  final String label;
  final String value;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: theme.colorScheme.primary),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              MyText(
                label,
                fontSize: 11,
                color: theme.textTheme.bodySmall?.color,
              ),
              Text(value,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }
}
