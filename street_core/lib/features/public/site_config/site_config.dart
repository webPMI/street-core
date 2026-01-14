/// Site Configuration Module
///
/// Centralized site configuration management for public pages.
/// Provides lazy loading of configuration sections with caching.
///
/// **Usage:**
/// ```dart
/// // Import the module
/// import 'package:street_core/features/public/site_config/site_config.dart';
///
/// // Use the cubit
/// await context.read<SiteConfigCubit>().loadLegalTexts();
/// final privacy = context.read<SiteConfigCubit>().privacyPolicy;
///
/// // Preload critical sections
/// await SiteConfigPreloader.preloadCritical(cubit);
/// ```

export 'cubit/site_config_cubit.dart';
export 'cubit/site_config_state.dart';
export 'repository/site_config_repository.dart';
export 'preloader/site_config_preloader.dart';
