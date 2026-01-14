import 'package:street_core/core/lang/locale_keys.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/widgets/my_text.dart';
import '../../models/judge_score_model.dart';
import '../../judges/bloc/judge_score_cubit.dart';
import '../../judges/bloc/judge_score_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CategoryRankingPage extends StatelessWidget {
  const CategoryRankingPage({
    super.key,
    required this.competitionId,
    required this.categoryId,
  });
  final String competitionId;
  final String categoryId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<JudgeScoreCubit>()
        ..getCategoryRanking(competitionId, categoryId),
      child: _CategoryRankingView(
        competitionId: competitionId,
        categoryId: categoryId,
      ),
    );
  }
}

class _CategoryRankingView extends StatelessWidget {
  const _CategoryRankingView({
    required this.competitionId,
    required this.categoryId,
  });
  final String competitionId;
  final String categoryId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.leaderboard),
            const SizedBox(width: 8),
            const MyText('category_ranking', istitle: true),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context
                .read<JudgeScoreCubit>()
                .getCategoryRanking(competitionId, categoryId),
          ),
        ],
      ),
      body: BlocBuilder<JudgeScoreCubit, JudgeScoreState>(
        builder: (context, state) {
          if (state is JudgeScoreLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is JudgeScoreError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: theme.colorScheme.error,
                  ),
                  const SizedBox(height: 16),
                  MyText(state.message, color: theme.colorScheme.error),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => context
                        .read<JudgeScoreCubit>()
                        .getCategoryRanking(competitionId, categoryId),
                    child: MyText('retry'),
                  ),
                ],
              ),
            );
          }

          if (state is JudgeScoreRankingLoaded) {
            final rankings = state.rankings;

            if (rankings.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.leaderboard,
                      size: 64,
                      color: theme.colorScheme.outline,
                    ),
                    const SizedBox(height: 16),
                    MyText(LocaleKeys.noRankingData,
                      color: theme.textTheme.bodySmall?.color,
                    ),
                  ],
                ),
              );
            }

            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Podium (Top 3) if available
                  if (rankings.length >= 3)
                    _buildPodium(context, rankings, theme),

                  const SizedBox(height: 24),

                  // Full rankings list
                  ...rankings.map((CategoryRankingEntry entry) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _buildRankingCard(context, entry, theme),
                    );
                  }),
                ],
              ),
            );
          }

          return Center(child: MyText(LocaleKeys.noDataAvailable));
        },
      ),
    );
  }

  Widget _buildPodium(
    BuildContext context,
    List<CategoryRankingEntry> rankings,
    ThemeData theme,
  ) {
    // Only show podium if we have top 3
    if (rankings.length < 3) return const SizedBox.shrink();

    final first = rankings.firstWhere(
      (e) => e.position == 1,
      orElse: () => rankings[0],
    );
    final second = rankings.firstWhere(
      (e) => e.position == 2,
      orElse: () => rankings[1],
    );
    final third = rankings.firstWhere(
      (e) => e.position == 3,
      orElse: () => rankings[2],
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            MyText('top_3', istitle: true, fontSize: 20),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Second place
                _buildPodiumPlace(context, second, 110, Colors.grey, theme),
                const SizedBox(width: 12),
                // First place
                _buildPodiumPlace(context, first, 140, Colors.amber, theme),
                const SizedBox(width: 12),
                // Third place
                _buildPodiumPlace(context, third, 90, Colors.brown, theme),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPodiumPlace(
    BuildContext context,
    CategoryRankingEntry entry,
    double height,
    Color color,
    ThemeData theme,
  ) {
    return Column(
      children: [
        CircleAvatar(
          radius: 32,
          backgroundColor: color.withValues(alpha: 0.2),
          child: MyText(
            entry.participantNumber ??
                entry.participantName.substring(0, 1).toUpperCase(),
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color.withValues(alpha: 0.9),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: 90,
          child: MyText(
            entry.participantName,
            fontSize: 13,
            fontWeight: FontWeight.bold,
            textAlign: TextAlign.center,
            maxLines: 2,
          ),
        ),
        const SizedBox(height: 4),
        MyText(
          entry.averageScore.toStringAsFixed(2),
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: theme.colorScheme.primary,
        ),
        const SizedBox(height: 8),
        Container(
          height: height,
          width: 90,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.3),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
          ),
          child: Center(
            child: MyText(
              entry.medalIcon.isNotEmpty
                  ? entry.medalIcon
                  : '#${entry.position}',
              fontSize: 32,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRankingCard(
    BuildContext context,
    CategoryRankingEntry entry,
    ThemeData theme,
  ) {
    final isTopThree = entry.position <= 3;

    return Card(
      elevation: isTopThree ? 4 : 2,
      color: isTopThree
          ? theme.colorScheme.primaryContainer.withValues(alpha: 0.3)
          : null,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Position badge
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _getPositionColor(entry.position, theme),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: MyText(
                      entry.medalIcon.isNotEmpty
                          ? entry.medalIcon
                          : '${entry.position}',
                      fontSize: entry.medalIcon.isNotEmpty ? 20 : 16,
                      fontWeight: FontWeight.bold,
                      color: entry.position <= 3
                          ? Colors.white
                          : theme.textTheme.bodyLarge?.color,
                    ),
                  ),
                ),
                const SizedBox(width: 16),

                // Participant info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      MyText(
                        entry.participantName,
                        istitle: true,
                        fontSize: 16,
                      ),
                      if (entry.participantNumber != null)
                        MyText(
                          '#${entry.participantNumber}',
                          fontSize: 13,
                          color: theme.textTheme.bodySmall?.color,
                        ),
                    ],
                  ),
                ),

                // Average score
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    MyText(
                      entry.averageScore.toStringAsFixed(2),
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                    MyText(LocaleKeys.averageScore,
                      fontSize: 11,
                      color: theme.textTheme.bodySmall?.color,
                    ),
                  ],
                ),
              ],
            ),

            // Scoring progress
            if (entry.totalJudges > 0) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    entry.isComplete ? Icons.check_circle : Icons.pending,
                    size: 16,
                    color: entry.isComplete ? Colors.green : Colors.orange,
                  ),
                  const SizedBox(width: 6),
                  MyText(
                    '${entry.scoresSubmitted}/${entry.totalJudges} ${LocaleKeys.judgesScored}',
                    fontSize: 12,
                    color: theme.textTheme.bodySmall?.color,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: LinearProgressIndicator(
                      value: entry.totalJudges > 0
                          ? entry.scoresSubmitted / entry.totalJudges
                          : 0,
                      backgroundColor:
                          theme.colorScheme.surfaceContainerHighest,
                      valueColor: AlwaysStoppedAnimation(
                        entry.isComplete ? Colors.green : Colors.orange,
                      ),
                    ),
                  ),
                ],
              ),
            ],

            // Criteria scores breakdown
            if (entry.criteriaAverages.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 8),
              MyText(LocaleKeys.scoringCriteria,
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: theme.textTheme.bodySmall?.color,
              ),
              const SizedBox(height: 8),
              ...entry.criteriaAverages.entries.map((criteriaEntry) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      MyText(
                        criteriaEntry.key,
                        fontSize: 12,
                        color: theme.textTheme.bodySmall?.color,
                      ),
                      MyText(
                        criteriaEntry.value.toStringAsFixed(2),
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ],
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }

  Color _getPositionColor(int position, ThemeData theme) {
    switch (position) {
      case 1:
        return Colors.amber;
      case 2:
        return Colors.grey.shade400;
      case 3:
        return Colors.brown.shade400;
      default:
        return theme.colorScheme.surfaceContainerHighest;
    }
  }
}
