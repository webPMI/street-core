import 'dart:async'; // CONTINGENCIA 4: Timer for debounce
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:street_core/core/lang/context_tr.dart';
import 'package:street_core/core/lang/locale_keys.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/helpers/snackbar_helper.dart';
import '../../../../core/helpers/logger.dart';
import '../../../../core/widgets/my_text.dart';
import '../../../../core/storage/hive_service.dart'; // CONTINGENCIA 4
import '../../models/heat_model.dart';
import '../../models/judge_score_model.dart';
import '../../models/draft_score.dart'; // CONTINGENCIA 4
import '../bloc/judge_score_cubit.dart';
import '../bloc/judge_score_state.dart';
import '../widgets/outbox_indicator.dart';
import '../widgets/score_validation_dialog.dart';
import '../../services/score_validation_service.dart';

/// Página de puntuación para jueces
///
/// Soporta 3 modos:
/// 1. Heat Sequential: Un atleta a la vez, navegación con botones Previous/Next
/// 2. Heat Simultaneous: Todos los atletas visibles, scoring en cualquier orden
/// 3. Legacy Mode: Lista de participantes (sin heat)
class JudgeScoringPage extends StatelessWidget {
  const JudgeScoringPage({
    super.key,
    required this.competitionId,
    required this.categoryId,
    this.heat, // If provided, uses heat mode
    this.judgeId, // Required for heat mode
    this.scoringCriteria,
  });

  final String competitionId;
  final String categoryId;
  final Heat? heat; // Optional: if provided, uses heat-based scoring
  final String? judgeId; // Required for heat mode
  final List<String>? scoringCriteria;

  bool get isHeatMode => heat != null && judgeId != null;
  bool get isSequentialMode => isHeatMode && heat!.isSequential;
  bool get isSimultaneousMode => isHeatMode && heat!.isSimultaneous;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) {
        final cubit = getIt<JudgeScoreCubit>();

        if (isHeatMode) {
          // Heat mode: Load first athlete for sequential, or all for simultaneous
          if (isSequentialMode && heat!.athleteOrder.isNotEmpty) {
            final firstAthleteId = heat!.athleteOrder.first;
            cubit.startHeatScoring(
              heat!,
              competitionId,
              categoryId,
              firstAthleteId,
              judgeId!,
            );
          } else if (isSimultaneousMode) {
            // For simultaneous, just select the heat
            cubit.selectHeat(heat!, competitionId, categoryId);
          }
        } else {
          // Legacy mode: Load category scores
          cubit.getScoresByCategory(competitionId, categoryId);
        }

        return cubit;
      },
      child: isHeatMode
          ? (isSequentialMode
              ? _SequentialScoringView(
                  competitionId: competitionId,
                  categoryId: categoryId,
                  heat: heat!,
                  judgeId: judgeId!,
                  scoringCriteria: scoringCriteria,
                )
              : _SimultaneousScoringView(
                  competitionId: competitionId,
                  categoryId: categoryId,
                  heat: heat!,
                  judgeId: judgeId!,
                  scoringCriteria: scoringCriteria,
                ))
          : _LegacyScoringView(
              competitionId: competitionId,
              categoryId: categoryId,
              scoringCriteria: scoringCriteria,
            ),
    );
  }
}

// =============================================================================
// SEQUENTIAL MODE VIEW
// =============================================================================

class _SequentialScoringView extends StatefulWidget {
  const _SequentialScoringView({
    required this.competitionId,
    required this.categoryId,
    required this.heat,
    required this.judgeId,
    this.scoringCriteria,
  });

  final String competitionId;
  final String categoryId;
  final Heat heat;
  final String judgeId;
  final List<String>? scoringCriteria;

  @override
  State<_SequentialScoringView> createState() => _SequentialScoringViewState();
}

class _SequentialScoringViewState extends State<_SequentialScoringView> {
  final Map<String, double> _scores = {};
  final Map<String, TextEditingController> _controllers = {};

  static const List<String> _defaultCriteria = [
    'Technique',
    'Style',
    'Difficulty',
    'Execution',
    'Flow',
  ];

  List<String> get _criteria => widget.scoringCriteria ?? _defaultCriteria;

  @override
  void initState() {
    super.initState();
    _initializeCriteria();
  }

  void _initializeCriteria() {
    for (final criterion in _criteria) {
      _scores[criterion] = 0.0;
      _controllers[criterion] = TextEditingController(text: '0.0');
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            MyText(
              widget.heat.name,
              noTranslation: true,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
            const SizedBox(height: 2),
            MyText(
              LocaleKeys.sequentialMode,
              fontSize: 12,
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
          ],
        ),
        actions: [
          // Outbox sync indicator
          const OutboxIndicator(),
          const SizedBox(width: 8),
          // Heat status indicator
          if (widget.heat.isCompleted)
            Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: theme.colorScheme.error.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.lock,
                    size: 14,
                    color: theme.colorScheme.error,
                  ),
                  const SizedBox(width: 4),
                  MyText(
                    LocaleKeys.closed,
                    fontSize: 12,
                    color: theme.colorScheme.error,
                  ),
                ],
              ),
            ),
        ],
      ),
      body: BlocConsumer<JudgeScoreCubit, JudgeScoreState>(
        listener: (context, state) {
          // Show backend errors with translation
          if (state is HeatError) {
            SnackBarHelper.showBackendError(
              context,
              errorCode: state.code,
              fallbackMessage: state.message,
            );
          }

          // Heat completed warning
          if (state is HeatCompletedWarning) {
            SnackBarHelper.showWarning(context, state.message);
          }

          // Success feedback
          if (state is ScoreActionSuccess) {
            SnackBarHelper.showSuccess(context, state.message);

            // Auto-advance to next athlete
            final cubit = context.read<JudgeScoreCubit>();
            final currentState = cubit.state;
            if (currentState is HeatScoringModeActive &&
                currentState.hasNextAthlete) {
              Future.delayed(const Duration(milliseconds: 500), () {
                cubit.navigateToNextAthlete(widget.judgeId);
              });
            } else {
              // All done, go back
              Future.delayed(const Duration(seconds: 1), () {
                if (mounted) {
                  Navigator.of(context).pop();
                }
              });
            }
          }

          // Update form when athlete changes
          if (state is HeatScoringModeActive) {
            _loadExistingScores(state.currentScores);
          }
        },
        builder: (context, state) {
          if (state is ScoresLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is HeatScoringModeActive) {
            final totalScore =
                _scores.values.fold(0.0, (sum, score) => sum + score);
            final isHeatClosed = state.isHeatCompleted;

            return Column(
              children: [
                // Large athlete name and counter header
                Container(
                  padding: const EdgeInsets.all(24),
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
                  child: Column(
                    children: [
                      // Athlete position counter (3/8)
                      MyText(
                        state.athletePositionDisplay,
                        noTranslation: true,
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(height: 8),

                      // Athlete name (large)
                      MyText(
                        '${context.tr(LocaleKeys.athlete)} ${state.currentAthleteId}', // TODO: Get actual name from athlete model
                        noTranslation: true,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 12),

                      // Progress bar
                      if (state.currentAthleteIndex != null)
                        LinearProgressIndicator(
                          value: (state.currentAthleteIndex! + 1) /
                              state.heat.athleteCount,
                          backgroundColor:
                              theme.colorScheme.surfaceContainerHighest,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            theme.colorScheme.primary,
                          ),
                        ),
                    ],
                  ),
                ),

                // Scoring form
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ..._criteria.map((criterion) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                MyText(
                                  criterion,
                                  noTranslation: true,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Slider(
                                        value: _scores[criterion]!,
                                        max: 10,
                                        divisions: 100,
                                        label: _scores[criterion]!
                                            .toStringAsFixed(1),
                                        onChanged: isHeatClosed
                                            ? null
                                            : (value) {
                                                setState(() {
                                                  _scores[criterion] = value;
                                                  _controllers[criterion]!
                                                      .text = value
                                                          .toStringAsFixed(1);
                                                });
                                              },
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    SizedBox(
                                      width: 70,
                                      child: TextField(
                                        controller: _controllers[criterion],
                                        enabled: !isHeatClosed,
                                        keyboardType:
                                            const TextInputType.numberWithOptions(
                                          decimal: true,
                                        ),
                                        decoration: const InputDecoration(
                                          isDense: true,
                                          contentPadding:
                                              EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 12,
                                          ),
                                          suffix: MyText(
                                            '/10',
                                            noTranslation: true,
                                            fontSize: 12,
                                          ),
                                        ),
                                        onChanged: (value) {
                                          final parsedValue =
                                              double.tryParse(value);
                                          if (parsedValue != null &&
                                              parsedValue >= 0 &&
                                              parsedValue <= 10) {
                                            setState(() {
                                              _scores[criterion] = parsedValue;
                                            });
                                          }
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        }),

                        const Divider(),
                        const SizedBox(height: 16),

                        // Total score display
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const MyText(
                              LocaleKeys.totalScore,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                            MyText(
                              totalScore.toStringAsFixed(2),
                              noTranslation: true,
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                            ),
                          ],
                        ),

                        const SizedBox(height: 80), // Space for bottom buttons
                      ],
                    ),
                  ),
                ),
              ],
            );
          }

          return const Center(
            child: MyText(LocaleKeys.errorLoadingScoringMode),
          );
        },
      ),

      // Fixed bottom navigation buttons
      bottomNavigationBar: BlocBuilder<JudgeScoreCubit, JudgeScoreState>(
        builder: (context, state) {
          if (state is! HeatScoringModeActive) {
            return const SizedBox.shrink();
          }

          final cubit = context.read<JudgeScoreCubit>();
          final isHeatClosed = state.isHeatCompleted;

          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                // Previous button
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: state.hasPreviousAthlete
                        ? () => cubit.navigateToPreviousAthlete(widget.judgeId)
                        : null,
                    icon: const Icon(Icons.arrow_back),
                    label: const MyText(LocaleKeys.previous),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                // Submit button
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: isHeatClosed
                        ? null
                        : () {
                            cubit.submitHeatScore(
                              widget.competitionId,
                              widget.categoryId,
                              state.currentAthleteId,
                              widget.heat.id,
                              _scores,
                              null, // comments
                              judgeId: widget.judgeId,
                            );
                          },
                    icon: const Icon(Icons.check),
                    label: MyText(
                      state.hasNextAthlete
                          ? LocaleKeys.submitAndNext
                          : LocaleKeys.submit,
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                // Next button (or Finish)
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: state.hasNextAthlete
                        ? () => cubit.navigateToNextAthlete(widget.judgeId)
                        : null,
                    icon: const Icon(Icons.arrow_forward),
                    label: const MyText(LocaleKeys.next),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _loadExistingScores(Map<String, double> existingScores) {
    setState(() {
      for (final criterion in _criteria) {
        final value = existingScores[criterion] ?? 0.0;
        _scores[criterion] = value;
        _controllers[criterion]?.text = value.toStringAsFixed(1);
      }
    });
  }
}

// =============================================================================
// SIMULTANEOUS MODE VIEW
// =============================================================================

class _SimultaneousScoringView extends StatelessWidget {
  const _SimultaneousScoringView({
    required this.competitionId,
    required this.categoryId,
    required this.heat,
    required this.judgeId,
    this.scoringCriteria,
  });

  final String competitionId;
  final String categoryId;
  final Heat heat;
  final String judgeId;
  final List<String>? scoringCriteria;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            MyText(
              heat.name,
              noTranslation: true,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
            const SizedBox(height: 2),
            MyText(
              LocaleKeys.simultaneousMode,
              fontSize: 12,
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
          ],
        ),
        actions: const [
          // Outbox sync indicator
          OutboxIndicator(),
          SizedBox(width: 8),
        ],
      ),
      body: BlocConsumer<JudgeScoreCubit, JudgeScoreState>(
        listener: (context, state) {
          if (state is HeatError) {
            SnackBarHelper.showBackendError(
              context,
              errorCode: state.code,
              fallbackMessage: state.message,
            );
          }

          if (state is ScoreActionSuccess) {
            SnackBarHelper.showSuccess(context, state.message);
          }
        },
        builder: (context, state) {
          return Column(
            children: [
              // Header with heat info
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
                      Icons.groups,
                      color: theme.colorScheme.primary,
                      size: 32,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const MyText(
                            LocaleKeys.scoreAllAthletes,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          const SizedBox(height: 4),
                          MyText(
                            LocaleKeys.athletesInHeat,
                            args: {'count': '${heat.athleteCount}'},
                            fontSize: 14,
                            color: theme.textTheme.bodySmall?.color,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Compact athletes list
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: heat.athleteIds.length,
                  itemBuilder: (context, index) {
                    final athleteId = heat.athleteIds[index];

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: theme.colorScheme.primaryContainer,
                          child: MyText(
                            '${index + 1}',
                            noTranslation: true,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        title: MyText(
                          '${context.tr(LocaleKeys.athlete)} $athleteId', // TODO: Get actual name
                          noTranslation: true,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                        trailing: const Icon(
                          Icons.access_time,
                          color: Colors.orange,
                          size: 28,
                        ),
                        onTap: heat.isCompleted
                            ? null
                            : () {
                                _openScoringDialog(
                                  context,
                                  athleteId,
                                  index + 1,
                                );
                              },
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _openScoringDialog(
    BuildContext context,
    String athleteId,
    int athleteNumber,
  ) async {
    // Start heat scoring for this athlete
    context.read<JudgeScoreCubit>().startHeatScoring(
          heat,
          competitionId,
          categoryId,
          athleteId,
          judgeId,
        );

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => _ScoringDialog(
        athleteId: athleteId,
        competitionId: competitionId,
        categoryId: categoryId,
        athleteNumber: athleteNumber,
        criteria: scoringCriteria,
        heatId: heat.id,
        judgeId: judgeId,
      ),
    );
  }
}

// =============================================================================
// LEGACY MODE VIEW (No Heat)
// =============================================================================

class _LegacyScoringView extends StatelessWidget {
  const _LegacyScoringView({
    required this.competitionId,
    required this.categoryId,
    this.scoringCriteria,
  });

  final String competitionId;
  final String categoryId;
  final List<String>? scoringCriteria;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: const [
            Icon(Icons.score),
            SizedBox(width: 8),
            MyText(LocaleKeys.judgeScoring),
          ],
        ),
        actions: const [
          // Outbox sync indicator
          OutboxIndicator(),
          SizedBox(width: 8),
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
                  MyText(state.message, noTranslation: true, color: theme.colorScheme.error),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => context
                        .read<JudgeScoreCubit>()
                        .getScoresByCategory(competitionId, categoryId),
                    child: const MyText(LocaleKeys.retry),
                  ),
                ],
              ),
            );
          }

          if (state is JudgeScoreListLoaded) {
            final scores = state.scores;

            if (scores.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.score,
                      size: 64,
                      color: theme.colorScheme.outline,
                    ),
                    const SizedBox(height: 16),
                    MyText(
                      LocaleKeys.noParticipantsToScore,
                      color: theme.textTheme.bodySmall?.color,
                    ),
                  ],
                ),
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: scores.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final score = scores[index];
                return _buildParticipantCard(context, score, theme);
              },
            );
          }

          return const Center(child: MyText(LocaleKeys.noDataAvailable));
        },
      ),
    );
  }

  Widget _buildParticipantCard(
    BuildContext context,
    JudgeScore score,
    ThemeData theme,
  ) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: () => _openScoringDialog(context, score),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: theme.colorScheme.primaryContainer,
                    radius: 24,
                    child: MyText(
                      score.participantNumber ?? score.participantName[0],
                      noTranslation: true,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        MyText(
                          score.participantName,
                          noTranslation: true,
                          istitle: true,
                          fontSize: 16,
                        ),
                        if (score.participantNumber != null)
                          MyText(
                            context.tr(LocaleKeys.participantNumber, args: {'number': score.participantNumber!}),
                            fontSize: 13,
                            color: theme.textTheme.bodySmall?.color,
                          ),
                      ],
                    ),
                  ),
                  if (score.isSubmitted)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.check_circle,
                            size: 14,
                            color: Colors.green,
                          ),
                          const SizedBox(width: 4),
                          MyText(
                            LocaleKeys.submitted,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade700,
                          ),
                        ],
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.pending,
                            size: 14,
                            color: Colors.orange,
                          ),
                          const SizedBox(width: 4),
                          MyText(
                            LocaleKeys.pending,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange.shade700,
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              if (score.hasScores) ...[
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const MyText(LocaleKeys.totalScore, fontSize: 14),
                    MyText(
                      score.totalScore.toStringAsFixed(2),
                      noTranslation: true,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openScoringDialog(
      BuildContext context, JudgeScore score) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => _ScoringDialog(
        athleteId: score.participantId,
        competitionId: competitionId,
        categoryId: categoryId,
        athleteNumber: int.tryParse(score.participantNumber ?? ''),
        criteria: scoringCriteria,
        existingScores: score.criteriaScores,
      ),
    );
  }
}

// =============================================================================
// SCORING DIALOG (Shared for simultaneous and legacy modes)
// =============================================================================

class _ScoringDialog extends StatefulWidget {
  const _ScoringDialog({
    required this.athleteId,
    required this.competitionId,
    required this.categoryId,
    this.athleteNumber,
    this.criteria,
    this.existingScores,
    this.heatId,
    this.judgeId,
  });

  final String athleteId;
  final String competitionId;
  final String categoryId;
  final int? athleteNumber;
  final List<String>? criteria;
  final Map<String, double>? existingScores;
  final String? heatId;
  final String? judgeId;

  @override
  State<_ScoringDialog> createState() => _ScoringDialogState();
}

class _ScoringDialogState extends State<_ScoringDialog> {
  final Map<String, double> _scores = {};
  final Map<String, TextEditingController> _controllers = {};

  // CONTINGENCIA 4: Auto-save
  Timer? _autoSaveTimer;
  late final String _draftId;
  final HiveService _hiveService = getIt<HiveService>();

  static const List<String> _defaultCriteria = [
    'Technique',
    'Style',
    'Difficulty',
    'Execution',
    'Flow',
  ];

  List<String> get _criteria => widget.criteria ?? _defaultCriteria;

  @override
  void initState() {
    super.initState();

    // Generate draft ID
    _draftId = DraftScore.generateId(
      competitionId: widget.competitionId,
      categoryId: widget.categoryId,
      athleteId: widget.athleteId,
      heatId: widget.heatId,
    );

    // CONTINGENCIA 4: Try to restore draft
    _restoreDraftIfExists();

    // Initialize scores from existing or draft
    for (final criterion in _criteria) {
      if (!_scores.containsKey(criterion)) {
        final value = widget.existingScores?[criterion] ?? 0.0;
        _scores[criterion] = value;
      }
      _controllers[criterion] = TextEditingController(
        text: _scores[criterion]!.toStringAsFixed(1),
      );
    }
  }

  @override
  void dispose() {
    _autoSaveTimer?.cancel();
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  /// CONTINGENCIA 4: Restore draft if exists
  void _restoreDraftIfExists() {
    final draft = _hiveService.getDraft(_draftId);
    if (draft != null && draft.hasAnyScores) {
      // Restore scores from draft
      _scores.addAll(draft.criteriaScores);

      // Show restoration snackbar
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          SnackBarHelper.showInfo(context, LocaleKeys.draftRestored);
        }
      });
    }
  }

  /// CONTINGENCIA 4: Auto-save draft with debounce (500ms)
  void _autoSaveDraft() {
    _autoSaveTimer?.cancel();
    _autoSaveTimer = Timer(const Duration(milliseconds: 500), () async {
      try {
        final draft = DraftScore(
          id: _draftId,
          competitionId: widget.competitionId,
          categoryId: widget.categoryId,
          athleteId: widget.athleteId,
          heatId: widget.heatId,
          judgeId: widget.judgeId,
          criteriaScores: Map<String, double>.from(_scores),
          lastModified: DateTime.now(),
          version: 1,
        );

        await _hiveService.saveDraft(draft);
      } catch (e) {
        // Silent fail - don't interrupt user experience
        AppLogger.error('Auto-save draft failed', error: e, tag: 'JudgeScoring');
      }
    });
  }

  /// CONTINGENCIA 4: Delete draft after successful submit
  Future<void> _deleteDraft() async {
    try {
      await _hiveService.deleteDraft(_draftId);
    } catch (e) {
      AppLogger.error('Delete draft failed', error: e, tag: 'JudgeScoring');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final totalScore = _scores.values.fold(0.0, (sum, score) => sum + score);

    return AlertDialog(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const MyText(LocaleKeys.scoreAthlete, istitle: true),
          const SizedBox(height: 4),
          MyText(
            widget.athleteNumber != null
                ? context.tr(LocaleKeys.athlete, args: {'number': '#${widget.athleteNumber}'})
                : '${context.tr(LocaleKeys.athlete)} ${widget.athleteId}',
            noTranslation: widget.athleteNumber == null,
            fontSize: 14,
            color: theme.textTheme.bodySmall?.color,
          ),
        ],
      ),
      content: SizedBox(
        width: 400,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ..._criteria.map((criterion) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      MyText(
                        criterion,
                        noTranslation: true,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: Slider(
                              value: _scores[criterion]!,
                              max: 10,
                              divisions: 100,
                              label: _scores[criterion]!.toStringAsFixed(1),
                              onChanged: (value) {
                                setState(() {
                                  _scores[criterion] = value;
                                  _controllers[criterion]!.text =
                                      value.toStringAsFixed(1);
                                });
                                _autoSaveDraft(); // CONTINGENCIA 4: Auto-save on change
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          SizedBox(
                            width: 60,
                            child: TextField(
                              controller: _controllers[criterion],
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                decimal: true,
                              ),
                              decoration: const InputDecoration(
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 8,
                                ),
                              ),
                              onChanged: (value) {
                                final parsedValue = double.tryParse(value);
                                if (parsedValue != null &&
                                    parsedValue >= 0 &&
                                    parsedValue <= 10) {
                                  setState(() {
                                    _scores[criterion] = parsedValue;
                                  });
                                  _autoSaveDraft(); // CONTINGENCIA 4: Auto-save on change
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }),
              const Divider(),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const MyText(
                    LocaleKeys.totalScore,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  MyText(
                    totalScore.toStringAsFixed(2),
                    noTranslation: true,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const MyText(LocaleKeys.cancel),
        ),
        BlocBuilder<JudgeScoreCubit, JudgeScoreState>(
          builder: (context, state) {
            // Show retry progress
            if (state is ScoreRetrying) {
              return _buildRetryingButton(context, state);
            }

            // Normal submit button
            return ElevatedButton.icon(
              onPressed: () => _handleSubmitWithValidation(context),
              icon: const Icon(Icons.send),
              label: const MyText(LocaleKeys.submit),
            );
          },
        ),
      ],
    );
  }

  /// Build retrying button with progress indicator
  Widget _buildRetryingButton(BuildContext context, ScoreRetrying state) {
    final progress = state.progressPercentage / 100;

    return ElevatedButton(
      onPressed: null,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              value: progress,
              strokeWidth: 3,
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              backgroundColor: Colors.white.withOpacity(0.3),
            ),
          ),
          const SizedBox(width: 12),
          MyText(
            '${state.attempt}/${state.maxAttempts}',
            noTranslation: true,
            fontSize: 14,
          ),
        ],
      ),
    );
  }

  /// Handle submit with heuristic validation
  Future<void> _handleSubmitWithValidation(BuildContext context) async {
    final cubit = context.read<JudgeScoreCubit>();
    final validationService = getIt<ScoreValidationService>();
    final totalScore = _scores.values.fold(0.0, (sum, score) => sum + score);

    // STEP 1: Fetch other judges' scores (if available)
    // TODO: In real implementation, fetch from repository
    // For now, assume empty (will skip validation)
    final List<JudgeScore> otherJudgeScores = [];

    // STEP 2: Validate score
    final validationResult = validationService.validateAgainstOtherJudges(
      submittedScore: totalScore,
      otherJudgeScores: otherJudgeScores,
      participantId: widget.athleteId,
    );

    // STEP 3: If suspicious, show confirmation dialog
    if (!validationResult.isValid) {
      final shouldProceed = await showScoreValidationDialog(
        context: context,
        validationResult: validationResult,
        submittedScore: totalScore,
      );

      if (shouldProceed != true) {
        return; // User chose to correct
      }
    }

    // STEP 4: Submit (validation passed or confirmed)
    if (!context.mounted) return;

    if (widget.heatId != null) {
      cubit.submitHeatScore(
        widget.competitionId,
        widget.categoryId,
        widget.athleteId,
        widget.heatId!,
        _scores,
        null, // comments
        judgeId: widget.judgeId,
      );
    } else {
      cubit.submitScore(
        widget.competitionId,
        widget.categoryId,
        widget.athleteId,
        _scores,
        '', // comments
      );
    }

    // CONTINGENCIA 4: Delete draft after successful submit
    await _deleteDraft();

    // Close dialog after submit
    if (context.mounted) {
      Navigator.of(context).pop();
    }
  }
}
// ... (rest of the file is unchanged)
