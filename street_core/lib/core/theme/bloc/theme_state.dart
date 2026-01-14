import 'package:equatable/equatable.dart';

/// Theme State
///
/// Represents the current theme configuration including:
/// - Selected theme name
/// - System theme following preference
/// - High contrast mode
/// - Load state
class ThemeState extends Equatable {
  const ThemeState({
    required this.themeName,
    this.isLoaded = true,
    this.followSystemTheme = false,
    this.useHighContrast = false,
  });

  /// Name of the current theme (e.g., 'Sporty Light', 'Professional Dark')
  final String themeName;

  /// Whether the theme has been loaded from storage
  final bool isLoaded;

  /// Whether to automatically follow system dark/light mode
  final bool followSystemTheme;

  /// Whether high contrast mode is enabled (accessibility)
  final bool useHighContrast;

  @override
  List<Object?> get props => [
    themeName,
    isLoaded,
    followSystemTheme,
    useHighContrast,
  ];

  ThemeState copyWith({
    String? themeName,
    bool? isLoaded,
    bool? followSystemTheme,
    bool? useHighContrast,
  }) {
    return ThemeState(
      themeName: themeName ?? this.themeName,
      isLoaded: isLoaded ?? this.isLoaded,
      followSystemTheme: followSystemTheme ?? this.followSystemTheme,
      useHighContrast: useHighContrast ?? this.useHighContrast,
    );
  }

  /// Check if theme is dark mode
  bool get isDark => themeName.toLowerCase().contains('dark');

  /// Check if theme is light mode
  bool get isLight => !isDark;

  /// Check if high contrast is currently active
  bool get isHighContrastActive {
    return themeName.contains('High Contrast') || useHighContrast;
  }

  /// Get the base theme name without Light/Dark suffix
  String get baseThemeName {
    return themeName
        .replaceAll(' Light', '')
        .replaceAll(' Dark', '')
        .replaceAll('High Contrast ', '');
  }

  @override
  String toString() {
    return 'ThemeState(themeName: $themeName, isLoaded: $isLoaded, '
        'followSystem: $followSystemTheme, highContrast: $useHighContrast)';
  }
}
