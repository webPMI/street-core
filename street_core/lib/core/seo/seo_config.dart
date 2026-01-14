/// SEO Configuration and Constants
///
/// Central configuration for all SEO-related metadata across the application.
/// This class provides default values and helper methods for SEO optimization.
library;

class SeoConfig {
  // App Information
  static const String appName = 'Street Core';
  static const String appDescription =
      'Urban sports platform for extreme sports enthusiasts. Connect with athletes, clubs, events, and competitions in skateboarding, BMX, parkour, and more.';

  // Production URL Configuration
  // Update this with your actual production domain before deploying
  static const String appUrl = String.fromEnvironment(
    'APP_URL',
    defaultValue: 'https://streetcore.app',
  );

  // Social Media
  static const String twitterHandle = '@streetcore';

  // Facebook App ID for Open Graph integration
  // Get this from: https://developers.facebook.com/apps/
  // Required for proper Facebook sharing and analytics
  static const String facebookAppId = String.fromEnvironment('FACEBOOK_APP_ID');

  // Default Images
  // Open Graph image should be at least 1200x630 pixels for optimal display
  // CDN or asset path recommended for better performance
  static const String defaultOgImage = String.fromEnvironment(
    'DEFAULT_OG_IMAGE',
    defaultValue: 'https://streetcore.app/assets/images/og-default.png',
  );

  static const String logoUrl = String.fromEnvironment(
    'LOGO_URL',
    defaultValue: 'https://streetcore.app/assets/images/logo.png',
  );

  // Organization Information (for structured data)
  static const String organizationName = 'Street Core';
  static const String organizationType = 'SportsOrganization';
  static const String contactEmail = 'contact@streetcore.com';
  static const String contactPhone = '+1-555-0123';

  // SEO Keywords
  static const List<String> defaultKeywords = [
    'urban sports',
    'street sports',
    'extreme sports',
    'skateboarding',
    'BMX',
    'inline aggressive skates',
    'competitions',
    'clubs',
    'events',
    'inline skating',
    'sports platform',
  ];

  // Language Configuration
  static const String defaultLanguage = 'es';
  static const String alternativeLanguage = 'en';

  /// Generate page-specific meta title with app name
  static String generateTitle(String pageTitle, {bool includeAppName = true}) {
    if (includeAppName) {
      return '$pageTitle | $appName';
    }
    return pageTitle;
  }

  /// Generate keywords string from list
  static String generateKeywords(List<String> additionalKeywords) {
    final allKeywords = [...defaultKeywords, ...additionalKeywords];
    return allKeywords.join(', ');
  }

  /// Generate canonical URL
  static String generateCanonicalUrl(String path) {
    final cleanPath = path.startsWith('/') ? path.substring(1) : path;
    return '$appUrl/$cleanPath';
  }

  /// Generate Open Graph image URL
  static String generateOgImageUrl(String? customImage) {
    return customImage ?? defaultOgImage;
  }
}

/// Page-specific SEO metadata
class SeoMetadata {
  const SeoMetadata({
    required this.title,
    required this.description,
    this.keywords = const [],
    this.imageUrl,
    this.author,
    this.type = 'website',
    this.publishedTime,
    this.modifiedTime,
  });
  final String title;
  final String description;
  final List<String> keywords;
  final String? imageUrl;
  final String? author;
  final String? type; // article, website, profile, product, event
  final DateTime? publishedTime;
  final DateTime? modifiedTime;

  /// Generate full title with app name
  String get fullTitle => SeoConfig.generateTitle(title);

  /// Generate keywords string
  String get keywordsString => SeoConfig.generateKeywords(keywords);

  /// Generate OG image URL
  String get ogImageUrl => SeoConfig.generateOgImageUrl(imageUrl);
}

/// Predefined SEO metadata for common pages
class SeoMetadataTemplates {
  // Home Page
  static const SeoMetadata home = SeoMetadata(
    title: 'Home',
    description:
        'Urban sports platform for extreme sports enthusiasts. Connect with athletes, clubs, events, and competitions in skateboarding, BMX, parkour, and more.',
    keywords: [
      'urban sports platform',
      'street sports community',
      'extreme sports management',
    ],
  );

  // Riders Listing
  static const SeoMetadata riders = SeoMetadata(
    title: 'Professional Athletes',
    description:
        'Browse professional urban sports athletes. View profiles, achievements, and competition history in skateboarding, BMX, parkour, and more.',
    keywords: [
      'professional athletes',
      'urban sports athletes',
      'athlete profiles',
      'street sports',
    ],
  );

  // Clubs Listing
  static const SeoMetadata clubs = SeoMetadata(
    title: 'Urban Sports Clubs',
    description:
        'Discover urban sports clubs and street sports organizations. Join clubs, connect with members, and participate in activities.',
    keywords: [
      'urban sports clubs',
      'street sports clubs',
      'extreme sports clubs',
      'skateboarding clubs',
    ],
  );

  // Events Listing
  static const SeoMetadata events = SeoMetadata(
    title: 'Sports Events & Competitions',
    description:
        'Find upcoming urban sports events, competitions, and tournaments. Register and participate in skateboarding, BMX, parkour events.',
    keywords: [
      'urban sports events',
      'street sports competitions',
      'skateboarding tournaments',
      'BMX events',
      'parkour competitions',
    ],
  );

  // Market/Products Listing
  static const SeoMetadata market = SeoMetadata(
    title: 'Urban Sports Marketplace',
    description:
        'Shop urban sports gear, equipment, and products. Browse our marketplace for skateboarding, BMX, parkour, and street sports needs.',
    keywords: [
      'urban sports marketplace',
      'street sports gear',
      'skateboarding equipment',
      'BMX gear',
    ],
  );

  // Contact Page
  static const SeoMetadata contact = SeoMetadata(
    title: 'Contact Us',
    description:
        'Get in touch with Street Core. Contact our team for support, partnerships, or inquiries.',
    keywords: ['contact', 'support', 'customer service'],
  );

  /// Generate metadata for individual athlete profile
  static SeoMetadata riderProfile({
    required String riderName,
    required String bio,
    String? imageUrl,
    List<String>? achievements,
  }) {
    return SeoMetadata(
      title: '$riderName - Athlete Profile',
      description: bio.length > 160 ? '${bio.substring(0, 157)}...' : bio,
      keywords: [
        'athlete profile',
        riderName.toLowerCase(),
        'urban sports athlete',
        'street sports',
        if (achievements != null) ...achievements,
      ],
      imageUrl: imageUrl,
      type: 'profile',
    );
  }

  /// Generate metadata for club detail
  static SeoMetadata clubDetail({
    required String clubName,
    required String description,
    String? imageUrl,
    String? discipline,
  }) {
    return SeoMetadata(
      title: '$clubName - Club Profile',
      description: description.length > 160
          ? '${description.substring(0, 157)}...'
          : description,
      keywords: [
        'urban sports club',
        'street sports club',
        clubName.toLowerCase(),
        if (discipline != null) discipline.toLowerCase(),
      ],
      imageUrl: imageUrl,
    );
  }

  /// Generate metadata for event detail
  static SeoMetadata eventDetail({
    required String eventName,
    required String description,
    required DateTime eventDate,
    String? imageUrl,
    String? location,
  }) {
    return SeoMetadata(
      title: '$eventName - Event',
      description: description.length > 160
          ? '${description.substring(0, 157)}...'
          : description,
      keywords: [
        'urban sports event',
        'street sports event',
        eventName.toLowerCase(),
        if (location != null) location.toLowerCase(),
      ],
      imageUrl: imageUrl,
      type: 'event',
      publishedTime: eventDate,
    );
  }

  /// Generate metadata for product detail
  static SeoMetadata productDetail({
    required String productName,
    required String description,
    required double price,
    String? imageUrl,
    String? category,
  }) {
    return SeoMetadata(
      title: '$productName - Product',
      description: description.length > 160
          ? '${description.substring(0, 157)}...'
          : description,
      keywords: [
        'urban sports product',
        'street sports gear',
        productName.toLowerCase(),
        if (category != null) category.toLowerCase(),
        'buy',
        'shop',
      ],
      imageUrl: imageUrl,
      type: 'product',
    );
  }
}
