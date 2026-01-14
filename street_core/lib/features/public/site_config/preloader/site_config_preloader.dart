import 'package:flutter/foundation.dart';
import '../cubit/site_config_cubit.dart';
import '../../../../core/helpers/logger.dart';

/// Site Config Preloader
///
/// Intelligent preloading strategy for site configuration sections.
/// Preloads critical sections based on app state and user navigation patterns.
///
/// **Strategy:**
/// - On app start: Load basicConfig (header/footer)
/// - On public pages: Load landingTexts, consentConfig
/// - Before legal pages: Load legalTexts
/// - Before contact page: Load contactInfo
/// - Smart caching prevents duplicate requests
///
/// **Usage:**
/// ```dart
/// // In main.dart or app initialization
/// await SiteConfigPreloader.preloadCritical(getIt<SiteConfigCubit>());
///
/// // Before navigating to specific pages
/// await SiteConfigPreloader.preloadForRoute('/legal', cubit);
/// ```
class SiteConfigPreloader {
  SiteConfigPreloader._(); // Private constructor

  /// Preload critical sections needed on app start
  ///
  /// Loads in parallel:
  /// - basicConfig (company + social) for header/footer
  /// - consentConfig for cookie banner
  /// - appConfig for maintenance mode check
  ///
  /// This ensures the app shell loads quickly with all necessary data.
  static Future<void> preloadCritical(SiteConfigCubit cubit) async {
    if (kDebugMode) {
      AppLogger.debug('Loading critical sections...', tag: 'SiteConfigPreloader');
    }

    final startTime = DateTime.now();

    try {
      // Load critical sections in parallel
      await Future.wait([
        cubit.loadBasicConfig(), // Header/footer
        cubit.loadConsentConfig(), // Cookie banner
        cubit.loadAppConfig(), // Maintenance mode
      ]);

      final duration = DateTime.now().difference(startTime);
      if (kDebugMode) {
        AppLogger.debug('Critical sections loaded in ${duration.inMilliseconds}ms', tag: 'SiteConfigPreloader');
      }
    } catch (e) {
      if (kDebugMode) {
        AppLogger.error('Error loading critical sections', error: e, tag: 'SiteConfigPreloader');
      }
      // Don't throw - let individual pages handle errors
    }
  }

  /// Preload sections for public home page
  ///
  /// Loads landing texts for testimonials, features, CTA sections
  static Future<void> preloadForHomePage(SiteConfigCubit cubit) async {
    if (kDebugMode) {
      AppLogger.debug('Loading home page sections...', tag: 'SiteConfigPreloader');
    }

    try {
      await cubit.loadLandingTexts();
    } catch (e) {
      if (kDebugMode) {
        AppLogger.error('Error loading landing texts', error: e, tag: 'SiteConfigPreloader');
      }
    }
  }

  /// Preload sections for legal pages
  ///
  /// Loads all legal texts (privacy, terms, cookies, etc.)
  static Future<void> preloadForLegalPages(SiteConfigCubit cubit) async {
    if (kDebugMode) {
      AppLogger.debug('Loading legal sections...', tag: 'SiteConfigPreloader');
    }

    try {
      await cubit.loadLegalTexts();
    } catch (e) {
      if (kDebugMode) {
        AppLogger.error('Error loading legal texts', error: e, tag: 'SiteConfigPreloader');
      }
    }
  }

  /// Preload sections for contact page
  ///
  /// Loads contact information (email, phone, address, etc.)
  static Future<void> preloadForContactPage(SiteConfigCubit cubit) async {
    if (kDebugMode) {
      AppLogger.debug('Loading contact sections...', tag: 'SiteConfigPreloader');
    }

    try {
      await cubit.loadContactInfo();
    } catch (e) {
      if (kDebugMode) {
        AppLogger.error('Error loading contact info', error: e, tag: 'SiteConfigPreloader');
      }
    }
  }

  /// Preload sections based on route
  ///
  /// Smart preloading that determines what to load based on the target route.
  /// Uses pattern matching to identify page type.
  ///
  /// **Examples:**
  /// - `/` or `/home` → landingTexts
  /// - `/legal/*` → legalTexts
  /// - `/contact` → contactInfo
  static Future<void> preloadForRoute(String route, SiteConfigCubit cubit) async {
    if (kDebugMode) {
      AppLogger.debug('Preloading for route: $route', tag: 'SiteConfigPreloader');
    }

    // Home page
    if (route == '/' || route.contains('/home')) {
      await preloadForHomePage(cubit);
      return;
    }

    // Legal pages
    if (route.contains('/legal') ||
        route.contains('/privacy') ||
        route.contains('/terms')) {
      await preloadForLegalPages(cubit);
      return;
    }

    // Contact page
    if (route.contains('/contact')) {
      await preloadForContactPage(cubit);
      return;
    }

    // Default: just ensure basic config is loaded
    try {
      await cubit.loadBasicConfig();
    } catch (e) {
      if (kDebugMode) {
        AppLogger.error('Error loading basic config', error: e, tag: 'SiteConfigPreloader');
      }
    }
  }

  /// Preload all sections
  ///
  /// Loads ALL sections in parallel. Use sparingly - only when you know
  /// the user will need everything (e.g., admin panel, settings page).
  ///
  /// **Warning:** This makes 7 parallel requests. Use only when necessary.
  static Future<void> preloadAll(SiteConfigCubit cubit) async {
    if (kDebugMode) {
      AppLogger.debug('Loading ALL sections (heavy operation)...', tag: 'SiteConfigPreloader');
    }

    final startTime = DateTime.now();

    try {
      await Future.wait([
        cubit.loadBasicConfig(),
        cubit.loadContactInfo(),
        cubit.loadLegalTexts(),
        cubit.loadLandingTexts(),
        cubit.loadConsentConfig(),
        cubit.loadSeoConfig(),
        cubit.loadAppConfig(),
      ]);

      final duration = DateTime.now().difference(startTime);
      if (kDebugMode) {
        AppLogger.debug('All sections loaded in ${duration.inMilliseconds}ms', tag: 'SiteConfigPreloader');
      }
    } catch (e) {
      if (kDebugMode) {
        AppLogger.error('Error loading all sections', error: e, tag: 'SiteConfigPreloader');
      }
    }
  }

  /// Background preload (fire and forget)
  ///
  /// Preloads sections in the background without blocking.
  /// Useful for preloading likely-needed data while user is viewing current page.
  ///
  /// **Example:**
  /// ```dart
  /// // User is on home page, preload legal in background
  /// SiteConfigPreloader.backgroundPreload(
  ///   cubit,
  ///   sections: [PreloadSection.legal],
  /// );
  /// ```
  static void backgroundPreload(
    SiteConfigCubit cubit, {
    required List<PreloadSection> sections,
  }) {
    if (kDebugMode) {
      AppLogger.debug('Background preloading: ${sections.map((s) => s.name).join(', ')}', tag: 'SiteConfigPreloader');
    }

    // Fire and forget - don't await
    Future.wait(
      sections.map((section) {
        switch (section) {
          case PreloadSection.basic:
            return cubit.loadBasicConfig();
          case PreloadSection.contact:
            return cubit.loadContactInfo();
          case PreloadSection.legal:
            return cubit.loadLegalTexts();
          case PreloadSection.landing:
            return cubit.loadLandingTexts();
          case PreloadSection.consent:
            return cubit.loadConsentConfig();
          case PreloadSection.seo:
            return cubit.loadSeoConfig();
          case PreloadSection.app:
            return cubit.loadAppConfig();
        }
      }),
    ).catchError((e) {
      if (kDebugMode) {
        AppLogger.error('Background preload error', error: e, tag: 'SiteConfigPreloader');
      }
      return []; // Return empty list to satisfy type requirement
    });
  }
}

/// Sections available for preloading
enum PreloadSection {
  basic,
  contact,
  legal,
  landing,
  consent,
  seo,
  app,
}
