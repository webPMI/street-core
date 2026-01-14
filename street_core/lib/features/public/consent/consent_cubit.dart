import '../site_config/site_config.dart';
import '../repositories/consent_repository.dart';
import 'consent_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Cubit for managing user consent (GDPR/Cookies)
///
/// Handles the state of user consent and persists it using ConsentRepository.
/// Also fetches granular consent texts from SiteConfigRepository.
class ConsentCubit extends Cubit<ConsentState> {
  ConsentCubit(this._repository, this._siteConfigRepo)
    : super(const ConsentState()) {
    checkConsent();
  }
  final ConsentRepository _repository;
  final SiteConfigRepository _siteConfigRepo;

  /// Check initial consent status and load config
  Future<void> checkConsent() async {
    // Load config from backend (texts)
    final config = await _siteConfigRepo.getConsentConfig();

    // Load local preferences
    final decision = await _repository.getConsentStatus();
    final granular = await _repository.getGranularConsent();

    if (decision == null) {
      // No decision yet -> Unknown (Show banner)
      emit(
        state.copyWith(
          status: ConsentStatus.unknown,
          isLoading: false,
          config: config,
          cookiesAccepted: granular['cookies'],
          analyticsAccepted: granular['analytics'],
          locationAccepted: granular['location'],
          marketingAccepted: granular['marketing'],
        ),
      );
    } else {
      // Decided -> Set status and load saved values
      emit(
        state.copyWith(
          status: decision ? ConsentStatus.accepted : ConsentStatus.rejected,
          isLoading: false,
          config: config,
          cookiesAccepted: granular['cookies'],
          analyticsAccepted: granular['analytics'],
          locationAccepted: granular['location'],
          marketingAccepted: granular['marketing'],
        ),
      );
    }
  }

  /// Toggle granular permission
  void toggleCookie(bool value) {
    emit(state.copyWith(cookiesAccepted: value));
  }

  void toggleAnalytics(bool value) {
    emit(state.copyWith(analyticsAccepted: value));
  }

  void toggleLocation(bool value) {
    emit(state.copyWith(locationAccepted: value));
  }

  void toggleMarketing(bool value) {
    emit(state.copyWith(marketingAccepted: value));
  }

  /// Save current granular preferences
  Future<void> savePreferences() async {
    await _repository.saveConsent(
      true, // Considered "Accepted" with customization
      cookies: state.cookiesAccepted,
      analytics: state.analyticsAccepted,
      location: state.locationAccepted,
      marketing: state.marketingAccepted,
    );
    emit(state.copyWith(status: ConsentStatus.accepted));
  }

  /// Accept all cookies/policies
  Future<void> acceptAll() async {
    await _repository.saveConsent(
      true,
      analytics: true,
      location: true,
      marketing: true,
    );
    emit(
      state.copyWith(
        status: ConsentStatus.accepted,
        cookiesAccepted: true,
        analyticsAccepted: true,
        locationAccepted: true,
        marketingAccepted: true,
      ),
    );
  }

  /// Reject all optional (keep only necessary)
  Future<void> rejectAll() async {
    await _repository.saveConsent(
      false, // "Rejected" might be simpler for analytics tracking to just checks "isAccepted"
    );
    emit(
      state.copyWith(
        status: ConsentStatus.rejected,
        cookiesAccepted: true,
        analyticsAccepted: false,
        locationAccepted: false,
        marketingAccepted: false,
      ),
    );
  }

  /// Reset consent (Debugging or "Revoke" feature)
  Future<void> resetConsent() async {
    await _repository.revokeConsent();
    emit(state.copyWith(status: ConsentStatus.unknown));
  }
}
