import './seo_config.dart';

/// Structured Data Generator
///
/// Generates JSON-LD structured data for different schema types.
/// Helps search engines understand content better.

class StructuredDataGenerator {
  /// Generate Organization schema
  static Map<String, dynamic> generateOrganizationSchema() {
    return {
      '@context': 'https://schema.org',
      '@type': SeoConfig.organizationType,
      'name': SeoConfig.organizationName,
      'url': SeoConfig.appUrl,
      'logo': SeoConfig.logoUrl,
      'description': SeoConfig.appDescription,
      'contactPoint': {
        '@type': 'ContactPoint',
        'telephone': SeoConfig.contactPhone,
        'email': SeoConfig.contactEmail,
        'contactType': 'customer service',
      },
    };
  }

  /// Generate Person schema for rider/athlete profile
  static Map<String, dynamic> generatePersonSchema({
    required String id,
    required String name,
    required String description,
    String? imageUrl,
    String? email,
    List<String>? achievements,
    String? clubName,
    String? sport,
  }) {
    final schema = <String, dynamic>{
      '@context': 'https://schema.org',
      '@type': 'Person',
      '@id': '${SeoConfig.appUrl}/public/riders/$id',
      'name': name,
      'description': description,
    };

    if (imageUrl != null) schema['image'] = imageUrl;
    if (email != null) schema['email'] = email;

    if (sport != null) {
      schema['sport'] = sport;
    }

    if (achievements != null && achievements.isNotEmpty) {
      schema['award'] = achievements;
    }

    if (clubName != null) {
      schema['memberOf'] = {'@type': 'SportsOrganization', 'name': clubName};
    }

    return schema;
  }

  /// Generate SportsOrganization schema for club
  static Map<String, dynamic> generateClubSchema({
    required String id,
    required String name,
    required String description,
    String? imageUrl,
    String? address,
    String? city,
    String? country,
    String? email,
    String? phone,
    String? discipline,
    int? memberCount,
  }) {
    final schema = <String, dynamic>{
      '@context': 'https://schema.org',
      '@type': 'SportsOrganization',
      '@id': '${SeoConfig.appUrl}/public/clubs/$id',
      'name': name,
      'description': description,
      'url': '${SeoConfig.appUrl}/public/clubs/$id',
    };

    if (imageUrl != null) schema['image'] = imageUrl;
    if (email != null) schema['email'] = email;
    if (phone != null) schema['telephone'] = phone;
    if (discipline != null) schema['sport'] = discipline;
    if (memberCount != null) schema['numberOfMembers'] = memberCount;

    if (address != null) {
      schema['address'] = {
        '@type': 'PostalAddress',
        'streetAddress': address,
        if (city != null) 'addressLocality': city,
        if (country != null) 'addressCountry': country,
      };
    }

    return schema;
  }

  /// Generate SportsEvent schema for competition/event
  static Map<String, dynamic> generateEventSchema({
    required String id,
    required String name,
    required String description,
    required DateTime startDate,
    DateTime? endDate,
    String? imageUrl,
    String? location,
    String? organizerName,
    String? eventStatus, // scheduled, postponed, cancelled
    double? entryFee,
    String? currency,
  }) {
    final schema = <String, dynamic>{
      '@context': 'https://schema.org',
      '@type': 'SportsEvent',
      '@id': '${SeoConfig.appUrl}/public/events/$id',
      'name': name,
      'description': description,
      'startDate': startDate.toIso8601String(),
      'url': '${SeoConfig.appUrl}/public/events/$id',
    };

    if (endDate != null) schema['endDate'] = endDate.toIso8601String();
    if (imageUrl != null) schema['image'] = imageUrl;

    if (location != null) {
      schema['location'] = {'@type': 'Place', 'name': location};
    }

    if (organizerName != null) {
      schema['organizer'] = {'@type': 'Organization', 'name': organizerName};
    }

    if (eventStatus != null) {
      final statusMap = {
        'scheduled': 'https://schema.org/EventScheduled',
        'postponed': 'https://schema.org/EventPostponed',
        'cancelled': 'https://schema.org/EventCancelled',
      };
      schema['eventStatus'] =
          statusMap[eventStatus.toLowerCase()] ??
          'https://schema.org/EventScheduled';
    }

    if (entryFee != null) {
      schema['offers'] = {
        '@type': 'Offer',
        'price': entryFee.toString(),
        'priceCurrency': currency ?? 'EUR',
      };
    }

    return schema;
  }

  /// Generate Product schema for marketplace items
  static Map<String, dynamic> generateProductSchema({
    required String id,
    required String name,
    required String description,
    required double price,
    required String currency,
    String? imageUrl,
    String? brand,
    String? category,
    bool? inStock,
    double? rating,
    int? reviewCount,
  }) {
    final schema = {
      '@context': 'https://schema.org',
      '@type': 'Product',
      '@id': '${SeoConfig.appUrl}/public/market/$id',
      'name': name,
      'description': description,
      'url': '${SeoConfig.appUrl}/public/market/$id',
      'offers': {
        '@type': 'Offer',
        'price': price.toString(),
        'priceCurrency': currency,
        'availability': inStock == false
            ? 'https://schema.org/OutOfStock'
            : 'https://schema.org/InStock',
      },
    };

    if (imageUrl != null) schema['image'] = imageUrl;
    if (brand != null) schema['brand'] = {'@type': 'Brand', 'name': brand};
    if (category != null) schema['category'] = category;

    if (rating != null && reviewCount != null && reviewCount > 0) {
      schema['aggregateRating'] = {
        '@type': 'AggregateRating',
        'ratingValue': rating.toString(),
        'reviewCount': reviewCount.toString(),
      };
    }

    return schema;
  }

  /// Generate BreadcrumbList schema for navigation
  static Map<String, dynamic> generateBreadcrumbSchema(
    List<Map<String, String>> breadcrumbs,
  ) {
    final items = <Map<String, dynamic>>[];

    for (var i = 0; i < breadcrumbs.length; i++) {
      items.add({
        '@type': 'ListItem',
        'position': i + 1,
        'name': breadcrumbs[i]['name'],
        'item': breadcrumbs[i]['url'],
      });
    }

    return {
      '@context': 'https://schema.org',
      '@type': 'BreadcrumbList',
      'itemListElement': items,
    };
  }

  /// Generate SearchAction schema for site search
  static Map<String, dynamic> generateSearchActionSchema(
    String searchUrlTemplate,
  ) {
    return {
      '@context': 'https://schema.org',
      '@type': 'WebSite',
      'url': SeoConfig.appUrl,
      'potentialAction': {
        '@type': 'SearchAction',
        'target': searchUrlTemplate,
        'query-input': 'required name=search_term_string',
      },
    };
  }

  /// Generate ItemList schema for listing pages
  static Map<String, dynamic> generateItemListSchema({
    required String listName,
    required List<Map<String, String>> items,
  }) {
    final listItems = <Map<String, dynamic>>[];

    for (var i = 0; i < items.length; i++) {
      listItems.add({
        '@type': 'ListItem',
        'position': i + 1,
        'url': items[i]['url'],
        'name': items[i]['name'],
      });
    }

    return {
      '@context': 'https://schema.org',
      '@type': 'ItemList',
      'name': listName,
      'itemListElement': listItems,
    };
  }

  /// Generate FAQPage schema
  static Map<String, dynamic> generateFAQSchema(
    List<Map<String, String>> faqs,
  ) {
    final mainEntity = <Map<String, dynamic>>[];

    for (final faq in faqs) {
      mainEntity.add({
        '@type': 'Question',
        'name': faq['question'],
        'acceptedAnswer': {'@type': 'Answer', 'text': faq['answer']},
      });
    }

    return {
      '@context': 'https://schema.org',
      '@type': 'FAQPage',
      'mainEntity': mainEntity,
    };
  }

  /// Generate Review schema for product reviews
  static Map<String, dynamic> generateReviewSchema({
    required String itemName,
    required String reviewBody,
    required double rating,
    required String authorName,
    required DateTime datePublished,
    String? itemUrl,
    int? maxRating,
  }) {
    return {
      '@context': 'https://schema.org',
      '@type': 'Review',
      'itemReviewed': {
        '@type': 'Product',
        'name': itemName,
        if (itemUrl != null) 'url': itemUrl,
      },
      'reviewRating': {
        '@type': 'Rating',
        'ratingValue': rating.toString(),
        'bestRating': (maxRating ?? 5).toString(),
      },
      'author': {
        '@type': 'Person',
        'name': authorName,
      },
      'reviewBody': reviewBody,
      'datePublished': datePublished.toIso8601String(),
    };
  }

  /// Generate HowTo schema for tutorials/guides
  static Map<String, dynamic> generateHowToSchema({
    required String name,
    required String description,
    required List<Map<String, String>> steps,
    String? imageUrl,
    Duration? totalTime,
    List<String>? tools,
  }) {
    final schema = <String, dynamic>{
      '@context': 'https://schema.org',
      '@type': 'HowTo',
      'name': name,
      'description': description,
    };

    if (imageUrl != null) schema['image'] = imageUrl;

    if (totalTime != null) {
      schema['totalTime'] = 'PT${totalTime.inMinutes}M';
    }

    if (tools != null && tools.isNotEmpty) {
      schema['tool'] = tools.map((tool) => {
        '@type': 'HowToTool',
        'name': tool,
      }).toList();
    }

    final stepList = <Map<String, dynamic>>[];
    for (var i = 0; i < steps.length; i++) {
      stepList.add({
        '@type': 'HowToStep',
        'position': i + 1,
        'name': steps[i]['name'],
        'text': steps[i]['text'],
        if (steps[i]['image'] != null) 'image': steps[i]['image'],
      });
    }
    schema['step'] = stepList;

    return schema;
  }

  /// Generate VideoObject schema
  static Map<String, dynamic> generateVideoSchema({
    required String name,
    required String description,
    required String thumbnailUrl,
    required String contentUrl,
    required DateTime uploadDate,
    Duration? duration,
    String? embedUrl,
  }) {
    final schema = <String, dynamic>{
      '@context': 'https://schema.org',
      '@type': 'VideoObject',
      'name': name,
      'description': description,
      'thumbnailUrl': thumbnailUrl,
      'contentUrl': contentUrl,
      'uploadDate': uploadDate.toIso8601String(),
    };

    if (duration != null) {
      schema['duration'] = 'PT${duration.inSeconds}S';
    }

    if (embedUrl != null) {
      schema['embedUrl'] = embedUrl;
    }

    return schema;
  }

  /// Generate LocalBusiness schema (for physical locations)
  static Map<String, dynamic> generateLocalBusinessSchema({
    required String name,
    required String streetAddress,
    required String city,
    required String region,
    required String postalCode,
    required String country,
    String? phone,
    String? email,
    String? imageUrl,
    double? latitude,
    double? longitude,
    List<String>? openingHours,
    double? rating,
    int? reviewCount,
  }) {
    final schema = <String, dynamic>{
      '@context': 'https://schema.org',
      '@type': 'LocalBusiness',
      'name': name,
      'address': {
        '@type': 'PostalAddress',
        'streetAddress': streetAddress,
        'addressLocality': city,
        'addressRegion': region,
        'postalCode': postalCode,
        'addressCountry': country,
      },
    };

    if (phone != null) schema['telephone'] = phone;
    if (email != null) schema['email'] = email;
    if (imageUrl != null) schema['image'] = imageUrl;

    if (latitude != null && longitude != null) {
      schema['geo'] = {
        '@type': 'GeoCoordinates',
        'latitude': latitude.toString(),
        'longitude': longitude.toString(),
      };
    }

    if (openingHours != null && openingHours.isNotEmpty) {
      schema['openingHoursSpecification'] = openingHours.map((hours) => {
        '@type': 'OpeningHoursSpecification',
        'opens': hours.split('-')[0],
        'closes': hours.split('-')[1],
      }).toList();
    }

    if (rating != null && reviewCount != null) {
      schema['aggregateRating'] = {
        '@type': 'AggregateRating',
        'ratingValue': rating.toString(),
        'reviewCount': reviewCount.toString(),
      };
    }

    return schema;
  }

  /// Generate Article schema (for blog posts/news)
  static Map<String, dynamic> generateArticleSchema({
    required String headline,
    required String articleBody,
    required DateTime datePublished,
    required String authorName,
    String? imageUrl,
    DateTime? dateModified,
    String? publisherName,
    String? publisherLogoUrl,
  }) {
    final schema = <String, dynamic>{
      '@context': 'https://schema.org',
      '@type': 'Article',
      'headline': headline,
      'articleBody': articleBody,
      'datePublished': datePublished.toIso8601String(),
      'author': {
        '@type': 'Person',
        'name': authorName,
      },
    };

    if (imageUrl != null) schema['image'] = imageUrl;

    if (dateModified != null) {
      schema['dateModified'] = dateModified.toIso8601String();
    }

    schema['publisher'] = {
      '@type': 'Organization',
      'name': publisherName ?? SeoConfig.organizationName,
      if (publisherLogoUrl != null)
        'logo': {
          '@type': 'ImageObject',
          'url': publisherLogoUrl,
        },
    };

    return schema;
  }

  /// Generate WebPage schema (generic page)
  static Map<String, dynamic> generateWebPageSchema({
    required String name,
    required String description,
    required String url,
    String? imageUrl,
    DateTime? datePublished,
    DateTime? dateModified,
  }) {
    final schema = <String, dynamic>{
      '@context': 'https://schema.org',
      '@type': 'WebPage',
      'name': name,
      'description': description,
      'url': url,
    };

    if (imageUrl != null) schema['image'] = imageUrl;
    if (datePublished != null) {
      schema['datePublished'] = datePublished.toIso8601String();
    }
    if (dateModified != null) {
      schema['dateModified'] = dateModified.toIso8601String();
    }

    return schema;
  }

  /// Generate Course schema (for training/educational content)
  static Map<String, dynamic> generateCourseSchema({
    required String name,
    required String description,
    required String providerName,
    String? imageUrl,
    double? price,
    String? currency,
  }) {
    final schema = <String, dynamic>{
      '@context': 'https://schema.org',
      '@type': 'Course',
      'name': name,
      'description': description,
      'provider': {
        '@type': 'Organization',
        'name': providerName,
      },
    };

    if (imageUrl != null) schema['image'] = imageUrl;

    if (price != null) {
      schema['offers'] = {
        '@type': 'Offer',
        'price': price.toString(),
        'priceCurrency': currency ?? 'USD',
      };
    }

    return schema;
  }

  /// Combine multiple schemas into @graph array
  static Map<String, dynamic> combineSchemas(
    List<Map<String, dynamic>> schemas,
  ) {
    return {
      '@context': 'https://schema.org',
      '@graph': schemas,
    };
  }

  /// Generate complete page schema with Organization + specific content
  static Map<String, dynamic> generatePageWithOrganization(
    Map<String, dynamic> contentSchema,
  ) {
    return combineSchemas([
      generateOrganizationSchema(),
      contentSchema,
    ]);
  }
}
