import 'package:flutter/material.dart' hide FormFieldValidator;
import 'package:flutter/services.dart';

import '../helpers/validators.dart';
import '../lang/context_tr.dart';
import '../theme/app_spacing.dart';

class MyTextFormField extends StatefulWidget {
  const MyTextFormField({
    super.key,
    // Core
    this.controller,
    required this.label,
    this.hint,
    // Input configuration
    this.obscureText,
    this.keyboardType,
    this.textInputAction,
    this.maxLines = 1,
    this.maxLength = 255,
    this.inputFormatters,
    this.autofillHints,
    // Validation
    this.validator,
    this.autoValidator,
    this.errorText,
    this.helperText,
    this.isRequired,
    this.showValidationIcon = true,
    // Callbacks
    this.onChanged,
    this.onFieldSubmitted,
    // Visual
    this.sufIcon,
    this.icon,
    this.preIcon,
    // Dimensions
    this.width = 400,
    this.height,
    this.margin,
    // State
    this.focusNode,
    this.autofocus,
    this.enabled,
  });

  final TextEditingController? controller;

  final String label;

  final String? hint;

  final bool? obscureText;

  /// ```
  final TextInputType? keyboardType;

  /// ```
  final TextInputAction? textInputAction;

  /// ```
  final int maxLines;

  final int? maxLength;

  final List<TextInputFormatter>? inputFormatters;

  final List<String>? autofillHints;

  final FormFieldValidator<String>? validator;

  final String? autoValidator;

  /// ```
  final String? errorText;
  final String? helperText;
  final bool? isRequired;

  final bool showValidationIcon;

  final void Function(String)? onChanged;

  final Function(String)? onFieldSubmitted;

  final Widget? sufIcon;

  final Widget? icon;

  final Widget? preIcon;

  final double? width;

  final double? height;

  final double? margin;

  final FocusNode? focusNode;

  final bool? autofocus;

  final bool? enabled;

  @override
  State<MyTextFormField> createState() => _MyTextFormFieldState();
}

class _MyTextFormFieldState extends State<MyTextFormField> {
  bool _isFocused = false;
  bool _isHovered = false;
  String? _currentError;

  @override
  Widget build(BuildContext context) {
    // OPTIMIZACIÓN: Extraer Theme una sola vez
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Determinar estados visuales
    final hasError = _currentError != null || widget.errorText != null;
    final isDisabled = widget.enabled == false;
    final hasText = widget.controller?.text.isNotEmpty ?? false;
    final isValid = hasText && !hasError && _isFocused;

    // OPTIMIZACIÓN: Memoizar valores efectivos
    final effectiveMargin = widget.margin ?? AppSpacing.sm;

    // Suffix icon con validación visual mejorada y animación
    Widget? effectiveSuffixIcon = widget.sufIcon;
    if (widget.showValidationIcon && isValid && widget.sufIcon == null) {
      effectiveSuffixIcon = TweenAnimationBuilder<double>(
        duration: AppDuration.fast,
        tween: Tween(begin: 0.0, end: 1.0),
        curve: Curves.easeOutBack,
        builder: (context, value, child) {
          return Transform.scale(
            scale: value,
            child: Icon(
              Icons.check_circle,
              color: colorScheme.tertiary,
              size: AppIconSize.sm,
            ),
          );
        },
      );
    }

    // Fill color con transición animada y soporte hover
    final fillColor = isDisabled
        ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.12)
        : _isFocused
        ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.5)
        : _isHovered
        ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.4)
        : colorScheme.surfaceContainerHighest.withValues(alpha: 0.3);

    // Border color con transición animada y soporte hover
    final enabledBorderColor = _isHovered
        ? colorScheme.outline.withValues(alpha: 0.5)
        : colorScheme.outline.withValues(alpha: 0.3);

    // OPTIMIZACIÓN: Construir InputDecoration una sola vez
    final standardDecoration = InputDecoration(
      labelText: context.tr(widget.label),
      hintText: widget.hint != null ? context.tr(widget.hint!) : null,
      suffixIcon: effectiveSuffixIcon,
      icon: widget.icon,
      prefixIcon: widget.preIcon,
      errorText:
          _currentError ??
          (widget.errorText != null ? context.tr(widget.errorText!) : null),
      helperText: widget.helperText != null
          ? context.tr(widget.helperText!)
          : null,
      filled: true,
      fillColor: fillColor,
      // Label style con animación de color
      labelStyle: TextStyle(
        color: hasError
            ? colorScheme.error
            : _isFocused
            ? colorScheme.primary
            : colorScheme.onSurfaceVariant,
      ),
      floatingLabelStyle: TextStyle(
        color: hasError ? colorScheme.error : colorScheme.primary,
        fontWeight: FontWeight.w500,
      ),
      // Estilos de hint
      hintStyle: TextStyle(
        color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
      ),
      // Helper text style
      helperStyle: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 12),
      // Error style
      errorStyle: TextStyle(color: colorScheme.error, fontSize: 12),
      // Borders - Usando AppRadius.inputRadius consistentemente
      border: const OutlineInputBorder(
        borderRadius: AppRadius.inputRadius,
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: AppRadius.inputRadius,
        borderSide: BorderSide(color: enabledBorderColor, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: AppRadius.inputRadius,
        borderSide: BorderSide(color: colorScheme.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: AppRadius.inputRadius,
        borderSide: BorderSide(color: colorScheme.error, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: AppRadius.inputRadius,
        borderSide: BorderSide(color: colorScheme.error, width: 2),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: AppRadius.inputRadius,
        borderSide: BorderSide(
          color: colorScheme.onSurface.withValues(alpha: 0.12),
          width: 1,
        ),
      ),
      // Content padding usando AppSpacing
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
      ),
      // Icon color
      prefixIconColor: isDisabled
          ? colorScheme.onSurface.withValues(alpha: 0.38)
          : colorScheme.onSurfaceVariant,
      suffixIconColor: isDisabled
          ? colorScheme.onSurface.withValues(alpha: 0.38)
          : colorScheme.onSurfaceVariant,
    );

    // Preparar el label de accesibilidad
    final String semanticLabel = widget.label;
    final String? semanticHint = widget.hint;
    final String semanticValue = hasText ? 'Tiene texto' : 'Vacío';

    return Semantics(
      label: semanticLabel,
      hint: semanticHint,
      value: semanticValue,
      enabled: !isDisabled,
      textField: true,
      focusable: !isDisabled,
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: AnimatedContainer(
          duration: AppDuration.fast,
          curve: Curves.easeInOutCubic,
          margin: EdgeInsets.all(effectiveMargin),
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          width: widget.width,
          height: widget.height,
          child: Focus(
            onFocusChange: (hasFocus) {
              setState(() {
                _isFocused = hasFocus;
              });
            },
            child: TextFormField(
              maxLength: widget.maxLength,
              inputFormatters: widget.inputFormatters,
              textInputAction: widget.textInputAction,
              autofocus: widget.autofocus ?? false,
              enabled: widget.enabled ?? true,
              focusNode: widget.focusNode,
              controller: widget.controller,
              obscureText: widget.obscureText ?? false,
              validator: (value) {
                final error = widget.autoValidator != null
                    ? _autoValidator(context, value)
                    : (widget.validator != null
                          ? widget.validator!(value)
                          : null);

                // Actualizar error state después del frame actual
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) {
                    setState(() {
                      _currentError = error;
                    });
                  }
                });

                return error;
              },
              keyboardType: widget.keyboardType,
              onChanged: widget.onChanged,
              onFieldSubmitted: widget.onFieldSubmitted,
              maxLines: widget.maxLines,
              autofillHints: widget.autofillHints,
              decoration: standardDecoration,
              // Estilo del texto
              style: TextStyle(
                color: isDisabled
                    ? colorScheme.onSurface.withValues(alpha: 0.38)
                    : colorScheme.onSurface,
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Auto-validator using unified validation system
  ///
  /// Supports string-based validator names like 'email', 'password:6', etc.
  /// See ValidatorFactory documentation for all supported formats.
  String? _autoValidator(BuildContext context, String? value) {
    final validator = widget.autoValidator;
    if (validator == null) return null;

    // Use unified ValidatorFactory (no fallback needed)
    final validatorFn = ValidatorFactory.create(context, validator);
    if (validatorFn != null) {
      return validatorFn(value);
    }

    // Unknown validator - log warning in debug mode
    assert(() {
      debugPrint(
        'Warning: Unknown validator "$validator" in MyTextFormField. '
        'See ValidatorFactory.create() for supported formats.',
      );
      return true;
    }());

    return null;
  }
}
