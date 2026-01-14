import '../../../../core/services/api_service.dart';
import '../../../../core/services/api_uris.dart';
import '../../../../core/services/cache_service.dart';
import '../../../../core/helpers/retry_helper.dart';
import '../../../../data/models/site_config/site_config_models.dart';

/// Repository for public site configuration with on-demand loading
///
/// Features:
/// - Load sections individually (legal, contact, company, etc.)
/// - Each section has its own cache with appropriate TTL
/// - Combined endpoint for header/footer (basic = company + social)
/// - No authentication required (public endpoints)
///
/// Usage:
/// ```dart
/// final repo = SiteConfigRepository(cacheService);
///
/// // Load only what you need
/// final legal = await repo.getLegalTexts();
/// final contact = await repo.getContactInfo();
/// final basic = await repo.getBasicConfig(); // company + social
/// ```
class SiteConfigRepository {
  SiteConfigRepository(this._cacheService, {ApiService? apiService})
    : _apiService = apiService ?? ApiService();
  final CacheService _cacheService;
  final ApiService _apiService;

  // Cache keys for each section
  static const String _keyBasic = 'site_config_basic';
  static const String _keyContact = 'site_config_contact';
  static const String _keySocial = 'site_config_social';
  static const String _keyLegal = 'site_config_legal';
  static const String _keyCompany = 'site_config_company';
  static const String _keySeo = 'site_config_seo';
  static const String _keyLanding = 'site_config_landing';
  static const String _keyApp = 'site_config_app';
  static const String _keyConsent = 'site_config_consent';

  // ===========================================================================
  // COMBINED ENDPOINTS
  // ===========================================================================

  /// Get basic config (company + social) for header/footer
  ///
  /// Returns [BasicConfig] with companyInfo and socialMedia
  /// TTL: 2 hours (very stable data)
  /// Includes automatic retry with exponential backoff on failure
  Future<BasicConfig> getBasicConfig() async {
    return _cacheService.getOrFetch<BasicConfig>(
      key: _keyBasic,
      ttl: CacheTTL.basicConfig,
      fetchFn: () => RetryHelper.executeNetwork<BasicConfig>(
        operation: () async {
          final response = await _apiService.useFetch(
            ApiUris.getSiteConfigBasic,
            method: 'GET',
            requiredToken: false,
            fromJsonT: (data) => BasicConfig.fromJson(data),
          );

          if (response.status == 'success' && response.data != null) {
            return response.data!;
          }
          return BasicConfig.empty();
        },
        operationName: 'getBasicConfig',
      ),
    );
  }

  // ===========================================================================
  // SECTION-SPECIFIC ENDPOINTS
  // ===========================================================================

  /// Get contact information
  /// TTL: 24 hours (stable data)
  /// Includes automatic retry with exponential backoff on failure
  Future<ContactInfo> getContactInfo() async {
    return _cacheService.getOrFetch<ContactInfo>(
      key: _keyContact,
      ttl: CacheTTL.contactInfo,
      fetchFn: () => RetryHelper.executeNetwork<ContactInfo>(
        operation: () async {
          final response = await _apiService.useFetch(
            ApiUris.getSiteConfigContact,
            method: 'GET',
            requiredToken: false,
            fromJsonT: (data) =>
                data != null ? ContactInfo.fromJson(data) : ContactInfo.empty(),
          );

          if (response.status == 'success' && response.data != null) {
            return response.data!;
          }
          return ContactInfo.empty();
        },
        operationName: 'getContactInfo',
      ),
    );
  }

  /// Get social media links
  /// TTL: 2 hours (very stable)
  /// Includes automatic retry with exponential backoff on failure
  Future<SocialMedia> getSocialMedia() async {
    return _cacheService.getOrFetch<SocialMedia>(
      key: _keySocial,
      ttl: CacheTTL.socialMedia,
      fetchFn: () => RetryHelper.executeNetwork<SocialMedia>(
        operation: () async {
          final response = await _apiService.useFetch(
            ApiUris.getSiteConfigSocial,
            method: 'GET',
            requiredToken: false,
            fromJsonT: (data) =>
                data != null ? SocialMedia.fromJson(data) : SocialMedia.empty(),
          );

          if (response.status == 'success' && response.data != null) {
            return response.data!;
          }
          return SocialMedia.empty();
        },
        operationName: 'getSocialMedia',
      ),
    );
  }

  /// Get legal texts (privacy policy, terms, etc.)
  /// TTL: 24 hours (very stable, rarely changes)
  /// Includes automatic retry with exponential backoff on failure
  Future<LegalTexts> getLegalTexts() async {
    return _cacheService.getOrFetch<LegalTexts>(
      key: _keyLegal,
      ttl: CacheTTL.legalTexts,
      fetchFn: () => RetryHelper.executeNetwork<LegalTexts>(
        operation: () async {
          final response = await _apiService.useFetch(
            ApiUris.getSiteConfigLegal,
            method: 'GET',
            requiredToken: false,
            fromJsonT: (data) =>
                data != null ? LegalTexts.fromJson(data) : LegalTexts.empty(),
          );

          if (response.status == 'success' && response.data != null) {
            return response.data!;
          }
          return LegalTexts.empty();
        },
        operationName: 'getLegalTexts',
      ),
    );
  }

  /// Get company information
  /// TTL: 2 hours (very stable)
  /// Includes automatic retry with exponential backoff on failure
  Future<CompanyInfo> getCompanyInfo() async {
    return _cacheService.getOrFetch<CompanyInfo>(
      key: _keyCompany,
      ttl: CacheTTL.companyInfo,
      fetchFn: () => RetryHelper.executeNetwork<CompanyInfo>(
        operation: () async {
          final response = await _apiService.useFetch(
            ApiUris.getSiteConfigCompany,
            method: 'GET',
            requiredToken: false,
            fromJsonT: (data) =>
                data != null ? CompanyInfo.fromJson(data) : CompanyInfo.empty(),
          );

          if (response.status == 'success' && response.data != null) {
            return response.data!;
          }
          return CompanyInfo.empty();
        },
        operationName: 'getCompanyInfo',
      ),
    );
  }

  /// Get SEO configuration
  /// TTL: 5 minutes (may need quick changes)
  /// Includes automatic retry with exponential backoff on failure
  Future<SEOConfig> getSeoConfig() async {
    return _cacheService.getOrFetch<SEOConfig>(
      key: _keySeo,
      ttl: CacheTTL.seoConfig,
      fetchFn: () => RetryHelper.executeNetwork<SEOConfig>(
        operation: () async {
          final response = await _apiService.useFetch(
            ApiUris.getSiteConfigSeo,
            method: 'GET',
            requiredToken: false,
            fromJsonT: (data) =>
                data != null ? SEOConfig.fromJson(data) : SEOConfig.empty(),
          );

          if (response.status == 'success' && response.data != null) {
            return response.data!;
          }
          return SEOConfig.empty();
        },
        operationName: 'getSeoConfig',
      ),
    );
  }

  /// Get landing page texts
  /// TTL: 15 minutes (marketing may update)
  /// Includes automatic retry with exponential backoff on failure
  Future<LandingTexts> getLandingTexts() async {
    return _cacheService.getOrFetch<LandingTexts>(
      key: _keyLanding,
      ttl: CacheTTL.landingTexts,
      fetchFn: () => RetryHelper.executeNetwork<LandingTexts>(
        operation: () async {
          final response = await _apiService.useFetch(
            ApiUris.getSiteConfigLanding,
            method: 'GET',
            requiredToken: false,
            fromJsonT: (data) =>
                data != null ? LandingTexts.fromJson(data) : LandingTexts.empty(),
          );

          if (response.status == 'success' && response.data != null) {
            return response.data!;
          }
          return LandingTexts.empty();
        },
        operationName: 'getLandingTexts',
      ),
    );
  }

  /// Get app configuration (maintenance mode, versions)
  /// TTL: 2 minutes (maintenance mode must propagate fast)
  /// Includes automatic retry with exponential backoff on failure
  Future<AppConfig> getAppConfig() async {
    return _cacheService.getOrFetch<AppConfig>(
      key: _keyApp,
      ttl: CacheTTL.appConfig,
      fetchFn: () => RetryHelper.executeNetwork<AppConfig>(
        operation: () async {
          final response = await _apiService.useFetch(
            ApiUris.getSiteConfigApp,
            method: 'GET',
            requiredToken: false,
            fromJsonT: (data) =>
                data != null ? AppConfig.fromJson(data) : AppConfig.empty(),
          );

          if (response.status == 'success' && response.data != null) {
            return response.data!;
          }
          return AppConfig.empty();
        },
        operationName: 'getAppConfig',
      ),
    );
  }

  /// Get consent configuration (cookie texts, granular options)
  /// TTL: 24 hours (rarely changes)
  /// Includes automatic retry with exponential backoff on failure
  Future<ConsentConfig> getConsentConfig() async {
    return _cacheService.getOrFetch<ConsentConfig>(
      key: _keyConsent,
      ttl: CacheTTL.legalTexts, // Similar TTL to legal texts
      fetchFn: () => RetryHelper.executeNetwork<ConsentConfig>(
        operation: () async {
          final response = await _apiService.useFetch(
            '${ApiUris.getSiteConfig}/consent',
            method: 'GET',
            requiredToken: false,
            fromJsonT: (data) => data != null
                ? ConsentConfig.fromJson(data)
                : ConsentConfig.empty(),
          );

          if (response.status == 'success' && response.data != null) {
            return response.data!;
          }
          return ConsentConfig.empty();
        },
        operationName: 'getConsentConfig',
      ),
    );
  }

  // ===========================================================================
  // CACHE MANAGEMENT
  // ===========================================================================

  /// Invalidate all site config cache
  void invalidateAll() {
    _cacheService.invalidatePattern('site_config_');
  }

  /// Invalidate specific section cache
  void invalidateSection(ConfigSection section) {
    switch (section) {
      case ConfigSection.contact:
        _cacheService.invalidate(_keyContact);
        break;
      case ConfigSection.social:
        _cacheService.invalidate(_keySocial);
        break;
      case ConfigSection.legal:
        _cacheService.invalidate(_keyLegal);
        break;
      case ConfigSection.company:
        _cacheService.invalidate(_keyCompany);
        _cacheService.invalidate(_keyBasic); // Also invalidate basic
        break;
      case ConfigSection.seo:
        _cacheService.invalidate(_keySeo);
        break;
      case ConfigSection.landing:
        _cacheService.invalidate(_keyLanding);
        break;
      case ConfigSection.email:
        // Email config is admin-only, not cached here
        break;
      case ConfigSection.app:
        _cacheService.invalidate(_keyApp);
        break;
      case ConfigSection.consent:
        _cacheService.invalidate(_keyConsent);
        break;
    }
  }
}

/// Combined config for header/footer (company + social)
class BasicConfig {
  BasicConfig({required this.companyInfo, required this.socialMedia});

  factory BasicConfig.fromJson(Map<String, dynamic> json) {
    return BasicConfig(
      companyInfo: json['companyInfo'] != null
          ? CompanyInfo.fromJson(json['companyInfo'])
          : CompanyInfo.empty(),
      socialMedia: json['socialMedia'] != null
          ? SocialMedia.fromJson(json['socialMedia'])
          : SocialMedia.empty(),
    );
  }

  factory BasicConfig.empty() => BasicConfig(
    companyInfo: CompanyInfo.empty(),
    socialMedia: SocialMedia.empty(),
  );
  final CompanyInfo companyInfo;
  final SocialMedia socialMedia;
}
