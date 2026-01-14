import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:street_core/core/lang/locale_keys.dart';
import '../../../core/lang/context_tr.dart';
import '../models/competition.dart';

/// Competition Timeline Widget
///
/// Displays a visual timeline of competition phases:
/// - Registration Phase
/// - Ongoing/Active Phase
/// - Results/Completed Phase
///
/// Features:
/// - Current phase highlighted
/// - Visual progress indicator
/// - Phase dates and status
class CompetitionTimeline extends StatelessWidget {
  const CompetitionTimeline({
    super.key,
    required this.competition,
    this.onPhaseSelected,
    this.compact = false,
  });

  final Competition competition;
  final Function(CompetitionPhase phase)? onPhaseSelected;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentPhase = _getCurrentPhase();

    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(compact ? 12.0 : 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!compact) ...[
              Text(
                context.tr(LocaleKeys.timelineTitle),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
            ],
            _buildTimeline(context, currentPhase),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeline(BuildContext context, CompetitionPhase currentPhase) {
    final phases = _getPhases();

    return Row(
      children: [
        for (int i = 0; i < phases.length; i++) ...[
          Expanded(
            child: _buildPhaseItem(
              context,
              phases[i],
              isActive: phases[i] == currentPhase,
              isPast: _isPastPhase(phases[i], currentPhase),
            ),
          ),
          if (i < phases.length - 1)
            _buildConnector(
              context,
              isCompleted: _isPastPhase(phases[i], currentPhase),
            ),
        ],
      ],
    );
  }

  Widget _buildPhaseItem(
    BuildContext context,
    CompetitionPhase phase, {
    required bool isActive,
    required bool isPast,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    Color getColor() {
      if (isActive) return colorScheme.primary;
      if (isPast) return colorScheme.secondary;
      return colorScheme.outline;
    }

    return InkWell(
      onTap: onPhaseSelected != null ? () => onPhaseSelected!(phase) : null,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Phase icon/indicator
            Container(
              width: isActive ? 48 : 40,
              height: isActive ? 48 : 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isActive ? getColor() : Colors.transparent,
                border: Border.all(
                  color: getColor(),
                  width: isActive ? 3 : 2,
                ),
              ),
              child: Icon(
                _getPhaseIcon(phase),
                color: isActive ? colorScheme.onPrimary : getColor(),
                size: isActive ? 24 : 20,
              ),
            ),

            const SizedBox(height: 8),

            // Phase label
            Text(
              _getPhaseLabel(context, phase),
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                color: getColor(),
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),

            if (!compact) ...[
              const SizedBox(height: 4),

              // Phase date
              Text(
                _getPhaseDate(phase),
                style: theme.textTheme.bodySmall?.copyWith(
                  fontSize: 10,
                  color: colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],

            if (isActive) ...[
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  context.tr(LocaleKeys.timelineCurrent),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildConnector(BuildContext context, {required bool isCompleted}) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      height: 2,
      width: 24,
      margin: EdgeInsets.only(bottom: compact ? 40 : 60),
      decoration: BoxDecoration(
        color: isCompleted ? colorScheme.secondary : colorScheme.outlineVariant,
        borderRadius: BorderRadius.circular(1),
      ),
    );
  }

  CompetitionPhase _getCurrentPhase() {
    final now = DateTime.now();

    // Check if before start date
    if (now.isBefore(competition.startDate)) {
      return CompetitionPhase.registration;
    }

    // Check if after end date
    if (now.isAfter(competition.endDate)) {
      return CompetitionPhase.completed;
    }

    // Check competition status (string comparison)
    if (competition.status == 'upcoming' ||
        competition.status == 'registration_open') {
      return CompetitionPhase.registration;
    }

    if (competition.status == 'ongoing' || competition.status == 'live') {
      return CompetitionPhase.active;
    }

    if (competition.status == 'completed' || competition.status == 'finished') {
      return CompetitionPhase.completed;
    }

    // Default to registration phase
    return CompetitionPhase.registration;
  }

  List<CompetitionPhase> _getPhases() {
    return [
      CompetitionPhase.registration,
      CompetitionPhase.active,
      CompetitionPhase.completed,
    ];
  }

  bool _isPastPhase(CompetitionPhase phase, CompetitionPhase currentPhase) {
    final phases = _getPhases();
    final phaseIndex = phases.indexOf(phase);
    final currentIndex = phases.indexOf(currentPhase);
    return phaseIndex < currentIndex;
  }

  IconData _getPhaseIcon(CompetitionPhase phase) {
    switch (phase) {
      case CompetitionPhase.registration:
        return Icons.how_to_reg;
      case CompetitionPhase.active:
        return Icons.sports_score;
      case CompetitionPhase.completed:
        return Icons.emoji_events;
    }
  }

  String _getPhaseLabel(BuildContext context, CompetitionPhase phase) {
    switch (phase) {
      case CompetitionPhase.registration:
        return context.tr(LocaleKeys.timelineRegistration);
      case CompetitionPhase.active:
        return context.tr(LocaleKeys.timelineActive);
      case CompetitionPhase.completed:
        return context.tr(LocaleKeys.timelineCompleted);
    }
  }

  String _getPhaseDate(CompetitionPhase phase) {
    final dateFormat = DateFormat('MMM d');

    switch (phase) {
      case CompetitionPhase.registration:
        return dateFormat.format(competition.startDate);

      case CompetitionPhase.active:
        return dateFormat.format(competition.startDate);

      case CompetitionPhase.completed:
        return dateFormat.format(competition.endDate);
    }
  }
}

/// Competition phases for timeline
enum CompetitionPhase {
  registration,
  active,
  completed,
}
