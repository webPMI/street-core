// lib/core/lang/locale_service.dart

/// Locale Service - Provides current locale for services
///
/// This service acts as a bridge between LocaleCubit (presentation layer)
/// and ApiService (data layer), following clean architecture principles.
///
/// Usage:
/// - LocaleCubit updates this service when locale changes
/// - ApiService reads from this service for API headers
class LocaleService {
  static const String _defaultLocale = 'es';

  String _currentLocale = _defaultLocale;

  /// Get current locale code (e.g., 'es', 'en')
  String get currentLocale => _currentLocale;

  /// Update current locale
  ///
  /// Called by LocaleCubit when user changes language
  void setLocale(String localeCode) {
    _currentLocale = localeCode;
  }

  /// Reset to default locale
  void reset() {
    _currentLocale = _defaultLocale;
  }
}
