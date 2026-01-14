import '../platform/platform_detector.dart';
import './seo_config.dart';
// Conditional import for web-specific SEO functionality
import './seo_helper_stub.dart'
    if (dart.library.js_interop) 'seo_helper_web.dart';

/// SEO Helper Class
///
/// Provides methods to dynamically update HTML meta tags for better SEO.
/// Uses conditional imports to only load web-specific code on web platform.
///
/// On web: Updates DOM meta tags using the web package
/// On mobile/desktop: No-op (SEO doesn't apply)
class SeoHelper {
  /// Update page meta tags dynamically
  /// On web: Updates DOM meta tags
  /// On other platforms: No-op
  static void updateMetaTags(SeoMetadata metadata, String currentPath) {
    if (!PlatformDetector.shouldEnableSEO) return;
    SeoHelperImpl.updateMetaTags(metadata, currentPath);
  }

  /// Update hreflang tags for multi-language support
  /// [languageUrls] is a map of language code to URL
  /// Example: {'es': 'https://example.com/es/page', 'en': 'https://example.com/en/page'}
  static void updateHreflangTags(
      String currentPath, Map<String, String> languageUrls) {
    if (!PlatformDetector.shouldEnableSEO) return;
    SeoHelperImpl.updateHreflangTags(currentPath, languageUrls);
  }

  /// Set robots meta tag content
  /// Common values: 'index, follow', 'noindex, follow', 'noindex, nofollow'
  static void setRobots(String content) {
    if (!PlatformDetector.shouldEnableSEO) return;
    SeoHelperImpl.setRobots(content);
  }

  /// Set noindex for pages that should not be indexed
  /// Use for private pages, login, admin areas, etc.
  static void setNoIndex() {
    if (!PlatformDetector.shouldEnableSEO) return;
    SeoHelperImpl.setNoIndex();
  }

  /// Add structured data (JSON-LD) to page
  /// On web: Adds JSON-LD script tag to DOM
  /// On other platforms: No-op
  /// [id] Optional unique ID for the script tag (for replacement)
  static void addStructuredData(Map<String, dynamic> jsonLd, {String? id}) {
    if (!PlatformDetector.shouldEnableSEO) return;
    SeoHelperImpl.addStructuredData(jsonLd, id: id);
  }

  /// Remove all structured data from page
  static void clearStructuredData() {
    if (!PlatformDetector.shouldEnableSEO) return;
    SeoHelperImpl.clearStructuredData();
  }

  /// Add multiple structured data schemas at once
  /// Clears existing schemas before adding new ones
  static void addMultipleStructuredData(List<Map<String, dynamic>> schemas) {
    if (!PlatformDetector.shouldEnableSEO) return;
    SeoHelperImpl.addMultipleStructuredData(schemas);
  }
}
