/// Score Validation Dialog - Muestra advertencias de validación heurística
///
/// CONTINGENCIA 2: "Dedo Veloz"
/// Si un juez ingresa un outlier (99 en lugar de 9.9), muestra confirmación

import 'package:flutter/material.dart';
import '../../../../core/widgets/my_text.dart';
import '../../../../core/lang/locale_keys.dart';
import '../../../../core/lang/context_tr.dart';
import '../../services/score_validation_service.dart';

/// Show score validation dialog when suspicious score detected
Future<bool?> showScoreValidationDialog({
  required BuildContext context,
  required ScoreValidationResult validationResult,
  required double submittedScore,
}) {
  return showDialog<bool>(
    context: context,
    barrierDismissible: false, // Force user decision
    builder: (dialogContext) => ScoreValidationDialog(
      validationResult: validationResult,
      submittedScore: submittedScore,
    ),
  );
}

class ScoreValidationDialog extends StatelessWidget {
  const ScoreValidationDialog({
    super.key,
    required this.validationResult,
    required this.submittedScore,
  });

  final ScoreValidationResult validationResult;
  final double submittedScore;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Determine icon and color based on warning type
    IconData iconData;
    Color iconColor;

    if (validationResult.warningType == null) {
      iconData = Icons.check_circle;
      iconColor = Colors.green;
    } else {
      switch (validationResult.warningType) {
        case ScoreWarningType.tooHigh:
          iconData = Icons.arrow_upward;
          iconColor = Colors.orange;
          break;
        case ScoreWarningType.tooLow:
          iconData = Icons.arrow_downward;
          iconColor = Colors.orange;
          break;
        case ScoreWarningType.outlier:
          iconData = Icons.warning_amber_rounded;
          iconColor = Colors.red;
          break;
        case ScoreWarningType.historicalMismatch:
          iconData = Icons.history_edu;
          iconColor = Colors.purple;
          break;
        default:
          iconData = Icons.warning_amber_rounded;
          iconColor = Colors.red;
      }
    }

    // Calculate comparison data if available
    final average = validationResult.comparisonData?.averageScore;
    final percentageDiff = validationResult.comparisonData?.percentageDifference;

    return AlertDialog(
      icon: Icon(iconData, size: 48, color: iconColor),
      title: const MyText(
        LocaleKeys.scoreValidationWarning,
        istitle: true,
        fontSize: 18,
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Warning message
            MyText(
              validationResult.message ?? LocaleKeys.error,
              fontSize: 14,
              color: theme.textTheme.bodyMedium?.color,
            ),

            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 12),

            // Comparison data
            MyText(
              LocaleKeys.confirmUnusualScore,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
            const SizedBox(height: 12),

            // Your score
            _buildComparisonRow(
              context: context,
              label: context.tr(LocaleKeys.yourScore),
              value: submittedScore.toStringAsFixed(1),
              isHighlighted: true,
              color: iconColor,
            ),

            if (average != null) ...[
              const SizedBox(height: 8),
              // Other judges average
              _buildComparisonRow(
                context: context,
                label: context.tr(LocaleKeys.otherJudgesAverage),
                value: average.toStringAsFixed(1),
                isHighlighted: false,
              ),
            ],

            if (percentageDiff != null) ...[
              const SizedBox(height: 8),
              // Percentage difference
              _buildComparisonRow(
                context: context,
                label: context.tr(LocaleKeys.difference),
                value: '${percentageDiff.toStringAsFixed(0)}%',
                isHighlighted: false,
                color: percentageDiff > 100 ? Colors.red : Colors.orange,
              ),
            ],
          ],
        ),
      ),
      actions: [
        // Correct score button
        TextButton.icon(
          onPressed: () => Navigator.of(context).pop(false),
          icon: const Icon(Icons.edit),
          label: MyText(
            LocaleKeys.correctScore,
            color: theme.colorScheme.primary,
          ),
        ),

        // Confirm score button
        ElevatedButton.icon(
          onPressed: () => Navigator.of(context).pop(true),
          icon: const Icon(Icons.check_circle),
          label: const MyText(
            LocaleKeys.confirmScore,
            color: Colors.white,
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.colorScheme.primary,
          ),
        ),
      ],
    );
  }

  Widget _buildComparisonRow({
    required BuildContext context,
    required String label,
    required String value,
    required bool isHighlighted,
    Color? color,
  }) {
    final theme = Theme.of(context);
    final textColor = color ??
        (isHighlighted
            ? theme.colorScheme.primary
            : theme.textTheme.bodyMedium?.color);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          MyText(
            label,
            noTranslation: true,
            fontSize: 14,
            fontWeight: isHighlighted ? FontWeight.bold : FontWeight.normal,
          ),
          MyText(
            value,
            noTranslation: true,
            fontSize: isHighlighted ? 18 : 16,
            fontWeight: isHighlighted ? FontWeight.bold : FontWeight.w600,
            color: textColor,
          ),
        ],
      ),
    );
  }
}
