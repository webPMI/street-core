import './seo_config.dart';

/// Sitemap URL entry
class SitemapUrl {

  const SitemapUrl({
    required this.loc,
    this.lastmod,
    this.changefreq,
    this.priority,
    this.alternates,
  });
  /// URL location
  final String loc;

  /// Last modification date
  final DateTime? lastmod;

  /// Change frequency: always, hourly, daily, weekly, monthly, yearly, never
  final String? changefreq;

  /// Priority: 0.0 to 1.0
  final double? priority;

  /// Alternate language versions
  final Map<String, String>? alternates;

  /// Generate XML for this URL entry
  String toXml() {
    final buffer = StringBuffer();
    buffer.writeln('  <url>');
    buffer.writeln('    <loc>$loc</loc>');

    if (lastmod != null) {
      buffer.writeln('    <lastmod>${_formatDate(lastmod!)}</lastmod>');
    }
    if (changefreq != null) {
      buffer.writeln('    <changefreq>$changefreq</changefreq>');
    }
    if (priority != null) {
      buffer.writeln('    <priority>${priority!.toStringAsFixed(1)}</priority>');
    }

    // Add alternate language versions (hreflang)
    if (alternates != null && alternates!.isNotEmpty) {
      for (final entry in alternates!.entries) {
        buffer.writeln(
            '    <xhtml:link rel="alternate" hreflang="${entry.key}" href="${entry.value}"/>');
      }
      // Add x-default
      final defaultUrl =
          alternates![SeoConfig.defaultLanguage] ?? alternates!.values.first;
      buffer.writeln(
          '    <xhtml:link rel="alternate" hreflang="x-default" href="$defaultUrl"/>');
    }

    buffer.writeln('  </url>');
    return buffer.toString();
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}

/// Sitemap generator for SEO
///
/// Generates XML sitemaps for search engine indexing.
/// Supports multiple languages via hreflang.
class SitemapGenerator {
  final List<SitemapUrl> _urls = [];

  /// Add a URL to the sitemap
  void addUrl(SitemapUrl url) {
    _urls.add(url);
  }

  /// Add multiple URLs
  void addUrls(List<SitemapUrl> urls) {
    _urls.addAll(urls);
  }

  /// Add a simple URL with default settings
  void addSimpleUrl(
    String path, {
    DateTime? lastmod,
    String changefreq = 'weekly',
    double priority = 0.5,
  }) {
    _urls.add(SitemapUrl(
      loc: SeoConfig.generateCanonicalUrl(path),
      lastmod: lastmod,
      changefreq: changefreq,
      priority: priority,
    ));
  }

  /// Add static pages with their priorities
  void addStaticPages() {
    // Home page - highest priority
    addSimpleUrl('/', changefreq: 'daily', priority: 1);

    // Public listing pages - high priority
    addSimpleUrl('/public/athletes', changefreq: 'daily', priority: 0.9);
    addSimpleUrl('/public/clubs', changefreq: 'daily', priority: 0.9);
    addSimpleUrl('/public/events', changefreq: 'daily', priority: 0.9);
    addSimpleUrl('/public/market', changefreq: 'daily', priority: 0.8);

    // Contact and legal pages - lower priority
    addSimpleUrl('/public/contact', changefreq: 'monthly', priority: 0.6);
    addSimpleUrl('/legal', changefreq: 'yearly', priority: 0.3);
    addSimpleUrl('/privacy-policy', changefreq: 'yearly', priority: 0.3);
    addSimpleUrl('/terms-of-service', changefreq: 'yearly', priority: 0.3);
    addSimpleUrl('/cookie-policy', changefreq: 'yearly', priority: 0.3);
    addSimpleUrl('/refund-policy', changefreq: 'yearly', priority: 0.3);
    addSimpleUrl('/data-protection', changefreq: 'yearly', priority: 0.3);
  }

  /// Add dynamic content URLs (athletes, clubs, events, products)
  void addDynamicUrls({
    List<DynamicSitemapEntry>? athletes,
    List<DynamicSitemapEntry>? clubs,
    List<DynamicSitemapEntry>? events,
    List<DynamicSitemapEntry>? products,
  }) {
    if (athletes != null) {
      for (final athlete in athletes) {
        addSimpleUrl(
          '/public/athletes/${athlete.id}',
          lastmod: athlete.lastModified,
          priority: 0.7,
        );
      }
    }

    if (clubs != null) {
      for (final club in clubs) {
        addSimpleUrl(
          '/public/clubs/${club.id}',
          lastmod: club.lastModified,
          priority: 0.7,
        );
      }
    }

    if (events != null) {
      for (final event in events) {
        addSimpleUrl(
          '/public/events/${event.id}',
          lastmod: event.lastModified,
          changefreq: 'daily',
          priority: 0.8,
        );
      }
    }

    if (products != null) {
      for (final product in products) {
        addSimpleUrl(
          '/public/market/${product.id}',
          lastmod: product.lastModified,
          priority: 0.6,
        );
      }
    }
  }

  /// Generate the complete sitemap XML
  String generate() {
    final buffer = StringBuffer();

    buffer.writeln('<?xml version="1.0" encoding="UTF-8"?>');
    buffer.writeln(
        '<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9"');
    buffer.writeln(
        '        xmlns:xhtml="http://www.w3.org/1999/xhtml">');

    for (final url in _urls) {
      buffer.write(url.toXml());
    }

    buffer.writeln('</urlset>');

    return buffer.toString();
  }

  /// Generate sitemap index for large sites
  static String generateSitemapIndex(List<SitemapIndexEntry> sitemaps) {
    final buffer = StringBuffer();

    buffer.writeln('<?xml version="1.0" encoding="UTF-8"?>');
    buffer.writeln(
        '<sitemapindex xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">');

    for (final sitemap in sitemaps) {
      buffer.writeln('  <sitemap>');
      buffer.writeln('    <loc>${sitemap.loc}</loc>');
      if (sitemap.lastmod != null) {
        buffer.writeln(
            '    <lastmod>${sitemap.lastmod!.toIso8601String().split('T')[0]}</lastmod>');
      }
      buffer.writeln('  </sitemap>');
    }

    buffer.writeln('</sitemapindex>');

    return buffer.toString();
  }

  /// Clear all URLs
  void clear() {
    _urls.clear();
  }

  /// Get URL count
  int get urlCount => _urls.length;
}

/// Entry for dynamic content in sitemap
class DynamicSitemapEntry {

  const DynamicSitemapEntry({
    required this.id,
    this.lastModified,
  });
  final String id;
  final DateTime? lastModified;
}

/// Entry for sitemap index
class SitemapIndexEntry {

  const SitemapIndexEntry({
    required this.loc,
    this.lastmod,
  });
  final String loc;
  final DateTime? lastmod;
}

/// Robots.txt generator
class RobotsTxtGenerator {
  final List<String> _allows = [];
  final List<String> _disallows = [];
  final List<String> _sitemaps = [];
  String _userAgent = '*';
  int? _crawlDelay;

  /// Set user agent (default: *)
  void setUserAgent(String userAgent) {
    _userAgent = userAgent;
  }

  /// Set crawl delay in seconds
  void setCrawlDelay(int seconds) {
    _crawlDelay = seconds;
  }

  /// Allow a path
  void allow(String path) {
    _allows.add(path);
  }

  /// Disallow a path
  void disallow(String path) {
    _disallows.add(path);
  }

  /// Add sitemap URL
  void addSitemap(String url) {
    _sitemaps.add(url);
  }

  /// Add default rules for FitRiders
  void addDefaultRules() {
    // Allow public pages
    allow('/');
    allow('/public/');

    // Disallow private/admin pages
    disallow('/dashboard');
    disallow('/profile');
    disallow('/settings');
    disallow('/admin');
    disallow('/login');
    disallow('/register');
    disallow('/api/');

    // Disallow assets that shouldn't be indexed
    disallow('/*.json');
    disallow('/*?*'); // Query parameters

    // Add sitemap
    addSitemap('${SeoConfig.appUrl}/sitemap.xml');
  }

  /// Generate robots.txt content
  String generate() {
    final buffer = StringBuffer();

    buffer.writeln('User-agent: $_userAgent');

    if (_crawlDelay != null) {
      buffer.writeln('Crawl-delay: $_crawlDelay');
    }

    buffer.writeln();

    for (final path in _allows) {
      buffer.writeln('Allow: $path');
    }

    for (final path in _disallows) {
      buffer.writeln('Disallow: $path');
    }

    buffer.writeln();

    for (final sitemap in _sitemaps) {
      buffer.writeln('Sitemap: $sitemap');
    }

    return buffer.toString();
  }

  /// Generate default robots.txt for FitRiders
  static String generateDefault() {
    final generator = RobotsTxtGenerator()..addDefaultRules();
    return generator.generate();
  }
}
