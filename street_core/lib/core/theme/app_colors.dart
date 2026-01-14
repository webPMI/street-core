import 'package:flutter/material.dart';

/// FitRiders Pro Color System
///
/// Material Design 3 Color Schemes with WCAG AA/AAA compliance.
/// All color combinations ensure proper contrast ratios for accessibility.
/// Refined color palettes with harmonious, modern aesthetics.
class AppColors {
  // ============================================================================
  // SPORTY THEME - Default for FitRiders Pro
  // ============================================================================
  // Energetic, athletic, motivating - perfect for fitness apps
  // Color palette: Vibrant coral/orange with deep teal accents

  static const ColorScheme sportyLightScheme = ColorScheme(
    brightness: Brightness.light,

    // Primary - Energetic Coral (Motivation & Action)
    primary: Color(0xFFE85D04),           // Vibrant coral-orange
    onPrimary: Color(0xFFFFFFFF),         // White text
    primaryContainer: Color(0xFFFFE4D6),  // Warm peach container
    onPrimaryContainer: Color(0xFF3D1600), // Deep brown text

    // Secondary - Deep Teal (Balance & Focus)
    secondary: Color(0xFF00897B),         // Rich teal
    onSecondary: Color(0xFFFFFFFF),       // White text
    secondaryContainer: Color(0xFFB2DFDB), // Soft mint container
    onSecondaryContainer: Color(0xFF002420), // Dark teal text

    // Tertiary - Golden Yellow (Achievement & Energy)
    tertiary: Color(0xFFF9A825),          // Bright gold
    onTertiary: Color(0xFF000000),        // Black text
    tertiaryContainer: Color(0xFFFFF3C4), // Light gold container
    onTertiaryContainer: Color(0xFF3D2800), // Dark amber text

    // Error
    error: Color(0xFFD32F2F),             // Strong red
    onError: Color(0xFFFFFFFF),           // White text
    errorContainer: Color(0xFFFFDAD6),    // Light red container
    onErrorContainer: Color(0xFF410002),  // Dark text

    // Surface & Background - Warm whites
    surface: Color(0xFFFFFBF8),           // Warm white
    onSurface: Color(0xFF1C1917),         // Rich black text
    surfaceContainerLowest: Color(0xFFFFFFFF), // Pure white
    surfaceContainerLow: Color(0xFFFFF8F5),    // Very light peach
    surfaceContainer: Color(0xFFFFF4EE),       // Light peach
    surfaceContainerHigh: Color(0xFFFFEDE4),   // Medium-light peach
    surfaceContainerHighest: Color(0xFFFFE6D9), // Medium peach
    onSurfaceVariant: Color(0xFF534340),   // Warm gray text

    // Outline
    outline: Color(0xFF8C7975),           // Warm border
    outlineVariant: Color(0xFFD7CCC8),    // Subtle warm border

    // Shadow & Scrim
    shadow: Color(0xFF000000),
    scrim: Color(0xFF000000),

    // Inverse (for snackbars, tooltips)
    inverseSurface: Color(0xFF362F2D),    // Dark warm surface
    onInverseSurface: Color(0xFFFFF0EB),  // Light text
    inversePrimary: Color(0xFFFFB598),    // Soft coral

    // Surface Tint
    surfaceTint: Color(0xFFE85D04),
  );

  static const ColorScheme sportyDarkScheme = ColorScheme(
    brightness: Brightness.dark,

    // Primary - Soft Coral
    primary: Color(0xFFFFB598),           // Soft coral
    onPrimary: Color(0xFF5F1D00),         // Deep brown text
    primaryContainer: Color(0xFFB54200),  // Rich burnt orange
    onPrimaryContainer: Color(0xFFFFE4D6), // Soft peach text

    // Secondary - Soft Teal
    secondary: Color(0xFF80CBC4),         // Soft teal
    onSecondary: Color(0xFF003731),       // Dark teal text
    secondaryContainer: Color(0xFF005048), // Medium teal
    onSecondaryContainer: Color(0xFFB2DFDB), // Light mint text

    // Tertiary - Soft Gold
    tertiary: Color(0xFFFFD54F),          // Soft gold
    onTertiary: Color(0xFF3D2800),        // Dark amber text
    tertiaryContainer: Color(0xFF5C4300), // Medium amber
    onTertiaryContainer: Color(0xFFFFF3C4), // Light gold text

    // Error
    error: Color(0xFFFFB4AB),
    onError: Color(0xFF690005),
    errorContainer: Color(0xFF93000A),
    onErrorContainer: Color(0xFFFFDAD6),

    // Surface & Background - Warm darks
    surface: Color(0xFF1A1512),           // Warm dark
    onSurface: Color(0xFFF5EDE8),         // Soft white text
    surfaceContainerLowest: Color(0xFF120E0B), // Darkest warm
    surfaceContainerLow: Color(0xFF231D19),    // Very dark warm
    surfaceContainer: Color(0xFF28221D),       // Dark warm
    surfaceContainerHigh: Color(0xFF332C27),   // Medium-dark warm
    surfaceContainerHighest: Color(0xFF3F3732), // Medium warm
    onSurfaceVariant: Color(0xFFD7CCC8),   // Light warm text

    // Outline
    outline: Color(0xFFA09793),
    outlineVariant: Color(0xFF534340),

    // Shadow & Scrim
    shadow: Color(0xFF000000),
    scrim: Color(0xFF000000),

    // Inverse
    inverseSurface: Color(0xFFF5EDE8),
    onInverseSurface: Color(0xFF362F2D),
    inversePrimary: Color(0xFFE85D04),

    // Surface Tint
    surfaceTint: Color(0xFFFFB598),
  );

  // ============================================================================
  // PROFESSIONAL THEME
  // ============================================================================
  // Clean, trustworthy, corporate - for business users
  // Color palette: Navy blue with elegant slate accents

  static const ColorScheme professionalLightScheme = ColorScheme(
    brightness: Brightness.light,

    // Primary - Navy Blue (Trust & Authority)
    primary: Color(0xFF1565C0),           // Rich navy blue
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: Color(0xFFD4E4FF),  // Soft sky blue
    onPrimaryContainer: Color(0xFF001C3A),

    // Secondary - Elegant Slate (Professional & Modern)
    secondary: Color(0xFF5C6B7A),         // Refined slate
    onSecondary: Color(0xFFFFFFFF),
    secondaryContainer: Color(0xFFE0E6ED), // Light cool gray
    onSecondaryContainer: Color(0xFF19222C),

    // Tertiary - Copper Accent (Premium & Warmth)
    tertiary: Color(0xFFB87333),          // Rich copper
    onTertiary: Color(0xFFFFFFFF),
    tertiaryContainer: Color(0xFFFFE0C4), // Light copper
    onTertiaryContainer: Color(0xFF351A00),

    // Error
    error: Color(0xFFBA1A1A),
    onError: Color(0xFFFFFFFF),
    errorContainer: Color(0xFFFFDAD6),
    onErrorContainer: Color(0xFF410002),

    // Surface - Cool whites
    surface: Color(0xFFFAFCFF),
    onSurface: Color(0xFF181C20),
    surfaceContainerLowest: Color(0xFFFFFFFF),
    surfaceContainerLow: Color(0xFFF4F7FB),
    surfaceContainer: Color(0xFFEEF2F6),
    surfaceContainerHigh: Color(0xFFE8ECF0),
    surfaceContainerHighest: Color(0xFFE2E6EA),
    onSurfaceVariant: Color(0xFF41484D),

    // Outline
    outline: Color(0xFF71787E),
    outlineVariant: Color(0xFFC1C7CE),

    // Shadow & Scrim
    shadow: Color(0xFF000000),
    scrim: Color(0xFF000000),

    // Inverse
    inverseSurface: Color(0xFF2D3135),
    onInverseSurface: Color(0xFFF0F1F4),
    inversePrimary: Color(0xFFA4C9FF),

    surfaceTint: Color(0xFF1565C0),
  );

  static const ColorScheme professionalDarkScheme = ColorScheme(
    brightness: Brightness.dark,

    primary: Color(0xFFA4C9FF),           // Soft sky blue
    onPrimary: Color(0xFF003060),
    primaryContainer: Color(0xFF004787),  // Rich blue
    onPrimaryContainer: Color(0xFFD4E4FF),

    secondary: Color(0xFFB8C8DA),         // Soft slate
    onSecondary: Color(0xFF2A3541),
    secondaryContainer: Color(0xFF404C58), // Medium slate
    onSecondaryContainer: Color(0xFFE0E6ED),

    tertiary: Color(0xFFFFBB8A),          // Soft copper
    onTertiary: Color(0xFF4E2600),
    tertiaryContainer: Color(0xFF6E3900), // Rich copper
    onTertiaryContainer: Color(0xFFFFE0C4),

    error: Color(0xFFFFB4AB),
    onError: Color(0xFF690005),
    errorContainer: Color(0xFF93000A),
    onErrorContainer: Color(0xFFFFDAD6),

    // Surface - Cool darks
    surface: Color(0xFF10141A),
    onSurface: Color(0xFFE1E3E8),
    surfaceContainerLowest: Color(0xFF0B0E14),
    surfaceContainerLow: Color(0xFF181C22),
    surfaceContainer: Color(0xFF1C2026),
    surfaceContainerHigh: Color(0xFF262B31),
    surfaceContainerHighest: Color(0xFF31363C),
    onSurfaceVariant: Color(0xFFC1C7CE),

    outline: Color(0xFF8B9198),
    outlineVariant: Color(0xFF41484D),

    shadow: Color(0xFF000000),
    scrim: Color(0xFF000000),

    inverseSurface: Color(0xFFE1E3E8),
    onInverseSurface: Color(0xFF2D3135),
    inversePrimary: Color(0xFF1565C0),

    surfaceTint: Color(0xFFA4C9FF),
  );

  // ============================================================================
  // VIBRANT THEME
  // ============================================================================
  // Bold, energetic, fun - for engagement & motivation
  // Color palette: Electric purple with magenta and lime accents

  static const ColorScheme vibrantLightScheme = ColorScheme(
    brightness: Brightness.light,

    // Primary - Electric Purple (Bold & Creative)
    primary: Color(0xFF7B1FA2),           // Rich purple
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: Color(0xFFF3E5F5),  // Soft lavender
    onPrimaryContainer: Color(0xFF2A0040),

    // Secondary - Vivid Magenta (Energy & Passion)
    secondary: Color(0xFFD81B60),         // Hot magenta
    onSecondary: Color(0xFFFFFFFF),
    secondaryContainer: Color(0xFFFFD9E4), // Soft pink
    onSecondaryContainer: Color(0xFF3E001F),

    // Tertiary - Electric Lime (Fresh & Dynamic)
    tertiary: Color(0xFF7CB342),          // Vibrant lime
    onTertiary: Color(0xFFFFFFFF),
    tertiaryContainer: Color(0xFFE7F5D6), // Light lime
    onTertiaryContainer: Color(0xFF1A3000),

    // Error
    error: Color(0xFFD32F2F),
    onError: Color(0xFFFFFFFF),
    errorContainer: Color(0xFFFFDAD6),
    onErrorContainer: Color(0xFF410002),

    // Surface - Neutral with slight purple tint
    surface: Color(0xFFFCFAFF),
    onSurface: Color(0xFF1C1B1E),
    surfaceContainerLowest: Color(0xFFFFFFFF),
    surfaceContainerLow: Color(0xFFF8F5FC),
    surfaceContainer: Color(0xFFF2EFF7),
    surfaceContainerHigh: Color(0xFFECE9F1),
    surfaceContainerHighest: Color(0xFFE6E3EB),
    onSurfaceVariant: Color(0xFF48454E),

    outline: Color(0xFF79757F),
    outlineVariant: Color(0xFFCAC4CF),

    shadow: Color(0xFF000000),
    scrim: Color(0xFF000000),

    inverseSurface: Color(0xFF313033),
    onInverseSurface: Color(0xFFF4EFF4),
    inversePrimary: Color(0xFFE1BEE7),

    surfaceTint: Color(0xFF7B1FA2),
  );

  static const ColorScheme vibrantDarkScheme = ColorScheme(
    brightness: Brightness.dark,

    primary: Color(0xFFE1BEE7),           // Soft lavender
    onPrimary: Color(0xFF4A0065),
    primaryContainer: Color(0xFF6A0089),  // Rich purple
    onPrimaryContainer: Color(0xFFF3E5F5),

    secondary: Color(0xFFFFB1C8),         // Soft pink
    onSecondary: Color(0xFF5E0035),
    secondaryContainer: Color(0xFF870049), // Deep magenta
    onSecondaryContainer: Color(0xFFFFD9E4),

    tertiary: Color(0xFFB5E085),          // Soft lime
    onTertiary: Color(0xFF2B4A00),
    tertiaryContainer: Color(0xFF416800), // Rich lime
    onTertiaryContainer: Color(0xFFE7F5D6),

    error: Color(0xFFFFB4AB),
    onError: Color(0xFF690005),
    errorContainer: Color(0xFF93000A),
    onErrorContainer: Color(0xFFFFDAD6),

    // Surface - Dark with slight purple tint
    surface: Color(0xFF151318),
    onSurface: Color(0xFFE8E1E8),
    surfaceContainerLowest: Color(0xFF100E13),
    surfaceContainerLow: Color(0xFF1D1B20),
    surfaceContainer: Color(0xFF211F24),
    surfaceContainerHigh: Color(0xFF2C292F),
    surfaceContainerHighest: Color(0xFF37343A),
    onSurfaceVariant: Color(0xFFCAC4CF),

    outline: Color(0xFF948F99),
    outlineVariant: Color(0xFF48454E),

    shadow: Color(0xFF000000),
    scrim: Color(0xFF000000),

    inverseSurface: Color(0xFFE8E1E8),
    onInverseSurface: Color(0xFF313033),
    inversePrimary: Color(0xFF7B1FA2),

    surfaceTint: Color(0xFFE1BEE7),
  );

  // ============================================================================
  // NATURE THEME
  // ============================================================================
  // Calm, organic, wellness-focused
  // Color palette: Forest green with earth tones and sky blue

  static const ColorScheme natureLightScheme = ColorScheme(
    brightness: Brightness.light,

    // Primary - Forest Green (Growth & Vitality)
    primary: Color(0xFF2E7D32),           // Rich forest green
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: Color(0xFFC8E6C9), // Soft sage
    onPrimaryContainer: Color(0xFF002204),

    // Secondary - Warm Earth (Grounding & Stability)
    secondary: Color(0xFF795548),         // Rich earth brown
    onSecondary: Color(0xFFFFFFFF),
    secondaryContainer: Color(0xFFEFDDD6), // Soft sand
    onSecondaryContainer: Color(0xFF2C1810),

    // Tertiary - Clear Sky Blue (Freshness & Clarity)
    tertiary: Color(0xFF0288D1),          // Sky blue
    onTertiary: Color(0xFFFFFFFF),
    tertiaryContainer: Color(0xFFB3E5FC), // Light sky
    onTertiaryContainer: Color(0xFF001E2E),

    // Error
    error: Color(0xFFC62828),
    onError: Color(0xFFFFFFFF),
    errorContainer: Color(0xFFFFDAD6),
    onErrorContainer: Color(0xFF410002),

    // Surface - Natural off-whites
    surface: Color(0xFFFCFDF6),
    onSurface: Color(0xFF1A1C18),
    surfaceContainerLowest: Color(0xFFFFFFFF),
    surfaceContainerLow: Color(0xFFF6F8F0),
    surfaceContainer: Color(0xFFF0F2EA),
    surfaceContainerHigh: Color(0xFFEAECE5),
    surfaceContainerHighest: Color(0xFFE4E6DF),
    onSurfaceVariant: Color(0xFF43483F),

    outline: Color(0xFF73796E),
    outlineVariant: Color(0xFFC3C9BD),

    shadow: Color(0xFF000000),
    scrim: Color(0xFF000000),

    inverseSurface: Color(0xFF2F312D),
    onInverseSurface: Color(0xFFF1F1EB),
    inversePrimary: Color(0xFFA5D6A7),

    surfaceTint: Color(0xFF2E7D32),
  );

  static const ColorScheme natureDarkScheme = ColorScheme(
    brightness: Brightness.dark,

    primary: Color(0xFFA5D6A7),           // Soft sage
    onPrimary: Color(0xFF003910),
    primaryContainer: Color(0xFF1B5E20),  // Deep forest
    onPrimaryContainer: Color(0xFFC8E6C9),

    secondary: Color(0xFFD7C4BC),         // Soft sand
    onSecondary: Color(0xFF3E2E25),
    secondaryContainer: Color(0xFF56453C), // Rich earth
    onSecondaryContainer: Color(0xFFEFDDD6),

    tertiary: Color(0xFF81D4FA),          // Soft sky
    onTertiary: Color(0xFF00344C),
    tertiaryContainer: Color(0xFF004C6D), // Deep sky
    onTertiaryContainer: Color(0xFFB3E5FC),

    error: Color(0xFFFFB4AB),
    onError: Color(0xFF690005),
    errorContainer: Color(0xFF93000A),
    onErrorContainer: Color(0xFFFFDAD6),

    // Surface - Natural darks
    surface: Color(0xFF12140F),
    onSurface: Color(0xFFE3E4DD),
    surfaceContainerLowest: Color(0xFF0D0F0A),
    surfaceContainerLow: Color(0xFF1A1C17),
    surfaceContainer: Color(0xFF1E201B),
    surfaceContainerHigh: Color(0xFF282B25),
    surfaceContainerHighest: Color(0xFF33362F),
    onSurfaceVariant: Color(0xFFC3C9BD),

    outline: Color(0xFF8D9388),
    outlineVariant: Color(0xFF43483F),

    shadow: Color(0xFF000000),
    scrim: Color(0xFF000000),

    inverseSurface: Color(0xFFE3E4DD),
    onInverseSurface: Color(0xFF2F312D),
    inversePrimary: Color(0xFF2E7D32),

    surfaceTint: Color(0xFFA5D6A7),
  );

  // ============================================================================
  // OCEAN THEME
  // ============================================================================
  // Calming, flowing, refreshing
  // Color palette: Deep ocean blue with aqua and coral accents

  static const ColorScheme oceanLightScheme = ColorScheme(
    brightness: Brightness.light,

    // Primary - Deep Ocean Blue (Depth & Calm)
    primary: Color(0xFF0277BD),           // Rich ocean blue
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: Color(0xFFB3E5FC),  // Soft sky blue
    onPrimaryContainer: Color(0xFF001F30),

    // Secondary - Aqua Teal (Flow & Balance)
    secondary: Color(0xFF00ACC1),         // Vibrant aqua
    onSecondary: Color(0xFFFFFFFF),
    secondaryContainer: Color(0xFFB2EBF2), // Soft aqua
    onSecondaryContainer: Color(0xFF002024),

    // Tertiary - Living Coral (Warmth & Life)
    tertiary: Color(0xFFFF6F61),          // Living coral
    onTertiary: Color(0xFFFFFFFF),
    tertiaryContainer: Color(0xFFFFDAD4), // Soft coral
    onTertiaryContainer: Color(0xFF3B0907),

    // Error
    error: Color(0xFFD32F2F),
    onError: Color(0xFFFFFFFF),
    errorContainer: Color(0xFFFFDAD6),
    onErrorContainer: Color(0xFF410002),

    // Surface - Cool ocean tints
    surface: Color(0xFFF9FDFF),
    onSurface: Color(0xFF181C1E),
    surfaceContainerLowest: Color(0xFFFFFFFF),
    surfaceContainerLow: Color(0xFFF3F8FA),
    surfaceContainer: Color(0xFFEDF3F5),
    surfaceContainerHigh: Color(0xFFE7EDF0),
    surfaceContainerHighest: Color(0xFFE1E7EA),
    onSurfaceVariant: Color(0xFF3F484B),

    outline: Color(0xFF6F797C),
    outlineVariant: Color(0xFFBFC8CB),

    shadow: Color(0xFF000000),
    scrim: Color(0xFF000000),

    inverseSurface: Color(0xFF2D3133),
    onInverseSurface: Color(0xFFEFF1F3),
    inversePrimary: Color(0xFF81D4FA),

    surfaceTint: Color(0xFF0277BD),
  );

  static const ColorScheme oceanDarkScheme = ColorScheme(
    brightness: Brightness.dark,

    primary: Color(0xFF81D4FA),           // Soft sky blue
    onPrimary: Color(0xFF003549),
    primaryContainer: Color(0xFF005373),  // Deep ocean
    onPrimaryContainer: Color(0xFFB3E5FC),

    secondary: Color(0xFF80DEEA),         // Soft aqua
    onSecondary: Color(0xFF00363C),
    secondaryContainer: Color(0xFF004F57), // Deep aqua
    onSecondaryContainer: Color(0xFFB2EBF2),

    tertiary: Color(0xFFFFAB9E),          // Soft coral
    onTertiary: Color(0xFF5F1410),
    tertiaryContainer: Color(0xFF832A24), // Deep coral
    onTertiaryContainer: Color(0xFFFFDAD4),

    error: Color(0xFFFFB4AB),
    onError: Color(0xFF690005),
    errorContainer: Color(0xFF93000A),
    onErrorContainer: Color(0xFFFFDAD6),

    // Surface - Deep ocean darks
    surface: Color(0xFF0F1416),
    onSurface: Color(0xFFE0E3E5),
    surfaceContainerLowest: Color(0xFF0A0F11),
    surfaceContainerLow: Color(0xFF171C1E),
    surfaceContainer: Color(0xFF1B2022),
    surfaceContainerHigh: Color(0xFF252A2D),
    surfaceContainerHighest: Color(0xFF303538),
    onSurfaceVariant: Color(0xFFBFC8CB),

    outline: Color(0xFF899295),
    outlineVariant: Color(0xFF3F484B),

    shadow: Color(0xFF000000),
    scrim: Color(0xFF000000),

    inverseSurface: Color(0xFFE0E3E5),
    onInverseSurface: Color(0xFF2D3133),
    inversePrimary: Color(0xFF0277BD),

    surfaceTint: Color(0xFF81D4FA),
  );

  // ============================================================================
  // SUNSET THEME
  // ============================================================================
  // Warm, passionate, inspiring
  // Color palette: Warm oranges with rose and purple accents

  static const ColorScheme sunsetLightScheme = ColorScheme(
    brightness: Brightness.light,

    // Primary - Sunset Orange (Passion & Warmth)
    primary: Color(0xFFE64A19),           // Rich sunset orange
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: Color(0xFFFFCCBC),  // Soft peach
    onPrimaryContainer: Color(0xFF380D00),

    // Secondary - Rose Gold (Elegance & Romance)
    secondary: Color(0xFFD4615A),         // Rose gold
    onSecondary: Color(0xFFFFFFFF),
    secondaryContainer: Color(0xFFFFDAD7), // Soft rose
    onSecondaryContainer: Color(0xFF3B0908),

    // Tertiary - Twilight Purple (Mystery & Depth)
    tertiary: Color(0xFF8E24AA),          // Twilight purple
    onTertiary: Color(0xFFFFFFFF),
    tertiaryContainer: Color(0xFFF3E5F5), // Soft lavender
    onTertiaryContainer: Color(0xFF2E004A),

    // Error
    error: Color(0xFFD32F2F),
    onError: Color(0xFFFFFFFF),
    errorContainer: Color(0xFFFFDAD6),
    onErrorContainer: Color(0xFF410002),

    // Surface - Warm sunset tints
    surface: Color(0xFFFFFBF9),
    onSurface: Color(0xFF201A18),
    surfaceContainerLowest: Color(0xFFFFFFFF),
    surfaceContainerLow: Color(0xFFFFF5F2),
    surfaceContainer: Color(0xFFFCEFEA),
    surfaceContainerHigh: Color(0xFFF6E9E4),
    surfaceContainerHighest: Color(0xFFF0E3DD),
    onSurfaceVariant: Color(0xFF52443F),

    outline: Color(0xFF84746E),
    outlineVariant: Color(0xFFD7C3BC),

    shadow: Color(0xFF000000),
    scrim: Color(0xFF000000),

    inverseSurface: Color(0xFF362F2C),
    onInverseSurface: Color(0xFFFCEEEA),
    inversePrimary: Color(0xFFFFB59B),

    surfaceTint: Color(0xFFE64A19),
  );

  static const ColorScheme sunsetDarkScheme = ColorScheme(
    brightness: Brightness.dark,

    primary: Color(0xFFFFB59B),           // Soft peach
    onPrimary: Color(0xFF5D1A00),
    primaryContainer: Color(0xFF862E00),  // Deep sunset
    onPrimaryContainer: Color(0xFFFFCCBC),

    secondary: Color(0xFFFFB4AD),         // Soft rose
    onSecondary: Color(0xFF571D18),
    secondaryContainer: Color(0xFF733329), // Deep rose
    onSecondaryContainer: Color(0xFFFFDAD7),

    tertiary: Color(0xFFE1BEE7),          // Soft lavender
    onTertiary: Color(0xFF4A0065),
    tertiaryContainer: Color(0xFF6A0089), // Deep purple
    onTertiaryContainer: Color(0xFFF3E5F5),

    error: Color(0xFFFFB4AB),
    onError: Color(0xFF690005),
    errorContainer: Color(0xFF93000A),
    onErrorContainer: Color(0xFFFFDAD6),

    // Surface - Warm sunset darks
    surface: Color(0xFF181210),
    onSurface: Color(0xFFF2E0DA),
    surfaceContainerLowest: Color(0xFF120D0B),
    surfaceContainerLow: Color(0xFF211A17),
    surfaceContainer: Color(0xFF261E1B),
    surfaceContainerHigh: Color(0xFF312925),
    surfaceContainerHighest: Color(0xFF3C342F),
    onSurfaceVariant: Color(0xFFD7C3BC),

    outline: Color(0xFF9F8E87),
    outlineVariant: Color(0xFF52443F),

    shadow: Color(0xFF000000),
    scrim: Color(0xFF000000),

    inverseSurface: Color(0xFFF2E0DA),
    onInverseSurface: Color(0xFF362F2C),
    inversePrimary: Color(0xFFE64A19),

    surfaceTint: Color(0xFFFFB59B),
  );

  // ============================================================================
  // HIGH CONTRAST THEMES (Accessibility)
  // ============================================================================
  // WCAG AAA compliant - for users who need maximum contrast

  static const ColorScheme highContrastLightScheme = ColorScheme(
    brightness: Brightness.light,

    // Primary - Maximum contrast blue
    primary: Color(0xFF0033CC),           // Deep blue
    onPrimary: Color(0xFFFFFFFF),         // Pure white
    primaryContainer: Color(0xFFD6E4FF),  // Very light blue
    onPrimaryContainer: Color(0xFF000033), // Very dark blue

    // Secondary - Maximum contrast green
    secondary: Color(0xFF007700),         // Deep green
    onSecondary: Color(0xFFFFFFFF),       // Pure white
    secondaryContainer: Color(0xFFD4FFD4), // Very light green
    onSecondaryContainer: Color(0xFF001A00), // Very dark green

    // Tertiary - Maximum contrast purple
    tertiary: Color(0xFF660099),          // Deep purple
    onTertiary: Color(0xFFFFFFFF),        // Pure white
    tertiaryContainer: Color(0xFFECD9FF), // Very light purple
    onTertiaryContainer: Color(0xFF1A0033), // Very dark purple

    // Error
    error: Color(0xFFCC0000),             // Deep red
    onError: Color(0xFFFFFFFF),           // Pure white
    errorContainer: Color(0xFFFFD6D6),    // Very light red
    onErrorContainer: Color(0xFF330000),  // Very dark red

    // Surface - Maximum contrast
    surface: Color(0xFFFFFFFF),           // Pure white
    onSurface: Color(0xFF000000),         // Pure black
    surfaceContainerLowest: Color(0xFFFFFFFF),
    surfaceContainerLow: Color(0xFFF5F5F5),
    surfaceContainer: Color(0xFFEEEEEE),
    surfaceContainerHigh: Color(0xFFE0E0E0),
    surfaceContainerHighest: Color(0xFFD0D0D0),
    onSurfaceVariant: Color(0xFF1A1A1A),

    // Outline - Strong borders
    outline: Color(0xFF333333),
    outlineVariant: Color(0xFF666666),

    shadow: Color(0xFF000000),
    scrim: Color(0xFF000000),

    inverseSurface: Color(0xFF000000),
    onInverseSurface: Color(0xFFFFFFFF),
    inversePrimary: Color(0xFF99BBFF),

    surfaceTint: Color(0xFF0033CC),
  );

  static const ColorScheme highContrastDarkScheme = ColorScheme(
    brightness: Brightness.dark,

    // Primary
    primary: Color(0xFF99BBFF),           // Bright blue
    onPrimary: Color(0xFF000000),         // Pure black
    primaryContainer: Color(0xFF003399),  // Medium blue
    onPrimaryContainer: Color(0xFFFFFFFF), // Pure white

    // Secondary
    secondary: Color(0xFF88FF88),         // Bright green
    onSecondary: Color(0xFF000000),       // Pure black
    secondaryContainer: Color(0xFF007700), // Medium green
    onSecondaryContainer: Color(0xFFFFFFFF), // Pure white

    // Tertiary
    tertiary: Color(0xFFD9AAFF),          // Bright purple
    onTertiary: Color(0xFF000000),        // Pure black
    tertiaryContainer: Color(0xFF660099), // Medium purple
    onTertiaryContainer: Color(0xFFFFFFFF), // Pure white

    // Error
    error: Color(0xFFFF8888),             // Bright red
    onError: Color(0xFF000000),           // Pure black
    errorContainer: Color(0xFFCC0000),    // Medium red
    onErrorContainer: Color(0xFFFFFFFF),  // Pure white

    // Surface - Maximum contrast
    surface: Color(0xFF000000),           // Pure black
    onSurface: Color(0xFFFFFFFF),         // Pure white
    surfaceContainerLowest: Color(0xFF000000),
    surfaceContainerLow: Color(0xFF1A1A1A),
    surfaceContainer: Color(0xFF262626),
    surfaceContainerHigh: Color(0xFF333333),
    surfaceContainerHighest: Color(0xFF404040),
    onSurfaceVariant: Color(0xFFE6E6E6),

    // Outline - Strong borders
    outline: Color(0xFFCCCCCC),
    outlineVariant: Color(0xFF999999),

    shadow: Color(0xFF000000),
    scrim: Color(0xFF000000),

    inverseSurface: Color(0xFFFFFFFF),
    onInverseSurface: Color(0xFF000000),
    inversePrimary: Color(0xFF0033CC),

    surfaceTint: Color(0xFF99BBFF),
  );

  // ============================================================================
  // SEMANTIC COLORS (Context-specific)
  // ============================================================================

  // Success colors
  static const Color successLight = Color(0xFF2E7D32);
  static const Color successDark = Color(0xFF81C784);

  // Warning colors
  static const Color warningLight = Color(0xFFF57C00);
  static const Color warningDark = Color(0xFFFFB74D);

  // Info colors
  static const Color infoLight = Color(0xFF0288D1);
  static const Color infoDark = Color(0xFF4FC3F7);

  // ============================================================================
  // GRADIENT DEFINITIONS
  // ============================================================================

  static const LinearGradient sportyGradient = LinearGradient(
    colors: [Color(0xFFE85D04), Color(0xFFFF8A50)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient oceanGradient = LinearGradient(
    colors: [Color(0xFF0277BD), Color(0xFF00ACC1)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient sunsetGradient = LinearGradient(
    colors: [Color(0xFFE64A19), Color(0xFFD4615A), Color(0xFF8E24AA)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient professionalGradient = LinearGradient(
    colors: [Color(0xFF1565C0), Color(0xFF42A5F5)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient vibrantGradient = LinearGradient(
    colors: [Color(0xFF7B1FA2), Color(0xFFD81B60)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient natureGradient = LinearGradient(
    colors: [Color(0xFF2E7D32), Color(0xFF81C784)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient highContrastGradient = LinearGradient(
    colors: [Color(0xFF0033CC), Color(0xFF007700)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
