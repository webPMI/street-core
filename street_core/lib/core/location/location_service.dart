// ignore_for_file: depend_on_referenced_packages

import 'dart:convert';

import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import '../storage/hive_service.dart';

/// Model for user location data
class UserLocation { // true if manually selected, false if auto-detected

  UserLocation({
    required this.latitude,
    required this.longitude,
    this.city,
    this.country,
    this.countryCode,
    this.state,
    this.address,
    DateTime? timestamp,
    this.isManual = false,
  }) : timestamp = timestamp ?? DateTime.now();

  /// Create from JSON
  factory UserLocation.fromJson(Map<String, dynamic> json) => UserLocation(
    latitude: json['latitude'] as double,
    longitude: json['longitude'] as double,
    city: json['city'] as String?,
    country: json['country'] as String?,
    countryCode: json['countryCode'] as String?,
    state: json['state'] as String?,
    address: json['address'] as String?,
    timestamp: DateTime.tryParse(json['timestamp'] ?? ''),
    isManual: json['isManual'] as bool? ?? false,
  );
  final double latitude;
  final double longitude;
  final String? city;
  final String? country;
  final String? countryCode;
  final String? state;
  final String? address;
  final DateTime timestamp;
  final bool isManual;

  /// Display name for the location
  String get displayName {
    if (city != null && country != null) {
      return '$city, $country';
    }
    if (city != null) return city!;
    if (country != null) return country!;
    return '${latitude.toStringAsFixed(4)}, ${longitude.toStringAsFixed(4)}';
  }

  /// Short display name
  String get shortName => city ?? country ?? 'Unknown';

  /// Convert to JSON for storage
  Map<String, dynamic> toJson() => {
    'latitude': latitude,
    'longitude': longitude,
    'city': city,
    'country': country,
    'countryCode': countryCode,
    'state': state,
    'address': address,
    'timestamp': timestamp.toIso8601String(),
    'isManual': isManual,
  };

  /// Calculate distance to another location in kilometers
  double distanceTo(UserLocation other) {
    return Geolocator.distanceBetween(
          latitude,
          longitude,
          other.latitude,
          other.longitude,
        ) /
        1000; // Convert meters to km
  }

  /// Calculate distance to coordinates in kilometers
  double distanceToCoords(double lat, double lng) {
    return Geolocator.distanceBetween(latitude, longitude, lat, lng) / 1000;
  }

  UserLocation copyWith({
    double? latitude,
    double? longitude,
    String? city,
    String? country,
    String? countryCode,
    String? state,
    String? address,
    DateTime? timestamp,
    bool? isManual,
  }) {
    return UserLocation(
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      city: city ?? this.city,
      country: country ?? this.country,
      countryCode: countryCode ?? this.countryCode,
      state: state ?? this.state,
      address: address ?? this.address,
      timestamp: timestamp ?? this.timestamp,
      isManual: isManual ?? this.isManual,
    );
  }
}

/// Result wrapper for location operations
class LocationResult {

  LocationResult({
    this.location,
    this.error,
    this.permissionDenied = false,
    this.serviceDisabled = false,
  });
  final UserLocation? location;
  final String? error;
  final bool permissionDenied;
  final bool serviceDisabled;

  bool get isSuccess => location != null && error == null;
  bool get isError => error != null;
}

/// Service for handling device location
class LocationService {
  final HiveService _hive;

  LocationService(this._hive);

  static const String _locationKey = 'user_location';
  static const String _radiusKey = 'location_radius_km';

  /// Default search radius in kilometers
  static const double defaultRadiusKm = 50;

  /// Check if location services are enabled
  Future<bool> isLocationServiceEnabled() async {
    return Geolocator.isLocationServiceEnabled();
  }

  /// Check current permission status
  Future<LocationPermission> checkPermission() async {
    return Geolocator.checkPermission();
  }

  /// Request location permission
  Future<LocationPermission> requestPermission() async {
    return Geolocator.requestPermission();
  }

  /// Get current device location with reverse geocoding
  Future<LocationResult> getCurrentLocation() async {
    try {
      // Check if location services are enabled
      final serviceEnabled = await isLocationServiceEnabled();
      if (!serviceEnabled) {
        return LocationResult(
          error: 'location.services.disabled',
          serviceDisabled: true,
        );
      }

      // Check permission
      LocationPermission permission = await checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await requestPermission();
        if (permission == LocationPermission.denied) {
          return LocationResult(
            error: 'location.permission.denied',
            permissionDenied: true,
          );
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return LocationResult(
          error: 'location.permission.denied.forever',
          permissionDenied: true,
        );
      }

      // Get position
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 10),
        ),
      );

      // Reverse geocode to get address details
      final location = await _reverseGeocode(
        position.latitude,
        position.longitude,
      );

      // Save location
      await saveLocation(location);

      return LocationResult(location: location);
    } catch (e) {
      return LocationResult(error: 'location.error: $e');
    }
  }

  /// Reverse geocode coordinates to get address details
  Future<UserLocation> _reverseGeocode(
    double latitude,
    double longitude, {
    bool isManual = false,
  }) async {
    try {
      final placemarks = await placemarkFromCoordinates(latitude, longitude);
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        return UserLocation(
          latitude: latitude,
          longitude: longitude,
          city: place.locality ?? place.subAdministrativeArea,
          country: place.country,
          countryCode: place.isoCountryCode,
          state: place.administrativeArea,
          address: _formatAddress(place),
          isManual: isManual,
        );
      }
    } catch (e) {
      // If geocoding fails, return basic location
    }

    return UserLocation(
      latitude: latitude,
      longitude: longitude,
      isManual: isManual,
    );
  }

  /// Format placemark to address string
  String _formatAddress(Placemark place) {
    final parts = <String>[];
    if (place.street != null && place.street!.isNotEmpty) {
      parts.add(place.street!);
    }
    if (place.locality != null && place.locality!.isNotEmpty) {
      parts.add(place.locality!);
    }
    if (place.administrativeArea != null &&
        place.administrativeArea!.isNotEmpty) {
      parts.add(place.administrativeArea!);
    }
    if (place.country != null && place.country!.isNotEmpty) {
      parts.add(place.country!);
    }
    return parts.join(', ');
  }

  /// Search for a location by address/city name
  Future<List<UserLocation>> searchLocation(String query) async {
    if (query.trim().isEmpty) return [];

    try {
      final locations = await locationFromAddress(query);
      final results = <UserLocation>[];

      for (final location in locations.take(5)) {
        final userLocation = await _reverseGeocode(
          location.latitude,
          location.longitude,
          isManual: true,
        );
        results.add(userLocation);
      }

      return results;
    } catch (e) {
      return [];
    }
  }

  /// Set a manual location
  Future<UserLocation> setManualLocation(
    double latitude,
    double longitude,
  ) async {
    final location = await _reverseGeocode(latitude, longitude, isManual: true);
    await saveLocation(location);
    return location;
  }

  /// Save location to persistent storage
  Future<void> saveLocation(UserLocation location) async {
    final json = location.toJson();
    await _hive.savePref(_locationKey, jsonEncode(json));
  }

  /// Get saved location from storage
  Future<UserLocation?> getSavedLocation() async {
    final jsonString = _hive.readPref<String>(_locationKey);
    if (jsonString == null) return null;

    try {
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      return UserLocation.fromJson(json);
    } catch (e) {
      return null;
    }
  }

  /// Clear saved location
  Future<void> clearSavedLocation() async {
    await _hive.deletePref(_locationKey);
  }

  /// Get saved search radius
  Future<double> getSearchRadius() async {
    return _hive.readPref<double>(_radiusKey, defaultValue: defaultRadiusKm) ?? defaultRadiusKm;
  }

  /// Save search radius
  Future<void> saveSearchRadius(double radiusKm) async {
    await _hive.savePref(_radiusKey, radiusKm);
  }

  /// Open device location settings
  Future<bool> openLocationSettings() async {
    return Geolocator.openLocationSettings();
  }

  /// Open app settings for permission
  Future<bool> openAppSettings() async {
    return Geolocator.openAppSettings();
  }
}
