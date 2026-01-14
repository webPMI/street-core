import '../helpers/logger.dart';
import '../platform/platform_detector.dart';
import './seo_config.dart';
import './seo_helper.dart';
import 'package:flutter/widgets.dart';

/// SEO Route Observer for GoRouter integration
///
/// Automatically updates meta tags when navigation occurs.
/// Only active on web platform.
///
/// Usage with GoRouter:
/// ```dart
/// final router = GoRouter(
///   observers: [SeoRouteObserver()],
///   routes: [...],
/// );
/// ```
class SeoRouteObserver extends NavigatorObserver {

  /// Factory constructor returns singleton
  factory SeoRouteObserver() => _instance;

  SeoRouteObserver._internal() {
    _initializeDefaultMetadata();
  }
  /// Map of route paths to their SEO metadata
  final Map<String, SeoMetadata> _routeMetadata = {};

  /// Singleton instance
  static final SeoRouteObserver _instance = SeoRouteObserver._internal();

  /// Initialize default metadata for known routes
  void _initializeDefaultMetadata() {
    // Home and public pages
    registerRoute('/', SeoMetadataTemplates.home);
    registerRoute('/login', _loginMetadata);
    registerRoute('/register', _registerMetadata);

    // Legal pages
    registerRoute('/legal', _legalMetadata);
    registerRoute('/privacy-policy', _privacyMetadata);
    registerRoute('/terms-of-service', _termsMetadata);
    registerRoute('/cookie-policy', _cookieMetadata);
    registerRoute('/refund-policy', _refundMetadata);
    registerRoute('/data-protection', _dataProtectionMetadata);
    registerRoute('/public/contact', SeoMetadataTemplates.contact);

    // Public listing pages
    registerRoute('/public/athletes', SeoMetadataTemplates.riders);
    registerRoute('/public/clubs', SeoMetadataTemplates.clubs);
    registerRoute('/public/events', SeoMetadataTemplates.events);
    registerRoute('/public/market', SeoMetadataTemplates.market);
  }

  /// Register custom metadata for a route
  void registerRoute(String path, SeoMetadata metadata) {
    _routeMetadata[path] = metadata;
  }

  /// Register metadata for dynamic routes (with parameters)
  void registerDynamicRoute(String path, SeoMetadata metadata) {
    _routeMetadata[path] = metadata;
  }

  /// Unregister a route's metadata
  void unregisterRoute(String path) {
    _routeMetadata.remove(path);
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    final from = previousRoute?.settings.name ?? 'null';
    final to = route.settings.name ?? 'unknown';
    AppLogger.navigation('Push', from: from, to: to);
    _updateSeoForRoute(route);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    if (newRoute != null) {
      final from = oldRoute?.settings.name ?? 'null';
      final to = newRoute.settings.name ?? 'unknown';
      AppLogger.navigation('Replace', from: from, to: to);
      _updateSeoForRoute(newRoute);
    }
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    if (previousRoute != null) {
      final from = route.settings.name ?? 'unknown';
      final to = previousRoute.settings.name ?? 'unknown';
      AppLogger.navigation('Pop', from: from, to: to);
      _updateSeoForRoute(previousRoute);
    }
  }

  /// Update SEO metadata for the current route
  void _updateSeoForRoute(Route<dynamic> route) {
    if (!PlatformDetector.shouldEnableSEO) return;

    final routeName = route.settings.name;
    if (routeName == null) return;

    // Try exact match first
    var metadata = _routeMetadata[routeName];

    // If no exact match, try to find a pattern match for dynamic routes
    metadata ??= _findPatternMatch(routeName);

    // Fall back to default if no metadata found
    metadata ??= _defaultMetadata;

    SeoHelper.updateMetaTags(metadata, routeName);
  }

  /// Find metadata for dynamic routes (e.g., /public/athletes/:id)
  SeoMetadata? _findPatternMatch(String path) {
    // Check for dynamic route patterns
    for (final entry in _routeMetadata.entries) {
      if (_matchesPattern(entry.key, path)) {
        return entry.value;
      }
    }
    return null;
  }

  /// Check if a path matches a route pattern
  bool _matchesPattern(String pattern, String path) {
    // Convert pattern like /public/athletes/:id to regex
    final regexPattern = pattern
        .replaceAll(RegExp(r':[\w]+'), '[^/]+')
        .replaceAll('/', r'\/');

    return RegExp('^$regexPattern\$').hasMatch(path);
  }

  /// Update SEO for current route manually
  /// Useful for dynamic content that loads after navigation
  void updateCurrentRoute(String path, SeoMetadata metadata) {
    if (!PlatformDetector.shouldEnableSEO) return;
    SeoHelper.updateMetaTags(metadata, path);
  }

  // Predefined metadata for common pages
  static const _loginMetadata = SeoMetadata(
    title: 'Login',
    description:
        'Sign in to Street Core. Access your urban sports profile, manage your club, and connect with the athlete community.',
    keywords: ['login', 'sign in', 'urban sports account'],
  );

  static const _registerMetadata = SeoMetadata(
    title: 'Create Account',
    description:
        'Join Street Core today. Create your urban sports profile and connect with athletes, clubs, and events worldwide.',
    keywords: ['register', 'sign up', 'create account', 'join'],
  );

  static const _legalMetadata = SeoMetadata(
    title: 'Legal Information',
    description:
        'Legal information and policies for Street Core. View our terms, privacy policy, and other legal documents.',
    keywords: ['legal', 'terms', 'policies'],
  );

  static const _privacyMetadata = SeoMetadata(
    title: 'Privacy Policy',
    description:
        'Street Core Privacy Policy. Learn how we collect, use, and protect your personal information.',
    keywords: ['privacy policy', 'data protection', 'personal data'],
  );

  static const _termsMetadata = SeoMetadata(
    title: 'Terms of Service',
    description:
        'Street Core Terms of Service. Read our terms and conditions for using the platform.',
    keywords: ['terms of service', 'terms and conditions', 'user agreement'],
  );

  static const _cookieMetadata = SeoMetadata(
    title: 'Cookie Policy',
    description:
        'Street Core Cookie Policy. Learn about how we use cookies and similar technologies.',
    keywords: ['cookie policy', 'cookies', 'tracking'],
  );

  static const _refundMetadata = SeoMetadata(
    title: 'Refund Policy',
    description:
        'Street Core Refund Policy. Learn about our refund and cancellation policies.',
    keywords: ['refund policy', 'cancellation', 'money back'],
  );

  static const _dataProtectionMetadata = SeoMetadata(
    title: 'Data Protection',
    description:
        'Street Core Data Protection information. Learn about your data rights under GDPR and other regulations.',
    keywords: ['data protection', 'GDPR', 'data rights'],
  );

  static const _defaultMetadata = SeoMetadata(
    title: 'Street Core',
    description: SeoConfig.appDescription,
  );
}
