import '../../../core/storage/hive_service.dart';

/// Repository for managing user consent (GDPR/Cookies)
///
/// Uses Hive to store the user's decision locally.
/// It doesn't need to be complex securely because it's client-side compliance.
class ConsentRepository {
  final HiveService _hive;

  ConsentRepository(this._hive);

  static const String _consentKey = 'privacy_consent_v1';
  static const String _consentDateKey = 'privacy_consent_date';

  static const String _keyAnalytics = 'privacy_analytics_v1';
  static const String _keyLocation = 'privacy_location_v1';
  static const String _keyMarketing = 'privacy_marketing_v1';
  static const String _keyCookies = 'privacy_cookies_v1';

  /// Check if user has already made a decision (Accepted or Rejected)
  Future<bool> hasUserDecided() async {
    return _hive.hasPref(_consentKey);
  }

  /// Get the current consent status (true = accepted, false = rejected, null = unknown)
  Future<bool?> getConsentStatus() async {
    return _hive.readPref<bool>(_consentKey);
  }

  /// Get granular consent preferences
  Future<Map<String, bool>> getGranularConsent() async {
    return {
      'analytics': _hive.readPref<bool>(_keyAnalytics) ?? false,
      'location': _hive.readPref<bool>(_keyLocation) ?? false,
      'marketing': _hive.readPref<bool>(_keyMarketing) ?? false,
      'cookies': _hive.readPref<bool>(_keyCookies) ?? true, // Default true for necessary
    };
  }

  /// Save user consent
  Future<void> saveConsent(
    bool accepted, {
    bool analytics = false,
    bool location = false,
    bool marketing = false,
    bool cookies = true,
  }) async {
    await _hive.savePref(_consentKey, accepted);
    await _hive.savePref(_consentDateKey, DateTime.now().toIso8601String());

    // Save granular
    await _hive.savePref(_keyAnalytics, analytics);
    await _hive.savePref(_keyLocation, location);
    await _hive.savePref(_keyMarketing, marketing);
    await _hive.savePref(_keyCookies, cookies);
  }

  /// Reset consent (for testing or "Revoke Consent" feature)
  Future<void> revokeConsent() async {
    await _hive.deletePref(_consentKey);
    await _hive.deletePref(_consentDateKey);
    await _hive.deletePref(_keyAnalytics);
    await _hive.deletePref(_keyLocation);
    await _hive.deletePref(_keyMarketing);
    await _hive.deletePref(_keyCookies);
  }
}
