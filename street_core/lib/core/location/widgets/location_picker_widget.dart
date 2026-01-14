import '../../lang/context_tr.dart';
import '../../lang/locale_keys.dart';
import '../bloc/location_cubit.dart';
import '../bloc/location_state.dart';
import '../../widgets/my_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Widget for displaying and selecting user location
class LocationPickerWidget extends StatefulWidget {
  const LocationPickerWidget({
    super.key,
    this.showRadius = true,
    this.compact = false,
    this.onLocationChanged,
  });
  final bool showRadius;
  final bool compact;
  final VoidCallback? onLocationChanged;

  @override
  State<LocationPickerWidget> createState() => _LocationPickerWidgetState();
}

class _LocationPickerWidgetState extends State<LocationPickerWidget> {
  final _searchController = TextEditingController();
  bool _showSearch = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<LocationCubit, LocationState>(
      listener: (context, state) {
        if (state.isLoaded && widget.onLocationChanged != null) {
          widget.onLocationChanged!();
        }
      },
      builder: (context, state) {
        if (widget.compact) {
          return _buildCompactView(context, state);
        }
        return _buildFullView(context, state);
      },
    );
  }

  Widget _buildCompactView(BuildContext context, LocationState state) {
    return InkWell(
      onTap: () => _showLocationSheet(context),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.location_on,
              size: 18,
              color: state.hasLocation
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: MyText(
                state.hasLocation
                    ? state.currentLocation!.shortName
                    : context.tr(LocaleKeys.selectLocation),
                fontSize: 14,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.arrow_drop_down,
              size: 18,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFullView(BuildContext context, LocationState state) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(
                  Icons.location_on,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: MyText(
                    LocaleKeys.yourLocation,
                    istitle: true,
                    fontSize: 16,
                  ),
                ),
                if (state.hasLocation)
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () =>
                        context.read<LocationCubit>().clearLocation(),
                    tooltip: context.tr(LocaleKeys.clearLocation),
                  ),
              ],
            ),
            const SizedBox(height: 12),

            // Current location display
            if (state.hasLocation) ...[
              _buildCurrentLocation(context, state),
              const SizedBox(height: 12),
            ],

            // Action buttons
            _buildActionButtons(context, state),

            // Search field
            if (_showSearch) ...[
              const SizedBox(height: 12),
              _buildSearchField(context, state),
            ],

            // Radius slider
            if (widget.showRadius && state.hasLocation) ...[
              const SizedBox(height: 16),
              _buildRadiusSlider(context, state),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentLocation(BuildContext context, LocationState state) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.primaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            state.currentLocation!.isManual
                ? Icons.edit_location
                : Icons.my_location,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                MyText(
                  state.currentLocation!.displayName,
                  fontWeight: FontWeight.w600,
                ),
                if (state.currentLocation!.address != null)
                  MyText(
                    state.currentLocation!.address!,
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    maxLines: 2,
                  ),
                MyText(
                  state.currentLocation!.isManual
                      ? context.tr(LocaleKeys.locationManual)
                      : context.tr(LocaleKeys.locationAuto),
                  fontSize: 11,
                  color: Theme.of(context).colorScheme.outline,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, LocationState state) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        // Auto-detect button
        FilledButton.icon(
          onPressed: state.isLoading
              ? null
              : () => context.read<LocationCubit>().detectCurrentLocation(),
          icon: state.isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.my_location, size: 18),
          label: MyText(LocaleKeys.detectLocation),
        ),

        // Manual search button
        OutlinedButton.icon(
          onPressed: () {
            setState(() => _showSearch = !_showSearch);
            if (!_showSearch) {
              _searchController.clear();
              context.read<LocationCubit>().clearSearchResults();
            }
          },
          icon: Icon(_showSearch ? Icons.close : Icons.search, size: 18),
          label: MyText(_showSearch ? LocaleKeys.cancel : LocaleKeys.searchLocation),
        ),
      ],
    );
  }

  Widget _buildSearchField(BuildContext context, LocationState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: context.tr(LocaleKeys.searchCityHint),
            prefixIcon: const Icon(Icons.search),
            suffixIcon: state.isSearching
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : _searchController.text != ''
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _searchController.clear();
                      context.read<LocationCubit>().clearSearchResults();
                    },
                  )
                : null,
            border: const OutlineInputBorder(),
          ),
          onChanged: (value) {
            context.read<LocationCubit>().searchLocations(value);
          },
        ),

        // Search results
        if (state.searchResults.isNotEmpty) ...[
          const SizedBox(height: 8),
          Container(
            constraints: const BoxConstraints(maxHeight: 200),
            decoration: BoxDecoration(
              border: Border.all(color: Theme.of(context).dividerColor),
              borderRadius: BorderRadius.circular(8),
            ),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: state.searchResults.length,
              itemBuilder: (context, index) {
                final location = state.searchResults[index];
                return ListTile(
                  leading: const Icon(Icons.location_on_outlined),
                  title: MyText(location.displayName),
                  subtitle: location.address != null
                      ? MyText(location.address!, fontSize: 12)
                      : null,
                  onTap: () {
                    context.read<LocationCubit>().setManualLocation(location);
                    setState(() => _showSearch = false);
                    _searchController.clear();
                  },
                );
              },
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildRadiusSlider(BuildContext context, LocationState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            MyText(LocaleKeys.searchRadius, fontWeight: FontWeight.w500),
            MyText(
              '${state.radiusKm.round()} km',
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ],
        ),
        Slider(
          value: state.radiusKm,
          min: 5,
          max: 500,
          divisions: 99,
          label: '${state.radiusKm.round()} km',
          onChanged: (value) {
            context.read<LocationCubit>().setSearchRadius(value);
          },
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            MyText(
              '5 km',
              fontSize: 11,
              color: Theme.of(context).colorScheme.outline,
            ),
            MyText(
              '500 km',
              fontSize: 11,
              color: Theme.of(context).colorScheme.outline,
            ),
          ],
        ),
      ],
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
                child: LocationPickerWidget(
                  showRadius: widget.showRadius,
                  onLocationChanged: () {
                    Navigator.pop(sheetContext);
                    widget.onLocationChanged?.call();
                  },
                ),
              );
            },
          ),
        );
      },
    );
  }
}

/// Small badge showing current location
class LocationBadge extends StatelessWidget {
  const LocationBadge({super.key, this.onTap});
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LocationCubit, LocationState>(
      builder: (context, state) {
        return ActionChip(
          avatar: Icon(
            state.hasLocation ? Icons.location_on : Icons.location_off,
            size: 18,
            color: state.hasLocation
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.outline,
          ),
          label: MyText(
            state.hasLocation
                ? state.currentLocation!.shortName
                : context.tr(LocaleKeys.noLocation),
            fontSize: 13,
          ),
          onPressed: onTap ?? () => _showLocationPicker(context),
        );
      },
    );
  }

  void _showLocationPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return BlocProvider.value(
          value: context.read<LocationCubit>(),
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
            ),
            child: const SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: LocationPickerWidget(),
            ),
          ),
        );
      },
    );
  }
}
