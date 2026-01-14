import 'package:equatable/equatable.dart';

import '../location_service.dart';

enum LocationStatus {
  initial,
  loading,
  loaded,
  error,
  permissionDenied,
  serviceDisabled,
}

class LocationState extends Equatable {

  const LocationState({
    this.status = LocationStatus.initial,
    this.currentLocation,
    this.radiusKm = LocationService.defaultRadiusKm,
    this.errorMessage,
    this.searchResults = const [],
    this.isSearching = false,
  });
  final LocationStatus status;
  final UserLocation? currentLocation;
  final double radiusKm;
  final String? errorMessage;
  final List<UserLocation> searchResults;
  final bool isSearching;

  bool get hasLocation => currentLocation != null;
  bool get isLoading => status == LocationStatus.loading;
  bool get isLoaded => status == LocationStatus.loaded;
  bool get isError => status == LocationStatus.error;
  bool get isPermissionDenied => status == LocationStatus.permissionDenied;
  bool get isServiceDisabled => status == LocationStatus.serviceDisabled;

  LocationState copyWith({
    LocationStatus? status,
    UserLocation? currentLocation,
    double? radiusKm,
    String? errorMessage,
    List<UserLocation>? searchResults,
    bool? isSearching,
    bool clearLocation = false,
    bool clearError = false,
  }) {
    return LocationState(
      status: status ?? this.status,
      currentLocation: clearLocation
          ? null
          : (currentLocation ?? this.currentLocation),
      radiusKm: radiusKm ?? this.radiusKm,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      searchResults: searchResults ?? this.searchResults,
      isSearching: isSearching ?? this.isSearching,
    );
  }

  @override
  List<Object?> get props => [
    status,
    currentLocation?.latitude,
    currentLocation?.longitude,
    radiusKm,
    errorMessage,
    searchResults,
    isSearching,
  ];
}
