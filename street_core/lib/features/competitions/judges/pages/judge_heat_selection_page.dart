import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:street_core/core/di/injection.dart';
import 'package:street_core/core/helpers/snackbar_helper.dart';
import 'package:street_core/core/lang/locale_keys.dart';
import 'package:street_core/core/widgets/my_text.dart';
import 'package:street_core/features/competitions/models/heat_model.dart';
import 'package:street_core/features/competitions/judges/bloc/judge_score_cubit.dart';
import 'package:street_core/features/competitions/judges/bloc/judge_score_state.dart';
import 'package:street_core/features/competitions/judges/pages/judge_scoring_page.dart';

/// Página de selección de heats para jueces
///
/// Muestra una lista de heats disponibles para puntuar.
/// Los heats completados están bloqueados, los activos resaltados.
class JudgeHeatSelectionPage extends StatelessWidget {
  const JudgeHeatSelectionPage({
    super.key,
    required this.competitionId,
    required this.roundId,
    required this.categoryId,
    required this.judgeId,
  });

  final String competitionId;
  final String roundId;
  final String categoryId;
  final String judgeId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<JudgeScoreCubit>()
        ..loadRoundHeats(competitionId, roundId),
      child: _JudgeHeatSelectionView(
        competitionId: competitionId,
        roundId: roundId,
        categoryId: categoryId,
        judgeId: judgeId,
      ),
    );
  }
}

class _JudgeHeatSelectionView extends StatelessWidget {
  const _JudgeHeatSelectionView({
    required this.competitionId,
    required this.roundId,
    required this.categoryId,
    required this.judgeId,
  });

  final String competitionId;
  final String roundId;
  final String categoryId;
  final String judgeId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.grid_view_rounded, size: 24),
            const SizedBox(width: 8),
            const MyText(LocaleKeys.selectHeat),
          ],
        ),
      ),
      body: BlocConsumer<JudgeScoreCubit, JudgeScoreState>(
        listener: (context, state) {
          // Mostrar errores con código traducido automáticamente
          if (state is HeatError) {
            SnackBarHelper.showBackendError(
              context,
              errorCode: state.code,
              fallbackMessage: state.message,
            );
          }

          // Advertencia de heat completado
          if (state is HeatCompletedWarning) {
            SnackBarHelper.showWarning(context, state.message);
          }

          // Navegar a página de scoring cuando se selecciona un heat
          if (state is HeatSelected) {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => JudgeScoringPage(
                  competitionId: competitionId,
                  categoryId: categoryId,
                  heat: state.heat,
                  judgeId: judgeId,
                ),
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is HeatsLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is HeatsLoaded) {
            final heats = state.heats;

            if (heats.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.grid_off,
                      size: 64,
                      color: theme.colorScheme.outline,
                    ),
                    const SizedBox(height: 16),
                    MyText(
                      LocaleKeys.noHeatsAvailable,
                      color: theme.textTheme.bodySmall?.color,
                    ),
                  ],
                ),
              );
            }

            return Column(
              children: [
                // Progress header
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer
                        .withOpacity(0.3),
                    border: Border(
                      bottom: BorderSide(
                        color: theme.dividerColor,
                        width: 1,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.analytics_outlined,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                             MyText(
                              LocaleKeys.roundProgress,
                              fontSize: 12,
                              color: theme.textTheme.bodySmall?.color,
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Expanded(
                                  child: LinearProgressIndicator(
                                    value: state.completionPercentage / 100,
                                    backgroundColor:
                                        theme.colorScheme.surfaceContainerHighest,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      theme.colorScheme.primary,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                MyText(
                                  '${state.completedCount}/${state.totalCount}',
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Heats list
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () async {
                      context.read<JudgeScoreCubit>().loadRoundHeats(
                            competitionId,
                            roundId,
                          );
                    },
                    child: ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: heats.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final heat = heats[index];
                        return _buildHeatCard(context, heat, theme);
                      },
                    ),
                  ),
                ),
              ],
            );
          }

          // Initial or error state
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
                 MyText(
                  LocaleKeys.errorLoadingHeats,
                  color: theme.colorScheme.error,
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => context
                      .read<JudgeScoreCubit>()
                      .loadRoundHeats(competitionId, roundId),
                  icon: const Icon(Icons.refresh),
                  label: const MyText(LocaleKeys.retry),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeatCard(BuildContext context, Heat heat, ThemeData theme) {
    final bool isCompleted = heat.isCompleted;
    final bool isActive = heat.isActive;

    // Color scheme based on status
    Color backgroundColor;
    Color borderColor;
    Color iconColor;
    IconData statusIcon;

    if (isCompleted) {
      backgroundColor = theme.colorScheme.surfaceContainerHighest;
      borderColor = theme.colorScheme.outline.withOpacity(0.3);
      iconColor = theme.colorScheme.outline;
      statusIcon = Icons.lock_outline;
    } else if (isActive) {
      backgroundColor = theme.colorScheme.primaryContainer.withOpacity(0.5);
      borderColor = theme.colorScheme.primary;
      iconColor = theme.colorScheme.primary;
      statusIcon = Icons.play_circle_outline;
    } else {
      backgroundColor = theme.colorScheme.surface;
      borderColor = theme.colorScheme.outline.withOpacity(0.5);
      iconColor = theme.colorScheme.secondary;
      statusIcon = Icons.pending_outlined;
    }

    return Card(
      elevation: isActive ? 4 : 2,
      color: backgroundColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: borderColor,
          width: isActive ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: isCompleted
            ? null
            : () {
                // Select heat and navigate to scoring page
                context.read<JudgeScoreCubit>().selectHeat(
                      heat,
                      competitionId,
                      categoryId,
                    );
              },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                children: [
                  // Status icon
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: iconColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      statusIcon,
                      color: iconColor,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Heat name and mode
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        MyText(
                          heat.name,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isCompleted
                              ? theme.textTheme.bodySmall?.color
                              : null,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              heat.isSequential
                                  ? Icons.arrow_forward
                                  : Icons.groups,
                              size: 14,
                              color: theme.textTheme.bodySmall?.color,
                            ),
                            const SizedBox(width: 4),
                            MyText(
                              heat.modeDisplay,
                              fontSize: 13,
                              color: theme.textTheme.bodySmall?.color,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Status badge
                  if (isCompleted)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.outline.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.lock,
                            size: 14,
                            color: theme.colorScheme.outline,
                          ),
                          const SizedBox(width: 4),
                           MyText(
                            LocaleKeys.completed,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.outline,
                          ),
                        ],
                      ),
                    )
                  else if (isActive)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.circle,
                            size: 10,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 6),
                           MyText(
                            LocaleKeys.active,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ],
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 16),

              // Athletes count
              Row(
                children: [
                  Icon(
                    Icons.people_outline,
                    size: 16,
                    color: theme.textTheme.bodySmall?.color,
                  ),
                  const SizedBox(width: 8),
                  MyText(
                    LocaleKeys.athletesCount,
                    args: {'count': heat.athleteCount.toString()},
                    fontSize: 14,
                    color: theme.textTheme.bodySmall?.color,
                  ),
                  if (heat.maxAthletes != null) ...[
                    MyText(
                      ' / ${heat.maxAthletes}',
                      noTranslation: true,
                      fontSize: 14,
                      color: theme.textTheme.bodySmall?.color,
                    ),
                  ],
                ],
              ),

              // Timing info (if available)
              if (heat.startTime != null || heat.duration != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 16,
                      color: theme.textTheme.bodySmall?.color,
                    ),
                    const SizedBox(width: 8),
                    if (heat.duration != null)
                      MyText(
                        LocaleKeys.durationMin,
                        args: {'duration': heat.duration.toString()},
                        fontSize: 14,
                        color: theme.textTheme.bodySmall?.color,
                      ),
                  ],
                ),
              ],

              // Call to action (only for non-completed heats)
              if (!isCompleted) ...[
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      context.read<JudgeScoreCubit>().selectHeat(
                            heat,
                            competitionId,
                            categoryId,
                          );
                    },
                    icon: Icon(
                      isActive ? Icons.play_arrow : Icons.score,
                      size: 18,
                    ),
                    label: MyText(
                      isActive ? LocaleKeys.startScoring : LocaleKeys.viewHeat,
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      backgroundColor: isActive
                          ? theme.colorScheme.primary
                          : theme.colorScheme.secondary,
                      foregroundColor: isActive
                          ? theme.colorScheme.onPrimary
                          : theme.colorScheme.onSecondary,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
