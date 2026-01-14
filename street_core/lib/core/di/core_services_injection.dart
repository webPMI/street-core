// lib/core/di/core_services_injection.dart

import '../helpers/device_storage.dart';
import '../lang/locale_service.dart';
import '../location/location_service.dart';
import '../router/navigation_service.dart';
import '../services/api_service.dart';
import '../services/app_info_service.dart';
import '../services/cache_service.dart';
import '../services/crash_reporting_service.dart';
import '../storage/hive_service.dart';
import 'package:get_it/get_it.dart';

/// Setup core services (HTTP client, configuration, etc.)
void setupCoreServices(GetIt getIt) {
  // ================================================================
  // CORE SERVICES (Singleton - Single instance throughout app)
  // ================================================================

  // -------------------- Localization --------------------

  /// Locale Service - Provides current locale for API headers
  /// Must be registered before ApiService
  if (!getIt.isRegistered<LocaleService>()) {
    getIt.registerLazySingleton<LocaleService>(LocaleService.new);
  }

  // -------------------- Storage & Device --------------------

  /// Hive Service - Local database for offline support AND preferences
  /// Replaces SharedPreferences with better performance and type safety
  if (!getIt.isRegistered<HiveService>()) {
    getIt.registerLazySingleton<HiveService>(HiveService.new);
  }

  /// Device Storage - Wrapper for Hive + SecureStorage
  /// Must be registered AFTER HiveService
  if (!getIt.isRegistered<StorageService>()) {
    getIt.registerLazySingleton<StorageService>(
      () => StorageService(getIt<HiveService>()),
    );
  }

  // -------------------- Caching --------------------

  /// Cache Service - In-memory cache with TTL support
  /// Reduces API calls by ~80% for repeated data access
  getIt.registerLazySingleton<CacheService>(CacheService.new);

  // -------------------- API & Network --------------------

  /// API Service - HTTP client for backend communication
  /// Injects LocaleService for dynamic Accept-Language header and StorageService for tokens
  getIt.registerLazySingleton<ApiService>(
    () => ApiService(
      localeService: getIt<LocaleService>(),
      storageService: getIt<StorageService>(),
    ),
  );

  // -------------------- Navigation --------------------

  /// Navigation Service - Type-safe centralized navigation
  /// Uses GetIt internally to access StorageService
  getIt.registerLazySingleton<NavigationService>(NavigationService.new);

  // -------------------- Monitoring & Logging --------------------

  /// Crash Reporting Service - Error tracking and reporting
  getIt.registerLazySingleton<CrashReportingService>(CrashReportingService.new);

  // -------------------- Location --------------------

  /// Location Service - Handles device location and permissions
  if (!getIt.isRegistered<LocationService>()) {
    getIt.registerLazySingleton<LocationService>(
      () => LocationService(getIt<HiveService>()),
    );
  }

  // -------------------- App Information --------------------

  /// App Info Service - Provides app version, build number, etc.
  if (!getIt.isRegistered<AppInfoService>()) {
    getIt.registerLazySingleton<AppInfoService>(AppInfoService.new);
  }

  // -------------------- Configuration (Future) --------------------

  /*   /// Site Config Service - Manages site configuration
  getIt.registerLazySingleton<SiteConfigService>(() => SiteConfigService());

  /// Contact Message Service - Manages contact messages
  getIt.registerLazySingleton<ContactMessageService>(
    () => ContactMessageService(),
  ); */
}
