import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:street_core/core/theme/app_spacing.dart';
import 'package:street_core/core/theme/app_theme.dart';
import 'package:street_core/core/theme/bloc/theme_state.dart';

import 'bloc/theme_cubit.dart';
import 'theme_animations.dart';

/// Advanced Theme Selector
///
/// Beautiful, categorized theme selector with:
/// - Theme categories
/// - Live preview
/// - Smooth animations
/// - System theme toggle
/// - High contrast toggle
class AdvancedThemeSelector extends StatelessWidget {
  const AdvancedThemeSelector({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeCubit, ThemeState>(
      builder: (context, state) {
        final themeCubit = context.read<ThemeCubit>();
        final colorScheme = Theme.of(context).colorScheme;

        return Container(
          padding: AppSpacing.edgeInsetsLG,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              _buildHeader(context, colorScheme),
              const SizedBox(height: AppSpacing.lg),

              // System Theme Toggle
              _buildSystemThemeToggle(context, state, themeCubit, colorScheme),
              const SizedBox(height: AppSpacing.lg),

              // High Contrast Toggle
              _buildHighContrastToggle(context, state, themeCubit, colorScheme),
              const SizedBox(height: AppSpacing.xl),

              // Theme Categories
              Expanded(
                child: ListView(
                  children: AppTheme.themeCategories.entries.map((entry) {
                    return _buildThemeCategory(
                      context,
                      entry.key,
                      entry.value,
                      state.themeName,
                      themeCubit,
                      colorScheme,
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, ColorScheme colorScheme) {
    return Row(
      children: [
        Icon(Icons.palette_outlined, color: colorScheme.primary, size: 28),
        const SizedBox(width: AppSpacing.md),
        Text(
          'Themes',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
        const Spacer(),
        IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }

  Widget _buildSystemThemeToggle(
    BuildContext context,
    ThemeState state,
    ThemeCubit themeCubit,
    ColorScheme colorScheme,
  ) {
    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainerHighest,
      child: SwitchListTile(
        title: Text(
          'Follow System Theme',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          'Automatically switch between light and dark mode',
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
        ),
        value: state.followSystemTheme,
        onChanged: (value) {
          themeCubit.setFollowSystemTheme(value);
        },
        secondary: Icon(
          state.followSystemTheme
              ? Icons.brightness_auto
              : Icons.brightness_6_outlined,
          color: colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildHighContrastToggle(
    BuildContext context,
    ThemeState state,
    ThemeCubit themeCubit,
    ColorScheme colorScheme,
  ) {
    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainerHighest,
      child: SwitchListTile(
        title: Text(
          'High Contrast Mode',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          'Improve visibility for better accessibility',
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
        ),
        value: state.useHighContrast,
        onChanged: (value) {
          themeCubit.setHighContrast(value);
        },
        secondary: Icon(
          state.useHighContrast ? Icons.contrast : Icons.contrast_outlined,
          color: colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildThemeCategory(
    BuildContext context,
    String category,
    List<String> themeNames,
    String currentTheme,
    ThemeCubit themeCubit,
    ColorScheme colorScheme,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Category Title
          Padding(
            padding: const EdgeInsets.only(
              left: AppSpacing.sm,
              bottom: AppSpacing.sm,
            ),
            child: Text(
              category,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.primary,
              ),
            ),
          ),

          // Theme Cards
          ...themeNames.map((themeName) {
            final isSelected = themeName == currentTheme;
            final isDark = themeName.contains('Dark');

            return ThemeAnimations.scaleIn(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                child: _ThemeCard(
                  themeName: themeName,
                  isSelected: isSelected,
                  isDark: isDark,
                  onTap: () => themeCubit.setTheme(themeName),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ============================================================================
// THEME CARD
// ============================================================================

class _ThemeCard extends StatefulWidget {
  const _ThemeCard({
    required this.themeName,
    required this.isSelected,
    required this.isDark,
    required this.onTap,
  });
  final String themeName;
  final bool isSelected;
  final bool isDark;
  final VoidCallback onTap;

  @override
  State<_ThemeCard> createState() => _ThemeCardState();
}

class _ThemeCardState extends State<_ThemeCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.getTheme(widget.themeName);
    final previewColor = theme.colorScheme.primary;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: AppDuration.fast,
        curve: ThemeAnimations.emphasized,
        transform: _isHovered
            // ignore: deprecated_member_use
            ? (Matrix4.identity()..scale(1.02))
            : null,
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: AppRadius.cardRadius,
          child: Container(
            padding: AppSpacing.edgeInsetsMD,
            decoration: BoxDecoration(
              color: widget.isSelected
                  ? previewColor.withValues(alpha: 0.1)
                  : Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: AppRadius.cardRadius,
              border: Border.all(
                color: widget.isSelected ? previewColor : Colors.transparent,
                width: 2,
              ),
              boxShadow: widget.isSelected || _isHovered
                  ? [
                      BoxShadow(
                        color: previewColor.withValues(alpha: 0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              children: [
                // Color Preview
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        previewColor,
                        previewColor.withValues(alpha: 0.7),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    boxShadow: [
                      BoxShadow(
                        color: previewColor.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    widget.isDark
                        ? Icons.dark_mode_outlined
                        : Icons.light_mode_outlined,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),

                // Theme Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.themeName,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              fontWeight: widget.isSelected
                                  ? FontWeight.bold
                                  : FontWeight.w600,
                            ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _getThemeDescription(widget.themeName),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),

                // Selection Indicator
                if (widget.isSelected)
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: previewColor,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getThemeDescription(String themeName) {
    if (themeName.contains('Sporty')) {
      return 'Energetic and motivating';
    } else if (themeName.contains('Professional')) {
      return 'Clean and trustworthy';
    } else if (themeName.contains('Vibrant')) {
      return 'Bold and engaging';
    } else if (themeName.contains('Nature')) {
      return 'Calm and organic';
    } else if (themeName.contains('Ocean')) {
      return 'Refreshing and flowing';
    } else if (themeName.contains('Sunset')) {
      return 'Warm and inspiring';
    } else if (themeName.contains('High Contrast')) {
      return 'Maximum visibility';
    }
    return 'Custom theme';
  }
}

// ============================================================================
// COMPACT THEME SWITCHER (Quick Access)
// ============================================================================

class CompactThemeSwitcher extends StatelessWidget {
  const CompactThemeSwitcher({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeCubit, ThemeState>(
      builder: (context, state) {
        final themeCubit = context.read<ThemeCubit>();
        final colorScheme = Theme.of(context).colorScheme;

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Dark/Light Toggle
            IconButton(
              icon: Icon(state.isDark ? Icons.light_mode : Icons.dark_mode),
              tooltip: state.isDark
                  ? 'Switch to Light Mode'
                  : 'Switch to Dark Mode',
              onPressed: themeCubit.toggleMode,
            ),

            const SizedBox(width: AppSpacing.xs),

            // Theme Selector
            TextButton.icon(
              icon: const Icon(Icons.palette_outlined),
              label: Text(state.baseThemeName),
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (context) => DraggableScrollableSheet(
                    initialChildSize: 0.7,
                    minChildSize: 0.5,
                    maxChildSize: 0.95,
                    builder: (context, scrollController) => DecoratedBox(
                      decoration: BoxDecoration(
                        color: colorScheme.surface,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(AppRadius.lg),
                        ),
                      ),
                      child: const AdvancedThemeSelector(),
                    ),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }
}

// ============================================================================
// THEME PREVIEW DIALOG (For Settings Page)
// ============================================================================

class ThemePreviewDialog extends StatelessWidget {
  const ThemePreviewDialog({super.key});

  static void show(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const ThemePreviewDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
        child: const AdvancedThemeSelector(),
      ),
    );
  }
}
