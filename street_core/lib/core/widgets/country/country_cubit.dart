// lib/domain/country/country_cubit.dart

import '/core/helpers/logger.dart';
import '/data/constants/country.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'country_repository.dart';
import 'country_state.dart';

/// Country Cubit
///
/// Manages country data state using the BLoC pattern.
/// Handles progressive loading of countries (priority first, then all)
/// with caching to prevent redundant loads.
///
/// Features:
/// - Progressive loading (priority countries -> all countries)
/// - Automatic caching (loads data only once)
/// - Safe state emission (checks if cubit is closed before emitting)
/// - Logging for debugging and monitoring
/// - Country lookup by code
///
/// Usage:
/// ```dart
/// final cubit = CountryCubit(countryRepository);
/// await cubit.loadCountriesProgressively(); // Load countries
/// final country = cubit.getCountryByCode('AR'); // Get specific country
/// ```
class CountryCubit extends Cubit<CountryState> {
  CountryCubit(this._repository) : super(const CountryState.initial()) {
    AppLogger.info('CountryCubit initialized', tag: 'CountryCubit');
  }
  final ICountryRepository _repository;

  /// Flag to track if countries have been loaded (caching mechanism)
  bool _hasLoadedCountries = false;

  /// Load countries progressively with caching
  ///
  /// Implements a two-phase progressive loading strategy:
  /// 1. Phase 1: Load and emit priority countries (30 countries) immediately
  /// 2. Phase 2: Load and emit all countries (255+) after a short delay
  ///
  /// The method includes caching - if countries have already been loaded,
  /// it will not reload them. This prevents redundant API calls or data
  /// processing when the cubit is reused.
  ///
  /// The method is safe to call multiple times - only the first call will
  /// trigger actual loading, subsequent calls are no-ops.
  ///
  /// Example:
  /// ```dart
  /// await cubit.loadCountriesProgressively();
  /// // First call: loads data
  ///
  /// await cubit.loadCountriesProgressively();
  /// // Second call: does nothing (cached)
  /// ```
  Future<void> loadCountriesProgressively() async {
    // Check cache - if already loaded, skip
    if (_hasLoadedCountries) {
      AppLogger.debug(
        'Countries already loaded (cached), skipping reload',
        tag: 'CountryCubit',
      );
      return;
    }

    try {
      AppLogger.info(
        'Starting progressive country loading',
        tag: 'CountryCubit',
      );

      // Subscribe to the progressive loading stream
      await for (final countries in _repository.loadCountriesProgressively()) {
        // Safety check: ensure cubit hasn't been closed before emitting
        if (isClosed) {
          AppLogger.warning(
            'Cubit closed during progressive loading, stopping emission',
            tag: 'CountryCubit',
          );
          break;
        }

        // Determine state based on country count
        // Priority countries: 30 countries
        // All countries: 255+ countries
        final isPriorityPhase = countries.length <= 30;

        if (isPriorityPhase) {
          AppLogger.debug(
            'Phase 1: Loaded ${countries.length} priority countries',
            tag: 'CountryCubit',
          );
          emit(CountryState.priority(countries));
        } else {
          AppLogger.debug(
            'Phase 2: Loaded all ${countries.length} countries',
            tag: 'CountryCubit',
          );
          emit(CountryState.complete(countries));

          // Mark as loaded for caching
          _hasLoadedCountries = true;
        }
      }
    } catch (error, stackTrace) {
      AppLogger.error(
        'Error loading countries progressively',
        error: error,
        stackTrace: stackTrace,
        tag: 'CountryCubit',
      );

      // On error, emit empty state
      if (!isClosed) {
        emit(const CountryState.initial());
      }
    }
  }

  /// Get a country by its ISO 3166-1 alpha-2 code
  ///
  /// Delegates to the repository to find the country.
  /// This method is synchronous and uses the repository's cached data.
  ///
  /// Parameters:
  /// - [code]: ISO 3166-1 alpha-2 country code (e.g., 'US', 'AR', 'ES')
  ///
  /// Returns: [Country] object if found, null otherwise
  ///
  /// Example:
  /// ```dart
  /// final argentina = cubit.getCountryByCode('AR');
  /// if (argentina != null) {
  ///   print('Found: ${argentina.name}');
  /// }
  /// ```
  Country? getCountryByCode(String code) {
    AppLogger.debug('Looking up country with code: $code', tag: 'CountryCubit');
    final country = _repository.getCountryByCode(code);

    if (country != null) {
      AppLogger.debug('Found country: ${country.name}', tag: 'CountryCubit');
    } else {
      AppLogger.warning(
        'Country not found for code: $code',
        tag: 'CountryCubit',
      );
    }

    return country;
  }

  /// Force reload countries (clears cache and reloads)
  ///
  /// Useful for testing or when you need to refresh the country data.
  /// This will bypass the cache and reload all countries from scratch.
  ///
  /// Example:
  /// ```dart
  /// await cubit.reload();
  /// ```
  Future<void> reload() async {
    AppLogger.info('Forcing country reload', tag: 'CountryCubit');
    _hasLoadedCountries = false;
    emit(const CountryState.initial());
    await loadCountriesProgressively();
  }

  @override
  Future<void> close() {
    AppLogger.info('CountryCubit closing', tag: 'CountryCubit');
    return super.close();
  }
}
