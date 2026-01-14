import 'package:flutter/material.dart';
import '../../../core/lang/context_tr.dart';
import '../../../core/lang/locale_keys.dart';
import '../../../core/widgets/my_text.dart';

/// Dialog for filtering tournaments list
class TournamentFiltersDialog extends StatefulWidget {
  final Map<String, dynamic>? currentFilters;

  const TournamentFiltersDialog({
    super.key,
    this.currentFilters,
  });

  @override
  State<TournamentFiltersDialog> createState() =>
      _TournamentFiltersDialogState();
}

class _TournamentFiltersDialogState extends State<TournamentFiltersDialog> {
  String? _selectedStatus;
  String? _selectedDiscipline;
  String? _selectedYear;

  final List<String> _statuses = [
    'all',
    'upcoming',
    'live',
    'completed',
  ];

  final List<String> _disciplines = [
    'all',
    'inline',
    'bmx',
    'skateboard',
    'scooter',
  ];

  @override
  void initState() {
    super.initState();
    _selectedStatus = widget.currentFilters?['status'] as String? ?? 'all';
    _selectedDiscipline =
        widget.currentFilters?['discipline'] as String? ?? 'all';
    _selectedYear = widget.currentFilters?['year'] as String?;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                MyText(
                  LocaleKeys.tournamentsFilters,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Status filter
            MyText(
              LocaleKeys.tournamentsFilterStatus,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _statuses.map((status) {
                final isSelected = _selectedStatus == status;
                return ChoiceChip(
                  label: MyText(
                    status == 'all'
                        ? LocaleKeys.all
                        : '${LocaleKeys.tournamentsStatus}.$status',
                  ),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      _selectedStatus = status;
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // Discipline filter
            MyText(
              LocaleKeys.tournamentsFilterDiscipline,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _disciplines.map((discipline) {
                final isSelected = _selectedDiscipline == discipline;
                return ChoiceChip(
                  label: MyText(
                    discipline == 'all'
                        ? LocaleKeys.all
                        : '${LocaleKeys.disciplines}.$discipline',
                  ),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      _selectedDiscipline = discipline;
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // Year filter
            MyText(
              LocaleKeys.tournamentsFilterYear,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _selectedYear,
              decoration: InputDecoration(
                hintText: context.tr(LocaleKeys.all),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
              items: [
                DropdownMenuItem(
                  value: null,
                  child: MyText(LocaleKeys.all),
                ),
                ...List.generate(
                  5,
                  (index) {
                    final year = DateTime.now().year - index;
                    return DropdownMenuItem(
                      value: year.toString(),
                      child: MyText(year.toString(), noTranslation: true),
                    );
                  },
                ),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedYear = value;
                });
              },
            ),
            const SizedBox(height: 24),

            // Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () {
                    setState(() {
                      _selectedStatus = 'all';
                      _selectedDiscipline = 'all';
                      _selectedYear = null;
                    });
                  },
                  child: MyText(LocaleKeys.clear),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    final filters = <String, dynamic>{};

                    if (_selectedStatus != null && _selectedStatus != 'all') {
                      filters['status'] = _selectedStatus;
                    }

                    if (_selectedDiscipline != null &&
                        _selectedDiscipline != 'all') {
                      filters['discipline'] = _selectedDiscipline;
                    }

                    if (_selectedYear != null) {
                      filters['year'] = _selectedYear;
                    }

                    Navigator.of(context).pop(filters);
                  },
                  child: MyText(LocaleKeys.apply),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
