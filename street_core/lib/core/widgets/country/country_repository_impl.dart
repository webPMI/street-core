// lib/data/repositories/country_repository_impl.dart

import '../../../data/constants/country.dart';
import '../../../data/constants/country.dart' as country_constants;
import '../../helpers/logger.dart';
import 'country_repository.dart';

/// Country Repository Implementation
///
/// Concrete implementation of [ICountryRepository] that provides country data
/// from local constants with singleton caching for performance optimization.
///
/// Features:
/// - Singleton caching: Prevents redundant data loading
/// - Progressive loading: Emits priority countries first, then all countries
/// - Efficient lookups: Fast country code lookups
/// - Logging: Comprehensive logging for debugging
///
/// The repository uses data from [country.dart] constants:
/// - [kPriorityCountries]: 30 commonly used countries
/// - [kCountries]: Complete list of 255+ countries
/// - [getCountryByCode]: Helper function for lookups
class CountryRepository implements ICountryRepository {
  CountryRepository() {
    AppLogger.debug(
      'CountryRepository instance created',
      tag: 'CountryRepository',
    );
  }
  // Singleton cache for all countries
  static List<Country>? _cachedAllCountries;

  // Singleton cache for priority countries
  static List<Country>? _cachedPriorityCountries;

  /// Get priority countries for immediate display
  ///
  /// Returns the list of 30 commonly used countries from [kPriorityCountries].
  /// Uses singleton caching to prevent redundant list copies.
  ///
  /// Priority countries are selected based on:
  /// - Population size
  /// - Economic activity
  /// - Expected app usage patterns
  /// - Regional distribution
  @override
  Future<List<Country>> getPriorityCountries() async {
    if (_cachedPriorityCountries != null) {
      AppLogger.debug(
        'Returning cached priority countries (${_cachedPriorityCountries!.length})',
        tag: 'CountryRepository',
      );
      return _cachedPriorityCountries!;
    }

    AppLogger.debug('Loading priority countries', tag: 'CountryRepository');

    // Create immutable copy of priority countries
    _cachedPriorityCountries = List<Country>.unmodifiable(kPriorityCountries);

    AppLogger.info(
      'Loaded ${_cachedPriorityCountries!.length} priority countries',
      tag: 'CountryRepository',
    );

    return _cachedPriorityCountries!;
  }

  /// Get all countries including priority and remaining countries
  ///
  /// Returns the complete list of 255+ countries from [kCountries].
  /// Uses singleton caching to prevent redundant list copies.
  @override
  Future<List<Country>> getAllCountries() async {
    if (_cachedAllCountries != null) {
      AppLogger.debug(
        'Returning cached all countries (${_cachedAllCountries!.length})',
        tag: 'CountryRepository',
      );
      return _cachedAllCountries!;
    }

    AppLogger.debug('Loading all countries', tag: 'CountryRepository');

    // Create immutable copy of all countries
    _cachedAllCountries = List<Country>.unmodifiable(kCountries);

    AppLogger.info(
      'Loaded ${_cachedAllCountries!.length} countries total',
      tag: 'CountryRepository',
    );

    return _cachedAllCountries!;
  }

  /// Get a specific country by its ISO 3166-1 alpha-2 code
  ///
  /// Uses the helper function from [country.dart]
  /// for efficient lookup in the complete country list.
  ///
  /// Parameters:
  /// - [code]: ISO 3166-1 alpha-2 country code (e.g., 'US', 'AR', 'ES')
  ///
  /// Returns: [Country] object if found, null otherwise
  @override
  Country? getCountryByCode(String code) {
    AppLogger.debug('Looking up country: $code', tag: 'CountryRepository');

    // Import the global function from country.dart with explicit name
    final country = country_constants.getCountryByCode(code);

    if (country != null) {
      AppLogger.debug(
        'Found country: ${country.name} (${country.code})',
        tag: 'CountryRepository',
      );
    } else {
      AppLogger.warning(
        'Country not found for code: $code',
        tag: 'CountryRepository',
      );
    }

    return country;
  }

  /// Stream countries progressively (priority first, then all)
  ///
  /// Implements progressive loading strategy:
  /// 1. Immediately emits priority countries (30 countries)
  /// 2. After 150ms delay, emits all countries (255+ countries)
  ///
  /// The delay ensures the UI can render priority countries first
  /// without blocking, providing a better user experience.
  ///
  /// Returns: Stream that emits country lists in two phases
  @override
  Stream<List<Country>> loadCountriesProgressively() async* {
    AppLogger.info(
      'Starting progressive country loading stream',
      tag: 'CountryRepository',
    );

    try {
      // Phase 1: Emit priority countries immediately
      final priorityCountries = await getPriorityCountries();

      AppLogger.debug(
        'Phase 1: Emitting ${priorityCountries.length} priority countries',
        tag: 'CountryRepository',
      );

      yield priorityCountries;

      // Phase 2: Short delay to allow UI to render, then emit all countries
      await Future<void>.delayed(const Duration(milliseconds: 150));

      final allCountries = await getAllCountries();

      AppLogger.debug(
        'Phase 2: Emitting all ${allCountries.length} countries',
        tag: 'CountryRepository',
      );

      yield allCountries;

      AppLogger.info(
        'Progressive loading completed successfully',
        tag: 'CountryRepository',
      );
    } catch (error, stackTrace) {
      AppLogger.error(
        'Error during progressive loading',
        error: error,
        stackTrace: stackTrace,
        tag: 'CountryRepository',
      );
      rethrow;
    }
  }

  /// Clear the singleton cache (useful for testing)
  ///
  /// Forces the next call to [getPriorityCountries] or [getAllCountries]
  /// to reload data from constants instead of using cached data.
  ///
  /// Example:
  /// ```dart
  /// CountryRepository.clearCache();
  /// final countries = await repository.getAllCountries(); // Reloads
  /// ```
  static void clearCache() {
    AppLogger.info('Clearing country cache', tag: 'CountryRepository');
    _cachedAllCountries = null;
    _cachedPriorityCountries = null;
  }
}
