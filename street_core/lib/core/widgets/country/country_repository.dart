// lib/domain/country/country_repository.dart

import '../../../data/constants/country.dart';

/// Country Repository Interface
///
/// Defines the contract for country data access operations.
/// This interface abstracts the data source, allowing for flexible implementations
/// (e.g., local data, API, cached data) following the Repository pattern.
///
/// The repository provides methods for:
/// - Progressive loading of countries (priority first, then all)
/// - Retrieving specific countries by code
/// - Streaming country data for real-time updates
abstract class ICountryRepository {
  /// Get priority countries for immediate display
  ///
  /// Returns a list of commonly used countries (30 countries) that should
  /// be loaded first for better user experience. These countries are selected
  /// based on population, economic activity, and app usage patterns.
  ///
  /// Returns: List of [Country] objects representing priority countries
  ///
  /// Example:
  /// ```dart
  /// final priorityCountries = await repository.getPriorityCountries();
  /// // Returns: [US, MX, CA, BR, AR, CO, CL, PE, ES, GB, ...]
  /// ```
  Future<List<Country>> getPriorityCountries();

  /// Get all countries including priority and remaining countries
  ///
  /// Returns the complete list of 255+ countries. This method should be called
  /// after priority countries are loaded to provide the full selection.
  ///
  /// Returns: List of all [Country] objects
  ///
  /// Example:
  /// ```dart
  /// final allCountries = await repository.getAllCountries();
  /// // Returns: [US, CA, MX, ..., ZW] (all 255+ countries)
  /// ```
  Future<List<Country>> getAllCountries();

  /// Get a specific country by its ISO 3166-1 alpha-2 code
  ///
  /// Searches for a country with the given code in the complete country list.
  /// This is useful for pre-selecting a country or validating country codes.
  ///
  /// Parameters:
  /// - [code]: ISO 3166-1 alpha-2 country code (e.g., 'US', 'AR', 'ES')
  ///
  /// Returns: [Country] object if found, null otherwise
  ///
  /// Example:
  /// ```dart
  /// final country = repository.getCountryByCode('AR');
  /// // Returns: Country(code: 'AR', name: 'argentina')
  ///
  /// final notFound = repository.getCountryByCode('XX');
  /// // Returns: null
  /// ```
  Country? getCountryByCode(String code);

  /// Stream countries progressively (priority first, then all)
  ///
  /// Emits countries in two phases for progressive loading:
  /// 1. First emission: Priority countries (fast, immediate)
  /// 2. Second emission: All countries (after a short delay)
  ///
  /// This allows the UI to be responsive while loading the full list
  /// in the background without blocking user interactions.
  ///
  /// Returns: Stream that emits country lists progressively
  ///
  /// Example:
  /// ```dart
  /// repository.loadCountriesProgressively().listen((countries) {
  ///   print('Loaded ${countries.length} countries');
  /// });
  /// // Output:
  /// // Loaded 30 countries (priority)
  /// // Loaded 255 countries (all)
  /// ```
  Stream<List<Country>> loadCountriesProgressively();
}
