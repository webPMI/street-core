/// API URIs for the Settings module
///
/// All settings-related backend endpoints.
/// Following Monolith-by-Features architecture (ADR-005).
///
/// Note: These endpoints are primarily for site configuration data
/// that can be loaded on-demand by section. Most are currently unused
/// in the settings feature but available for future use.
library;

import '../../config/env.dart';

class SettingsUris {
  static const String _api = '/api/${Env.apiVersion}';

  // ============================================================================
  // SITE CONFIG ENDPOINTS (Public - on-demand loading by section)
  // ============================================================================
  // These endpoints match backend/routes/site_config_routes.go
  // All endpoints are public and return JSON configuration data.

  /// GET /api/v1/site-config
  /// Full site configuration (for admin panel or complete config needs)
  static const String siteConfig = '$_api/site-config';

  /// GET /api/v1/site-config/basic
  /// Combined endpoint for header/footer (company + social media)
  /// Useful for: App bar, footer, basic branding
  static const String siteConfigBasic = '$_api/site-config/basic';

  /// GET /api/v1/site-config/contact
  /// Contact information only (email, phone, address)
  /// Useful for: Contact page, help center
  static const String siteConfigContact = '$_api/site-config/contact';

  /// GET /api/v1/site-config/social
  /// Social media links only (Instagram, Facebook, Twitter, etc.)
  /// Useful for: Footer, share buttons
  static const String siteConfigSocial = '$_api/site-config/social';

  /// GET /api/v1/site-config/legal
  /// Legal texts only (privacy policy, terms of service, cookie policy)
  /// Useful for: Legal pages, consent forms
  static const String siteConfigLegal = '$_api/site-config/legal';

  /// GET /api/v1/site-config/company
  /// Company information only (name, description, tagline)
  /// Useful for: About page, branding
  static const String siteConfigCompany = '$_api/site-config/company';

  /// GET /api/v1/site-config/seo
  /// SEO configuration only (meta tags, descriptions, keywords)
  /// Useful for: Meta tags, search engine optimization
  static const String siteConfigSeo = '$_api/site-config/seo';

  /// GET /api/v1/site-config/landing
  /// Landing page texts only (hero, features, call-to-actions)
  /// Useful for: Landing page, home page
  static const String siteConfigLanding = '$_api/site-config/landing';

  /// GET /api/v1/site-config/app
  /// App configuration only (maintenance mode, min version, update URLs)
  /// Useful for: Version check, maintenance screen
  static const String siteConfigApp = '$_api/site-config/app';

  /// GET /api/v1/site-config/consent
  /// Consent configuration (cookie consent, GDPR settings)
  /// Useful for: Cookie banner, consent management
  static const String siteConfigConsent = '$_api/site-config/consent';
}
