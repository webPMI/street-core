import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:street_core/core/widgets/error_card.dart';

import '../../helpers/responsive/breakpoints.dart';
import '../../lang/locale_keys.dart';
import '../bloc/location_cubit.dart';
import '../bloc/location_state.dart';
import 'location_filter_components.dart';
import '../../widgets/my_text.dart';

/// A wrapper widget that adds location filtering capability to any list
///
/// Usage:
/// ```dart
/// LocationAwareList<Event>(
///   items: events,
///   getLatitude: (e) => e.latitude,
///   getLongitude: (e) => e.longitude,
///   onRefresh: () => cubit.loadEvents(),
///   builder: (context, filteredItems) => ListView.builder(
///     itemCount: filteredItems.length,
///     itemBuilder: (context, index) => EventCard(event: filteredItems[index]),
///   ),
/// )
/// ```
class LocationAwareList<T> extends StatelessWidget {
  const LocationAwareList({
    super.key,
    required this.items,
    required this.builder,
    this.getLatitude,
    this.getLongitude,
    this.onRefresh,
    this.showLocationBar = true,
    this.filterByRadius = true,
    this.sortByDistance = true,
    this.header,
    this.isLoading = false,
    this.error,
    this.emptyWidget,
  });

  /// All items before filtering
  final List<T> items;

  /// Builder that receives filtered items
  final Widget Function(BuildContext context, List<T> filteredItems) builder;

  /// Extract latitude from item
  final double? Function(T item)? getLatitude;

  /// Extract longitude from item
  final double? Function(T item)? getLongitude;

  /// Called when location changes or refresh is needed
  final VoidCallback? onRefresh;

  /// Whether to show the location filter bar
  final bool showLocationBar;

  /// Whether to filter items by radius
  final bool filterByRadius;

  /// Whether to sort items by distance (nearest first)
  final bool sortByDistance;

  /// Header widget to show above the list
  final Widget? header;

  /// Loading state
  final bool isLoading;

  /// Error message
  final String? error;

  /// Empty state widget
  final Widget? emptyWidget;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LocationCubit, LocationState>(
      builder: (context, locationState) {
        final filteredItems = _processItems(context, locationState);

        return Column(
          children: [
            // Location indicator (compact)
            if (showLocationBar && locationState.hasLocation)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    if (header != null) header!,
                    const Spacer(),
                    LocationIndicator(
                      onLocationChanged: onRefresh,
                    ),
                  ],
                ),
              ),

            // Content
            Expanded(child: _buildContent(context, filteredItems)),
          ],
        );
      },
    );
  }

  List<T> _processItems(BuildContext context, LocationState state) {
    if (!state.hasLocation || getLatitude == null || getLongitude == null) {
      return items;
    }

    var result = List<T>.from(items);
    final locationCubit = context.read<LocationCubit>();

    // Filter by radius
    if (filterByRadius) {
      result = result.where((item) {
        final lat = getLatitude!(item);
        final lng = getLongitude!(item);
        if (lat == null || lng == null) return true;
        return locationCubit.isWithinRadius(lat, lng);
      }).toList();
    }

    // Sort by distance
    if (sortByDistance) {
      result.sort((a, b) {
        final latA = getLatitude!(a);
        final lngA = getLongitude!(a);
        final latB = getLatitude!(b);
        final lngB = getLongitude!(b);

        if (latA == null || lngA == null) return 1;
        if (latB == null || lngB == null) return -1;

        final distA = locationCubit.getDistanceTo(latA, lngA);
        final distB = locationCubit.getDistanceTo(latB, lngB);

        // If both distances are null, they're equal
        if (distA == null && distB == null) return 0;
        // If only distA is null, put it at the end
        if (distA == null) return 1;
        // If only distB is null, put it at the end
        if (distB == null) return -1;

        // Both distances are valid, compare them
        return distA.compareTo(distB);
      });
    }

    return result;
  }

  Widget _buildContent(BuildContext context, List<T> filteredItems) {
    if (isLoading && items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (error != null && items.isEmpty) {
      return ErrorCard(message: error, onRetry: onRefresh);
    }

    if (filteredItems.isEmpty) {
      return emptyWidget ?? _buildDefaultEmpty(context);
    }

    return builder(context, filteredItems);
  }

  Widget _buildDefaultEmpty(BuildContext context) {
    return SizedBox(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 48,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 16),
          MyText(
            'no.items.found',
            style: TextStyle(color: Theme.of(context).colorScheme.outline),
          ),
          const SizedBox(height: 8),
          BlocBuilder<LocationCubit, LocationState>(
            builder: (context, state) {
              if (state.hasLocation) {
                return TextButton.icon(
                  onPressed: () {
                    context.read<LocationCubit>().clearLocation();
                    onRefresh?.call();
                  },
                  icon: const Icon(Icons.location_off),
                  label: MyText(LocaleKeys.showAllLocations),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
    );
  }
}

/// A responsive grid/list that adapts to screen size
class ResponsiveGridList<T> extends StatelessWidget {
  const ResponsiveGridList({
    super.key,
    required this.items,
    required this.itemBuilder,
    this.mobileColumns,
    this.tabletColumns,
    this.desktopColumns,
    this.aspectRatio = 1.0,
    this.spacing = 12.0,
    this.padding,
    this.shrinkWrap = false,
    this.physics,
    this.controller,
  });
  final List<T> items;
  final Widget Function(BuildContext context, T item, int index) itemBuilder;
  final int? mobileColumns;
  final int? tabletColumns;
  final int? desktopColumns;
  final double aspectRatio;
  final double spacing;
  final EdgeInsets? padding;
  final bool shrinkWrap;
  final ScrollPhysics? physics;
  final ScrollController? controller;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final deviceType = getDeviceType(width);

    int columns;
    switch (deviceType) {
      case DeviceType.mobile:
        columns = mobileColumns ?? 1;
        break;
      case DeviceType.tablet:
        columns = tabletColumns ?? 2;
        break;
      case DeviceType.desktop:
        columns = desktopColumns ?? getGridColumns(width);
        break;
    }

    final effectivePadding =
        padding ?? EdgeInsets.all(getHorizontalPadding(width));

    if (columns == 1) {
      return ListView.builder(
        controller: controller,
        shrinkWrap: shrinkWrap,
        physics: physics,
        padding: effectivePadding,
        itemCount: items.length,
        itemBuilder: (context, index) => Padding(
          padding: EdgeInsets.only(bottom: spacing),
          child: itemBuilder(context, items[index], index),
        ),
      );
    }

    return GridView.builder(
      controller: controller,
      shrinkWrap: shrinkWrap,
      physics: physics,
      padding: effectivePadding,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        crossAxisSpacing: spacing,
        mainAxisSpacing: spacing,
        childAspectRatio: aspectRatio,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) =>
          itemBuilder(context, items[index], index),
    );
  }
}

/// Extension to add location badge to any card widget
extension LocationBadgeExtension on Widget {
  /// Wraps this widget and adds a distance badge in the corner
  Widget withDistanceBadge({
    required double? latitude,
    required double? longitude,
    AlignmentGeometry alignment = Alignment.topRight,
  }) {
    return Builder(
      builder: (context) {
        return Stack(
          children: [
            this,
            if (latitude != null && longitude != null)
              Positioned(
                top: 8,
                right: 8,
                child: BlocBuilder<LocationCubit, LocationState>(
                  builder: (context, state) {
                    if (!state.hasLocation) return const SizedBox.shrink();

                    final distance = context
                        .read<LocationCubit>()
                        .getDistanceTo(latitude, longitude);
                    if (distance == null) return const SizedBox.shrink();

                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.surface.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.near_me,
                            size: 12,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _formatDistance(distance),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
          ],
        );
      },
    );
  }
}

String _formatDistance(double km) {
  if (km < 1) return '${(km * 1000).round()} m';
  if (km < 10) return '${km.toStringAsFixed(1)} km';
  return '${km.round()} km';
}
