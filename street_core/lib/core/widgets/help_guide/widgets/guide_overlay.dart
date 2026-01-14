// lib/core/widgets/help_guide/widgets/guide_overlay.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../lang/context_tr.dart';
import '../../../lang/locale_keys.dart';
import '../bloc/guide_cubit.dart';
import '../bloc/guide_state.dart';
import 'guide_bottom_sheet.dart';

/// Floating action button that appears when a guide is available
/// Shows in bottom-right corner with "?" icon
class GuideOverlay extends StatelessWidget {
  const GuideOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<GuideCubit, GuideState>(
      builder: (context, state) {
        // Only show button when guide is available (not showing)
        if (state is! GuideAvailable) {
          return const SizedBox.shrink();
        }

        final theme = Theme.of(context);
        final colorScheme = theme.colorScheme;

        return Positioned(
          right: 16,
          bottom: 80, // Above potential other FABs
          child: FloatingActionButton(
            heroTag: 'guide_help_button',
            onPressed: () {
              context.read<GuideCubit>().showGuide(state.config.routePath);
              // Show bottom sheet after a small delay to let state update
              Future.delayed(const Duration(milliseconds: 100), () {
                if (context.mounted) {
                  GuideBottomSheet.show(context);
                }
              });
            },
            tooltip: context.tr(LocaleKeys.helpGuideTitle),
            backgroundColor: colorScheme.primaryContainer,
            foregroundColor: colorScheme.onPrimaryContainer,
            elevation: 4,
            child: const Icon(Icons.help_outline_rounded, size: 28),
          ),
        );
      },
    );
  }
}

/// Automatic guide that shows on page load (if configured)
/// Displays bottom sheet automatically for first-time visitors
class AutoGuide extends StatefulWidget {
  const AutoGuide({super.key});

  @override
  State<AutoGuide> createState() => _AutoGuideState();
}

class _AutoGuideState extends State<AutoGuide> {
  @override
  void initState() {
    super.initState();
    _checkAndShowGuide();
  }

  void _checkAndShowGuide() {
    // Wait for build to complete
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      final state = context.read<GuideCubit>().state;
      if (state is GuideShowing) {
        GuideBottomSheet.show(context);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<GuideCubit, GuideState>(
      listener: (context, state) {
        // Show bottom sheet when guide starts showing
        if (state is GuideShowing) {
          GuideBottomSheet.show(context);
        }
      },
      child: const SizedBox.shrink(),
    );
  }
}
