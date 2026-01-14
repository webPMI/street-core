// form_item_config.dart
// ============================================================================
// Immutable Form Field Configuration
// ============================================================================
//
// Replacement for FormItemModel with:
// - Immutability (compatible with BLoC)
// - Type-safety (no dynamic values)
// - Integration with unified validation system
// - Composable validators

import '/core/helpers/validators.dart';
import 'package:flutter/material.dart';

/// Form field types supported by the dynamic form system
enum FormFieldType {
  text,
  email,
  password,
  number,
  phone,
  url,
  dropdown,
  country,
  date,
  datetime,
  time,
  timeRange,
  checkbox,
  switcher,
  textarea,
  image,
  custom,
}

/// Immutable configuration for a form field
///
/// This replaces the mutable FormItemModel with a clean, immutable design
/// that integrates properly with the validator system.
@immutable
// ignore: must_be_immutable
class FormItemConfig {
  FormItemConfig({
    required this.id,
    required this.label,
    required this.type,
    this.defaultValue,
    this.validator,
    this.apiKey,
    this.hintText,
    this.autofillHints,
    this.maxLines = 1,
    this.isRequired = false,
    this.options,
    this.customWidget,
    this.metadata,
    this.icon,
    this.enabled = true,
    this.maxLength,
  });

  // ============================================================================
  // Factory Methods for Common Field Types
  // ============================================================================

  /// Email field with automatic validation
  factory FormItemConfig.email({
    required String id,
    required String label,
    String? defaultValue,
    String? hintText,
    bool isRequired = true,
    IconData? icon,
  }) => FormItemConfig(
    id: id,
    label: label,
    type: FormFieldType.email,
    defaultValue: defaultValue,
    validator: isRequired ? emailValidator : optionalEmailValidator,
    hintText: hintText,
    autofillHints: const [AutofillHints.email],
    isRequired: isRequired,
    icon: icon ?? Icons.email_outlined,
    maxLength: 50,
  );

  /// Password field with configurable strength requirements
  factory FormItemConfig.password({
    required String id,
    required String label,
    int minLength = 8,
    bool requireStrong = true,
    String? hintText,
    IconData? icon,
    String? defaultValue,
  }) => FormItemConfig(
    icon: icon ?? Icons.lock_clock_outlined,
    id: id,
    label: label,
    type: FormFieldType.password,
    defaultValue: defaultValue,
    validator: requireStrong
        ? PasswordValidator(minLength: minLength)
        : PasswordValidator(
            minLength: minLength,
            requireUppercase: false,
            requireLowercase: false,
            requireDigit: false,
            requireSpecialChar: false,
          ),

    hintText: hintText,
    autofillHints: const [AutofillHints.password],
    isRequired: true,
  );

  /// Text field
  factory FormItemConfig.text({
    required String id,
    required String label,
    String? defaultValue,
    String? hintText,
    Validator? validator,
    bool isRequired = false,
    int maxLines = 1,
    List<String>? autofillHints,
    IconData? icon,
    int? maxLength,
  }) => FormItemConfig(
    id: id,
    label: label,
    type: FormFieldType.text,
    defaultValue: defaultValue,
    validator: validator ?? (isRequired ? requiredValidator : null),
    hintText: hintText,
    autofillHints: autofillHints,
    maxLines: maxLines,
    isRequired: isRequired,
    icon: icon,
    maxLength: maxLength,
  );

  /// Textarea field (multiline text)
  factory FormItemConfig.textarea({
    required String id,
    required String label,
    String? defaultValue,
    String? hintText,
    Validator? validator,
    bool isRequired = false,
    int maxLines = 4,
    IconData? icon,
    int? maxLength,
  }) => FormItemConfig(
    id: id,
    label: label,
    type: FormFieldType.textarea,
    defaultValue: defaultValue,
    validator: validator ?? (isRequired ? requiredValidator : null),
    hintText: hintText,
    maxLines: maxLines,
    isRequired: isRequired,
    icon: icon ?? Icons.notes,
    maxLength: maxLength,
  );

  /// Phone number field
  factory FormItemConfig.phone({
    required String id,
    required String label,
    String? defaultValue,
    String? hintText,
    bool isRequired = false,
    int? minLength,
    int? maxLength,
    IconData? icon,
  }) => FormItemConfig(
    id: id,
    label: label,
    type: FormFieldType.phone,
    defaultValue: defaultValue,
    validator: PhoneValidator(
      required: isRequired,
      minLength: minLength,
      maxLength: maxLength,
    ),
    hintText: hintText,
    autofillHints: const [AutofillHints.telephoneNumber],
    isRequired: isRequired,
    icon: icon ?? Icons.phone,
  );

  /// URL field
  factory FormItemConfig.url({
    required String id,
    required String label,
    String? defaultValue,
    String? hintText,
    bool isRequired = false,
    bool requireHttps = false,
    IconData? icon,
  }) => FormItemConfig(
    id: id,
    label: label,
    type: FormFieldType.url,
    defaultValue: defaultValue,
    validator: UrlValidator(required: isRequired, requireHttps: requireHttps),
    hintText: hintText,
    autofillHints: const [AutofillHints.url],
    isRequired: isRequired,
    icon: icon ?? Icons.link,
  );

  /// Number field
  factory FormItemConfig.number({
    required String id,
    required String label,
    num? defaultValue,
    String? hintText,
    bool isRequired = false,
    bool allowDecimal = false,
    bool allowNegative = true,
    num? min,
    num? max,
    IconData? icon,
  }) => FormItemConfig(
    id: id,
    label: label,
    type: FormFieldType.number,
    defaultValue: defaultValue,
    validator: min != null && max != null
        ? RangeValidator(min: min, max: max)
        : NumberValidator(
            required: isRequired,
            allowDecimal: allowDecimal,
            allowNegative: allowNegative,
          ),
    hintText: hintText,
    isRequired: isRequired,
    icon: icon ?? Icons.numbers,
  );

  /// Dropdown field
  factory FormItemConfig.dropdown({
    required String id,
    required String label,
    required List<String> options,
    String? defaultValue,
    String? hintText,
    bool isRequired = true,
    IconData? icon,
  }) => FormItemConfig(
    id: id,
    label: label,
    type: FormFieldType.dropdown,
    defaultValue: defaultValue,
    validator: isRequired ? requiredValidator : null,
    hintText: hintText,
    options: options,
    isRequired: isRequired,
    icon: icon ?? Icons.arrow_drop_down,
  );

  /// Country picker field with flag support
  factory FormItemConfig.country({
    required String id,
    required String label,
    String? defaultValue,
    String? hintText,
    bool isRequired = false,
    IconData? icon,
  }) => FormItemConfig(
    id: id,
    label: label,
    type: FormFieldType.country,
    defaultValue: defaultValue,
    validator: isRequired ? requiredValidator : null,
    hintText: hintText,
    isRequired: isRequired,
    icon: icon ?? Icons.public,
  );

  /// Date picker field
  factory FormItemConfig.date({
    required String id,
    required String label,
    DateTime? defaultValue,
    String? hintText,
    bool isRequired = false,
    DateTime? minDate,
    DateTime? maxDate,
    IconData? icon,
  }) => FormItemConfig(
    id: id,
    label: label,
    type: FormFieldType.date,
    defaultValue: defaultValue,
    validator: DateValidator(
      required: isRequired,
      minDate: minDate,
      maxDate: maxDate,
    ),
    hintText: hintText,
    isRequired: isRequired,
    icon: icon ?? Icons.calendar_today,
  );

  /// DateTime picker field (date + time)
  factory FormItemConfig.datetime({
    required String id,
    required String label,
    DateTime? defaultValue,
    String? hintText,
    bool isRequired = false,
    DateTime? minDate,
    DateTime? maxDate,
    IconData? icon,
  }) => FormItemConfig(
    id: id,
    label: label,
    type: FormFieldType.datetime,
    defaultValue: defaultValue,
    validator: DateValidator(
      required: isRequired,
      minDate: minDate,
      maxDate: maxDate,
    ),
    hintText: hintText,
    isRequired: isRequired,
    icon: icon ?? Icons.event,
  );

  /// Checkbox field
  factory FormItemConfig.checkbox({
    required String id,
    required String label,
    bool defaultValue = false,
    Validator? validator,
  }) => FormItemConfig(
    id: id,
    label: label,
    type: FormFieldType.checkbox,
    defaultValue: defaultValue,
    validator: validator,
  );

  /// Switch field
  factory FormItemConfig.switcher({
    required String id,
    required String label,
    bool defaultValue = false,
    String? hintText,
  }) => FormItemConfig(
    id: id,
    label: label,
    type: FormFieldType.switcher,
    defaultValue: defaultValue,
    hintText: hintText,
  );

  /// Image picker field
  ///
  /// Supports Web, Android, and iOS with validation
  ///
  /// Example:
  /// ```dart
  /// FormItemConfig.image(
  ///   id: 'profile_photo',
  ///   label: 'Profile Photo',
  ///   maxSizeBytes: 5 * 1024 * 1024, // 5MB
  ///   allowedExtensions: ['jpg', 'png'],
  /// )
  /// ```
  factory FormItemConfig.image({
    required String id,
    required String label,
    String? hintText,
    String? initialImageUrl,
    bool isRequired = false,
    double width = 300,
    double height = 200,
    List<String> allowedExtensions = const [
      'jpg',
      'jpeg',
      'png',
      'gif',
      'webp',
    ],
    int maxSizeBytes = 10 * 1024 * 1024, // 10MB
    double maxImageDimension = 1920,
    int imageQuality = 85,
    bool showDeleteButton = true,
    IconData? icon,
  }) => FormItemConfig(
    id: id,
    label: label,
    type: FormFieldType.image,
    defaultValue: initialImageUrl,
    validator: isRequired ? requiredValidator : null,
    hintText: hintText,
    isRequired: isRequired,
    icon: icon ?? Icons.image_outlined,
    metadata: {
      'width': width,
      'height': height,
      'allowedExtensions': allowedExtensions,
      'maxSizeBytes': maxSizeBytes,
      'maxImageDimension': maxImageDimension,
      'imageQuality': imageQuality,
      'showDeleteButton': showDeleteButton,
    },
  );

  /// Custom widget field
  factory FormItemConfig.custom({
    required String id,
    required String label,
    required Widget customWidget,
    Object? defaultValue,
    Validator? validator,
  }) => FormItemConfig(
    id: id,
    label: label,
    type: FormFieldType.custom,
    defaultValue: defaultValue,
    validator: validator,
    customWidget: customWidget,
  );

  /// Unique identifier for this field (used as key in form data)
  final String id;

  /// Label to display (translation key)
  final String label;

  /// Type of form field to render
  final FormFieldType type;

  /// Initial/default value for this field
  Object? defaultValue;

  /// Validator instance (can be composed with & operator)
  final Validator? validator;

  /// Key to use when sending data to API (defaults to id)
  final String? apiKey;

  /// Placeholder text (translation key)
  final String? hintText;

  /// Autofill hints for browser/OS integration
  final List<String>? autofillHints;

  /// Maximum number of lines (for text fields)
  final int maxLines;

  /// Whether this field is required
  final bool isRequired;

  /// Options for dropdown/radio fields
  final List<String>? options;

  /// Custom widget to render (for FormFieldType.custom)
  final Widget? customWidget;

  /// Additional metadata for extensions
  final Map<String, dynamic>? metadata;

  /// Icon to display before the field
  final IconData? icon;

  /// Whether the field is enabled
  final bool enabled;
  final int? maxLength;

  /// API key to use (returns apiKey if set, otherwise id)
  String get effectiveApiKey => apiKey ?? id;

  /// Create a copy with some fields updated
  FormItemConfig copyWith({
    String? id,
    String? label,
    FormFieldType? type,
    Object? defaultValue,
    Validator? validator,
    String? apiKey,
    String? hintText,
    List<String>? autofillHints,
    int? maxLines,
    bool? isRequired,
    List<String>? options,
    Widget? customWidget,
    Map<String, dynamic>? metadata,
    IconData? icon,
    bool? enabled,
    int? maxLenght,
  }) {
    return FormItemConfig(
      id: id ?? this.id,
      label: label ?? this.label,
      type: type ?? this.type,
      defaultValue: defaultValue ?? this.defaultValue,
      validator: validator ?? this.validator,
      apiKey: apiKey ?? this.apiKey,
      hintText: hintText ?? this.hintText,
      autofillHints: autofillHints ?? this.autofillHints,
      maxLines: maxLines ?? this.maxLines,
      isRequired: isRequired ?? this.isRequired,
      options: options ?? this.options,
      customWidget: customWidget ?? this.customWidget,
      metadata: metadata ?? this.metadata,
      icon: icon ?? this.icon,
      enabled: enabled ?? this.enabled,
    );
  }
}
