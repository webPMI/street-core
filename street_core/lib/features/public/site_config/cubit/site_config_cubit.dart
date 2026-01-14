import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../data/models/site_config/site_config_models.dart';
import '../repository/site_config_repository.dart';
import 'site_config_state.dart';

/// Unified Site Config Cubit
///
/// Centralized state management for all site configuration sections.
/// Supports lazy loading - only loads sections when requested.
///
/// **Replaces:**
/// - PublicSiteConfigCubit
/// - LegalConfigCubit
/// - BasicConfigCubit
/// - ContactConfigCubit
///
/// **Usage:**
/// ```dart
/// // Load specific sections as needed
/// await context.read<SiteConfigCubit>().loadBasicConfig();
/// await context.read<SiteConfigCubit>().loadLegalTexts();
///
/// // Access data
/// final basicConfig = context.read<SiteConfigCubit>().state.safeBasicConfig;
/// final privacy = context.read<SiteConfigCubit>().privacyPolicy;
///
/// // Listen to changes
/// BlocBuilder<SiteConfigCubit, SiteConfigState>(
///   builder: (context, state) {
///     if (state.isLoadingBasic) return CircularProgressIndicator();
///     return Text(state.safeBasicConfig.companyInfo.safeName);
///   },
/// )
/// ```
class SiteConfigCubit extends Cubit<SiteConfigState> {
  SiteConfigCubit(this._repository) : super(const SiteConfigState());
  final SiteConfigRepository _repository;

  // ===========================================================================
  // LOAD METHODS (Lazy Loading)
  // ===========================================================================

  /// Load basic config (company + social) for header/footer
  /// Skips if already loaded. Use refresh to force reload.
  Future<void> loadBasicConfig() async {
    if (state.hasBasicConfig || state.isLoadingBasic) return;

    emit(state.copyWith(isLoadingBasic: true, errorBasic: null));

    try {
      final basicConfig = await _repository.getBasicConfig();
      emit(state.copyWith(
        basicConfig: basicConfig,
        isLoadingBasic: false,
      ));
    } catch (e) {
      emit(state.copyWith(
        isLoadingBasic: false,
        errorBasic: 'error_loading_basic_config',
      ));
    }
  }

  /// Load contact information
  /// Skips if already loaded. Use refresh to force reload.
  Future<void> loadContactInfo() async {
    if (state.hasContactInfo || state.isLoadingContact) return;

    emit(state.copyWith(isLoadingContact: true, errorContact: null));

    try {
      final contactInfo = await _repository.getContactInfo();
      emit(state.copyWith(
        contactInfo: contactInfo,
        isLoadingContact: false,
      ));
    } catch (e) {
      emit(state.copyWith(
        isLoadingContact: false,
        errorContact: 'error_loading_contact',
      ));
    }
  }

  /// Load legal texts (privacy, terms, cookies, etc.)
  /// Skips if already loaded. Use refresh to force reload.
  Future<void> loadLegalTexts() async {
    if (state.hasLegalTexts || state.isLoadingLegal) return;

    emit(state.copyWith(isLoadingLegal: true, errorLegal: null));

    try {
      final legalTexts = await _repository.getLegalTexts();
      emit(state.copyWith(
        legalTexts: legalTexts,
        isLoadingLegal: false,
      ));
    } catch (e) {
      emit(state.copyWith(
        isLoadingLegal: false,
        errorLegal: 'error_loading_legal',
      ));
    }
  }

  /// Load landing page texts (testimonials, features, CTA)
  /// Skips if already loaded. Use refresh to force reload.
  Future<void> loadLandingTexts() async {
    if (state.hasLandingTexts || state.isLoadingLanding) return;

    emit(state.copyWith(isLoadingLanding: true, errorLanding: null));

    try {
      final landingTexts = await _repository.getLandingTexts();
      emit(state.copyWith(
        landingTexts: landingTexts,
        isLoadingLanding: false,
      ));
    } catch (e) {
      emit(state.copyWith(
        isLoadingLanding: false,
        errorLanding: 'error_loading_landing',
      ));
    }
  }

  /// Load consent configuration (cookie banner, GDPR)
  /// Skips if already loaded. Use refresh to force reload.
  Future<void> loadConsentConfig() async {
    if (state.hasConsentConfig || state.isLoadingConsent) return;

    emit(state.copyWith(isLoadingConsent: true, errorConsent: null));

    try {
      final consentConfig = await _repository.getConsentConfig();
      emit(state.copyWith(
        consentConfig: consentConfig,
        isLoadingConsent: false,
      ));
    } catch (e) {
      emit(state.copyWith(
        isLoadingConsent: false,
        errorConsent: 'error_loading_consent',
      ));
    }
  }

  /// Load SEO configuration
  /// Skips if already loaded. Use refresh to force reload.
  Future<void> loadSeoConfig() async {
    if (state.hasSeoConfig || state.isLoadingSeo) return;

    emit(state.copyWith(isLoadingSeo: true, errorSeo: null));

    try {
      final seoConfig = await _repository.getSeoConfig();
      emit(state.copyWith(
        seoConfig: seoConfig,
        isLoadingSeo: false,
      ));
    } catch (e) {
      emit(state.copyWith(
        isLoadingSeo: false,
        errorSeo: 'error_loading_seo',
      ));
    }
  }

  /// Load app configuration (maintenance mode, versions)
  /// Skips if already loaded. Use refresh to force reload.
  Future<void> loadAppConfig() async {
    if (state.hasAppConfig || state.isLoadingApp) return;

    emit(state.copyWith(isLoadingApp: true, errorApp: null));

    try {
      final appConfig = await _repository.getAppConfig();
      emit(state.copyWith(
        appConfig: appConfig,
        isLoadingApp: false,
      ));
    } catch (e) {
      emit(state.copyWith(
        isLoadingApp: false,
        errorApp: 'error_loading_app',
      ));
    }
  }

  // ===========================================================================
  // REFRESH METHODS (Force Reload)
  // ===========================================================================

  /// Force refresh basic config
  Future<void> refreshBasicConfig() async {
    _repository.invalidateSection(ConfigSection.company);
    _repository.invalidateSection(ConfigSection.social);
    emit(state.copyWith(basicConfig: null));
    await loadBasicConfig();
  }

  /// Force refresh contact info
  Future<void> refreshContactInfo() async {
    _repository.invalidateSection(ConfigSection.contact);
    emit(state.copyWith(contactInfo: null));
    await loadContactInfo();
  }

  /// Force refresh legal texts
  Future<void> refreshLegalTexts() async {
    _repository.invalidateSection(ConfigSection.legal);
    emit(state.copyWith(legalTexts: null));
    await loadLegalTexts();
  }

  /// Force refresh landing texts
  Future<void> refreshLandingTexts() async {
    _repository.invalidateSection(ConfigSection.landing);
    emit(state.copyWith(landingTexts: null));
    await loadLandingTexts();
  }

  /// Force refresh consent config
  Future<void> refreshConsentConfig() async {
    _repository.invalidateSection(ConfigSection.consent);
    emit(state.copyWith(consentConfig: null));
    await loadConsentConfig();
  }

  /// Force refresh SEO config
  Future<void> refreshSeoConfig() async {
    _repository.invalidateSection(ConfigSection.seo);
    emit(state.copyWith(seoConfig: null));
    await loadSeoConfig();
  }

  /// Force refresh app config
  Future<void> refreshAppConfig() async {
    _repository.invalidateSection(ConfigSection.app);
    emit(state.copyWith(appConfig: null));
    await loadAppConfig();
  }

  /// Refresh all loaded sections
  Future<void> refreshAll() async {
    _repository.invalidateAll();
    emit(const SiteConfigState());

    // Reload all previously loaded sections
    await Future.wait([
      if (state.hasBasicConfig) loadBasicConfig(),
      if (state.hasContactInfo) loadContactInfo(),
      if (state.hasLegalTexts) loadLegalTexts(),
      if (state.hasLandingTexts) loadLandingTexts(),
      if (state.hasConsentConfig) loadConsentConfig(),
      if (state.hasSeoConfig) loadSeoConfig(),
      if (state.hasAppConfig) loadAppConfig(),
    ]);
  }

  // ===========================================================================
  // CONVENIENCE GETTERS (Backward Compatibility)
  // ===========================================================================

  // Basic Config
  CompanyInfo get companyInfo => state.safeBasicConfig.companyInfo;
  SocialMedia get socialMedia => state.safeBasicConfig.socialMedia;

  // Contact Info
  ContactInfo get contactInfo => state.safeContactInfo;

  // Legal Texts - Individual Documents
  String get privacyPolicy => state.safeLegalTexts.safePrivacyPolicy;
  String get termsConditions => state.safeLegalTexts.safeTermsConditions;
  String get cookiesPolicy => state.safeLegalTexts.safeCookiesPolicy;
  String get legalNotice => state.safeLegalTexts.safeLegalNotice;
  String get refundPolicy => state.safeLegalTexts.safeRefundPolicy;
  String get dataProtection => state.safeLegalTexts.safeDataProtection;

  // Landing Texts
  List<Testimonial>? get testimonials => state.landingTexts?.testimonials;
  List<FeatureItem>? get features => state.landingTexts?.features;

  // Multi-region legal support
  bool get isMultiRegion => state.legalTexts?.isMultiRegion ?? false;
  RegionalLegalTexts? getRegionalTexts(LegalRegion region) {
    return state.legalTexts?.getRegion(region);
  }

  RegionalLegalTexts getEffectiveTexts(LegalRegion? userRegion) {
    final texts = state.legalTexts;
    if (texts == null) return RegionalLegalTexts.empty();
    return texts.getEffectiveTexts(userRegion);
  }
}
