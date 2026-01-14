import 'dart:async';
import 'dart:io' show File;

import 'package:street_core/core/lang/context_tr.dart';
import 'package:street_core/core/lang/locale_keys.dart';
import 'package:street_core/core/widgets/buttons/animated_primary_button.dart';
import 'my_checkbox.dart';
import '/core/helpers/logger.dart';
import '/core/helpers/snackbar_helper.dart';
import 'package:flutter/foundation.dart' show kIsWeb, Uint8List;
import 'package:flutter/material.dart';

import 'form/form_field_helper.dart';
import 'form/form_item_config.dart';
import 'country/my_country_dropdown.dart';
import 'my_dropdown.dart';
import 'my_password_field.dart';
import 'my_switcher.dart';
import 'my_text.dart';
import 'my_text_form_field.dart';
import 'upload/select_image.dart';

class MyForm extends StatefulWidget {
  const MyForm({
    super.key,
    required this.formItems,
    required this.onSubmit,
    this.title,
    this.buttonText,
    this.initialData,
    this.onValidationFailed,
    this.headerWidget,
    this.footerWidget,
    this.isLoading = false,
    this.showTitle = false,
    this.enableAutoValidation = false,
    this.validationDebounceMs = 300,
    this.padding,
    this.spacing = 0,
    this.onChanged,
    this.isScrollable = true,
  });

  /// Campos del formulario
  final List<FormItemConfig> formItems;

  /// Callback cuando el formulario es válido y se envía
  /// Recibe un Map con los datos del formulario
  final void Function(Map<String, dynamic> data) onSubmit;

  /// Título del formulario (clave de traducción)
  final String? title;

  /// Texto del botón (clave de traducción)
  final String? buttonText;

  /// Datos iniciales para edición
  final Map<String, dynamic>? initialData;

  /// Callback cuando la validación falla
  final VoidCallback? onValidationFailed;

  /// Widget personalizado arriba del formulario
  final Widget? headerWidget;

  /// Widget personalizado debajo del formulario (antes del botón)
  final Widget? footerWidget;

  /// Estado de carga (deshabilita el botón)
  final bool isLoading;

  /// Mostrar título
  final bool showTitle;

  /// Habilitar validación automática mientras se escribe
  final bool enableAutoValidation;

  /// Delay en ms para debouncing de validación
  final int validationDebounceMs;

  /// Padding del formulario
  final EdgeInsetsGeometry? padding;

  /// Espacio entre campos
  final double spacing;

  /// Callback for live updates (optional)
  final void Function(Map<String, dynamic> data)? onChanged;

  /// Disable internal scrolling (renders as Column)
  /// Use this when embedding MyForm inside another ScrollView to avoid
  /// "shrinkWrap: true" performance issues.
  final bool isScrollable;

  @override
  State<MyForm> createState() => _MyFormState();
}

class _MyFormState extends State<MyForm> {
  final _formKey = GlobalKey<FormState>();

  // Controladores y estados
  final _controllers = <String, TextEditingController>{};
  final _boolValues = <String, ValueNotifier<bool>>{};
  final _otherValues = <String, dynamic>{};
  final _focusNodes = <String, FocusNode>{};

  // Timer para debouncing
  Timer? _validationDebounceTimer;

  // Helpers para tipos
  bool _isTextType(FormFieldType type) =>
      type == FormFieldType.text ||
      type == FormFieldType.email ||
      type == FormFieldType.url ||
      type == FormFieldType.textarea;

  bool _isBoolType(FormFieldType type) =>
      type == FormFieldType.checkbox || type == FormFieldType.switcher;

  bool _isNumType(FormFieldType type) => type == FormFieldType.number;

  String get _buttonLabel => widget.buttonText ?? LocaleKeys.save;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    AppLogger.debug(
      'MyForm initialized with ${widget.formItems.length} fields',
      tag: 'MyForm',
    );
  }

  void _initializeControllers() {
    for (final item in widget.formItems) {
      final initialValue = _getInitialValue(item);

      if (_isTextType(item.type) ||
          _isNumType(item.type) ||
          item.type == FormFieldType.password) {
        final controller = TextEditingController(
          text: initialValue?.toString() ?? '',
        );
        // Listen for changes
        if (widget.onChanged != null) {
          controller.addListener(_onAnyFieldChanged);
        }
        _controllers[item.id] = controller;
        _focusNodes[item.id] = FocusNode();
      } else if (_isBoolType(item.type)) {
        final boolValue = FormFieldHelper.parseBool(initialValue);
        final notifier = ValueNotifier<bool>(boolValue);
        // Listen for changes
        if (widget.onChanged != null) {
          notifier.addListener(_onAnyFieldChanged);
        }
        _boolValues[item.id] = notifier;
      } else if (item.type == FormFieldType.date ||
          item.type == FormFieldType.datetime ||
          item.type == FormFieldType.time ||
          item.type == FormFieldType.timeRange) {
        _otherValues[item.id] = FormFieldHelper.parseDate(initialValue);
      } else if (item.type == FormFieldType.image) {
        // For images, store the initial URL if provided
        _otherValues[item.id] = initialValue;
        // Initialize bytes storage for web
        _otherValues['${item.id}_bytes'] = null;
      } else {
        _otherValues[item.id] = initialValue;
      }
    }
  }

  dynamic _getInitialValue(FormItemConfig item) {
    if (widget.initialData != null &&
        widget.initialData!.containsKey(item.id)) {
      return widget.initialData![item.id];
    }
    return item.defaultValue;
  }

  FocusNode? _getNextFocusNode(String currentId) {
    final currentIndex = widget.formItems.indexWhere(
      (item) => item.id == currentId,
    );
    if (currentIndex == -1) return null;

    for (int i = currentIndex + 1; i < widget.formItems.length; i++) {
      final item = widget.formItems[i];
      if (_focusNodes.containsKey(item.id)) {
        return _focusNodes[item.id];
      }
    }
    return null;
  }

  void _focusNextFieldOrSubmit(String currentId) {
    final nextFocus = _getNextFocusNode(currentId);
    if (nextFocus != null) {
      nextFocus.requestFocus();
    } else {
      _handleSubmit();
    }
  }

  void _focusFirstInvalidField() {
    for (final item in widget.formItems) {
      if (!_focusNodes.containsKey(item.id)) continue;

      final focusNode = _focusNodes[item.id]!;
      bool hasError = false;

      if (_isTextType(item.type) ||
          _isNumType(item.type) ||
          item.type == FormFieldType.password) {
        final controller = _controllers[item.id];
        if (controller != null) {
          final value = controller.text;
          if (item.isRequired && value.isEmpty) {
            hasError = true;
          }
          if (!hasError && item.validator != null) {
            final error = item.validator!.validate(context, value);
            hasError = error != null;
          }
        }
      } else if (_isBoolType(item.type)) {
        final notifier = _boolValues[item.id];
        if (notifier != null && item.isRequired && !notifier.value) {
          hasError = true;
        }
      }

      if (hasError) {
        Future<void>.delayed(const Duration(milliseconds: 100), () {
          if (mounted) focusNode.requestFocus();
        });
        return;
      }
    }
  }

  void _validateWithDebounce() {
    _validationDebounceTimer?.cancel();
    _validationDebounceTimer = Timer(
      Duration(milliseconds: widget.validationDebounceMs),
      () {
        if (mounted && widget.enableAutoValidation) {
          _formKey.currentState?.validate();
        }
      },
    );
  }

  void _onAnyFieldChanged() {
    if (widget.onChanged != null) {
      // Defer to next frame/microtask if needed, or just run
      // Collecting data is synchronous
      final data = _collectFormData();
      widget.onChanged!(data);
    }
  }

  void _onFieldChanged(String value) {
    if (widget.enableAutoValidation) {
      _validateWithDebounce();
    }
    // _onAnyFieldChanged is already handled by controller listeners for text fields
  }

  /// Recolecta todos los datos del formulario
  Map<String, dynamic> _collectFormData() {
    final data = <String, dynamic>{};

    for (final item in widget.formItems) {
      final key = item.effectiveApiKey;
      dynamic value;

      if (_isTextType(item.type) || _isNumType(item.type)) {
        value = _controllers[item.id]?.text ?? '';
        if (_isNumType(item.type) && value is String && value.isNotEmpty) {
          value = FormFieldHelper.parseNumber(value) ?? value;
        }
      } else if (item.type == FormFieldType.password) {
        value = _controllers[item.id]?.text ?? '';
      } else if (_isBoolType(item.type)) {
        value = _boolValues[item.id]?.value ?? false;
      } else if (item.type == FormFieldType.date ||
          item.type == FormFieldType.datetime) {
        final date = _otherValues[item.id];
        value = date is DateTime ? date.toUtc().toIso8601String() : null;
      } else if (item.type == FormFieldType.image) {
        // For images, include both path/indicator and bytes (for web)
        final imagePath = _otherValues[item.id];
        final imageBytes = _otherValues['${item.id}_bytes'];

        if (kIsWeb && imageBytes != null) {
          // For web, return the bytes
          data['${key}_bytes'] = imageBytes;
          value = 'web_image';
        } else {
          value = imagePath;
        }
      } else {
        value = _otherValues[item.id] ?? item.defaultValue;
      }

      if (value != null || item.isRequired) {
        data[key] = value;
      }
    }

    return data;
  }

  void _handleSubmit() {
    AppLogger.debug('Form submit attempted', tag: 'MyForm');

    // Validate FormField widgets (text, number, etc.)
    final formFieldsValid = _formKey.currentState!.validate();

    // Validate non-FormField widgets (dropdown, date, datetime)
    final nonFormFieldErrors = _validateNonFormFields();

    if (formFieldsValid && nonFormFieldErrors.isEmpty) {
      final data = _collectFormData();
      AppLogger.info(
        'Form valid, submitting ${data.keys.length} fields',
        tag: 'MyForm',
      );
      widget.onSubmit(data);
    } else {
      AppLogger.warning('Form validation failed', tag: 'MyForm');
      if (nonFormFieldErrors.isNotEmpty) {
        // Show first error for non-FormField widgets
        SnackBarHelper.showWarning(context, nonFormFieldErrors.first);
      } else {
        SnackBarHelper.showWarning(context, LocaleKeys.pleaseCheckFields);
      }
      _focusFirstInvalidField();
      widget.onValidationFailed?.call();
    }
  }

  /// Validate fields that don't use FormField (dropdown, date, datetime)
  List<String> _validateNonFormFields() {
    final errors = <String>[];

    for (final item in widget.formItems) {
      if (!item.isRequired) continue;

      // Skip section headers and custom widgets
      if (item.type == FormFieldType.custom) continue;

      // Check dropdown, date, datetime fields
      if (item.type == FormFieldType.dropdown ||
          item.type == FormFieldType.date ||
          item.type == FormFieldType.datetime ||
          item.type == FormFieldType.country) {
        final value = _otherValues[item.id] ?? item.defaultValue;
        if (value == null || (value is String && value.isEmpty)) {
          errors.add('${context.tr(item.label)} ${context.tr(LocaleKeys.isRequired)}');
        }
      }
    }

    return errors;
  }

  void clearForm() {
    for (final item in widget.formItems) {
      if (_isTextType(item.type) ||
          _isNumType(item.type) ||
          item.type == FormFieldType.password) {
        _controllers[item.id]?.clear();
      } else if (_isBoolType(item.type)) {
        final defaultValue = FormFieldHelper.parseBool(item.defaultValue);
        _boolValues[item.id]?.value = defaultValue;
      } else {
        _otherValues[item.id] = item.defaultValue;
      }
    }
    _formKey.currentState?.reset();
  }

  // ============================================================================
  // Build Methods
  // ============================================================================

  Widget _buildField(FormItemConfig item, int index) {
    switch (item.type) {
      case FormFieldType.password:
        return _buildPasswordField(item);
      case FormFieldType.checkbox:
      case FormFieldType.switcher:
        return _buildBoolField(item);
      case FormFieldType.dropdown:
        return _buildDropdownField(item);
      case FormFieldType.country:
        return _buildCountryField(item);
      case FormFieldType.number:
        return _buildNumberField(item);
      case FormFieldType.text:
      case FormFieldType.email:
      case FormFieldType.url:
      case FormFieldType.phone:
        return _buildTextField(item);
      case FormFieldType.textarea:
        return _buildTextareaField(item);
      case FormFieldType.date:
        return _buildDateField(item);
      case FormFieldType.datetime:
        return _buildDateTimeField(item);
      case FormFieldType.image:
        return _buildImageField(item);
      case FormFieldType.custom:
        return item.customWidget ?? const SizedBox.shrink();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildTextField(FormItemConfig item) {
    return FormFieldHelper.withPadding(
      MyTextFormField(
        maxLength: item.maxLength,
        label: item.hintText ?? item.label,
        hint: item.hintText,
        controller: _controllers[item.id],
        focusNode: _focusNodes[item.id],
        icon: FormFieldHelper.iconOrNull(item.icon),
        autofillHints: item.autofillHints,
        validator: FormFieldHelper.toValidatorFunction(context, item.validator),
        maxLines: item.maxLines,
        isRequired: item.isRequired,
        enabled: item.enabled,
        onFieldSubmitted: (_) => _focusNextFieldOrSubmit(item.id),
        onChanged: widget.enableAutoValidation ? _onFieldChanged : null,
      ),
      spacing: widget.spacing,
    );
  }

  Widget _buildTextareaField(FormItemConfig item) {
    return FormFieldHelper.withPadding(
      MyTextFormField(
        width: 600,
        maxLength: item.maxLength,
        label: item.hintText ?? item.label,
        hint: item.hintText,
        controller: _controllers[item.id],
        focusNode: _focusNodes[item.id],
        icon: FormFieldHelper.iconOrNull(item.icon),
        validator: FormFieldHelper.toValidatorFunction(context, item.validator),
        maxLines: item.maxLines,
        isRequired: item.isRequired,
        enabled: item.enabled,
        onChanged: widget.enableAutoValidation ? _onFieldChanged : null,
      ),
      spacing: widget.spacing,
    );
  }

  Widget _buildNumberField(FormItemConfig item) {
    return FormFieldHelper.withPadding(
      MyTextFormField(
        label: item.hintText ?? item.label,
        hint: item.hintText,
        controller: _controllers[item.id],
        focusNode: _focusNodes[item.id],
        sufIcon: IconButton(
          onPressed: () => _incrementNumber(item.id),
          icon: const Icon(Icons.add),
        ),
        preIcon: IconButton(
          onPressed: () => _decrementNumber(item.id),
          icon: const Icon(Icons.remove),
        ),
        icon: FormFieldHelper.iconOrNull(item.icon),
        autofillHints: item.autofillHints,
        validator: FormFieldHelper.toValidatorFunction(context, item.validator),
        keyboardType: TextInputType.number,
        isRequired: item.isRequired,
        enabled: item.enabled,
        onFieldSubmitted: (_) => _focusNextFieldOrSubmit(item.id),
        onChanged: widget.enableAutoValidation ? _onFieldChanged : null,
      ),
      spacing: widget.spacing,
    );
  }

  void _incrementNumber(String id) {
    final controller = _controllers[id];
    if (controller != null) {
      final currentValue = int.tryParse(controller.text) ?? 0;
      controller.text = (currentValue + 1).toString();
    }
  }

  void _decrementNumber(String id) {
    final controller = _controllers[id];
    if (controller != null) {
      final currentValue = int.tryParse(controller.text) ?? 0;
      controller.text = (currentValue - 1).toString();
    }
  }

  Widget _buildPasswordField(FormItemConfig item) {
    final controller = _controllers[item.id];
    final focusNode = _focusNodes[item.id];

    if (controller == null) {
      AppLogger.error(
        'Password controller not found for ${item.id}',
        tag: 'MyForm',
      );
      return const SizedBox.shrink();
    }

    return FormFieldHelper.withPadding(
      MyPasswordField(
        icon: FormFieldHelper.iconOrNull(item.icon),
        controller: controller,
        focusNode: focusNode,
        onFieldSubmitted: (_) => _focusNextFieldOrSubmit(item.id),
      ),
      spacing: widget.spacing,
    );
  }

  Widget _buildBoolField(FormItemConfig item) {
    final notifier = _boolValues[item.id];
    if (notifier == null) {
      AppLogger.error('Bool notifier not found for ${item.id}', tag: 'MyForm');
      return const SizedBox.shrink();
    }

    return FormFieldHelper.withPadding(
      ValueListenableBuilder<bool>(
        valueListenable: notifier,
        builder: (context, value, child) {
          if (item.type == FormFieldType.checkbox) {
            return MyCheckbox(
              label: item.hintText ?? item.label,
              value: value,
              onChanged: item.enabled
                  ? (newValue) => notifier.value = newValue
                  : (_) {},
            );
          } else {
            return MySwitcher(
              title: item.label,
              value: value,
              onChanged: item.enabled
                  ? (newValue) => notifier.value = newValue
                  : (_) {},
            );
          }
        },
      ),
      spacing: widget.spacing,
    );
  }

  Widget _buildDropdownField(FormItemConfig item) {
    final currentValue = _otherValues[item.id] ?? item.defaultValue;

    // OPTIMIZACIÓN: Pre-construir items solo una vez si no cambian frecuentemente
    // Los items podrían ser memoizados si son estáticos
    return FormFieldHelper.withPadding(
      MyDropdown(
        title: item.label,
        hintText: item.hintText ?? LocaleKeys.selectOption,
        value: currentValue,
        items: [
          for (final option in item.options ?? [])
            DropdownMenuItem<String>(
              value: option,
              child: MyText(option, selectable: false),
            ),
        ],
        onChanged: item.enabled
            ? (value) {
                setState(() => _otherValues[item.id] = value);
                // Notificar cambios si hay listener
                _onAnyFieldChanged();
              }
            : null,
        icon: item.icon ?? Icons.arrow_drop_down,
        borderRadius: 8,
        elevation: 2,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        margin: EdgeInsets.zero,
      ),
      spacing: widget.spacing,
    );
  }

  Widget _buildCountryField(FormItemConfig item) {
    final currentValue = _otherValues[item.id] ?? item.defaultValue;

    return FormFieldHelper.withPadding(
      MyCountryDropdown(
        title: item.label,
        selectedCountryCode: currentValue?.toString(),
        onChanged: item.enabled
            ? (value) => setState(() => _otherValues[item.id] = value)
            : null,
      ),
      spacing: widget.spacing,
    );
  }

  Widget _buildDateField(FormItemConfig item) {
    return Container(
      padding: EdgeInsets.all(12),
      width: 380,
      child: FormFieldHelper.withPadding(
        InkWell(
          onTap: item.enabled ? () => _selectDate(item) : null,
          child: InputDecorator(
            decoration: InputDecoration(
              labelText: context.tr(item.hintText ?? item.label),
              border: const OutlineInputBorder(),
              suffixIcon: Icon(item.icon ?? Icons.calendar_today),
            ),
            child: MyText(
              _otherValues[item.id] != null
                  ? FormFieldHelper.formatDate(
                      _otherValues[item.id] as DateTime,
                    )
                  : context.tr(LocaleKeys.selectDate),
              selectable: false,
            ),
          ),
        ),
        spacing: widget.spacing,
      ),
    );
  }

  Future<void> _selectDate(FormItemConfig item) async {
    final date = await showDatePicker(
      context: context,
      initialDate: _otherValues[item.id] as DateTime? ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
    );

    if (date != null) {
      setState(() => _otherValues[item.id] = date);
    }
  }

  Widget _buildDateTimeField(FormItemConfig item) {
    return Container(
      padding: const EdgeInsets.all(12),
      width: 380,
      child: FormFieldHelper.withPadding(
        InkWell(
          onTap: item.enabled ? () => _selectDateTime(item) : null,
          child: InputDecorator(
            decoration: InputDecoration(
              labelText: context.tr(item.hintText ?? item.label),
              border: const OutlineInputBorder(),
              suffixIcon: Icon(item.icon ?? Icons.event),
            ),
            child: MyText(
              _otherValues[item.id] != null
                  ? FormFieldHelper.formatDateTime(
                      _otherValues[item.id] as DateTime,
                    )
                  : context.tr(LocaleKeys.selectDateTime),
              selectable: false,
            ),
          ),
        ),
        spacing: widget.spacing,
      ),
    );
  }

  Future<void> _selectDateTime(FormItemConfig item) async {
    final currentValue = _otherValues[item.id] as DateTime? ?? DateTime.now();

    // First, select date
    final date = await showDatePicker(
      context: context,
      initialDate: currentValue,
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
    );

    if (date == null) return;

    // Then, select time
    if (!mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(currentValue),
    );

    if (time != null) {
      final dateTime = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
      setState(() => _otherValues[item.id] = dateTime);
    }
  }

  Widget _buildImageField(FormItemConfig item) {
    final metadata = item.metadata ?? {};
    final width = (metadata['width'] as num?)?.toDouble() ?? 300.0;
    final height = (metadata['height'] as num?)?.toDouble() ?? 200.0;
    final allowedExtensions =
        (metadata['allowedExtensions'] as List<dynamic>?)?.cast<String>() ??
        const ['jpg', 'jpeg', 'png', 'gif', 'webp'];
    final maxSizeBytes = (metadata['maxSizeBytes'] as int?) ?? 10 * 1024 * 1024;
    final maxImageDimension =
        (metadata['maxImageDimension'] as num?)?.toDouble() ?? 1920.0;
    final imageQuality = (metadata['imageQuality'] as int?) ?? 85;
    final showDeleteButton = (metadata['showDeleteButton'] as bool?) ?? true;

    // Get initial URL from defaultValue or initialData
    final initialUrl =
        _otherValues[item.id]?.toString() ?? item.defaultValue?.toString();

    return FormFieldHelper.withPadding(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (item.label.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: MyText(
                item.label,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ImagePickerWidget(
            width: width,
            height: height,
            initialImageUrl: initialUrl,
            allowedExtensions: allowedExtensions,
            maxSizeBytes: maxSizeBytes,
            maxImageDimension: maxImageDimension,
            imageQuality: imageQuality,
            showDeleteButton: showDeleteButton,
            placeholderText: item.hintText,
            onImageSelected: (File? file) {
              setState(() {
                if (file != null) {
                  // Store the file path for mobile
                  _otherValues[item.id] = file.path;
                } else if (!kIsWeb) {
                  _otherValues[item.id] = null;
                }
              });
              _onAnyFieldChanged();
            },
            onImageSelectedWeb: (Uint8List? bytes) {
              setState(() {
                if (bytes != null) {
                  // Store the bytes for web (as base64 or keep reference)
                  _otherValues['${item.id}_bytes'] = bytes;
                  _otherValues[item.id] = 'web_image_selected';
                } else {
                  _otherValues['${item.id}_bytes'] = null;
                  _otherValues[item.id] = null;
                }
              });
              _onAnyFieldChanged();
            },
          ),
          // Show validation error if required and no image
          if (item.isRequired && _otherValues[item.id] == null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: MyText(
                LocaleKeys.fieldRequired,
                color: Theme.of(context).colorScheme.error,
                fontSize: 12,
              ),
            ),
        ],
      ),
      spacing: widget.spacing,
    );
  }

  ////
  ////// BUILD PRINCIPAL
  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        // padding: widget.padding,
        //  shrinkWrap: true,
        //   physics: const ClampingScrollPhysics(),
        children: [
          // Título
          if (widget.showTitle && widget.title != null)
            MyText(
              widget.title!,
              fontSize: 24,
              margin: 12,
              istitle: true,
           
            ),

          // Header widget personalizado
          if (widget.headerWidget != null) widget.headerWidget!,

          // Campos del formulario
          ...List.generate(
            widget.formItems.length,
            (index) => _buildField(widget.formItems[index], index),
          ),

          const SizedBox(height: 8),

          // Footer widget personalizado
          if (widget.footerWidget != null) widget.footerWidget!,
          AnimatedPrimaryButton(
            width: 300,
            isLoading: widget.isLoading,
            onPressed: widget.isLoading ? null : _handleSubmit,
            child: MyText(_buttonLabel, selectable: false),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    AppLogger.debug('Disposing MyForm resources', tag: 'MyForm');

    _validationDebounceTimer?.cancel();

    for (final controller in _controllers.values) {
      controller.dispose();
    }
    for (final notifier in _boolValues.values) {
      notifier.dispose();
    }
    for (final focusNode in _focusNodes.values) {
      focusNode.dispose();
    }

    super.dispose();
  }
}
