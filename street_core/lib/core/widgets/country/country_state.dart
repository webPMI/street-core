// lib/domain/country/country_state.dart

import 'package:equatable/equatable.dart';
import '/data/constants/country.dart';

/// Country State
///
/// Represents the current state of country data in the application.
/// Uses Equatable for efficient state comparison and change detection.
///
/// The state tracks:
/// - Current list of available countries
/// - Loading status for all countries
/// - Whether all countries have been loaded
///
/// This enables the UI to show progressive loading indicators and
/// handle different loading phases appropriately.
class CountryState extends Equatable {
  const CountryState({
    required this.countries,
    required this.isLoadingAll,
    required this.hasLoadedAll,
  });

  /// Initial state with empty country list
  ///
  /// Used when the cubit is first created, before any countries are loaded.
  const CountryState.initial()
    : countries = const [],
      isLoadingAll = true,
      hasLoadedAll = false;

  /// State with priority countries loaded
  ///
  /// Used after the first phase of progressive loading completes.
  /// Indicates that common countries are available but the full list
  /// is still being loaded in the background.
  ///
  /// Parameters:
  /// - [countries]: List of priority countries (typically 30 countries)
  const CountryState.priority(this.countries)
    : isLoadingAll = true,
      hasLoadedAll = false;

  /// State with all countries loaded
  ///
  /// Used after the second phase of progressive loading completes.
  /// Indicates that the complete country list is available.
  ///
  /// Parameters:
  /// - [countries]: Complete list of all countries (255+)
  const CountryState.complete(this.countries)
    : isLoadingAll = false,
      hasLoadedAll = true;

  /// List of currently available countries
  ///
  /// Initially contains priority countries (30 countries), then expands
  /// to include all countries (255+) after progressive loading completes.
  final List<Country> countries;

  /// Whether all countries are currently being loaded
  ///
  /// True during the background loading phase (after priority countries
  /// are loaded but before all countries are available).
  final bool isLoadingAll;

  /// Whether all countries have been loaded
  ///
  /// False initially and while loading priority countries.
  /// True once the complete country list is available.
  final bool hasLoadedAll;

  /// Create a copy of this state with modified fields
  ///
  /// Useful for making incremental changes to the state without
  /// creating completely new named constructors.
  CountryState copyWith({
    List<Country>? countries,
    bool? isLoadingAll,
    bool? hasLoadedAll,
  }) {
    return CountryState(
      countries: countries ?? this.countries,
      isLoadingAll: isLoadingAll ?? this.isLoadingAll,
      hasLoadedAll: hasLoadedAll ?? this.hasLoadedAll,
    );
  }

  /// Properties used for equality comparison
  ///
  /// Equatable uses these properties to determine if two states are equal.
  /// This enables efficient state change detection in BLoC.
  @override
  List<Object?> get props => [countries, isLoadingAll, hasLoadedAll];

  /// String representation for debugging
  @override
  String toString() {
    return 'CountryState(countries: ${countries.length}, '
        'isLoadingAll: $isLoadingAll, hasLoadedAll: $hasLoadedAll)';
  }
}
