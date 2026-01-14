import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../../../core/widgets/my_text.dart';
import '../../../../core/widgets/my_text_form_field.dart';
import '../../../../core/lang/locale_keys.dart';

class CompeFilters extends StatefulWidget {
  const CompeFilters({
    super.key,
    required this.selectedFilter,
    required this.onFilterChanged,
    required this.onSearchChanged,
  });
  final String selectedFilter;
  final ValueChanged<String> onFilterChanged;
  final ValueChanged<String> onSearchChanged;

  @override
  State<CompeFilters> createState() => _CompeFiltersState();
}

class _CompeFiltersState extends State<CompeFilters> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    setState(() {});
  }

  @override
  void dispose() {
    _searchController.removeListener(_onTextChanged);
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          ScrollConfiguration(
            behavior: ScrollConfiguration.of(context).copyWith(
              dragDevices: {
                PointerDeviceKind.touch,
                PointerDeviceKind.mouse,
                PointerDeviceKind.trackpad,
              },
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip(context, 'all', LocaleKeys.allCompetitions),
                  const SizedBox(width: 8),
                  _buildFilterChip(
                    context,
                    'live',
                    LocaleKeys.tournamentsStatusLive,
                    isLive: true,
                  ),
                  const SizedBox(width: 8),
                  _buildFilterChip(context, 'upcoming', LocaleKeys.upcomingEvents),
                  const SizedBox(width: 8),
                  _buildFilterChip(context, 'completed', LocaleKeys.results),
                  const SizedBox(width: 8),
                ],
              ),
            ),
          ),
          MyTextFormField(
            controller: _searchController,
            autofocus: false,
            label: LocaleKeys.searchCompetition,
            sufIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      _searchController.clear();
                      widget.onSearchChanged('');
                    },
                  )
                : const Icon(Icons.search),
            onChanged: (value) {
              widget.onSearchChanged(value);
            },
          ),
          const Divider(),
        ],
      ),
    );
  }

  Widget _buildFilterChip(
    BuildContext context,
    String value,
    String label, {
    bool isLive = false,
  }) {
    final theme = Theme.of(context);
    final isSelected = widget.selectedFilter == value;

    return FilterChip(
      selected: isSelected,
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isLive) ...[
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: isSelected ? theme.colorScheme.onPrimary : Colors.red,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
          ],
          MyText(label),
        ],
      ),
      onSelected: (selected) {
        if (selected) {
          widget.onFilterChanged(value);
        }
      },
      backgroundColor: theme.colorScheme.surfaceContainerHighest,
      selectedColor: theme.colorScheme.primary,
      labelStyle: TextStyle(
        color: isSelected
            ? theme.colorScheme.onPrimary
            : theme.colorScheme.onSurface,
      ),
    );
  }
}
