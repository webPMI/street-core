// Web-specific SEO helper
// This file should only be imported when running on web platform
// ignore_for_file: avoid_web_libraries_in_flutter

import 'dart:convert' show jsonEncode;
import 'dart:js_interop';

import './seo_config.dart';
import 'package:web/web.dart' as web;

/// Unique ID for JSON-LD script tags to enable replacement
const String _jsonLdScriptId = 'seo-json-ld';

/// Web-specific SEO Helper Implementation
///
/// This class provides methods to dynamically update HTML meta tags
/// using the web package. Only works on web platform.
class SeoHelperImpl {
  /// Update page meta tags dynamically on web
  static void updateMetaTags(SeoMetadata metadata, String currentPath) {
    // Update title
    web.document.title = metadata.fullTitle;

    // Update meta description
    _updateMetaTag('name', 'description', metadata.description);

    // Generate canonical URL from current path
    final canonicalUrl = SeoConfig.generateCanonicalUrl(currentPath);

    // --- Core SEO Meta Tags ---
    _updateMetaTag('name', 'robots', 'index, follow');
    if (metadata.author != null) {
      _updateMetaTag('name', 'author', metadata.author!);
    }

    // --- Open Graph Tags ---
    _updateMetaTag('property', 'og:title', metadata.fullTitle);
    _updateMetaTag('property', 'og:description', metadata.description);
    _updateMetaTag('property', 'og:url', canonicalUrl);
    _updateMetaTag('property', 'og:type', metadata.type ?? 'website');
    _updateMetaTag('property', 'og:site_name', SeoConfig.appName);
    _updateMetaTag(
      'property',
      'og:locale',
      SeoConfig.defaultLanguage == 'es' ? 'es_ES' : 'en_US',
    );
    if (metadata.imageUrl != null) {
      _updateMetaTag('property', 'og:image', metadata.imageUrl!);
      _updateMetaTag('property', 'og:image:alt', metadata.title);
    }
    if (SeoConfig.facebookAppId.isNotEmpty) {
      _updateMetaTag('property', 'fb:app_id', SeoConfig.facebookAppId);
    }

    // Article-specific Open Graph tags
    if (metadata.type == 'article') {
      if (metadata.publishedTime != null) {
        _updateMetaTag(
          'property',
          'article:published_time',
          metadata.publishedTime!.toIso8601String(),
        );
      }
      if (metadata.modifiedTime != null) {
        _updateMetaTag(
          'property',
          'article:modified_time',
          metadata.modifiedTime!.toIso8601String(),
        );
      }
      if (metadata.author != null) {
        _updateMetaTag('property', 'article:author', metadata.author!);
      }
    }

    // --- Twitter Card Tags ---
    _updateMetaTag('name', 'twitter:card', 'summary_large_image');
    _updateMetaTag('name', 'twitter:title', metadata.fullTitle);
    _updateMetaTag('name', 'twitter:description', metadata.description);
    _updateMetaTag('name', 'twitter:site', SeoConfig.twitterHandle);
    if (metadata.imageUrl != null) {
      _updateMetaTag('name', 'twitter:image', metadata.imageUrl!);
      _updateMetaTag('name', 'twitter:image:alt', metadata.title);
    }

    // --- Link Tags ---
    _updateLinkTag('canonical', canonicalUrl);

    // Update keywords if provided
    if (metadata.keywords.isNotEmpty) {
      _updateMetaTag('name', 'keywords', metadata.keywords.join(', '));
    }
  }

  /// Update hreflang tags for multi-language support
  static void updateHreflangTags(
    String currentPath,
    Map<String, String> languageUrls,
  ) {
    final head = web.document.head;
    if (head == null) return;

    // Remove existing hreflang tags
    _removeExistingTags('link[rel="alternate"][hreflang]');

    // Add new hreflang tags
    for (final entry in languageUrls.entries) {
      final linkTag =
          web.document.createElement('link') as web.HTMLLinkElement;
      linkTag.rel = 'alternate';
      linkTag.setAttribute('hreflang', entry.key);
      linkTag.href = entry.value;
      head.appendChild(linkTag);
    }

    // Add x-default for language selection page
    if (languageUrls.isNotEmpty) {
      final defaultUrl =
          languageUrls[SeoConfig.defaultLanguage] ?? languageUrls.values.first;
      final xDefaultTag =
          web.document.createElement('link') as web.HTMLLinkElement;
      xDefaultTag.rel = 'alternate';
      xDefaultTag.setAttribute('hreflang', 'x-default');
      xDefaultTag.href = defaultUrl;
      head.appendChild(xDefaultTag);
    }
  }

  /// Set robots meta tag
  static void setRobots(String content) {
    _updateMetaTag('name', 'robots', content);
  }

  /// Set noindex for private pages
  static void setNoIndex() {
    _updateMetaTag('name', 'robots', 'noindex, nofollow');
  }

  /// Remove existing tags matching selector
  static void _removeExistingTags(String selector) {
    final elements = web.document.querySelectorAll(selector);
    for (var i = 0; i < elements.length; i++) {
      final node = elements.item(i);
      if (node != null && node.isA<web.Element>()) {
        (node as web.Element).remove();
      }
    }
  }

  /// Update or create a meta tag
  static void _updateMetaTag(
    String attributeName,
    String attributeValue,
    String content,
  ) {
    final head = web.document.head;
    if (head == null) return;

    // Find existing meta tag
    final selector = 'meta[$attributeName="$attributeValue"]';
    final existing = web.document.querySelector(selector);

    if (existing != null) {
      // Update existing meta tag
      existing.setAttribute('content', content);
    } else {
      // Create new meta tag
      final metaTag = web.document.createElement('meta');
      metaTag.setAttribute(attributeName, attributeValue);
      metaTag.setAttribute('content', content);
      head.appendChild(metaTag);
    }
  }

  /// Update or create a link tag
  static void _updateLinkTag(String rel, String href) {
    final head = web.document.head;
    if (head == null) return;

    // Find existing link tag
    final selector = 'link[rel="$rel"]';
    final existing = web.document.querySelector(selector);

    if (existing != null) {
      // Update existing link tag
      existing.setAttribute('href', href);
    } else {
      // Create new link tag
      final linkTag = web.document.createElement('link');
      linkTag.setAttribute('rel', rel);
      linkTag.setAttribute('href', href);
      head.appendChild(linkTag);
    }
  }

  /// Add structured data (JSON-LD) to page
  /// Replaces any existing JSON-LD script with the same ID
  static void addStructuredData(Map<String, dynamic> jsonLd, {String? id}) {
    final head = web.document.head;
    if (head == null) return;

    final scriptId = id ?? _jsonLdScriptId;

    // Remove existing JSON-LD script with same ID
    final existingScript = web.document.getElementById(scriptId);
    if (existingScript != null) {
      existingScript.remove();
    }

    // Create script tag for JSON-LD
    final scriptTag =
        web.document.createElement('script') as web.HTMLScriptElement;
    scriptTag.type = 'application/ld+json';
    scriptTag.id = scriptId;
    scriptTag.text = jsonEncode(jsonLd);

    head.appendChild(scriptTag);
  }

  /// Remove all JSON-LD structured data
  static void clearStructuredData() {
    _removeExistingTags('script[type="application/ld+json"]');
  }

  /// Add multiple structured data schemas
  static void addMultipleStructuredData(List<Map<String, dynamic>> schemas) {
    clearStructuredData();
    for (var i = 0; i < schemas.length; i++) {
      addStructuredData(schemas[i], id: '$_jsonLdScriptId-$i');
    }
  }
}
