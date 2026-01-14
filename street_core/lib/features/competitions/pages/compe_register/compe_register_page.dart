import 'package:flutter/material.dart';
import 'package:street_core/core/lang/locale_keys.dart';
import '../../../../core/widgets/my_text.dart';
import '../../models/competition.dart';

/// Sheet de registro con información detallada
class CompetitionRegisterSheet extends StatelessWidget {
  final Competition competition;
  final VoidCallback onConfirm;

  const CompetitionRegisterSheet({
    super.key,
    required this.competition,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Título
          Row(
            children: [
              Icon(Icons.how_to_reg, color: theme.colorScheme.primary),
              const SizedBox(width: 12),
              Expanded(
                child: MyText(
                  LocaleKeys.registerToCompetition,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            competition.title,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),

          const SizedBox(height: 24),

          // Info cards
          _buildInfoCard(
            context,
            icon: Icons.calendar_today,
            label: LocaleKeys.start,
            value: _formatDate(competition.startDate),
          ),
          const SizedBox(height: 12),

          if (competition.venue != null || competition.city != null)
            _buildInfoCard(
              context,
              icon: Icons.place,
              label: LocaleKeys.venue,
              value: competition.venue ?? competition.city ?? '',
            ),

          if (competition.entryFee != null) ...[
            const SizedBox(height: 12),
            _buildInfoCard(
              context,
              icon: Icons.attach_money,
              label: LocaleKeys.entryFee,
              value:
                  '${competition.entryFee!.toStringAsFixed(2)} ${competition.currency ?? 'USD'}',
              highlighted: true,
            ),
          ],

          const SizedBox(height: 12),
          _buildInfoCard(
            context,
            icon: Icons.people,
            label: LocaleKeys.participants,
            value:
                '${competition.currentParticipants} / ${competition.maxParticipants}',
          ),

          // Nota de aprobación
          if (competition.requiresApproval) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.tertiaryContainer.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: theme.colorScheme.tertiary.withOpacity(0.5),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 20,
                    color: theme.colorScheme.tertiary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: MyText(
                      LocaleKeys.requiresApprovalHint,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onTertiaryContainer,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 24),

          // Botones
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const MyText(LocaleKeys.cancel),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: FilledButton.icon(
                  onPressed: onConfirm,
                  icon: const Icon(Icons.check),
                  label: const MyText(LocaleKeys.confirmRegister),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    bool highlighted = false,
  }) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: highlighted
            ? theme.colorScheme.primaryContainer.withOpacity(0.3)
            : theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: highlighted
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                MyText(
                  label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: highlighted ? FontWeight.bold : null,
                    color: highlighted
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
