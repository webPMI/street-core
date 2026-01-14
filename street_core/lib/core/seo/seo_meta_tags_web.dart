/// SEO Meta Tags Generator
///
/// This utility generates SEO meta tags for Flutter Web applications.
/// It provides functions to dynamically update page metadata for better
/// search engine optimization and social media sharing.
///
library;

// ignore: deprecated_member_use
import 'package:web/web.dart' as web;

/// SEOMetaTags class handles dynamic meta tag generation and injection
class SEOMetaTags {
  /// Update page title
  static void updateTitle(String title) {
    web.document.title = title;
    _updateOrCreateMetaTag('property', 'og:title', title);
    _updateOrCreateMetaTag('name', 'twitter:title', title);
  }

  /// Update page description
  static void updateDescription(String description) {
    _updateOrCreateMetaTag('name', 'description', description);
    _updateOrCreateMetaTag('property', 'og:description', description);
    _updateOrCreateMetaTag('name', 'twitter:description', description);
  }

  /// Update canonical URL
  static void updateCanonicalUrl(String url) {
    _updateOrCreateLinkTag('canonical', url);
    _updateOrCreateMetaTag('property', 'og:url', url);
  }

  /// Update page image for social sharing
  static void updateImage(String imageUrl, {String? alt}) {
    _updateOrCreateMetaTag('property', 'og:image', imageUrl);
    _updateOrCreateMetaTag('name', 'twitter:image', imageUrl);
    if (alt != null) {
      _updateOrCreateMetaTag('property', 'og:image:alt', alt);
      _updateOrCreateMetaTag('name', 'twitter:image:alt', alt);
    }
  }

  /// Update keywords
  static void updateKeywords(List<String> keywords) {
    _updateOrCreateMetaTag('name', 'keywords', keywords.join(', '));
  }

  /// Set Open Graph type
  static void updateOGType(String type) {
    _updateOrCreateMetaTag('property', 'og:type', type);
  }

  /// Set Twitter Card type
  static void updateTwitterCard(String cardType) {
    _updateOrCreateMetaTag('name', 'twitter:card', cardType);
  }

  /// Set robots meta tag
  static void updateRobots(String value) {
    _updateOrCreateMetaTag('name', 'robots', value);
  }

  /// Update all meta tags at once for a competition
  static void updateCompetitionMeta({
    required String title,
    required String description,
    required String canonicalUrl,
    String? imageUrl,
    List<String>? keywords,
  }) {
    updateTitle(title);
    updateDescription(description);
    updateCanonicalUrl(canonicalUrl);

    if (imageUrl != null && imageUrl.isNotEmpty) {
      updateImage(imageUrl, alt: title);
    }

    if (keywords != null && keywords.isNotEmpty) {
      updateKeywords(keywords);
    }

    // Set Open Graph type for events
    updateOGType('sports_event');

    // Use large image card for Twitter
    updateTwitterCard('summary_large_image');

    // Set site name
    _updateOrCreateMetaTag('property', 'og:site_name', 'FitRiders Pro');
    _updateOrCreateMetaTag('name', 'twitter:site', '@fitriders');
  }

  /// Reset meta tags to defaults
  static void resetToDefaults() {
    updateTitle('FitRiders Pro - Fitness Competitions & Events');
    updateDescription(
      'Join the leading platform for fitness competitions, events, and athlete communities. '
      'Discover competitions, connect with clubs, and track your performance.',
    );
    updateOGType('website');
    updateTwitterCard('summary');
  }

  /// Helper to update or create meta tag
  static void _updateOrCreateMetaTag(
    String attributeName,
    String attributeValue,
    String content,
  ) {
    try {
      // Try to find existing meta tag
      final existing = web.document.querySelector(
        'meta[$attributeName="$attributeValue"]',
      );

      if (existing != null) {
        // Update existing tag
        existing.setAttribute('content', content);
      } else {
        // Create new tag
        final meta = web.HTMLMetaElement()
          ..setAttribute(attributeName, attributeValue)
          ..content = content;
        web.document.head?.append(meta);
      }
    } catch (e) {
      // Silently fail on non-web platforms
    }
  }

  /// Helper to update or create link tag
  static void _updateOrCreateLinkTag(String rel, String href) {
    try {
      // Try to find existing link tag
      final existing = web.document.querySelector('link[rel="$rel"]');

      if (existing != null) {
        // Update existing tag
        existing.setAttribute('href', href);
      } else {
        // Create new tag
        final link = web.HTMLLinkElement()
          ..rel = rel
          ..href = href;
        web.document.head?.append(link);
      }
    } catch (e) {
      // Silently fail on non-web platforms
    }
  }

  /// Add structured data (JSON-LD) to page
  static void addStructuredData(Map<String, dynamic> structuredData) {
    try {
      // Remove existing structured data scripts
      final existingScripts = web.document.querySelectorAll(
        'script[type="application/ld+json"]',
      );
      for (var i = 0; i < existingScripts.length; i++) {
        final node = existingScripts.item(i);
        if (node != null) {
          node.parentNode?.removeChild(node);
        }
      }

      // Create new script tag with structured data
      final script = web.HTMLScriptElement()
        ..type = 'application/ld+json'
        ..text = _jsonEncode(structuredData);

      web.document.head?.append(script);
    } catch (e) {
      // Silently fail on non-web platforms
    }
  }

  /// Simple JSON encoder (you may want to use dart:convert instead)
  static String _jsonEncode(Map<String, dynamic> data) {
    // This is a simplified encoder - use dart:convert json.encode in production
    final buffer = StringBuffer('{');
    final entries = data.entries.toList();

    for (var i = 0; i < entries.length; i++) {
      final entry = entries[i];
      buffer.write('"${entry.key}":');

      if (entry.value is String) {
        buffer.write('"${entry.value}"');
      } else if (entry.value is Map) {
        buffer.write(_jsonEncode(entry.value as Map<String, dynamic>));
      } else if (entry.value is List) {
        buffer.write('[');
        final list = entry.value as List;
        for (var j = 0; j < list.length; j++) {
          if (list[j] is Map) {
            buffer.write(_jsonEncode(list[j] as Map<String, dynamic>));
          } else if (list[j] is String) {
            buffer.write('"${list[j]}"');
          } else {
            buffer.write(list[j].toString());
          }
          if (j < list.length - 1) buffer.write(',');
        }
        buffer.write(']');
      } else {
        buffer.write(entry.value.toString());
      }

      if (i < entries.length - 1) buffer.write(',');
    }

    buffer.write('}');
    return buffer.toString();
  }
}

/// Competition-specific structured data generator
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
    final data = <String, dynamic>{
      '@context': 'https://schema.org',
      '@type': 'SportsEvent',
      '@id': id,
      'name': name,
      'description': description,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
    };

    // Add location if available
    if (venue != null || city != null) {
      data['location'] = {
        '@type': 'Place',
        if (venue != null) 'name': venue,
        if (city != null || country != null)
          'address': {
            '@type': 'PostalAddress',
            if (city != null) 'addressLocality': city,
            if (country != null) 'addressCountry': country,
          },
      };
    }

    // Add image
    if (imageUrl != null && imageUrl.isNotEmpty) {
      data['image'] = imageUrl;
    }

    // Add organizer
    if (organizerName != null) {
      data['organizer'] = {'@type': 'Organization', 'name': organizerName};
    }

    // Add event status
    final eventStatus = _mapStatusToSchemaStatus(status);
    if (eventStatus != null) {
      data['eventStatus'] = eventStatus;
    }

    // Add attendance mode (assuming offline/physical events)
    data['eventAttendanceMode'] =
        'https://schema.org/OfflineEventAttendanceMode';

    return data;
  }

  /// Generate BreadcrumbList structured data
  static Map<String, dynamic> generateBreadcrumbs({
    required String baseUrl,
    required List<BreadcrumbItem> items,
  }) {
    return {
      '@context': 'https://schema.org',
      '@type': 'BreadcrumbList',
      'itemListElement': items
          .asMap()
          .entries
          .map(
            (entry) => {
              '@type': 'ListItem',
              'position': entry.key + 1,
              'name': entry.value.name,
              'item': '$baseUrl${entry.value.url}',
            },
          )
          .toList(),
    };
  }

  /// Map competition status to schema.org EventStatus
  static String? _mapStatusToSchemaStatus(String? status) {
    switch (status) {
      case 'upcoming':
        return 'https://schema.org/EventScheduled';
      case 'live':
        return 'https://schema.org/EventScheduled';
      case 'completed':
        return 'https://schema.org/EventCompleted';
      case 'cancelled':
        return 'https://schema.org/EventCancelled';
      default:
        return null;
    }
  }
}

/// Breadcrumb item for structured data
class BreadcrumbItem {
  BreadcrumbItem({required this.name, required this.url});
  final String name;
  final String url;
}
