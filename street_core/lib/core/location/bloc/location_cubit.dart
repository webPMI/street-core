import './location_state.dart';
import '../location_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class LocationCubit extends Cubit<LocationState> {

  LocationCubit({required LocationService locationService})
    : _locationService = locationService,
      super(const LocationState()) {
    _init();
  }
  final LocationService _locationService;

  /// Initialize: load saved location and radius
  Future<void> _init() async {
    final savedLocation = await _locationService.getSavedLocation();
    final savedRadius = await _locationService.getSearchRadius();

    if (savedLocation != null) {
      emit(
        state.copyWith(
          status: LocationStatus.loaded,
          currentLocation: savedLocation,
          radiusKm: savedRadius,
        ),
      );
    } else {
      emit(state.copyWith(radiusKm: savedRadius));
    }
  }

  /// Get current device location (auto-detect)
  Future<void> detectCurrentLocation() async {
    emit(state.copyWith(status: LocationStatus.loading, clearError: true));

    final result = await _locationService.getCurrentLocation();

    if (result.isSuccess) {
      emit(
        state.copyWith(
          status: LocationStatus.loaded,
          currentLocation: result.location,
        ),
      );
    } else if (result.permissionDenied) {
      emit(
        state.copyWith(
          status: LocationStatus.permissionDenied,
          errorMessage: result.error,
        ),
      );
    } else if (result.serviceDisabled) {
      emit(
        state.copyWith(
          status: LocationStatus.serviceDisabled,
          errorMessage: result.error,
        ),
      );
    } else {
      emit(
        state.copyWith(
          status: LocationStatus.error,
          errorMessage: result.error,
        ),
      );
    }
  }

  /// Search for locations by query
  Future<void> searchLocations(String query) async {
    if (query.trim().length < 2) {
      emit(state.copyWith(searchResults: [], isSearching: false));
      return;
    }

    emit(state.copyWith(isSearching: true));

    final results = await _locationService.searchLocation(query);
    emit(state.copyWith(searchResults: results, isSearching: false));
  }

  /// Clear search results
  void clearSearchResults() {
    emit(state.copyWith(searchResults: [], isSearching: false));
  }

  /// Set manual location from search result or coordinates
  Future<void> setManualLocation(UserLocation location) async {
    emit(state.copyWith(status: LocationStatus.loading));

    await _locationService.saveLocation(location);

    emit(
      state.copyWith(
        status: LocationStatus.loaded,
        currentLocation: location,
        searchResults: [],
      ),
    );
  }

  /// Set location from coordinates
  Future<void> setLocationFromCoords(double latitude, double longitude) async {
    emit(state.copyWith(status: LocationStatus.loading));

    final location = await _locationService.setManualLocation(
      latitude,
      longitude,
    );

    emit(
      state.copyWith(status: LocationStatus.loaded, currentLocation: location),
    );
  }

  /// Update search radius
  Future<void> setSearchRadius(double radiusKm) async {
    await _locationService.saveSearchRadius(radiusKm);
    emit(state.copyWith(radiusKm: radiusKm));
  }

  /// Clear current location
  Future<void> clearLocation() async {
    await _locationService.clearSavedLocation();
    emit(state.copyWith(status: LocationStatus.initial, clearLocation: true));
  }

  /// Open device location settings
  Future<void> openLocationSettings() async {
    await _locationService.openLocationSettings();
  }

  /// Open app settings for permission
  Future<void> openAppSettings() async {
    await _locationService.openAppSettings();
  }

  /// Refresh location (re-detect)
  Future<void> refreshLocation() async {
    await detectCurrentLocation();
  }

  /// Check if a location is within the current search radius
  bool isWithinRadius(double lat, double lng) {
    if (state.currentLocation == null) return true;
    final distance = state.currentLocation!.distanceToCoords(lat, lng);
    return distance <= state.radiusKm;
  }

  /// Get distance from current location
  double? getDistanceTo(double lat, double lng) {
    if (state.currentLocation == null) return null;
    return state.currentLocation!.distanceToCoords(lat, lng);
  }
}
