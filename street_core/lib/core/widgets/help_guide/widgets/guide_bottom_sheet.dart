// lib/core/widgets/help_guide/widgets/guide_bottom_sheet.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../lang/context_tr.dart';
import '../../../lang/locale_keys.dart';
import '../bloc/guide_cubit.dart';
import '../bloc/guide_state.dart';

/// Bottom sheet widget that displays guide steps
class GuideBottomSheet extends StatelessWidget {
  const GuideBottomSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<GuideCubit, GuideState>(
      builder: (context, state) {
        if (state is! GuideShowing) {
          return const SizedBox.shrink();
        }

        final currentStep = state.config.steps[state.currentStep];
        final theme = Theme.of(context);
        final colorScheme = theme.colorScheme;

        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: colorScheme.onSurfaceVariant.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Header
              Row(
                children: [
                  Icon(
                    Icons.help_outline_rounded,
                    color: colorScheme.primary,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.tr(state.config.titleKey),
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          context.tr(
                            LocaleKeys.helpGuideStepOf,
                            args: {
                              'current': '${state.currentStep + 1}',
                              'total': '${state.totalSteps}',
                            },
                          ),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => context.read<GuideCubit>().skipGuide(),
                    tooltip: context.tr(LocaleKeys.helpGuideClose),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Step content
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.tr(currentStep.titleKey),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      context.tr(currentStep.descriptionKey),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Progress indicator
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: (state.currentStep + 1) / state.totalSteps,
                  backgroundColor: colorScheme.surfaceVariant,
                  color: colorScheme.primary,
                  minHeight: 6,
                ),
              ),

              const SizedBox(height: 24),

              // Navigation buttons
              Row(
                children: [
                  // Don't show again button
                  TextButton.icon(
                    onPressed: () {
                      context.read<GuideCubit>().dismissPermanently();
                    },
                    icon: const Icon(Icons.block_rounded, size: 18),
                    label: Text(
                      context.tr(LocaleKeys.helpGuideDontShowAgain),
                      style: const TextStyle(fontSize: 13),
                    ),
                    style: TextButton.styleFrom(
                      foregroundColor: colorScheme.error,
                    ),
                  ),

                  const Spacer(),

                  // Previous button
                  if (!state.isFirstStep)
                    OutlinedButton(
                      onPressed: () => context.read<GuideCubit>().previousStep(),
                      child: Text(context.tr(LocaleKeys.helpGuidePrevious)),
                    ),

                  if (!state.isFirstStep) const SizedBox(width: 12),

                  // Next/Finish button
                  FilledButton(
                    onPressed: () => context.read<GuideCubit>().nextStep(),
                    child: Text(
                      state.isLastStep
                          ? context.tr(LocaleKeys.helpGuideGotIt)
                          : context.tr(LocaleKeys.helpGuideNext),
                    ),
                  ),
                ],
              ),

              // Safe area padding at bottom
              SizedBox(height: MediaQuery.of(context).padding.bottom),
            ],
          ),
        );
      },
    );
  }

  /// Show the guide bottom sheet
  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const GuideBottomSheet(),
    );
  }
}
