/// Legal Texts Models
///
/// Contains all legal document models with multi-region support.

/// Supported legal regions for the application.
/// Each region has specific legal requirements and regulations.
enum LegalRegion {
  /// European Union - GDPR/RGPD compliance
  eu,

  /// Latin America - Various local regulations (LFPDPPP Mexico, etc.)
  latam,

  /// United States - CCPA, state-specific laws
  usa,
}

/// Extension methods for LegalRegion enum
extension LegalRegionExtension on LegalRegion {
  String get displayName {
    switch (this) {
      case LegalRegion.eu:
        return 'Europa (UE)';
      case LegalRegion.latam:
        return 'Latinoamerica';
      case LegalRegion.usa:
        return 'Estados Unidos';
    }
  }

  String get code {
    switch (this) {
      case LegalRegion.eu:
        return 'eu';
      case LegalRegion.latam:
        return 'latam';
      case LegalRegion.usa:
        return 'usa';
    }
  }

  /// Default minimum consent age for this region
  int get defaultMinConsentAge {
    switch (this) {
      case LegalRegion.eu:
        return 16; // GDPR default (can be 13-16 by member state)
      case LegalRegion.latam:
        return 18; // Most LATAM countries
      case LegalRegion.usa:
        return 13; // COPPA
    }
  }

  /// Primary regulation name
  String get primaryRegulation {
    switch (this) {
      case LegalRegion.eu:
        return 'GDPR/RGPD';
      case LegalRegion.latam:
        return 'LFPDPPP / Local';
      case LegalRegion.usa:
        return 'CCPA / State Laws';
    }
  }

  static LegalRegion? fromCode(String? code) {
    if (code == null) return null;
    switch (code.toLowerCase()) {
      case 'eu':
        return LegalRegion.eu;
      case 'latam':
        return LegalRegion.latam;
      case 'usa':
        return LegalRegion.usa;
      default:
        return null;
    }
  }
}

/// Regional legal texts with jurisdiction-specific content.
/// Each region can have different legal requirements.
class RegionalLegalTexts {
  RegionalLegalTexts({
    this.privacyPolicy,
    this.termsConditions,
    this.cookiesPolicy,
    this.refundPolicy,
    this.dataProtection,
    this.legalNotice,
    this.localAuthority,
    this.localContact,
    this.minConsentAge,
    this.additionalRights,
    this.effectiveDate,
    this.languageCode,
  });

  factory RegionalLegalTexts.fromJson(Map<String, dynamic> json) {
    return RegionalLegalTexts(
      privacyPolicy: json['privacyPolicy'],
      termsConditions: json['termsConditions'],
      cookiesPolicy: json['cookiesPolicy'],
      refundPolicy: json['refundPolicy'],
      dataProtection: json['dataProtection'],
      legalNotice: json['legalNotice'],
      localAuthority: json['localAuthority'],
      localContact: json['localContact'],
      minConsentAge: json['minConsentAge'],
      additionalRights: json['additionalRights'],
      effectiveDate: json['effectiveDate'] != null
          ? DateTime.tryParse(json['effectiveDate'])
          : null,
      languageCode: json['languageCode'],
    );
  }

  factory RegionalLegalTexts.empty() => RegionalLegalTexts();

  /// Privacy policy content (GDPR Art. 13-14 / CCPA / LFPDPPP)
  final String? privacyPolicy;

  /// Terms and conditions / Terms of service
  final String? termsConditions;

  /// Cookie policy (required for EU, recommended elsewhere)
  final String? cookiesPolicy;

  /// Refund and cancellation policy
  final String? refundPolicy;

  /// Data protection policy / rights
  final String? dataProtection;

  /// Legal notice / Imprint (required in EU)
  final String? legalNotice;

  /// Local supervisory authority contact
  final String? localAuthority;

  /// Local DPO/contact for data requests
  final String? localContact;

  /// Minimum age for consent in this region
  final int? minConsentAge;

  /// Additional rights text specific to region
  final String? additionalRights;

  /// Effective date for this region's policies
  final DateTime? effectiveDate;

  /// Language code for this region's texts (e.g., 'es', 'en', 'pt')
  final String? languageCode;

  // Convenience getters
  String get safePrivacyPolicy => privacyPolicy ?? '';
  String get safeTermsConditions => termsConditions ?? '';
  String get safeCookiesPolicy => cookiesPolicy ?? '';
  String get safeRefundPolicy => refundPolicy ?? '';
  String get safeDataProtection => dataProtection ?? '';
  String get safeLegalNotice => legalNotice ?? '';
  String get safeLocalAuthority => localAuthority ?? '';
  String get safeLocalContact => localContact ?? '';
  String get safeAdditionalRights => additionalRights ?? '';

  Map<String, dynamic> toJson() => {
        if (privacyPolicy != null) 'privacyPolicy': privacyPolicy,
        if (termsConditions != null) 'termsConditions': termsConditions,
        if (cookiesPolicy != null) 'cookiesPolicy': cookiesPolicy,
        if (refundPolicy != null) 'refundPolicy': refundPolicy,
        if (dataProtection != null) 'dataProtection': dataProtection,
        if (legalNotice != null) 'legalNotice': legalNotice,
        if (localAuthority != null) 'localAuthority': localAuthority,
        if (localContact != null) 'localContact': localContact,
        if (minConsentAge != null) 'minConsentAge': minConsentAge,
        if (additionalRights != null) 'additionalRights': additionalRights,
        if (effectiveDate != null)
          'effectiveDate': effectiveDate!.toIso8601String(),
        if (languageCode != null) 'languageCode': languageCode,
      };

  RegionalLegalTexts copyWith({
    String? privacyPolicy,
    String? termsConditions,
    String? cookiesPolicy,
    String? refundPolicy,
    String? dataProtection,
    String? legalNotice,
    String? localAuthority,
    String? localContact,
    int? minConsentAge,
    String? additionalRights,
    DateTime? effectiveDate,
    String? languageCode,
  }) {
    return RegionalLegalTexts(
      privacyPolicy: privacyPolicy ?? this.privacyPolicy,
      termsConditions: termsConditions ?? this.termsConditions,
      cookiesPolicy: cookiesPolicy ?? this.cookiesPolicy,
      refundPolicy: refundPolicy ?? this.refundPolicy,
      dataProtection: dataProtection ?? this.dataProtection,
      legalNotice: legalNotice ?? this.legalNotice,
      localAuthority: localAuthority ?? this.localAuthority,
      localContact: localContact ?? this.localContact,
      minConsentAge: minConsentAge ?? this.minConsentAge,
      additionalRights: additionalRights ?? this.additionalRights,
      effectiveDate: effectiveDate ?? this.effectiveDate,
      languageCode: languageCode ?? this.languageCode,
    );
  }

  /// Check if this region has meaningful content
  bool get hasContent =>
      privacyPolicy != null ||
      termsConditions != null ||
      cookiesPolicy != null ||
      refundPolicy != null;
}

/// Legal Texts with optional multi-region support.
///
/// This class maintains backward compatibility with the original single-region
/// structure while adding optional multi-region support for EU, LATAM, and USA.
///
/// Usage:
/// - For single region apps: Use the direct fields (privacyPolicy, termsConditions, etc.)
/// - For multi-region apps: Use the regional fields (eu, latam, usa)
/// - The getEffectiveTexts() method resolves which texts to show based on user region
class LegalTexts {
  // ============================================================
  // CONSTRUCTOR
  // ============================================================

  LegalTexts({
    // Common
    this.title,
    this.description,
    this.footer,
    // Direct fields (single region)
    this.privacyPolicy,
    this.termsConditions,
    this.legalNotice,
    this.cookiesPolicy,
    this.refundPolicy,
    this.dataProtection,
    // Multi-region
    this.eu,
    this.latam,
    this.usa,
    this.defaultRegion,
  });

  // ============================================================
  // SERIALIZATION
  // ============================================================

  factory LegalTexts.fromJson(Map<String, dynamic> json) {
    return LegalTexts(
      // Common
      title: json['title'],
      description: json['description'],
      footer: json['footer'],
      // Direct fields
      privacyPolicy: json['privacyPolicy'],
      termsConditions: json['termsConditions'],
      legalNotice: json['legalNotice'],
      cookiesPolicy: json['cookiesPolicy'],
      refundPolicy: json['refundPolicy'],
      dataProtection: json['dataProtection'],
      // Multi-region
      eu: json['eu'] != null ? RegionalLegalTexts.fromJson(json['eu']) : null,
      latam: json['latam'] != null
          ? RegionalLegalTexts.fromJson(json['latam'])
          : null,
      usa: json['usa'] != null
          ? RegionalLegalTexts.fromJson(json['usa'])
          : null,
      defaultRegion: json['defaultRegion'],
    );
  }

  factory LegalTexts.empty() => LegalTexts();

  // ============================================================
  // COMMON FIELDS (used in both single and multi-region modes)
  // ============================================================

  /// Company/site title for legal documents
  final String? title;

  /// Brief description of the company/service
  final String? description;

  /// Common footer text (shown on all regions)
  final String? footer;

  // ============================================================
  // DIRECT LEGAL TEXT FIELDS (original structure - single region)
  // ============================================================

  /// Privacy policy content
  final String? privacyPolicy;

  /// Terms and conditions / Terms of service
  final String? termsConditions;

  /// Legal notice / Imprint
  final String? legalNotice;

  /// Cookie policy
  final String? cookiesPolicy;

  /// Refund and cancellation policy
  final String? refundPolicy;

  /// Data protection policy / rights
  final String? dataProtection;

  // ============================================================
  // MULTI-REGION FIELDS (optional - for international apps)
  // ============================================================

  /// European Union legal texts (GDPR/RGPD compliant)
  final RegionalLegalTexts? eu;

  /// Latin America legal texts
  final RegionalLegalTexts? latam;

  /// United States legal texts (CCPA compliant)
  final RegionalLegalTexts? usa;

  /// Default region to use when user region cannot be determined
  final String? defaultRegion;

  // ============================================================
  // CONVENIENCE GETTERS
  // ============================================================

  String get safeTitle => title ?? '';
  String get safeDescription => description ?? '';
  String get safeFooter => footer ?? '';
  String get safePrivacyPolicy => privacyPolicy ?? '';
  String get safeTermsConditions => termsConditions ?? '';
  String get safeLegalNotice => legalNotice ?? '';
  String get safeCookiesPolicy => cookiesPolicy ?? '';
  String get safeRefundPolicy => refundPolicy ?? '';
  String get safeDataProtection => dataProtection ?? '';

  /// Check if multi-region mode is enabled
  bool get isMultiRegion => eu != null || latam != null || usa != null;

  /// Get default region enum
  LegalRegion get defaultRegionEnum =>
      LegalRegionExtension.fromCode(defaultRegion) ?? LegalRegion.eu;

  // ============================================================
  // MULTI-REGION METHODS
  // ============================================================

  /// Get regional texts by region enum
  RegionalLegalTexts? getRegion(LegalRegion region) {
    switch (region) {
      case LegalRegion.eu:
        return eu;
      case LegalRegion.latam:
        return latam;
      case LegalRegion.usa:
        return usa;
    }
  }

  /// Get regional texts by region code string
  RegionalLegalTexts? getRegionByCode(String code) {
    final region = LegalRegionExtension.fromCode(code);
    return region != null ? getRegion(region) : null;
  }

  /// Get the effective texts for a given region.
  /// If multi-region is enabled, returns regional texts.
  /// Otherwise, returns the direct fields wrapped in RegionalLegalTexts.
  RegionalLegalTexts getEffectiveTexts(LegalRegion? userRegion) {
    // If multi-region mode is enabled
    if (isMultiRegion) {
      if (userRegion != null) {
        final regional = getRegion(userRegion);
        if (regional != null && regional.hasContent) {
          return regional;
        }
      }
      // Fallback to default region
      final defaultRegional = getRegion(defaultRegionEnum);
      if (defaultRegional != null && defaultRegional.hasContent) {
        return defaultRegional;
      }
    }

    // Single region mode - return direct fields
    return RegionalLegalTexts(
      privacyPolicy: privacyPolicy,
      termsConditions: termsConditions,
      legalNotice: legalNotice,
      cookiesPolicy: cookiesPolicy,
      refundPolicy: refundPolicy,
      dataProtection: dataProtection,
    );
  }

  Map<String, dynamic> toJson() => {
        // Common
        if (title != null) 'title': title,
        if (description != null) 'description': description,
        if (footer != null) 'footer': footer,
        // Direct fields
        if (privacyPolicy != null) 'privacyPolicy': privacyPolicy,
        if (termsConditions != null) 'termsConditions': termsConditions,
        if (legalNotice != null) 'legalNotice': legalNotice,
        if (cookiesPolicy != null) 'cookiesPolicy': cookiesPolicy,
        if (refundPolicy != null) 'refundPolicy': refundPolicy,
        if (dataProtection != null) 'dataProtection': dataProtection,
        // Multi-region
        if (eu != null) 'eu': eu!.toJson(),
        if (latam != null) 'latam': latam!.toJson(),
        if (usa != null) 'usa': usa!.toJson(),
        if (defaultRegion != null) 'defaultRegion': defaultRegion,
      };

  // ============================================================
  // COPY WITH
  // ============================================================

  LegalTexts copyWith({
    String? title,
    String? description,
    String? footer,
    String? privacyPolicy,
    String? termsConditions,
    String? legalNotice,
    String? cookiesPolicy,
    String? refundPolicy,
    String? dataProtection,
    RegionalLegalTexts? eu,
    RegionalLegalTexts? latam,
    RegionalLegalTexts? usa,
    String? defaultRegion,
  }) {
    return LegalTexts(
      title: title ?? this.title,
      description: description ?? this.description,
      footer: footer ?? this.footer,
      privacyPolicy: privacyPolicy ?? this.privacyPolicy,
      termsConditions: termsConditions ?? this.termsConditions,
      legalNotice: legalNotice ?? this.legalNotice,
      cookiesPolicy: cookiesPolicy ?? this.cookiesPolicy,
      refundPolicy: refundPolicy ?? this.refundPolicy,
      dataProtection: dataProtection ?? this.dataProtection,
      eu: eu ?? this.eu,
      latam: latam ?? this.latam,
      usa: usa ?? this.usa,
      defaultRegion: defaultRegion ?? this.defaultRegion,
    );
  }

  /// Update a specific region's texts
  LegalTexts updateRegion(LegalRegion region, RegionalLegalTexts texts) {
    switch (region) {
      case LegalRegion.eu:
        return copyWith(eu: texts);
      case LegalRegion.latam:
        return copyWith(latam: texts);
      case LegalRegion.usa:
        return copyWith(usa: texts);
    }
  }
}
