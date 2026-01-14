/// Site Configuration Model
///
/// Main configuration model that aggregates all site config sections.

import 'app_config.dart';
import 'company_info.dart';
import 'consent_config.dart';
import 'contact_info.dart';
import 'email_config.dart';
import 'landing_texts.dart';
import 'legal_texts.dart';
import 'seo_config.dart';
import 'social_media.dart';

/// Config Section enum for navigation
enum ConfigSection {
  contact,
  social,
  legal,
  company,
  seo,
  landing,
  email,
  app,
  consent,
}

/// Site Configuration Model
///
/// Contains all configurable content for the application.
/// This is the main model that aggregates all configuration sections.
class SiteConfig {
  SiteConfig({
    this.id,
    this.version,
    this.updatedAt,
    this.updatedBy,
    this.contactInfo,
    this.socialMedia,
    this.legalTexts,
    this.companyInfo,
    this.seoConfig,
    this.landingTexts,
    this.emailConfig,
    this.appConfig,
    this.consentConfig,
  });

  factory SiteConfig.fromJson(Map<String, dynamic> json) {
    return SiteConfig(
      id: json['id'],
      version: json['version'],
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : null,
      updatedBy: json['updatedBy'],
      contactInfo: json['contactInfo'] != null
          ? ContactInfo.fromJson(json['contactInfo'])
          : null,
      socialMedia: json['socialMedia'] != null
          ? SocialMedia.fromJson(json['socialMedia'])
          : null,
      legalTexts: json['legalTexts'] != null
          ? LegalTexts.fromJson(json['legalTexts'])
          : null,
      companyInfo: json['companyInfo'] != null
          ? CompanyInfo.fromJson(json['companyInfo'])
          : null,
      seoConfig: json['seoConfig'] != null
          ? SEOConfig.fromJson(json['seoConfig'])
          : null,
      landingTexts: json['landingTexts'] != null
          ? LandingTexts.fromJson(json['landingTexts'])
          : null,
      emailConfig: json['emailConfig'] != null
          ? EmailConfig.fromJson(json['emailConfig'])
          : null,
      appConfig: json['appConfig'] != null
          ? AppConfig.fromJson(json['appConfig'])
          : null,
      consentConfig: json['consentConfig'] != null
          ? ConsentConfig.fromJson(json['consentConfig'])
          : null,
    );
  }

  // Factory for empty config
  factory SiteConfig.empty() {
    return SiteConfig(
      contactInfo: ContactInfo.empty(),
      socialMedia: SocialMedia.empty(),
      legalTexts: LegalTexts.empty(),
      companyInfo: CompanyInfo.empty(),
      seoConfig: SEOConfig.empty(),
      landingTexts: LandingTexts.empty(),
      emailConfig: EmailConfig.empty(),
      appConfig: AppConfig.empty(),
      consentConfig: ConsentConfig.empty(),
    );
  }

  final String? id;
  final int? version;
  final DateTime? updatedAt;
  final String? updatedBy;
  final ContactInfo? contactInfo;
  final SocialMedia? socialMedia;
  final LegalTexts? legalTexts;
  final CompanyInfo? companyInfo;
  final SEOConfig? seoConfig;
  final LandingTexts? landingTexts;
  final EmailConfig? emailConfig;
  final AppConfig? appConfig;
  final ConsentConfig? consentConfig;

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (version != null) 'version': version,
      if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
      if (updatedBy != null) 'updatedBy': updatedBy,
      if (contactInfo != null) 'contactInfo': contactInfo!.toJson(),
      if (socialMedia != null) 'socialMedia': socialMedia!.toJson(),
      if (legalTexts != null) 'legalTexts': legalTexts!.toJson(),
      if (companyInfo != null) 'companyInfo': companyInfo!.toJson(),
      if (seoConfig != null) 'seoConfig': seoConfig!.toJson(),
      if (landingTexts != null) 'landingTexts': landingTexts!.toJson(),
      if (emailConfig != null) 'emailConfig': emailConfig!.toJson(),
      if (appConfig != null) 'appConfig': appConfig!.toJson(),
      if (consentConfig != null) 'consentConfig': consentConfig!.toJson(),
    };
  }

  SiteConfig copyWith({
    String? id,
    int? version,
    DateTime? updatedAt,
    String? updatedBy,
    ContactInfo? contactInfo,
    SocialMedia? socialMedia,
    LegalTexts? legalTexts,
    CompanyInfo? companyInfo,
    SEOConfig? seoConfig,
    LandingTexts? landingTexts,
    EmailConfig? emailConfig,
    AppConfig? appConfig,
    ConsentConfig? consentConfig,
  }) {
    return SiteConfig(
      id: id ?? this.id,
      version: version ?? this.version,
      updatedAt: updatedAt ?? this.updatedAt,
      updatedBy: updatedBy ?? this.updatedBy,
      contactInfo: contactInfo ?? this.contactInfo,
      socialMedia: socialMedia ?? this.socialMedia,
      legalTexts: legalTexts ?? this.legalTexts,
      companyInfo: companyInfo ?? this.companyInfo,
      seoConfig: seoConfig ?? this.seoConfig,
      landingTexts: landingTexts ?? this.landingTexts,
      emailConfig: emailConfig ?? this.emailConfig,
      appConfig: appConfig ?? this.appConfig,
      consentConfig: consentConfig ?? this.consentConfig,
    );
  }

  // Convenience getters for safe access to sections
  ContactInfo get safeContactInfo => contactInfo ?? ContactInfo.empty();
  SocialMedia get safeSocialMedia => socialMedia ?? SocialMedia.empty();
  CompanyInfo get safeCompanyInfo => companyInfo ?? CompanyInfo.empty();
  LegalTexts get safeLegalTexts => legalTexts ?? LegalTexts.empty();
  SEOConfig get safeSeoConfig => seoConfig ?? SEOConfig.empty();
  LandingTexts get safeLandingTexts => landingTexts ?? LandingTexts.empty();
  EmailConfig get safeEmailConfig => emailConfig ?? EmailConfig.empty();
  AppConfig get safeAppConfig => appConfig ?? AppConfig.empty();
  ConsentConfig get safeConsentConfig => consentConfig ?? ConsentConfig.empty();
}
