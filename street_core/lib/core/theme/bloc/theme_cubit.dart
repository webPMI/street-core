// ============================================================================
// theme_cubit.dart
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../helpers/device_storage.dart'; // Relative path

import '../../helpers/logger.dart';
import '../app_theme.dart';
import 'theme_state.dart';

/// Theme Management Cubit
///
/// Manages app theme with:
/// - Persistent storage
/// - System theme preference support
/// - Smooth theme transitions
/// - Accessibility features
class ThemeCubit extends Cubit<ThemeState> {
  ThemeCubit({required StorageService storage})
    : _deviceStorage = storage,
      super(const ThemeState(themeName: 'Light', isLoaded: false)) {
    _init();
  }
  static const String themeKey = 'app_theme_name';
  static const String systemThemeKey = 'follow_system_theme';
  static const String highContrastKey = 'high_contrast_mode';

  final StorageService _deviceStorage;

  // ============================================================================
  // INITIALIZATION
  // ============================================================================

  Future<void> _init() async {
    await loadTheme();
    _checkSystemTheme();
  }

  /// Load saved theme preferences
  Future<void> loadTheme() async {
    try {
      final savedTheme = await _deviceStorage.read(themeKey);
      final followSystem = await _deviceStorage.read(systemThemeKey);
      final highContrast = await _deviceStorage.read(highContrastKey);

      if (isClosed) return;

      /// Use default if no saved theme
      /// AQUÍ ESTA EL TEMA POR DEFECTO
      final themeName = savedTheme ?? 'Nature Light';
      final followSystemBool = followSystem == 'true';
      final useHighContrastBool = highContrast == 'true';

      emit(
        ThemeState(
          themeName: themeName,
          followSystemTheme: followSystemBool,
          useHighContrast: useHighContrastBool,
        ),
      );

      // Apply system theme if enabled
      if (followSystemBool) {
        _applySystemTheme();
      }
    } catch (e) {
      AppLogger.error('Error loading theme', error: e, tag: 'Theme');
      if (!isClosed) {
        emit(state.copyWith(isLoaded: true));
      }
    }
  }

  // ============================================================================
  // THEME MANAGEMENT
  // ============================================================================

  /// Set a specific theme
  void setTheme(String themeName, {bool animate = true}) {
    if (!AppTheme.allThemes.containsKey(themeName)) {
      AppLogger.warning('Theme "$themeName" not found', tag: 'Theme');
      return;
    }

    emit(
      state.copyWith(
        themeName: themeName,
        isLoaded: true,
        followSystemTheme: false,
      ),
    );

    _saveTheme(themeName);
    _saveSystemThemePreference(false);
  }

  /// Toggle between light and dark mode of current theme
  void toggleMode() {
    final currentTheme = state.themeName;
    final newTheme = AppTheme.getMatchingTheme(currentTheme, dark: !isDarkMode);

    setTheme(newTheme);
  }

  /// Set theme to match system preference
  void setFollowSystemTheme(bool follow) {
    emit(state.copyWith(followSystemTheme: follow, isLoaded: true));

    _saveSystemThemePreference(follow);

    if (follow) {
      _applySystemTheme();
    }
  }

  /// Toggle high contrast mode for accessibility
  void setHighContrast(bool enabled) {
    final baseName = state.themeName
        .replaceAll(' Light', '')
        .replaceAll(' Dark', '')
        .replaceAll('High Contrast ', '');

    String newTheme;
    if (enabled) {
      // Switch to high contrast version
      newTheme = isDarkMode ? 'High Contrast Dark' : 'High Contrast Light';
    } else {
      // Switch back to regular theme
      newTheme = isDarkMode ? '$baseName Dark' : '$baseName Light';

      ///--------- DEFAULT THEME IF NOT FOUND ---------///
      // Fallback to Sporty if theme doesn't exist
      /// INFLUENCIA DIRECTA AL TEMA, CAMBIAR TEMA POR DEFECTO AQUÍ
      if (!AppTheme.allThemes.containsKey(newTheme)) {
        newTheme = isDarkMode ? 'Oswald Dark' : 'Nature Light';
      }
    }
    emit(
      state.copyWith(
        themeName: newTheme,
        useHighContrast: enabled,
        isLoaded: true,
      ),
    );

    _saveTheme(newTheme);
    _saveHighContrastPreference(enabled);
  }

  /// Set theme by category (e.g., 'Sport', 'Business')
  void setThemeByCategory(String category, {bool dark = false}) {
    final themes = AppTheme.themeCategories[category];
    if (themes == null || themes.isEmpty) {
      AppLogger.warning('Category "$category" not found', tag: 'Theme');
      return;
    }

    final themeName = dark ? themes.last : themes.first;
    setTheme(themeName);
  }

  // ============================================================================
  // SYSTEM THEME INTEGRATION
  // ============================================================================

  /// Check and apply system theme preference
  void _checkSystemTheme() {
    if (state.followSystemTheme) {
      _applySystemTheme();
    }
  }

  /// Apply theme matching system brightness
  void _applySystemTheme() {
    final brightness =
        SchedulerBinding.instance.platformDispatcher.platformBrightness;
    final isDark = brightness == Brightness.dark;

    final currentBaseName = state.themeName
        .replaceAll(' Light', '')
        .replaceAll(' Dark', '')
        .replaceAll('High Contrast ', '');

    String newTheme;
    if (state.useHighContrast) {
      newTheme = isDark ? 'High Contrast Dark' : 'High Contrast Light';
    } else {
      newTheme = AppTheme.getMatchingTheme(currentBaseName, dark: isDark);
    }

    if (newTheme != state.themeName) {
      emit(state.copyWith(themeName: newTheme));
      _saveTheme(newTheme);
    }
  }

  /// Update theme when system theme changes
  void onSystemThemeChanged(Brightness brightness) {
    if (state.followSystemTheme) {
      _applySystemTheme();
    }
  }

  // ============================================================================
  // PERSISTENCE
  // ============================================================================

  Future<void> _saveTheme(String themeName) async {
    try {
      await _deviceStorage.save(themeKey, themeName);
    } catch (e) {
      AppLogger.error('Error saving theme', error: e, tag: 'Theme');
    }
  }

  Future<void> _saveSystemThemePreference(bool follow) async {
    try {
      await _deviceStorage.save(systemThemeKey, follow.toString());
    } catch (e) {
      AppLogger.error(
        'Error saving system theme preference',
        error: e,
        tag: 'Theme',
      );
    }
  }

  Future<void> _saveHighContrastPreference(bool enabled) async {
    try {
      await _deviceStorage.save(highContrastKey, enabled.toString());
    } catch (e) {
      AppLogger.error(
        'Error saving high contrast preference',
        error: e,
        tag: 'Theme',
      );
    }
  }

  // ============================================================================
  // UTILITIES
  // ============================================================================

  /// Get current theme data
  ThemeData get currentTheme {
    return AppTheme.getTheme(state.themeName);
  }

  /// Get current color scheme
  ColorScheme get colorScheme {
    return currentTheme.colorScheme;
  }

  /// Check if current theme is dark
  bool get isDarkMode {
    return AppTheme.isDark(state.themeName);
  }

  /// Check if current theme is light
  bool get isLightMode => !isDarkMode;

  /// Check if high contrast is enabled
  bool get isHighContrast {
    return state.themeName.contains('High Contrast');
  }

  /// Get available themes grouped by category
  Map<String, List<String>> get themeCategories {
    return AppTheme.themeCategories;
  }

  /// Get all available theme names
  List<String> get availableThemes {
    return AppTheme.allThemes.keys.toList();
  }

  /// Get theme preview color
  Color getThemePreviewColor(String themeName) {
    final themeData = AppTheme.getTheme(themeName);
    return themeData.colorScheme.primary;
  }

  // ============================================================================
  // RESET
  // ============================================================================

  /// Reset to default theme
  Future<void> resetToDefault() async {
    setTheme('Sporty Light');
    setFollowSystemTheme(false);
    setHighContrast(false);
  }
}
