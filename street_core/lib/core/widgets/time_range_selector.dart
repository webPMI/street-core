// lib/core/widgets/form/time_range_selector.dart

import '/core/lang/context_tr.dart';
import '/core/lang/locale_keys.dart';
import 'my_text.dart';
import 'my_time_selector.dart';
import 'package:flutter/material.dart';

/// TimeRangeSelector - Selector de rango de tiempo
///
/// Características:
/// - Selección de hora inicio y hora fin
/// - Validación automática (inicio < fin)
/// - Formato 24h
/// - Interfaz compacta
///
/// Uso:
/// ```dart
/// TimeRangeSelector(
///   label: 'Horario del curso',
///   startTime: TimeOfDay(hour: 10, minute: 0),
///   endTime: TimeOfDay(hour: 12, minute: 0),
///   onChanged: (start, end) {
///     print('De $start a $end');
///   },
/// )
/// ```
class TimeRangeSelector extends StatefulWidget {
  const TimeRangeSelector({
    super.key,
    required this.label,
    this.startTime,
    this.endTime,
    this.onChanged,
    this.isRequired = false,
    this.enabled = true,
    this.startLabel = LocaleKeys.startTime,
    this.endLabel = LocaleKeys.endTime,
    this.helperText,
    this.validateRange = true,
  });
  final String label;
  final TimeOfDay? startTime;
  final TimeOfDay? endTime;
  final ValueChanged<TimeRange>? onChanged;
  final bool isRequired;
  final bool enabled;
  final String startLabel;
  final String endLabel;
  final String? helperText;
  final bool validateRange;

  @override
  State<TimeRangeSelector> createState() => _TimeRangeSelectorState();
}

class _TimeRangeSelectorState extends State<TimeRangeSelector> {
  late TimeOfDay? _startTime;
  late TimeOfDay? _endTime;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _startTime = widget.startTime;
    _endTime = widget.endTime;
    _validateRange();
  }

  @override
  void didUpdateWidget(TimeRangeSelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.startTime != widget.startTime ||
        oldWidget.endTime != widget.endTime) {
      _startTime = widget.startTime;
      _endTime = widget.endTime;
      _validateRange();
    }
  }

  void _validateRange() {
    if (!widget.validateRange) {
      _errorMessage = null;
      return;
    }

    if (_startTime != null && _endTime != null) {
      final startMinutes = _startTime!.hour * 60 + _startTime!.minute;
      final endMinutes = _endTime!.hour * 60 + _endTime!.minute;

      if (startMinutes >= endMinutes) {
        _errorMessage = LocaleKeys.startTimeBeforeEndTime;
      } else {
        _errorMessage = null;
      }
    } else {
      _errorMessage = null;
    }
  }

  void _onStartTimeChanged(TimeOfDay? time) {
    setState(() {
      _startTime = time;
      _validateRange();
    });
    _notifyChange();
  }

  void _onEndTimeChanged(TimeOfDay? time) {
    setState(() {
      _endTime = time;
      _validateRange();
    });
    _notifyChange();
  }

  void _notifyChange() {
    if (widget.onChanged != null) {
      widget.onChanged!(TimeRange(start: _startTime, end: _endTime));
    }
  }

  String _formatDuration() {
    if (_startTime == null || _endTime == null) return '';

    final startMinutes = _startTime!.hour * 60 + _startTime!.minute;
    final endMinutes = _endTime!.hour * 60 + _endTime!.minute;

    if (startMinutes >= endMinutes) return '';

    final durationMinutes = endMinutes - startMinutes;
    final hours = durationMinutes ~/ 60;
    final minutes = durationMinutes % 60;

    if (hours > 0 && minutes > 0) {
      return '$hours h $minutes min';
    } else if (hours > 0) {
      return '$hours h';
    } else {
      return '$minutes min';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final duration = _formatDuration();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label
        if (widget.label.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Icon(
                  Icons.schedule,
                  size: 20,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                MyText(widget.label, istitle: true),
                if (widget.isRequired) const MyText(' *', color: Colors.red),
              ],
            ),
          ),

        // Time selectors
        Row(
          children: [
            // Start time
            Expanded(
              child: MyTimeSelector(
                label: widget.startLabel,
                value: _startTime,
                onChanged: widget.enabled ? _onStartTimeChanged : (time) {},
                requiredField: widget.isRequired,
              ),
            ),

            // Separator
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 20),
              child: Icon(
                Icons.arrow_forward,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),

            // End time
            Expanded(
              child: MyTimeSelector(
                label: widget.endLabel,
                value: _endTime,
                onChanged: widget.enabled ? _onEndTimeChanged : (time) {},
                requiredField: widget.isRequired,
              ),
            ),
          ],
        ),

        // Duration info
        if (duration.isNotEmpty) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.timer,
                  size: 16,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
                const SizedBox(width: 8),
                MyText(
                  '${context.tr(LocaleKeys.duration)}: $duration',
                  color: theme.colorScheme.onPrimaryContainer,
                  noTranslation: true,
                ),
              ],
            ),
          ),
        ],

        // Helper text
        if (widget.helperText != null && _errorMessage == null) ...[
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(left: 12),
            child: MyText(
              widget.helperText!,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],

        // Error message
        if (_errorMessage != null) ...[
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(left: 12),
            child: Row(
              children: [
                Icon(
                  Icons.error_outline,
                  size: 16,
                  color: theme.colorScheme.error,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: MyText(_errorMessage!, color: theme.colorScheme.error),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

/// TimeRange - Modelo para rango de tiempo
class TimeRange {
  const TimeRange({this.start, this.end});
  final TimeOfDay? start;
  final TimeOfDay? end;

  bool get isValid {
    if (start == null || end == null) return false;
    final startMinutes = start!.hour * 60 + start!.minute;
    final endMinutes = end!.hour * 60 + end!.minute;
    return startMinutes < endMinutes;
  }

  int get durationMinutes {
    if (!isValid) return 0;
    final startMinutes = start!.hour * 60 + start!.minute;
    final endMinutes = end!.hour * 60 + end!.minute;
    return endMinutes - startMinutes;
  }

  Map<String, String> toJson() {
    return {
      if (start != null)
        'startTime':
            '${start!.hour.toString().padLeft(2, '0')}:${start!.minute.toString().padLeft(2, '0')}',
      if (end != null)
        'endTime':
            '${end!.hour.toString().padLeft(2, '0')}:${end!.minute.toString().padLeft(2, '0')}',
    };
  }

  @override
  String toString() {
    if (!isValid) return 'Invalid time range';
    return '${start!.hour.toString().padLeft(2, '0')}:${start!.minute.toString().padLeft(2, '0')} - '
        '${end!.hour.toString().padLeft(2, '0')}:${end!.minute.toString().padLeft(2, '0')}';
  }

  TimeRange copyWith({TimeOfDay? start, TimeOfDay? end}) {
    return TimeRange(start: start ?? this.start, end: end ?? this.end);
  }
}
