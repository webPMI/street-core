// lib/core/di/injection.dart
import '/core/storage/hive_service.dart';

import 'package:get_it/get_it.dart';
import 'package:street_core/features/competitions/competitions.dart';
import 'package:street_core/features/tournaments/di/tournaments_injection.dart';
import '/features/profile/di/profile_injection.dart';
import '../media/media.dart';
import '../services/app_info_service.dart';
import '../widgets/country/country_di.dart';
import 'cubits_injection.dart'; // For core Cubits
import 'core_services_injection.dart'; // For core services (if any)
import '../../features/auth/di/auth_injection.dart'; // For Auth feature dependencies
import '../../features/public/di/public_injection.dart'; // For Public feature dependencies

/// Service Locator - Dependency Injection Container
final getIt = GetIt.instance;

/// Initialize all dependencies
///
/// This function orchestrates the dependency injection setup by calling
/// specialized setup functions for each layer of the application:
/// 1. Core Services (HTTP, configuration, etc.)
/// 2. Features (Monolith-by-Features architecture - ADR-005)
/// 3. Repositories (data access layer - legacy, being migrated to features)
/// 4. Cubits (state management - core cubits, others are feature-specific)
Future<void> setupDependencyInjection() async {
  // 1. Register core services (but don't create Cubits yet)
  setupCoreServices(getIt);
  
  // 2. Initialize Hive BEFORE creating Cubits that depend on it
  //---Inicializa Hive para almacenamiento local offline
  await getIt<HiveService>().init();
  
  // 3. NOW it's safe to create Cubits that use HiveService
  setupCubits(getIt); // LocaleBloc and ThemeCubit will now work correctly
  
  //---Inicializa el servicio de sincronización offline
 // await getIt<OfflineSyncService>().init();

  setupAuthFeature(getIt);
  setupPublicFeature(getIt);
  //-- Form widgets ------------------------------------------------
  //-- Country selector --------------------------------------------
  /// Country Cubit - Manages country data (Singleton for sharing across app)
  setupCountryDi(getIt);
  setupMediaDependencies(getIt); // Media module dependencies
  setupProfileModule(getIt); // Profile feature module
  //MODULES
  setupCompeFeature(getIt);
  setupTournamentsFeature(getIt); // Tournaments feature module

  // Initialize services that require async setup
  await getIt<AppInfoService>().initialize();
}

/// Reset all dependencies (useful for testing)
Future<void> resetDependencies() async {
  await getIt.reset();
}
