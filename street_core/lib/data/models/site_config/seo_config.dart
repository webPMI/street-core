/// SEO Configuration Model
///
/// Contains SEO metadata and analytics configuration.
class SEOConfig {
  SEOConfig({
    this.defaultTitle,
    this.defaultDescription,
    this.defaultKeywords,
    this.ogImage,
    this.twitterHandle,
    this.googleAnalyticsId,
    this.facebookPixelId,
    this.canonicalUrl,
  });

  factory SEOConfig.fromJson(Map<String, dynamic> json) {
    return SEOConfig(
      defaultTitle: json['defaultTitle'],
      defaultDescription: json['defaultDescription'],
      defaultKeywords: json['defaultKeywords'] != null
          ? List<String>.from(json['defaultKeywords'])
          : null,
      ogImage: json['ogImage'],
      twitterHandle: json['twitterHandle'],
      googleAnalyticsId: json['googleAnalyticsId'],
      facebookPixelId: json['facebookPixelId'],
      canonicalUrl: json['canonicalUrl'],
    );
  }

  factory SEOConfig.empty() => SEOConfig();

  final String? defaultTitle;
  final String? defaultDescription;
  final List<String>? defaultKeywords;
  final String? ogImage;
  final String? twitterHandle;
  final String? googleAnalyticsId;
  final String? facebookPixelId;
  final String? canonicalUrl;

  Map<String, dynamic> toJson() => {
        if (defaultTitle != null) 'defaultTitle': defaultTitle,
        if (defaultDescription != null) 'defaultDescription': defaultDescription,
        if (defaultKeywords != null) 'defaultKeywords': defaultKeywords,
        if (ogImage != null) 'ogImage': ogImage,
        if (twitterHandle != null) 'twitterHandle': twitterHandle,
        if (googleAnalyticsId != null) 'googleAnalyticsId': googleAnalyticsId,
        if (facebookPixelId != null) 'facebookPixelId': facebookPixelId,
        if (canonicalUrl != null) 'canonicalUrl': canonicalUrl,
      };
}
