/// SEO Meta Tags Stub Implementation
///
/// This is a stub implementation for non-web platforms (Android, iOS, Desktop).
/// SEO meta tags are only relevant for web platforms, so this provides
/// no-op implementations that do nothing.
library;

/// SEOMetaTags class stub for non-web platforms
class SEOMetaTags {
  /// Update page title (no-op on non-web platforms)
  static void updateTitle(String title) {
    // No-op on non-web platforms
  }

  /// Update page description (no-op on non-web platforms)
  static void updateDescription(String description) {
    // No-op on non-web platforms
  }

  /// Update canonical URL (no-op on non-web platforms)
  static void updateCanonicalUrl(String url) {
    // No-op on non-web platforms
  }

  /// Update page image (no-op on non-web platforms)
  static void updateImage(String imageUrl, {String? alt}) {
    // No-op on non-web platforms
  }

  /// Update keywords (no-op on non-web platforms)
  static void updateKeywords(List<String> keywords) {
    // No-op on non-web platforms
  }

  /// Set Open Graph type (no-op on non-web platforms)
  static void updateOGType(String type) {
    // No-op on non-web platforms
  }

  /// Set Twitter Card type (no-op on non-web platforms)
  static void updateTwitterCard(String cardType) {
    // No-op on non-web platforms
  }

  /// Set robots meta tag (no-op on non-web platforms)
  static void updateRobots(String value) {
    // No-op on non-web platforms
  }

  /// Update all meta tags at once (no-op on non-web platforms)
  static void updateCompetitionMeta({
    required String title,
    required String description,
    required String canonicalUrl,
    String? imageUrl,
    List<String>? keywords,
  }) {
    // No-op on non-web platforms
  }

  /// Reset meta tags to defaults (no-op on non-web platforms)
  static void resetToDefaults() {
    // No-op on non-web platforms
  }

  /// Add structured data (no-op on non-web platforms)
  static void addStructuredData(Map<String, dynamic> structuredData) {
    // No-op on non-web platforms
  }
}

/// Competition-specific structured data generator (stub)
class CompetitionStructuredData {
  /// Generate schema.org SportsEvent structured data
  static Map<String, dynamic> generateSportsEvent({
    required String id,
    required String name,
    required String description,
    required DateTime startDate,
    required DateTime endDate,
    String? venue,
    String? city,
    String? country,
    String? imageUrl,
    String? organizerName,
    String? status,
  }) {
    return {}; // Return empty map on non-web platforms
  }

  /// Generate BreadcrumbList structured data
  static Map<String, dynamic> generateBreadcrumbs({
    required String baseUrl,
    required List<BreadcrumbItem> items,
  }) {
    return {}; // Return empty map on non-web platforms
  }
}

/// Breadcrumb item for structured data
class BreadcrumbItem {
  BreadcrumbItem({required this.name, required this.url});
  final String name;
  final String url;
}
