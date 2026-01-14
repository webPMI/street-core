import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_colors.dart';
import 'app_spacing.dart';

/// Street Core Theme System
///
/// Complete Material Design 3 implementation with:
/// - Dynamic color schemes
/// - Comprehensive component themes
/// - Accessibility support
/// - Smooth transitions
class AppTheme {
  // ============================================================================
  // THEME CONFIGURATION
  // ============================================================================

  /// Get font family for a specific theme
  static String _getFontFamily(String themeName) {
    // Sporty themes use Oswald (condensed, athletic)
    if (themeName.contains('Sporty')) {
      return 'Oswald';
    }
    // Professional themes use Roboto (clean, geometric)
    if (themeName.contains('Professional')) {
      return 'Roboto';
    }
    // Vibrant themes use Oswald (bold, energetic)
    if (themeName.contains('Vibrant')) {
      return 'Oswald';
    }
    // Sunset themes use Oswald (modern, warm)
    if (themeName.contains('Sunset')) {
      return 'Oswald';
    }
    // Nature and Ocean themes use OpenSans (friendly, humanist)
    if (themeName.contains('Nature') || themeName.contains('Ocean')) {
      return 'OpenSans';
    }
    // High Contrast themes use Roboto (maximum legibility)
    if (themeName.contains('High Contrast')) {
      return 'Roboto';
    }
    // Default fallback
    return 'OpenSans';
  }

  /// Creates a complete ThemeData from a color scheme
  static ThemeData _buildTheme({
    required ColorScheme colorScheme,
    required Brightness brightness,
    String? themeName,
  }) {
    // Determine font family based on theme
    final fontFamily = themeName != null
        ? _getFontFamily(themeName)
        : 'OpenSans';

    final textTheme = _buildTextTheme(
      colorScheme.onSurface,
      fontFamily: fontFamily,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      fontFamily: fontFamily,

      // SCAFFOLD & BACKGROUNDS
      scaffoldBackgroundColor: colorScheme.surface,
      canvasColor: colorScheme.surface,
      cardColor: colorScheme.surfaceContainerLowest,

      // DIVIDER
      dividerColor: colorScheme.outlineVariant,
      dividerTheme: DividerThemeData(
        color: colorScheme.outlineVariant,
        thickness: 1,
        space: 1,
      ),

      // TEXT THEME
      textTheme: textTheme,
      primaryTextTheme: textTheme,

      // APP BAR
      appBarTheme: _buildAppBarTheme(colorScheme, textTheme),

      // CARDS
      cardTheme: _buildCardTheme(colorScheme),

      // BUTTONS
      elevatedButtonTheme: _buildElevatedButtonTheme(colorScheme),
      filledButtonTheme: _buildFilledButtonTheme(colorScheme),
      outlinedButtonTheme: _buildOutlinedButtonTheme(colorScheme),
      textButtonTheme: _buildTextButtonTheme(colorScheme),
      iconButtonTheme: _buildIconButtonTheme(colorScheme),
      floatingActionButtonTheme: _buildFabTheme(colorScheme),

      // INPUTS
      inputDecorationTheme: _buildInputTheme(colorScheme),

      // CHIPS
      chipTheme: _buildChipTheme(colorScheme),

      // NAVIGATION
      navigationBarTheme: _buildNavigationBarTheme(colorScheme),
      navigationRailTheme: _buildNavigationRailTheme(colorScheme),
      bottomNavigationBarTheme: _buildBottomNavTheme(colorScheme),
      drawerTheme: _buildDrawerTheme(colorScheme),

      // DIALOGS & SHEETS
      dialogTheme: _buildDialogTheme(colorScheme),
      bottomSheetTheme: _buildBottomSheetTheme(colorScheme),

      // LISTS
      listTileTheme: _buildListTileTheme(colorScheme),

      // ICONS
      iconTheme: IconThemeData(
        color: colorScheme.onSurface,
        size: AppIconSize.md,
      ),
      primaryIconTheme: IconThemeData(
        color: colorScheme.primary,
        size: AppIconSize.md,
      ),

      // SNACKBARS
      snackBarTheme: _buildSnackBarTheme(colorScheme),

      // TOOLTIPS
      tooltipTheme: _buildTooltipTheme(colorScheme),

      // SWITCHES & CHECKBOXES
      switchTheme: _buildSwitchTheme(colorScheme),
      checkboxTheme: _buildCheckboxTheme(colorScheme),
      radioTheme: _buildRadioTheme(colorScheme),

      // SLIDERS
      sliderTheme: _buildSliderTheme(colorScheme),

      // PROGRESS INDICATORS
      progressIndicatorTheme: _buildProgressTheme(colorScheme),

      // TAB BAR
      tabBarTheme: _buildTabBarTheme(colorScheme, textTheme),

      // EXPANSION TILE
      expansionTileTheme: _buildExpansionTileTheme(colorScheme),

      // BADGES
      badgeTheme: _buildBadgeTheme(colorScheme),

      // SEARCH BAR
      searchBarTheme: _buildSearchBarTheme(colorScheme),

      // POPUP MENU
      popupMenuTheme: _buildPopupMenuTheme(colorScheme),

      // PAGE TRANSITIONS
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: PredictiveBackPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.linux: FadeUpwardsPageTransitionsBuilder(),
        },
      ),

      // ANIMATIONS
      splashColor: colorScheme.primary.withValues(alpha: 0.12),
      highlightColor: colorScheme.primary.withValues(alpha: 0.08),
      hoverColor: colorScheme.onSurface.withValues(alpha: 0.08),
      focusColor: colorScheme.primary.withValues(alpha: 0.12),

      // VISUAL DENSITY
      visualDensity: VisualDensity.adaptivePlatformDensity,

      // SCROLL BEHAVIOR - Enhanced for smooth scrolling
      scrollbarTheme: ScrollbarThemeData(
        thumbColor: WidgetStateProperty.all(
          colorScheme.primary.withValues(alpha: 0.5),
        ),
        trackColor: WidgetStateProperty.all(
          colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        ),
        trackBorderColor: WidgetStateProperty.all(Colors.transparent),
        radius: const Radius.circular(8),
        thickness: WidgetStateProperty.all(8),
        thumbVisibility: WidgetStateProperty.all(false),
        trackVisibility: WidgetStateProperty.all(false),
      ),
    );
  }

  // ============================================================================
  // COMPONENT THEMES
  // ============================================================================

  static AppBarTheme _buildAppBarTheme(
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    // Use primary color for AppBar in light mode for better branding
    // Use surface container for dark mode for better readability
    final bool isDark = colorScheme.brightness == Brightness.dark;
    final backgroundColor = isDark
        ? colorScheme.surfaceContainer
        : colorScheme.primary;
    final foregroundColor = isDark
        ? colorScheme.onSurface
        : colorScheme.onPrimary;

    return AppBarTheme(
      elevation: 0,
      centerTitle: false,
      scrolledUnderElevation: isDark ? 2 : 4,
      surfaceTintColor: isDark ? colorScheme.surfaceTint : Colors.transparent,
      backgroundColor: backgroundColor,
      foregroundColor: foregroundColor,
      shadowColor: colorScheme.shadow.withValues(alpha: 0.3),
      titleTextStyle: textTheme.titleLarge?.copyWith(
        color: foregroundColor,
        fontWeight: FontWeight.w600,
      ),
      iconTheme: IconThemeData(color: foregroundColor, size: AppIconSize.md),
      actionsIconTheme: IconThemeData(
        color: foregroundColor,
        size: AppIconSize.md,
      ),
      systemOverlayStyle: isDark
          ? SystemUiOverlayStyle.light
          : SystemUiOverlayStyle.light, // Light icons on primary color
    );
  }

  static CardThemeData _buildCardTheme(ColorScheme colorScheme) {
    return CardThemeData(
      elevation: AppElevation.card,
      surfaceTintColor: colorScheme.surfaceTint,
      color: colorScheme.surfaceContainerLowest,
      shadowColor: colorScheme.shadow,
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.cardRadius),
      clipBehavior: Clip.antiAlias,
      margin: AppSpacing.edgeInsetsMD,
    );
  }

  static ElevatedButtonThemeData _buildElevatedButtonTheme(
    ColorScheme colorScheme,
  ) {
    return ElevatedButtonThemeData(
      style:
          ElevatedButton.styleFrom(
            elevation: AppElevation.button,
            backgroundColor: colorScheme.primary,
            foregroundColor: colorScheme.onPrimary,
            disabledBackgroundColor: colorScheme.onSurface.withValues(
              alpha: 0.12,
            ),
            disabledForegroundColor: colorScheme.onSurface.withValues(
              alpha: 0.38,
            ),
            shadowColor: colorScheme.shadow,
            surfaceTintColor: colorScheme.surfaceTint,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            minimumSize: const Size(64, 48),
            maximumSize: const Size(double.infinity, 56),
            shape: const RoundedRectangleBorder(
              borderRadius: AppRadius.buttonRadius,
            ),
            textStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.1,
            ),
          ).copyWith(
            // Enhanced states
            overlayColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.hovered)) {
                return colorScheme.onPrimary.withValues(alpha: 0.08);
              }
              if (states.contains(WidgetState.focused)) {
                return colorScheme.onPrimary.withValues(alpha: 0.12);
              }
              if (states.contains(WidgetState.pressed)) {
                return colorScheme.onPrimary.withValues(alpha: 0.12);
              }
              return null;
            }),
          ),
    );
  }

  static FilledButtonThemeData _buildFilledButtonTheme(
    ColorScheme colorScheme,
  ) {
    return FilledButtonThemeData(
      style: FilledButton.styleFrom(
        elevation: 0,
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        disabledBackgroundColor: colorScheme.onSurface.withValues(alpha: 0.12),
        disabledForegroundColor: colorScheme.onSurface.withValues(alpha: 0.38),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        minimumSize: const Size(64, 48),
        shape: const RoundedRectangleBorder(
          borderRadius: AppRadius.buttonRadius,
        ),
      ),
    );
  }

  static OutlinedButtonThemeData _buildOutlinedButtonTheme(
    ColorScheme colorScheme,
  ) {
    return OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: colorScheme.primary,
        disabledForegroundColor: colorScheme.onSurface.withValues(alpha: 0.38),
        side: BorderSide(color: colorScheme.outline),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        minimumSize: const Size(64, 48),
        shape: const RoundedRectangleBorder(
          borderRadius: AppRadius.buttonRadius,
        ),
      ),
    );
  }

  static TextButtonThemeData _buildTextButtonTheme(ColorScheme colorScheme) {
    return TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: colorScheme.primary,
        disabledForegroundColor: colorScheme.onSurface.withValues(alpha: 0.38),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        minimumSize: const Size(48, 48),
        shape: const RoundedRectangleBorder(
          borderRadius: AppRadius.buttonRadius,
        ),
      ),
    );
  }

  static IconButtonThemeData _buildIconButtonTheme(ColorScheme colorScheme) {
    return IconButtonThemeData(
      style: IconButton.styleFrom(
        foregroundColor: colorScheme.onSurface,
        disabledForegroundColor: colorScheme.onSurface.withValues(alpha: 0.38),
        hoverColor: colorScheme.onSurface.withValues(alpha: 0.08),
        focusColor: colorScheme.onSurface.withValues(alpha: 0.12),
        highlightColor: colorScheme.onSurface.withValues(alpha: 0.12),
        minimumSize: const Size(48, 48),
      ),
    );
  }

  static FloatingActionButtonThemeData _buildFabTheme(ColorScheme colorScheme) {
    return FloatingActionButtonThemeData(
      elevation: AppElevation.lg,
      backgroundColor: colorScheme.primaryContainer,
      foregroundColor: colorScheme.onPrimaryContainer,
      focusElevation: AppElevation.lg,
      hoverElevation: AppElevation.xl,
      highlightElevation: AppElevation.xl,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
    );
  }

  static InputDecorationTheme _buildInputTheme(ColorScheme colorScheme) {
    return InputDecorationTheme(
      filled: true,
      fillColor: colorScheme.surfaceContainerHighest,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
      ),
      border: OutlineInputBorder(
        borderRadius: AppRadius.inputRadius,
        borderSide: BorderSide(color: colorScheme.outline),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: AppRadius.inputRadius,
        borderSide: BorderSide(color: colorScheme.outline),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: AppRadius.inputRadius,
        borderSide: BorderSide(color: colorScheme.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: AppRadius.inputRadius,
        borderSide: BorderSide(color: colorScheme.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: AppRadius.inputRadius,
        borderSide: BorderSide(color: colorScheme.error, width: 2),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: AppRadius.inputRadius,
        borderSide: BorderSide(
          color: colorScheme.onSurface.withValues(alpha: 0.12),
        ),
      ),
      labelStyle: TextStyle(color: colorScheme.onSurfaceVariant),
      hintStyle: TextStyle(color: colorScheme.onSurfaceVariant),
      errorStyle: TextStyle(color: colorScheme.error),
      prefixIconColor: colorScheme.onSurfaceVariant,
      suffixIconColor: colorScheme.onSurfaceVariant,
    );
  }

  static ChipThemeData _buildChipTheme(ColorScheme colorScheme) {
    return ChipThemeData(
      backgroundColor: colorScheme.surfaceContainerHighest,
      deleteIconColor: colorScheme.onSurfaceVariant,
      disabledColor: colorScheme.onSurface.withValues(alpha: 0.12),
      selectedColor: colorScheme.secondaryContainer,
      secondarySelectedColor: colorScheme.secondaryContainer,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      labelPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      labelStyle: TextStyle(color: colorScheme.onSurfaceVariant),
      secondaryLabelStyle: TextStyle(color: colorScheme.onSecondaryContainer),
      brightness: colorScheme.brightness,
      elevation: 0,
      pressElevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
    );
  }

  static NavigationBarThemeData _buildNavigationBarTheme(
    ColorScheme colorScheme,
  ) {
    final bool isDark = colorScheme.brightness == Brightness.dark;

    return NavigationBarThemeData(
      elevation: AppElevation.sm,
      backgroundColor: isDark
          ? colorScheme.surfaceContainer
          : colorScheme.surfaceContainerLowest,
      surfaceTintColor: Colors.transparent,
      indicatorColor: colorScheme.primaryContainer,
      height: 72,
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return TextStyle(
            color: colorScheme.primary,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          );
        }
        return TextStyle(
          color: colorScheme.onSurfaceVariant,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        );
      }),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return IconThemeData(
            color: colorScheme.onPrimaryContainer,
            size: AppIconSize.md,
          );
        }
        return IconThemeData(
          color: colorScheme.onSurfaceVariant,
          size: AppIconSize.md,
        );
      }),
    );
  }

  static NavigationRailThemeData _buildNavigationRailTheme(
    ColorScheme colorScheme,
  ) {
    final bool isDark = colorScheme.brightness == Brightness.dark;

    return NavigationRailThemeData(
      elevation: 0,
      backgroundColor: isDark
          ? colorScheme.surfaceContainerLow
          : colorScheme.surfaceContainerLowest,
      selectedIconTheme: IconThemeData(
        color: colorScheme.onPrimaryContainer,
        size: AppIconSize.md,
      ),
      unselectedIconTheme: IconThemeData(
        color: colorScheme.onSurfaceVariant,
        size: AppIconSize.md,
      ),
      selectedLabelTextStyle: TextStyle(
        color: colorScheme.primary,
        fontWeight: FontWeight.w600,
      ),
      unselectedLabelTextStyle: TextStyle(
        color: colorScheme.onSurfaceVariant,
        fontWeight: FontWeight.w500,
      ),
      indicatorColor: colorScheme.primaryContainer,
    );
  }

  static BottomNavigationBarThemeData _buildBottomNavTheme(
    ColorScheme colorScheme,
  ) {
    final bool isDark = colorScheme.brightness == Brightness.dark;

    return BottomNavigationBarThemeData(
      elevation: AppElevation.md,
      backgroundColor: isDark
          ? colorScheme.surfaceContainer
          : colorScheme.surfaceContainerLowest,
      selectedItemColor: colorScheme.primary,
      unselectedItemColor: colorScheme.onSurfaceVariant,
      selectedIconTheme: IconThemeData(
        color: colorScheme.primary,
        size: AppIconSize.md,
      ),
      unselectedIconTheme: IconThemeData(
        color: colorScheme.onSurfaceVariant,
        size: AppIconSize.md,
      ),
      selectedLabelStyle: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: colorScheme.primary,
      ),
      unselectedLabelStyle: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: colorScheme.onSurfaceVariant,
      ),
      type: BottomNavigationBarType.fixed,
      showSelectedLabels: true,
      showUnselectedLabels: true,
    );
  }

  static DrawerThemeData _buildDrawerTheme(ColorScheme colorScheme) {
    final bool isDark = colorScheme.brightness == Brightness.dark;

    return DrawerThemeData(
      backgroundColor: isDark
          ? colorScheme.surfaceContainerLow
          : colorScheme.surfaceContainerLowest,
      surfaceTintColor: Colors.transparent,
      elevation: AppElevation.lg,
      shadowColor: colorScheme.shadow.withValues(alpha: 0.4),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(AppRadius.lg),
          bottomRight: Radius.circular(AppRadius.lg),
        ),
      ),
      width: 280,
    );
  }

  static DialogThemeData _buildDialogTheme(ColorScheme colorScheme) {
    return DialogThemeData(
      elevation: AppElevation.dialog,
      backgroundColor: colorScheme.surface,
      surfaceTintColor: colorScheme.surfaceTint,
      shadowColor: colorScheme.shadow,
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.dialogRadius),
      alignment: Alignment.center,
      titleTextStyle: TextStyle(
        color: colorScheme.onSurface,
        fontSize: 24,
        fontWeight: FontWeight.w600,
      ),
      contentTextStyle: TextStyle(
        color: colorScheme.onSurfaceVariant,
        fontSize: 14,
        fontWeight: FontWeight.w400,
      ),
    );
  }

  static BottomSheetThemeData _buildBottomSheetTheme(ColorScheme colorScheme) {
    return BottomSheetThemeData(
      elevation: AppElevation.bottomSheet,
      backgroundColor: colorScheme.surface,
      surfaceTintColor: colorScheme.surfaceTint,
      shadowColor: colorScheme.shadow,
      modalElevation: AppElevation.bottomSheet,
      modalBackgroundColor: colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(AppRadius.lg),
          topRight: Radius.circular(AppRadius.lg),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      constraints: const BoxConstraints(maxWidth: 640),
    );
  }

  static ListTileThemeData _buildListTileTheme(ColorScheme colorScheme) {
    return ListTileThemeData(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      iconColor: colorScheme.onSurfaceVariant,
      textColor: colorScheme.onSurface,
      tileColor: Colors.transparent,
      selectedTileColor: colorScheme.secondaryContainer.withValues(alpha: 0.12),
      selectedColor: colorScheme.onSecondaryContainer,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      minVerticalPadding: AppSpacing.xs,
      minLeadingWidth: 40,
    );
  }

  static SnackBarThemeData _buildSnackBarTheme(ColorScheme colorScheme) {
    return SnackBarThemeData(
      elevation: AppElevation.md,
      backgroundColor: colorScheme.inverseSurface,
      contentTextStyle: TextStyle(
        color: colorScheme.onInverseSurface,
        fontSize: 14,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      behavior: SnackBarBehavior.floating,
      actionTextColor: colorScheme.inversePrimary,
    );
  }

  static TooltipThemeData _buildTooltipTheme(ColorScheme colorScheme) {
    return TooltipThemeData(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      margin: const EdgeInsets.all(AppSpacing.sm),
      verticalOffset: 24,
      preferBelow: true,
      constraints: const BoxConstraints(minHeight: 32),
      decoration: BoxDecoration(
        color: colorScheme.inverseSurface.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(AppRadius.xs),
      ),
      textStyle: TextStyle(
        color: colorScheme.onInverseSurface,
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
      waitDuration: const Duration(milliseconds: 500),
      showDuration: const Duration(milliseconds: 1500),
    );
  }

  static SwitchThemeData _buildSwitchTheme(ColorScheme colorScheme) {
    return SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) {
          return colorScheme.onSurface.withValues(alpha: 0.38);
        }
        if (states.contains(WidgetState.selected)) {
          return colorScheme.onPrimary;
        }
        return colorScheme.outline;
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) {
          return colorScheme.surfaceContainerHighest.withValues(alpha: 0.12);
        }
        if (states.contains(WidgetState.selected)) {
          return colorScheme.primary;
        }
        return colorScheme.surfaceContainerHighest;
      }),
      trackOutlineColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return null;
        }
        return colorScheme.outline;
      }),
    );
  }

  static CheckboxThemeData _buildCheckboxTheme(ColorScheme colorScheme) {
    return CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) {
          return colorScheme.onSurface.withValues(alpha: 0.38);
        }
        if (states.contains(WidgetState.selected)) {
          return colorScheme.primary;
        }
        return Colors.transparent;
      }),
      checkColor: WidgetStateProperty.all(colorScheme.onPrimary),
      overlayColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.hovered)) {
          return colorScheme.primary.withValues(alpha: 0.08);
        }
        if (states.contains(WidgetState.focused)) {
          return colorScheme.primary.withValues(alpha: 0.12);
        }
        if (states.contains(WidgetState.pressed)) {
          return colorScheme.primary.withValues(alpha: 0.12);
        }
        return null;
      }),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
    );
  }

  static RadioThemeData _buildRadioTheme(ColorScheme colorScheme) {
    return RadioThemeData(
      fillColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) {
          return colorScheme.onSurface.withValues(alpha: 0.38);
        }
        if (states.contains(WidgetState.selected)) {
          return colorScheme.primary;
        }
        return colorScheme.onSurfaceVariant;
      }),
      overlayColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.hovered)) {
          return colorScheme.primary.withValues(alpha: 0.08);
        }
        if (states.contains(WidgetState.focused)) {
          return colorScheme.primary.withValues(alpha: 0.12);
        }
        if (states.contains(WidgetState.pressed)) {
          return colorScheme.primary.withValues(alpha: 0.12);
        }
        return null;
      }),
    );
  }

  static SliderThemeData _buildSliderTheme(ColorScheme colorScheme) {
    return SliderThemeData(
      activeTrackColor: colorScheme.primary,
      inactiveTrackColor: colorScheme.surfaceContainerHighest,
      thumbColor: colorScheme.primary,
      overlayColor: colorScheme.primary.withValues(alpha: 0.12),
      valueIndicatorColor: colorScheme.primary,
      valueIndicatorTextStyle: TextStyle(
        color: colorScheme.onPrimary,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      trackHeight: 4,
      thumbShape: const RoundSliderThumbShape(),
      overlayShape: const RoundSliderOverlayShape(overlayRadius: 20),
    );
  }

  static ProgressIndicatorThemeData _buildProgressTheme(
    ColorScheme colorScheme,
  ) {
    return ProgressIndicatorThemeData(
      color: colorScheme.primary,
      linearTrackColor: colorScheme.surfaceContainerHighest,
      circularTrackColor: colorScheme.surfaceContainerHighest,
      refreshBackgroundColor: colorScheme.surface,
    );
  }

  static TabBarThemeData _buildTabBarTheme(
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    return TabBarThemeData(
      labelColor: colorScheme.primary,
      unselectedLabelColor: colorScheme.onSurfaceVariant,
      indicatorColor: colorScheme.primary,
      indicatorSize: TabBarIndicatorSize.tab,
      dividerColor: colorScheme.surfaceContainerHighest,
      labelStyle: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
      unselectedLabelStyle: textTheme.titleSmall?.copyWith(
        fontWeight: FontWeight.w500,
      ),
      overlayColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.hovered)) {
          return colorScheme.primary.withValues(alpha: 0.08);
        }
        if (states.contains(WidgetState.focused)) {
          return colorScheme.primary.withValues(alpha: 0.12);
        }
        if (states.contains(WidgetState.pressed)) {
          return colorScheme.primary.withValues(alpha: 0.12);
        }
        return null;
      }),
    );
  }

  static ExpansionTileThemeData _buildExpansionTileTheme(
    ColorScheme colorScheme,
  ) {
    return ExpansionTileThemeData(
      backgroundColor: Colors.transparent,
      collapsedBackgroundColor: Colors.transparent,
      iconColor: colorScheme.onSurfaceVariant,
      collapsedIconColor: colorScheme.onSurfaceVariant,
      textColor: colorScheme.onSurface,
      collapsedTextColor: colorScheme.onSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      collapsedShape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      tilePadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
    );
  }

  static BadgeThemeData _buildBadgeTheme(ColorScheme colorScheme) {
    return BadgeThemeData(
      backgroundColor: colorScheme.error,
      textColor: colorScheme.onError,
      smallSize: 6,
      largeSize: 16,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      alignment: AlignmentDirectional.topEnd,
    );
  }

  static SearchBarThemeData _buildSearchBarTheme(ColorScheme colorScheme) {
    return SearchBarThemeData(
      elevation: WidgetStateProperty.all(AppElevation.none),
      backgroundColor: WidgetStateProperty.all(
        colorScheme.surfaceContainerHighest,
      ),
      surfaceTintColor: WidgetStateProperty.all(colorScheme.surfaceTint),
      overlayColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.hovered)) {
          return colorScheme.onSurface.withValues(alpha: 0.08);
        }
        if (states.contains(WidgetState.focused)) {
          return colorScheme.onSurface.withValues(alpha: 0.12);
        }
        return null;
      }),
      side: WidgetStateProperty.all(BorderSide(color: colorScheme.outline)),
      shape: WidgetStateProperty.all(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.full),
        ),
      ),
      padding: WidgetStateProperty.all(
        const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      ),
      textStyle: WidgetStateProperty.all(
        TextStyle(color: colorScheme.onSurface),
      ),
      hintStyle: WidgetStateProperty.all(
        TextStyle(color: colorScheme.onSurfaceVariant),
      ),
    );
  }

  static PopupMenuThemeData _buildPopupMenuTheme(ColorScheme colorScheme) {
    return PopupMenuThemeData(
      elevation: AppElevation.md,
      color: colorScheme.surface,
      surfaceTintColor: colorScheme.surfaceTint,
      shadowColor: colorScheme.shadow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      textStyle: TextStyle(color: colorScheme.onSurface, fontSize: 14),
      labelTextStyle: WidgetStateProperty.all(
        TextStyle(color: colorScheme.onSurface),
      ),
    );
  }

  // ============================================================================
  // TEXT THEME
  // ============================================================================

  static TextTheme _buildTextTheme(Color textColor, {String? fontFamily}) {
    return TextTheme(
      // Display styles - largest text
      displayLarge: TextStyle(
        fontFamily: fontFamily,
        fontWeight: FontWeight.w400,
        fontSize: 57,
        height: 1.12,
        letterSpacing: -0.25,
        color: textColor,
      ),
      displayMedium: TextStyle(
        fontFamily: fontFamily,
        fontWeight: FontWeight.w400,
        fontSize: 45,
        height: 1.16,
        color: textColor,
      ),
      displaySmall: TextStyle(
        fontFamily: fontFamily,
        fontWeight: FontWeight.w400,
        fontSize: 36,
        height: 1.22,
        color: textColor,
      ),

      // Headline styles
      headlineLarge: TextStyle(
        fontFamily: fontFamily,
        fontWeight: FontWeight.w400,
        fontSize: 32,
        height: 1.25,
        color: textColor,
      ),
      headlineMedium: TextStyle(
        fontFamily: fontFamily,
        fontWeight: FontWeight.w400,
        fontSize: 28,
        height: 1.29,
        color: textColor,
      ),
      headlineSmall: TextStyle(
        fontFamily: fontFamily,
        fontWeight: FontWeight.w400,
        fontSize: 24,
        height: 1.33,
        color: textColor,
      ),

      // Title styles
      titleLarge: TextStyle(
        fontFamily: fontFamily,
        fontWeight: FontWeight.w500,
        fontSize: 22,
        height: 1.27,
        color: textColor,
      ),
      titleMedium: TextStyle(
        fontFamily: fontFamily,
        fontWeight: FontWeight.w500,
        fontSize: 16,
        height: 1.50,
        letterSpacing: 0.15,
        color: textColor,
      ),
      titleSmall: TextStyle(
        fontFamily: fontFamily,
        fontWeight: FontWeight.w500,
        fontSize: 14,
        height: 1.43,
        letterSpacing: 0.1,
        color: textColor,
      ),

      // Body styles
      bodyLarge: TextStyle(
        fontFamily: fontFamily,
        fontWeight: FontWeight.w400,
        fontSize: 16,
        height: 1.50,
        letterSpacing: 0.5,
        color: textColor,
      ),
      bodyMedium: TextStyle(
        fontFamily: fontFamily,
        fontWeight: FontWeight.w400,
        fontSize: 14,
        height: 1.43,
        letterSpacing: 0.25,
        color: textColor,
      ),
      bodySmall: TextStyle(
        fontFamily: fontFamily,
        fontWeight: FontWeight.w400,
        fontSize: 12,
        height: 1.33,
        letterSpacing: 0.4,
        color: textColor,
      ),

      // Label styles
      labelLarge: TextStyle(
        fontFamily: fontFamily,
        fontWeight: FontWeight.w500,
        fontSize: 14,
        height: 1.43,
        letterSpacing: 0.1,
        color: textColor,
      ),
      labelMedium: TextStyle(
        fontFamily: fontFamily,
        fontWeight: FontWeight.w500,
        fontSize: 12,
        height: 1.33,
        letterSpacing: 0.5,
        color: textColor,
      ),
      labelSmall: TextStyle(
        fontFamily: fontFamily,
        fontWeight: FontWeight.w500,
        fontSize: 11,
        height: 1.45,
        letterSpacing: 0.5,
        color: textColor,
      ),
    );
  }

  // ============================================================================
  // PREDEFINED THEMES
  // ============================================================================

  // SPORTY THEME (Primary theme for Street Core) - Oswald font
  static final ThemeData sportyLight = _buildTheme(
    colorScheme: AppColors.sportyLightScheme,
    brightness: Brightness.light,
    themeName: 'Sporty Light',
  );

  static final ThemeData sportyDark = _buildTheme(
    colorScheme: AppColors.sportyDarkScheme,
    brightness: Brightness.dark,
    themeName: 'Sporty Dark',
  );

  // PROFESSIONAL THEME - Roboto font
  static final ThemeData professionalLight = _buildTheme(
    colorScheme: AppColors.professionalLightScheme,
    brightness: Brightness.light,
    themeName: 'Professional Light',
  );

  static final ThemeData professionalDark = _buildTheme(
    colorScheme: AppColors.professionalDarkScheme,
    brightness: Brightness.dark,
    themeName: 'Professional Dark',
  );

  // VIBRANT THEME - Oswald font
  static final ThemeData vibrantLight = _buildTheme(
    colorScheme: AppColors.vibrantLightScheme,
    brightness: Brightness.light,
    themeName: 'Vibrant Light',
  );

  static final ThemeData vibrantDark = _buildTheme(
    colorScheme: AppColors.vibrantDarkScheme,
    brightness: Brightness.dark,
    themeName: 'Vibrant Dark',
  );

  // NATURE THEME - OpenSans font
  static final ThemeData natureLight = _buildTheme(
    colorScheme: AppColors.natureLightScheme,
    brightness: Brightness.light,
    themeName: 'Nature Light',
  );

  static final ThemeData natureDark = _buildTheme(
    colorScheme: AppColors.natureDarkScheme,
    brightness: Brightness.dark,
    themeName: 'Nature Dark',
  );

  // OCEAN THEME - OpenSans font
  static final ThemeData oceanLight = _buildTheme(
    colorScheme: AppColors.oceanLightScheme,
    brightness: Brightness.light,
    themeName: 'Ocean Light',
  );

  static final ThemeData oceanDark = _buildTheme(
    colorScheme: AppColors.oceanDarkScheme,
    brightness: Brightness.dark,
    themeName: 'Ocean Dark',
  );

  // SUNSET THEME - Oswald font
  static final ThemeData sunsetLight = _buildTheme(
    colorScheme: AppColors.sunsetLightScheme,
    brightness: Brightness.light,
    themeName: 'Sunset Light',
  );

  static final ThemeData sunsetDark = _buildTheme(
    colorScheme: AppColors.sunsetDarkScheme,
    brightness: Brightness.dark,
    themeName: 'Sunset Dark',
  );

  // HIGH CONTRAST THEMES (Accessibility) - Roboto font for maximum legibility
  static final ThemeData highContrastLight = _buildTheme(
    colorScheme: AppColors.highContrastLightScheme,
    brightness: Brightness.light,
    themeName: 'High Contrast Light',
  );

  static final ThemeData highContrastDark = _buildTheme(
    colorScheme: AppColors.highContrastDarkScheme,
    brightness: Brightness.dark,
    themeName: 'High Contrast Dark',
  );

  // ============================================================================
  // THEME MAP
  // ============================================================================

  static final Map<String, ThemeData> allThemes = {
    // Sporty (Default)
    'Sporty Light': sportyLight,
    'Sporty Dark': sportyDark,

    // Professional
    'Professional Light': professionalLight,
    'Professional Dark': professionalDark,

    // Vibrant
    'Vibrant Light': vibrantLight,
    'Vibrant Dark': vibrantDark,

    // Nature
    'Nature Light': natureLight,
    'Nature Dark': natureDark,

    // Ocean
    'Ocean Light': oceanLight,
    'Ocean Dark': oceanDark,

    // Sunset
    'Sunset Light': sunsetLight,
    'Sunset Dark': sunsetDark,

    // High Contrast (Accessibility)
    'High Contrast Light': highContrastLight,
    'High Contrast Dark': highContrastDark,
  };

  // ============================================================================
  // THEME CATEGORIES
  // ============================================================================

  static const Map<String, List<String>> themeCategories = {
    'Sport': ['Sporty Light', 'Sporty Dark'],
    'Business': ['Professional Light', 'Professional Dark'],
    'Energetic': ['Vibrant Light', 'Vibrant Dark'],
    'Natural': ['Nature Light', 'Nature Dark'],
    'Calm': ['Ocean Light', 'Ocean Dark'],
    'Warm': ['Sunset Light', 'Sunset Dark'],
    'Accessibility': ['High Contrast Light', 'High Contrast Dark'],
  };

  // ============================================================================
  // GETTERS
  // ============================================================================

  static ThemeData get lightTheme => sportyLight;
  static ThemeData get darkTheme => sportyDark;

  /// Get theme by name, with fallback
  static ThemeData getTheme(String name) {
    return allThemes[name] ?? sportyLight;
  }

  /// Check if theme is dark
  static bool isDark(String themeName) {
    return themeName.toLowerCase().contains('dark');
  }

  /// Get matching dark/light theme
  static String getMatchingTheme(String currentTheme, {required bool dark}) {
    final baseName = currentTheme
        .replaceAll(' Light', '')
        .replaceAll(' Dark', '');
    final targetName = '$baseName ${dark ? 'Dark' : 'Light'}';
    return allThemes.containsKey(targetName) ? targetName : currentTheme;
  }
}
