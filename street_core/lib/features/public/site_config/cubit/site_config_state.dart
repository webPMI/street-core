import 'package:equatable/equatable.dart';
import '../../../../data/models/site_config/site_config_models.dart';
import '../repository/site_config_repository.dart';

/// Site Config State
///
/// Manages loading state for each section of site config independently.
/// This allows lazy loading - only load what you need.
class SiteConfigState extends Equatable {
  const SiteConfigState({
    this.basicConfig,
    this.contactInfo,
    this.legalTexts,
    this.landingTexts,
    this.consentConfig,
    this.seoConfig,
    this.appConfig,
    this.isLoadingBasic = false,
    this.isLoadingContact = false,
    this.isLoadingLegal = false,
    this.isLoadingLanding = false,
    this.isLoadingConsent = false,
    this.isLoadingSeo = false,
    this.isLoadingApp = false,
    this.errorBasic,
    this.errorContact,
    this.errorLegal,
    this.errorLanding,
    this.errorConsent,
    this.errorSeo,
    this.errorApp,
  });

  // Loaded data
  final BasicConfig? basicConfig;
  final ContactInfo? contactInfo;
  final LegalTexts? legalTexts;
  final LandingTexts? landingTexts;
  final ConsentConfig? consentConfig;
  final SEOConfig? seoConfig;
  final AppConfig? appConfig;

  // Loading states
  final bool isLoadingBasic;
  final bool isLoadingContact;
  final bool isLoadingLegal;
  final bool isLoadingLanding;
  final bool isLoadingConsent;
  final bool isLoadingSeo;
  final bool isLoadingApp;

  // Error states
  final String? errorBasic;
  final String? errorContact;
  final String? errorLegal;
  final String? errorLanding;
  final String? errorConsent;
  final String? errorSeo;
  final String? errorApp;

  @override
  List<Object?> get props => [
        basicConfig,
        contactInfo,
        legalTexts,
        landingTexts,
        consentConfig,
        seoConfig,
        appConfig,
        isLoadingBasic,
        isLoadingContact,
        isLoadingLegal,
        isLoadingLanding,
        isLoadingConsent,
        isLoadingSeo,
        isLoadingApp,
        errorBasic,
        errorContact,
        errorLegal,
        errorLanding,
        errorConsent,
        errorSeo,
        errorApp,
      ];

  SiteConfigState copyWith({
    BasicConfig? basicConfig,
    ContactInfo? contactInfo,
    LegalTexts? legalTexts,
    LandingTexts? landingTexts,
    ConsentConfig? consentConfig,
    SEOConfig? seoConfig,
    AppConfig? appConfig,
    bool? isLoadingBasic,
    bool? isLoadingContact,
    bool? isLoadingLegal,
    bool? isLoadingLanding,
    bool? isLoadingConsent,
    bool? isLoadingSeo,
    bool? isLoadingApp,
    String? errorBasic,
    String? errorContact,
    String? errorLegal,
    String? errorLanding,
    String? errorConsent,
    String? errorSeo,
    String? errorApp,
  }) {
    return SiteConfigState(
      basicConfig: basicConfig ?? this.basicConfig,
      contactInfo: contactInfo ?? this.contactInfo,
      legalTexts: legalTexts ?? this.legalTexts,
      landingTexts: landingTexts ?? this.landingTexts,
      consentConfig: consentConfig ?? this.consentConfig,
      seoConfig: seoConfig ?? this.seoConfig,
      appConfig: appConfig ?? this.appConfig,
      isLoadingBasic: isLoadingBasic ?? this.isLoadingBasic,
      isLoadingContact: isLoadingContact ?? this.isLoadingContact,
      isLoadingLegal: isLoadingLegal ?? this.isLoadingLegal,
      isLoadingLanding: isLoadingLanding ?? this.isLoadingLanding,
      isLoadingConsent: isLoadingConsent ?? this.isLoadingConsent,
      isLoadingSeo: isLoadingSeo ?? this.isLoadingSeo,
      isLoadingApp: isLoadingApp ?? this.isLoadingApp,
      errorBasic: errorBasic,
      errorContact: errorContact,
      errorLegal: errorLegal,
      errorLanding: errorLanding,
      errorConsent: errorConsent,
      errorSeo: errorSeo,
      errorApp: errorApp,
    );
  }

  // Convenience getters with safe defaults
  BasicConfig get safeBasicConfig => basicConfig ?? BasicConfig.empty();
  ContactInfo get safeContactInfo => contactInfo ?? ContactInfo.empty();
  LegalTexts get safeLegalTexts => legalTexts ?? LegalTexts.empty();
  LandingTexts get safeLandingTexts => landingTexts ?? LandingTexts.empty();
  ConsentConfig get safeConsentConfig => consentConfig ?? ConsentConfig.empty();
  SEOConfig get safeSeoConfig => seoConfig ?? SEOConfig.empty();
  AppConfig get safeAppConfig => appConfig ?? AppConfig.empty();

  // Check if sections are loaded
  bool get hasBasicConfig => basicConfig != null;
  bool get hasContactInfo => contactInfo != null;
  bool get hasLegalTexts => legalTexts != null;
  bool get hasLandingTexts => landingTexts != null;
  bool get hasConsentConfig => consentConfig != null;
  bool get hasSeoConfig => seoConfig != null;
  bool get hasAppConfig => appConfig != null;
}
