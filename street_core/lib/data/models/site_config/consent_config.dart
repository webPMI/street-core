/// Consent Configuration Model
///
/// Contains consent banner texts for GDPR/privacy compliance.
class ConsentConfig {
  const ConsentConfig({
    this.cookieConsentText,
    this.analyticsConsentText,
    this.locationConsentText,
    this.marketingConsentText,
  });

  factory ConsentConfig.fromJson(Map<String, dynamic> json) {
    return ConsentConfig(
      cookieConsentText: json['cookieConsentText'],
      analyticsConsentText: json['analyticsConsentText'],
      locationConsentText: json['locationConsentText'],
      marketingConsentText: json['marketingConsentText'],
    );
  }

  factory ConsentConfig.empty() => const ConsentConfig();

  final String? cookieConsentText;
  final String? analyticsConsentText;
  final String? locationConsentText;
  final String? marketingConsentText;

  // Convenience getters
  String get safeCookieConsentText => cookieConsentText ?? '';
  String get safeAnalyticsConsentText => analyticsConsentText ?? '';
  String get safeLocationConsentText => locationConsentText ?? '';
  String get safeMarketingConsentText => marketingConsentText ?? '';

  Map<String, dynamic> toJson() => {
        if (cookieConsentText != null) 'cookieConsentText': cookieConsentText,
        if (analyticsConsentText != null)
          'analyticsConsentText': analyticsConsentText,
        if (locationConsentText != null) 'locationConsentText': locationConsentText,
        if (marketingConsentText != null)
          'marketingConsentText': marketingConsentText,
      };
}
