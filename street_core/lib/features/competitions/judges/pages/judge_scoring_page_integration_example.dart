/// EJEMPLO DE INTEGRACIÓN - JudgeScoringPage con Contingencias UI
///
/// Este archivo muestra cómo quedaría la integración de:
/// 1. OutboxIndicator en el AppBar
/// 2. Validación heurística antes de submit
/// 3. Botón submit con progress indicator

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/widgets/my_text.dart';
import '../../../../core/lang/locale_keys.dart';
import '../bloc/judge_score_cubit.dart';
import '../bloc/judge_score_state.dart';
import '../../services/score_validation_service.dart';
import '../../models/judge_score_model.dart';
import '../widgets/score_validation_dialog.dart';

/// =============================================================================
/// INTEGRACIÓN 1: AppBar con OutboxIndicator
/// =============================================================================

/// Add this to the AppBar of JudgeScoringPage
///
/// ```dart
/// AppBar(
///   title: const MyText(LocaleKeys.judgeScoring),
///   actions: [
///     // NUEVO: Indicador de sincronización
///     const OutboxIndicator(),
///     const SizedBox(width: 8),
///   ],
/// )
/// ```

/// =============================================================================
/// INTEGRACIÓN 2: _ScoringDialog con Validación Heurística
/// =============================================================================

class _ScoringDialogRefactored extends StatefulWidget {
  const _ScoringDialogRefactored({
    required this.competitionId,
    required this.categoryId,
    required this.athleteId,
    this.athleteNumber,
    this.criteria,
    this.existingScores,
    this.heatId,
  });

  final String competitionId;
  final String categoryId;
  final String athleteId;
  final int? athleteNumber;
  final List<String>? criteria;
  final Map<String, double>? existingScores;
  final String? heatId;

  @override
  State<_ScoringDialogRefactored> createState() =>
      _ScoringDialogRefactoredState();
}

class _ScoringDialogRefactoredState extends State<_ScoringDialogRefactored> {
  final Map<String, double> _scores = {};
  final Map<String, TextEditingController> _controllers = {};

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
    for (final criterion in _criteria) {
      final value = widget.existingScores?[criterion] ?? 0.0;
      _scores[criterion] = value;
      _controllers[criterion] = TextEditingController(
        text: value.toStringAsFixed(1),
      );
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
    final totalScore = _scores.values.fold(0.0, (sum, score) => sum + score);

    return AlertDialog(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const MyText(LocaleKeys.scoreAthlete, istitle: true),
          const SizedBox(height: 4),
          MyText(
            widget.athleteNumber != null
                ? 'Athlete #${widget.athleteNumber}'
                : widget.athleteId,
            noTranslation: true,
            fontSize: 14,
            color: theme.textTheme.bodyMedium?.color,
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ... Sliders para cada criterio (igual que antes)
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
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        SizedBox(
                          width: 60,
                          child: TextField(
                            controller: _controllers[criterion],
                            keyboardType: const TextInputType.numberWithOptions(
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
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const MyText(LocaleKeys.cancel),
        ),

        // =======================================================================
        // REFACTOR: Botón Submit con Validación Heurística y Progress
        // =======================================================================
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
              label: const MyText(
                LocaleKeys.submit,
                color: Colors.white,
              ),
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
            color: Colors.white,
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

    // Close dialog after submit
    if (context.mounted) {
      Navigator.of(context).pop();
    }
  }
}

/// =============================================================================
/// RESUMEN DE CAMBIOS NECESARIOS EN judge_scoring_page.dart
/// =============================================================================
///
/// 1. APPBAR:
///    - Agregar: const OutboxIndicator() en actions
///
/// 2. _ScoringDialog:
///    - Reemplazar el ElevatedButton submit (línea 1165-1168) con:
///      BlocBuilder<JudgeScoreCubit, JudgeScoreState> que renderiza
///      _buildRetryingButton() cuando state is ScoreRetrying
///
/// 3. Submit Flow:
///    - Reemplazar: Navigator.of(context).pop(_scores)
///    - Con: _handleSubmitWithValidation(context) que valida y luego envía
///
/// 4. Imports:
///    - import '../widgets/outbox_indicator.dart';
///    - import '../widgets/score_validation_dialog.dart';
///    - import '../../services/score_validation_service.dart';
