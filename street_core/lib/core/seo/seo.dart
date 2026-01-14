library;

// Schema validation
export 'schema_validator.dart' show SchemaValidationResult, SchemaValidator;
/// SEO Module
///
/// Provides comprehensive SEO optimization utilities for Flutter Web including:
/// - Dynamic meta tag management (Open Graph, Twitter Cards, hreflang)
/// - Structured data (JSON-LD) generation with validation
/// - SEO validation and scoring
/// - Semantic HTML heading widgets (H1-H6)
/// - Sitemap and robots.txt generation
/// - GoRouter integration via observer
///
/// ## Quick Start
///
/// ```dart
/// import 'seo.dart';
/// ///
/// /// // 1. Add SeoRouteObserver to GoRouter
/// /// final router = GoRouter(
/// ///   observers: [SeoRouteObserver()],
/// ///   routes: [...],
/// /// );
/// ///
/// /// // 2. Update page meta tags manually (if needed)
/// /// SeoHelper.updateMetaTags(SeoMetadataTemplates.home, '/');
/// ///
/// /// // 3. Add structured data
/// /// final schema = StructuredDataGenerator.generateOrganizationSchema();
/// /// SeoHelper.addStructuredData(schema);
/// ///
/// /// // 4. Use semantic headings in widgets
/// /// SeoH1('Page Title');
/// /// SeoH2('Section Title');
/// /// ```
///
/// ## Features
///
/// ### Meta Tags
/// - `SeoHelper.updateMetaTags()` - Update all meta tags
/// - `SeoHelper.updateHreflangTags()` - Multi-language support
/// - `SeoHelper.setNoIndex()` - Hide pages from search engines
///
/// ### Structured Data
/// - `StructuredDataGenerator` - Generate JSON-LD schemas
/// - `SchemaValidator` - Validate schemas before use
///
/// ### Headings
/// - `SeoH1` through `SeoH6` - Semantic HTML headings
///
/// ### Sitemap & Robots
/// - `SitemapGenerator` - Generate sitemap.xml
/// - `RobotsTxtGenerator` - Generate robots.txt

// Configuration and metadata
export 'seo_config.dart' show SeoConfig, SeoMetadata, SeoMetadataTemplates;
// Semantic heading widgets
export 'seo_heading.dart' show SeoH1, SeoH2, SeoH3, SeoH4, SeoH5, SeoH6;
// Core helper for meta tag management
export 'seo_helper.dart' show SeoHelper;
// Router integration
export 'seo_route_observer.dart' show SeoRouteObserver;
// Validation and utilities
export 'seo_utils.dart'
    show
        HeadingHierarchyResult,
        HeadingInfo,
        PageSeoScore,
        SeoUtils,
        SeoValidationResult;
// Sitemap and robots.txt generation
export 'sitemap_generator.dart'
    show
        DynamicSitemapEntry,
        RobotsTxtGenerator,
        SitemapGenerator,
        SitemapIndexEntry,
        SitemapUrl;
// Structured data generation
export 'structured_data.dart' show StructuredDataGenerator;
