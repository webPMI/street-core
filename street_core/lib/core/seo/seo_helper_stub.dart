// Stub implementation for non-web platforms
// This file is used when dart.library.js_interop is not available

import './seo_config.dart';

/// Stub implementation of SeoHelperImpl for non-web platforms
///
/// This class provides no-op implementations that will be used
/// on mobile and desktop platforms where SEO doesn't apply.
class SeoHelperImpl {
  /// Update page meta tags (no-op on non-web platforms)
  static void updateMetaTags(SeoMetadata metadata, String currentPath) {
    // No-op on non-web platforms
  }

  /// Update hreflang tags (no-op on non-web platforms)
  static void updateHreflangTags(
      String currentPath, Map<String, String> languageUrls) {
    // No-op on non-web platforms
  }

  /// Set robots meta tag (no-op on non-web platforms)
  static void setRobots(String content) {
    // No-op on non-web platforms
  }

  /// Set noindex (no-op on non-web platforms)
  static void setNoIndex() {
    // No-op on non-web platforms
  }

  /// Add structured data (no-op on non-web platforms)
  static void addStructuredData(Map<String, dynamic> jsonLd, {String? id}) {
    // No-op on non-web platforms
  }

  /// Clear structured data (no-op on non-web platforms)
  static void clearStructuredData() {
    // No-op on non-web platforms
  }

  /// Add multiple structured data (no-op on non-web platforms)
  static void addMultipleStructuredData(List<Map<String, dynamic>> schemas) {
    // No-op on non-web platforms
  }
}
