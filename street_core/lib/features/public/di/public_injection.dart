// lib/features/public/di/public_injection.dart

import 'package:street_core/core/helpers/logger.dart';
import 'package:street_core/core/storage/hive_service.dart';

import '../contact/contact_cubit.dart';
import '../consent/consent_cubit.dart';
import '../repositories/consent_repository.dart';
import '../site_config/site_config.dart';
import '../../../core/services/cache_service.dart';
import 'package:get_it/get_it.dart';

import '../repositories/contact_message_repository.dart';

/// ============================================================================
/// PUBLIC MODULE - Dependency Injection
/// ============================================================================
/// Módulo CORE para páginas públicas (landing, contacto, legal)
/// ⚠️ REQUERIDO - No deshabilitar este módulo
///
/// Este módulo gestiona:
/// - Configuración del sitio (básica, legal, contacto)
/// - Formulario de contacto
/// - Consent/GDPR
/// - Landing page
/// ============================================================================

void setupPublicFeature(GetIt getIt) {
  AppLogger.info('------- > Setting up Public Feature DI');
  // ============== REPOSITORIES ==============

  /// Site Config Repository - Handles public site configuration
  /// Centralized repository for all site config sections
  getIt.registerLazySingleton<SiteConfigRepository>(
    () => SiteConfigRepository(getIt<CacheService>()),
  );

  /// Contact Message Repository - Handles public contact form submission
  getIt.registerLazySingleton<ContactMessageRepository>(
    ContactMessageRepository.new, // Has optional ApiService with default
  );

  /// Consent Repository - Handles GDPR consent
  getIt.registerLazySingleton<ConsentRepository>(
    () => ConsentRepository(getIt<HiveService>()), // Uses HiveService for storage
  );

  // ============== CUBITS ==============

  /// Unified Site Config Cubit - Manages ALL site configuration sections
  /// Replaces: PublicSiteConfigCubit, BasicConfigCubit, LegalConfigCubit, ContactConfigCubit
  ///
  /// Supports lazy loading of sections:
  /// - basicConfig (company + social) - for header/footer
  /// - legalTexts (privacy, terms, etc.) - for legal pages
  /// - contactInfo - for contact page
  /// - landingTexts (testimonials, features) - for home page
  /// - consentConfig - for cookie banner
  /// - seoConfig - for meta tags
  /// - appConfig - for maintenance mode
  ///
  /// PROVIDED GLOBALLY - Singleton ensures consistent state across all pages
  getIt.registerLazySingleton<SiteConfigCubit>(
    () => SiteConfigCubit(getIt<SiteConfigRepository>()),
  );

  /// Contact Cubit - Manages public contact form state
  getIt.registerFactory<ContactCubit>(
    () => ContactCubit(repository: getIt<ContactMessageRepository>()),
  );

  /// Consent Cubit - Manages user consent
  getIt.registerFactory<ConsentCubit>(
    () => ConsentCubit(
      getIt<ConsentRepository>(),
      getIt<SiteConfigRepository>(),
    ),
  );
}
