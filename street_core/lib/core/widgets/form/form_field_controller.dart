// form_field_controller.dart
// ============================================================================
// Form Field Controller Abstraction
// ============================================================================
//
// Type-safe controllers for different form field types
// Replaces direct TextEditingController management

import 'form_item_config.dart';
import 'package:flutter/material.dart';

/// Abstract base class for form field controllers
///
/// Provides type-safe value management for different field types
abstract class FormFieldController<T> extends ValueNotifier<T> {
  FormFieldController(super.initialValue);

  /// Factory constructor to create appropriate controller for field type
  factory FormFieldController.create({
    required FormFieldType type,
    required T initialValue,
  }) {
    switch (type) {
      case FormFieldType.text:
      case FormFieldType.email:
      case FormFieldType.password:
      case FormFieldType.phone:
      case FormFieldType.url:
      case FormFieldType.textarea:
        return TextFormFieldController(initialValue as String? ?? '')
            as FormFieldController<T>;

      case FormFieldType.number:
        return NumberFormFieldController(initialValue as num? ?? 0)
            as FormFieldController<T>;

      case FormFieldType.checkbox:
      case FormFieldType.switcher:
        return BoolFormFieldController(initialValue as bool? ?? false)
            as FormFieldController<T>;

      case FormFieldType.date:
      case FormFieldType.datetime:
        return DateFormFieldController(initialValue as DateTime?)
            as FormFieldController<T>;

      case FormFieldType.dropdown:
        return DropdownFormFieldController(initialValue as String?)
            as FormFieldController<T>;

      case FormFieldType.custom:
      default:
        return GenericFormFieldController<T>(initialValue);
    }
  }

  /// Clear the field value
  void clear();

  /// Reset to initial value
  void reset();

  /// Get the current value as dynamic for API
  dynamic get apiValue => value;
}

/// Controller for text-based fields
class TextFormFieldController extends FormFieldController<String> {
  TextFormFieldController(this.initialValue) : super(initialValue) {
    textController = TextEditingController(text: initialValue);
    textController.addListener(_onTextChanged);
  }
  late final TextEditingController textController;
  final String initialValue;

  void _onTextChanged() {
    value = textController.text;
  }

  @override
  void clear() {
    textController.clear();
  }

  @override
  void reset() {
    textController.text = initialValue;
  }

  @override
  void dispose() {
    textController.removeListener(_onTextChanged);
    textController.dispose();
    super.dispose();
  }
}

/// Controller for number fields
class NumberFormFieldController extends FormFieldController<num> {
  NumberFormFieldController(this.initialValue) : super(initialValue) {
    textController = TextEditingController(text: initialValue.toString());
    textController.addListener(_onTextChanged);
  }
  late final TextEditingController textController;
  final num initialValue;

  void _onTextChanged() {
    final parsed = num.tryParse(textController.text);
    if (parsed != null) {
      value = parsed;
    }
  }

  @override
  void clear() {
    textController.text = '0';
    value = 0;
  }

  @override
  void reset() {
    textController.text = initialValue.toString();
    value = initialValue;
  }

  @override
  void dispose() {
    textController.removeListener(_onTextChanged);
    textController.dispose();
    super.dispose();
  }
}

/// Controller for boolean fields (checkbox, switch)
class BoolFormFieldController extends FormFieldController<bool> {
  BoolFormFieldController(this.initialValue) : super(initialValue);
  final bool initialValue;

  @override
  void clear() {
    value = false;
  }

  @override
  void reset() {
    value = initialValue;
  }

  void toggle() {
    value = !value;
  }
}

/// Controller for date fields
class DateFormFieldController extends FormFieldController<DateTime?> {
  DateFormFieldController(this.initialValue) : super(initialValue);
  final DateTime? initialValue;

  @override
  void clear() {
    value = null;
  }

  @override
  void reset() {
    value = initialValue;
  }

  @override
  dynamic get apiValue => value?.toUtc().toIso8601String();
}

/// Controller for dropdown fields
class DropdownFormFieldController extends FormFieldController<String?> {
  DropdownFormFieldController(this.initialValue) : super(initialValue);
  final String? initialValue;

  @override
  void clear() {
    value = null;
  }

  @override
  void reset() {
    value = initialValue;
  }
}

/// Generic controller for custom field types
class GenericFormFieldController<T> extends FormFieldController<T> {
  GenericFormFieldController(this.initialValue) : super(initialValue);
  final T initialValue;

  @override
  void clear() {
    // For generic types, we can't clear to a default value
    // Subclasses should override if they know a sensible default
  }

  @override
  void reset() {
    value = initialValue;
  }
}
