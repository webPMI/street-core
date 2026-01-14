/// Widget de Sección de Lista de Jueces
/// Muestra la lista de jueces asignados a una competición.
/// Siguiendo la arquitectura Monolith-by-Features (ADR-005).

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/lang/context_tr.dart';
import '../../../core/lang/locale_keys.dart';
import '../../../core/widgets/help_guide/bloc/guide_cubit.dart';
import '../../../core/widgets/help_guide/widgets/guide_overlay.dart';
import '../bloc/competitions_cubit.dart';
import '../bloc/competitions_state.dart';
import '../judges/widgets/invite_judge_dialog.dart';
import '../models/competition.dart';

class JudgesListSection extends StatefulWidget {
  final String competitionId;
  final bool canManage;

  const JudgesListSection({
    super.key,
    required this.competitionId,
    this.canManage = false,
  });

  @override
  State<JudgesListSection> createState() => _JudgesListSectionState();
}

class _JudgesListSectionState extends State<JudgesListSection> {
  @override
  void initState() {
    super.initState();

    // Load guide for judges invitation page
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<GuideCubit>().loadGuideForRoute('/competitions/judges');
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CompetitionsCubit, CompetitionsState>(
      builder: (context, state) {
        if (state is CompetitionDetailLoaded) {
          final competition = state.competition;
          return _buildContent(context, competition);
        }

        if (state is CompetitionsLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        return _buildEmptyState(context);
      },
    );
  }

  Widget _buildContent(BuildContext context, Competition competition) {
    final judgeIds = competition.judgeIds;
    final requiredJudges = competition.requiredJudges;
    final currentJudges = judgeIds.length;

    if (judgeIds.isEmpty) {
      return _buildEmptyState(
        context,
        competition: competition,
        requiredJudges: requiredJudges,
      );
    }

    return Stack(
      children: [
        CustomScrollView(
          slivers: [
            // Header with stats
            SliverToBoxAdapter(
              child: _buildHeader(context, currentJudges, requiredJudges),
            ),

            // Judges list
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text(
                  context.tr(LocaleKeys.assignedJudges),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) =>
                    _buildJudgeCard(context, judgeIds[index], index + 1),
                childCount: judgeIds.length,
              ),
            ),

            // Scoring criteria info
            SliverToBoxAdapter(child: _buildScoringInfo(context, competition)),

            // Bottom padding
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
        if (widget.canManage && currentJudges < requiredJudges)
          Positioned(
            bottom: 16,
            right: 16,
            child: FloatingActionButton.extended(
              heroTag: LocaleKeys.inviteJudgeFab,
              onPressed: () => showInviteJudgeDialog(context, competition),
              icon: const Icon(Icons.person_add),
              label: Text(context.tr(LocaleKeys.inviteJudge)),
            ),
          ),

        // Help guide widgets
        const AutoGuide(),
        const GuideOverlay(),
      ],
    );
  }

  Widget _buildHeader(BuildContext context, int current, int required) {
    final isComplete = current >= required;
    final percentage = required > 0
        ? (current / required).clamp(0.0, 1.0)
        : 0.0;

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.gavel,
                      color: isComplete ? Colors.green : Colors.orange,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      context.tr(LocaleKeys.judgesPanel),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: isComplete
                        ? Colors.green.withAlpha(30)
                        : Colors.orange.withAlpha(30),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$current / $required',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isComplete ? Colors.green : Colors.orange,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: percentage,
                minHeight: 8,
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(
                  isComplete ? Colors.green : Colors.orange,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isComplete
                  ? context.tr(LocaleKeys.judgesPanelComplete)
                  : context.tr(
                      LocaleKeys.judgesMissing,
                      args: {'count': '${required - current}'},
                    ),
              style: TextStyle(
                fontSize: 13,
                color: isComplete ? Colors.green[700] : Colors.orange[700],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(
    BuildContext context, {
    Competition? competition,
    int requiredJudges = 3,
  }) {
    return Stack(
      children: [
        Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.gavel, size: 80, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  context.tr(LocaleKeys.noJudges),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.grey[600],
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${context.tr(LocaleKeys.requiredJudges)}: $requiredJudges',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.grey[500]),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orange.withAlpha(20),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange.withAlpha(50)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.warning_amber, color: Colors.orange[700]),
                      const SizedBox(width: 8),
                      Text(
                        context.tr(LocaleKeys.judgesNeededToStart),
                        style: TextStyle(color: Colors.orange[700]),
                      ),
                    ],
                  ),
                ),
                if (widget.canManage && competition != null) ...[
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => showInviteJudgeDialog(context, competition),
                    icon: const Icon(Icons.person_add),
                    label: Text(context.tr(LocaleKeys.inviteJudge)),
                  ),
                ],
              ],
            ),
          ),
        ),

        // Help guide widgets
        const AutoGuide(),
        const GuideOverlay(),
      ],
    );
  }

  Widget _buildJudgeCard(BuildContext context, String judgeId, int number) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).primaryColor,
          child: Text(
            '#$number',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          '${context.tr(LocaleKeys.judge)} #$number',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.green.withAlpha(30),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_circle, size: 16, color: Colors.green[700]),
              const SizedBox(width: 4),
              Text(
                context.tr(LocaleKeys.assigned),
                style: TextStyle(fontSize: 12, color: Colors.green[700]),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScoringInfo(BuildContext context, Competition competition) {
    final criteria = competition.scoringCriteria;

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.score, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text(
                  context.tr(LocaleKeys.scoringSystem),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildInfoRow(
              context.tr(LocaleKeys.type),
              _getScoringTypeName(context, criteria.type),
            ),
            _buildInfoRow(
              context.tr(LocaleKeys.range),
              '${criteria.minScore.toInt()} - ${criteria.maxScore.toInt()} ${context.tr(LocaleKeys.points)}',
            ),
            if (competition.dropHighestScore ||
                competition.dropLowestScore) ...[
              const Divider(height: 16),
              if (competition.dropHighestScore)
                _buildInfoRow(
                  context.tr(LocaleKeys.adjustment),
                  context.tr(LocaleKeys.dropHighestScore),
                ),
              if (competition.dropLowestScore)
                _buildInfoRow(
                  context.tr(LocaleKeys.adjustment),
                  context.tr(LocaleKeys.dropLowestScore),
                ),
            ],
            if (criteria.criteria != null && criteria.criteria!.isNotEmpty) ...[
              const Divider(height: 16),
              Text(
                context.tr(LocaleKeys.evaluationCriteria),
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 8),
              ...criteria.criteria!.map(
                (c) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      Icon(Icons.check, size: 16, color: Colors.green),
                      const SizedBox(width: 8),
                      Expanded(child: Text(c.name)),
                      Text(
                        '${(c.weight * 100).toInt()}%',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600])),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  String _getScoringTypeName(BuildContext context, String type) {
    switch (type.toLowerCase()) {
      case 'points':
        return context.tr(LocaleKeys.scoringTypePoints);
      case 'time':
        return context.tr(LocaleKeys.scoringTypeTime);
      case 'average':
        return context.tr(LocaleKeys.scoringTypeAverage);
      case 'sum':
        return context.tr(LocaleKeys.scoringTypeSum);
      case 'weighted_average':
        return context.tr(LocaleKeys.scoringTypeWeightedAverage);
      default:
        return type;
    }
  }
}
