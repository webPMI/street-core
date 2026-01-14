import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../lang/context_tr.dart';
import '../../lang/locale_keys.dart';
import '../bloc/location_cubit.dart';
import '../bloc/location_state.dart';
import '../../widgets/my_text.dart';
import './location_picker_widget.dart';

/// Simple icon button for AppBar - opens location picker sheet
class LocationFilterButton extends StatelessWidget {
  const LocationFilterButton({
    super.key,
    this.onLocationChanged,
    this.showRadius = true,
  });

  final VoidCallback? onLocationChanged;
  final bool showRadius;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LocationCubit, LocationState>(
      builder: (context, state) {
        return IconButton(
          icon: Badge(
            isLabelVisible: state.hasLocation,
            child: Icon(
              state.hasLocation
                  ? Icons.location_on
                  : Icons.location_off_outlined,
              color: state.hasLocation
                  ? Theme.of(context).colorScheme.primary
                  : null,
            ),
          ),
          tooltip: state.hasLocation
              ? '${state.currentLocation!.shortName} • ${state.radiusKm.round()} km'
              : context.tr( LocaleKeys.selectLocation),
          onPressed: () => _showLocationSheet(context),
        );
      },
    );
  }

  void _showLocationSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return BlocProvider.value(
          value: context.read<LocationCubit>(),
          child: DraggableScrollableSheet(
            initialChildSize: 0.6,
            minChildSize: 0.4,
            maxChildSize: 0.9,
            expand: false,
            builder: (_, controller) {
              return SingleChildScrollView(
                controller: controller,
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Handle bar
                    Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.outlineVariant,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    LocationPickerWidget(
                      showRadius: showRadius,
                      onLocationChanged: () {
                        Navigator.pop(sheetContext);
                        onLocationChanged?.call();
                      },
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}

/// Compact indicator chip showing current location + radius
/// Can be placed anywhere - tapping opens location picker
class LocationIndicator extends StatelessWidget {
  const LocationIndicator({
    super.key,
    this.onLocationChanged,
    this.showRadius = true,
    this.onClear,
  });

  final VoidCallback? onLocationChanged;
  final bool showRadius;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LocationCubit, LocationState>(
      builder: (context, state) {
        if (!state.hasLocation) {
          return const SizedBox.shrink();
        }

        return Chip(
          avatar: Icon(
            Icons.location_on,
            size: 16,
            color: Theme.of(context).colorScheme.primary,
          ),
          label: MyText(
            showRadius
                ? '${state.currentLocation!.shortName} • ${state.radiusKm.round()} km'
                : state.currentLocation!.shortName,
            fontSize: 12,
          ),
          deleteIcon: const Icon(Icons.close, size: 16),
          onDeleted:
              onClear ??
              () {
                context.read<LocationCubit>().clearLocation();
                onLocationChanged?.call();
              },
          visualDensity: VisualDensity.compact,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        );
      },
    );
  }
}

/// Distance badge to show how far something is from user's location
class DistanceBadge extends StatelessWidget {
  const DistanceBadge({
    super.key,
    required this.latitude,
    required this.longitude,
    this.showIcon = true,
  });

  final double? latitude;
  final double? longitude;
  final bool showIcon;

  @override
  Widget build(BuildContext context) {
    if (latitude == null || longitude == null) return const SizedBox.shrink();

    return BlocBuilder<LocationCubit, LocationState>(
      builder: (context, state) {
        if (!state.hasLocation) return const SizedBox.shrink();

        final distance = context.read<LocationCubit>().getDistanceTo(
          latitude!,
          longitude!,
        );
        if (distance == null) return const SizedBox.shrink();

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (showIcon) ...[
                Icon(
                  Icons.near_me,
                  size: 12,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 2),
              ],
              MyText(
                _formatDistance(distance),
                fontSize: 11,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatDistance(double km) {
    if (km < 1) {
      return '${(km * 1000).round()} m';
    } else if (km < 10) {
      return '${km.toStringAsFixed(1)} km';
    } else {
      return '${km.round()} km';
    }
  }
}

/// Extension to easily filter lists by location
extension LocationFilter<T> on List<T> {
  /// Filter items by distance from user's location
  /// Returns all items if no location is set
  List<T> filterByLocation(
    LocationCubit locationCubit, {
    required double? Function(T item) getLatitude,
    required double? Function(T item) getLongitude,
  }) {
    final state = locationCubit.state;
    if (!state.hasLocation) return this;

    return where((item) {
      final lat = getLatitude(item);
      final lng = getLongitude(item);
      if (lat == null || lng == null) {
        return true; // Include items without location
      }
      return locationCubit.isWithinRadius(lat, lng);
    }).toList();
  }

  /// Sort items by distance from user's location (nearest first)
  /// Returns original order if no location is set
  List<T> sortByDistance(
    LocationCubit locationCubit, {
    required double? Function(T item) getLatitude,
    required double? Function(T item) getLongitude,
  }) {
    final state = locationCubit.state;
    if (!state.hasLocation) return this;

    final sorted = List<T>.from(this);
    sorted.sort((a, b) {
      final latA = getLatitude(a);
      final lngA = getLongitude(a);
      final latB = getLatitude(b);
      final lngB = getLongitude(b);

      // Items without location go to the end
      if (latA == null || lngA == null) return 1;
      if (latB == null || lngB == null) return -1;

      final distA = locationCubit.getDistanceTo(latA, lngA) ?? double.infinity;
      final distB = locationCubit.getDistanceTo(latB, lngB) ?? double.infinity;

      return distA.compareTo(distB);
    });

    return sorted;
  }
}
