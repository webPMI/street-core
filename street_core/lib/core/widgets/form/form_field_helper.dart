// form_field_helper.dart
// ============================================================================
// Form Field Helper - Utilities para construcción de campos
// ============================================================================
//
// Helper que elimina código repetido en la construcción de campos de formulario.

import 'package:flutter/material.dart';

/// Helper con utilidades comunes para campos de formulario
class FormFieldHelper {
  /// Padding estándar para campos de formulario
  static const EdgeInsets fieldPadding = EdgeInsets.only(bottom: 12);

  /// Envuelve un widget con el padding estándar de campo
  ///
  /// ```dart
  /// FormFieldHelper.withPadding(
  ///   MyTextField(...),
  ///   spacing: 16, // Opcional, override del padding por defecto
  /// )
  /// ```
  static Widget withPadding(Widget child, {double? spacing}) {
    final padding = spacing != null
        ? EdgeInsets.only(bottom: spacing)
        : fieldPadding;
    return Padding(padding: padding, child: child);
  }

  /// Convierte un Validator a una función de validación para FormField
  ///
  /// ```dart
  /// validator: FormFieldHelper.toValidatorFunction(context, item.validator)
  /// ```
  static String? Function(String?)? toValidatorFunction(
    BuildContext context,
    dynamic validator,
  ) {
    if (validator == null) return null;

    // Si ya es una función, retornarla
    if (validator is String? Function(String?)) {
      return validator;
    }

    // Si es un Validator con método validate
    if (validator.validate != null) {
      return (value) => validator.validate(context, value);
    }

    return null;
  }

  /// Crea un Icon widget desde IconData (helper para evitar null checks repetidos)
  ///
  /// ```dart
  /// icon: FormFieldHelper.iconOrNull(item.icon)
  /// ```
  static Widget? iconOrNull(IconData? iconData) {
    return iconData != null ? Icon(iconData) : null;
  }

  /// Obtiene el TextInputType apropiado para un tipo de campo
  ///
  /// ```dart
  /// keyboardType: FormFieldHelper.getKeyboardType(item.type)
  /// ```
  static TextInputType getKeyboardType(dynamic fieldType) {
    // Para evitar errores, convertir a string y normalizar
    final typeStr = fieldType.toString().toLowerCase();

    if (typeStr.contains('email')) {
      return TextInputType.emailAddress;
    } else if (typeStr.contains('phone')) {
      return TextInputType.phone;
    } else if (typeStr.contains('number')) {
      return TextInputType.number;
    } else if (typeStr.contains('url')) {
      return TextInputType.url;
    } else if (typeStr.contains('multiline')) {
      return TextInputType.multiline;
    }

    return TextInputType.text;
  }

  /// Parse seguro de booleanos desde cualquier tipo
  ///
  /// ```dart
  /// final boolValue = FormFieldHelper.parseBool(value);
  /// ```
  static bool parseBool(dynamic value) {
    if (value == null) return false;
    if (value is bool) return value;
    if (value is String) {
      return value.toLowerCase() == 'true' || value == '1';
    }
    if (value is int) return value != 0;
    return false;
  }

  /// Parse seguro de números desde cualquier tipo
  ///
  /// ```dart
  /// final number = FormFieldHelper.parseNumber(value);
  /// ```
  static num? parseNumber(dynamic value) {
    if (value == null) return null;
    if (value is num) return value;
    if (value is String) {
      return num.tryParse(value);
    }
    return null;
  }

  /// Parse seguro de fechas desde cualquier tipo
  ///
  /// ```dart
  /// final date = FormFieldHelper.parseDate(value);
  /// ```
  static DateTime? parseDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  /// Formatea una fecha en formato dd/MM/yyyy
  ///
  /// ```dart
  /// final formatted = FormFieldHelper.formatDate(date);
  /// ```
  static String formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  /// Formatea una fecha en formato dd/MM/yyyy HH:mm
  ///
  /// ```dart
  /// final formatted = FormFieldHelper.formatDateTime(dateTime);
  /// ```
  static String formatDateTime(DateTime dateTime) {
    return '${formatDate(dateTime)} '
        '${dateTime.hour.toString().padLeft(2, '0')}:'
        '${dateTime.minute.toString().padLeft(2, '0')}';
  }

  /// Valida si un string es un email válido (simple)
  ///
  /// ```dart
  /// if (FormFieldHelper.isValidEmail(email)) { ... }
  /// ```
  static bool isValidEmail(String? email) {
    if (email == null || email.isEmpty) return false;
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(email);
  }

  /// Valida si un string es una URL válida (simple)
  ///
  /// ```dart
  /// if (FormFieldHelper.isValidUrl(url)) { ... }
  /// ```
  static bool isValidUrl(String? url) {
    if (url == null || url.isEmpty) return false;
    try {
      final uri = Uri.parse(url);
      return uri.hasScheme && uri.hasAuthority;
    } catch (e) {
      return false;
    }
  }

  /// Limita el texto a un máximo de caracteres
  ///
  /// ```dart
  /// final limited = FormFieldHelper.limitText(text, 100);
  /// ```
  static String limitText(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}...';
  }

  /// Capitaliza la primera letra de un string
  ///
  /// ```dart
  /// final capitalized = FormFieldHelper.capitalize('hello'); // 'Hello'
  /// ```
  static String capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }

  /// Normaliza un string removiendo espacios y lowercase
  ///
  /// ```dart
  /// final normalized = FormFieldHelper.normalize(' Hello World '); // 'hello world'
  /// ```
  static String normalize(String text) {
    return text.trim().toLowerCase();
  }
}
