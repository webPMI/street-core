import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../helpers/device_storage.dart';
import '../locale_service.dart';
import 'locale_state.dart';

class LocaleBloc extends Cubit<LocaleState> {
  LocaleBloc({required StorageService storage, LocaleService? localeService})
    : _storage = storage,
      _localeService = localeService,
      super(const LocaleState(Locale('es'))) {
    initLocale();
  }

  final StorageService _storage;
  final LocaleService? _localeService;

  /// Initializes the locale when the app starts.
  Future<void> initLocale() async {
    // Try to load saved locale.
    final savedLang = await _storage.read('locale');

    // Important: Check if cubit is closed during async operation.
    if (isClosed) return;

    if (savedLang != null && _isSupported(savedLang)) {
      _updateLocale(Locale(savedLang));
    } else {
      // If no saved locale, use system locale (if supported), otherwise default to 'en'.
      final systemLocale =
          WidgetsBinding.instance.platformDispatcher.locale.languageCode;
      final locale = _isSupported(systemLocale)
          ? Locale(systemLocale)
          : const Locale('es');

      _updateLocale(locale);
      await _storage.save('locale', locale.languageCode);
    }
  }

  /// Updates both the cubit state and the LocaleService
  void _updateLocale(Locale locale) {
    // Update LocaleService for API calls
    _localeService?.setLocale(locale.languageCode);
    // Emit new state for UI
    emit(LocaleState(locale));
  }

  /// Sets the application's locale.
  Future<void> setLocale(Locale locale) async {
    if (_isSupported(locale.languageCode)) {
      if (isClosed) return;
      _updateLocale(locale);
      await _storage.save('locale', locale.languageCode);
    }
  }

  Set<Locale> supportedLocales = {const Locale('es') /* const Locale('en') */};

  /// Loads the previously saved locale from storage.
  Future<void> loadSavedLocale() async {
    final String? langCode = await _storage.read('locale');

    if (isClosed) return;
    if (langCode != null) {
      emit(LocaleState(Locale(langCode)));
    }
  }

  /// Checks if a given language code is supported.
  bool _isSupported(String code) {
    return supportedLocales.any((l) => l.languageCode == code);
  }
}
