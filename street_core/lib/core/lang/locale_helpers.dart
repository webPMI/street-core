import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'context_tr.dart';
import 'locale_keys.dart';

/// Locale Helpers - Utilidades para formateo y localización
///
/// Proporciona funciones helper para:
/// - Formateo de fechas y horas
/// - Pluralización
/// - Formateo de números y monedas
/// - Tiempo relativo (time ago)
///
/// Diseñado para ser escalable y soportar múltiples idiomas.
/// Todas las funciones respetan el locale actual del contexto.
class LocaleHelpers {
  LocaleHelpers._(); // Constructor privado - clase de utilidades estáticas

  // ============================================================================
  // FORMATEO DE FECHAS Y HORAS
  // ============================================================================

  /// Formatea una fecha en formato corto según el locale
  /// Ejemplo: "06/01/2026" (es), "1/6/2026" (en)
  static String formatDate(DateTime date, BuildContext context) {
    final locale = Localizations.localeOf(context);
    return DateFormat.yMd(locale.toString()).format(date);
  }

  /// Formatea una fecha en formato largo según el locale
  /// Ejemplo: "6 de enero de 2026" (es), "January 6, 2026" (en)
  static String formatDateLong(DateTime date, BuildContext context) {
    final locale = Localizations.localeOf(context);
    return DateFormat.yMMMMd(locale.toString()).format(date);
  }

  /// Formatea una fecha y hora según el locale
  /// Ejemplo: "06/01/2026 15:30" (es), "1/6/2026 3:30 PM" (en)
  static String formatDateTime(DateTime date, BuildContext context) {
    final locale = Localizations.localeOf(context);
    return DateFormat.yMd(locale.toString()).add_jm().format(date);
  }

  /// Formatea solo la hora según el locale
  /// Ejemplo: "15:30" (es), "3:30 PM" (en)
  static String formatTime(DateTime date, BuildContext context) {
    final locale = Localizations.localeOf(context);
    return DateFormat.jm(locale.toString()).format(date);
  }

  /// Formatea una fecha relativa (hoy, ayer, mañana)
  /// Si no es ninguna de estas, retorna la fecha formateada
  static String formatDateRelative(DateTime date, BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final tomorrow = today.add(const Duration(days: 1));
    final dateOnly = DateTime(date.year, date.month, date.day);

    if (dateOnly == today) {
      return context.tr(LocaleKeys.today);
    } else if (dateOnly == yesterday) {
      return context.tr(LocaleKeys.yesterday);
    } else if (dateOnly == tomorrow) {
      return context.tr(LocaleKeys.tomorrow);
    } else {
      return formatDate(date, context);
    }
  }

  // ============================================================================
  // TIEMPO RELATIVO (TIME AGO)
  // ============================================================================

  /// Formatea un tiempo relativo (hace 5 minutos, hace 2 horas, etc.)
  /// Soporta: segundos, minutos, horas, días, semanas, meses, años
  static String timeAgo(DateTime date, BuildContext context) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inSeconds < 60) {
      return context.tr(LocaleKeys.justNow);
    } else if (difference.inMinutes < 60) {
      return _formatTimeUnit(
        context,
        LocaleKeys.minutesAgo,
        difference.inMinutes,
      );
    } else if (difference.inHours < 24) {
      return _formatTimeUnit(
        context,
        LocaleKeys.hoursAgo,
        difference.inHours,
      );
    } else if (difference.inDays < 7) {
      return _formatTimeUnit(
        context,
        LocaleKeys.daysAgo,
        difference.inDays,
      );
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return _formatTimeUnit(context, LocaleKeys.weeksAgo, weeks);
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return _formatTimeUnit(context, LocaleKeys.monthsAgo, months);
    } else {
      final years = (difference.inDays / 365).floor();
      return _formatTimeUnit(context, LocaleKeys.yearsAgo, years);
    }
  }

  /// Helper privado para formatear unidades de tiempo con pluralización
  static String _formatTimeUnit(
    BuildContext context,
    String key,
    int count,
  ) {
    return context.tr(key, args: {'count': count.toString()});
  }

  // ============================================================================
  // PLURALIZACIÓN
  // ============================================================================

  /// Pluraliza una palabra según el conteo
  /// Usa las claves {key}.singular y {key}.plural
  ///
  /// Ejemplo:
  /// ```dart
  /// plural(context, 'participant', 1) // "1 participante"
  /// plural(context, 'participant', 5) // "5 participantes"
  /// ```
  static String plural(BuildContext context, String key, int count) {
    final countStr = count.toString();
    if (count == 1) {
      return context.tr('$key.singular', args: {'count': countStr});
    } else {
      return context.tr('$key.plural', args: {'count': countStr});
    }
  }

  /// Pluraliza solo la palabra (sin incluir el número)
  /// Útil cuando quieres controlar el formato del número por separado
  static String pluralWord(BuildContext context, String key, int count) {
    if (count == 1) {
      return context.tr('$key.singular.word');
    } else {
      return context.tr('$key.plural.word');
    }
  }

  // ============================================================================
  // FORMATEO DE NÚMEROS
  // ============================================================================

  /// Formatea un número según el locale
  /// Ejemplo: 1234567.89 -> "1,234,567.89" (en), "1.234.567,89" (es)
  static String formatNumber(num number, BuildContext context) {
    final locale = Localizations.localeOf(context);
    return NumberFormat.decimalPattern(locale.toString()).format(number);
  }

  /// Formatea un número con decimales específicos
  static String formatNumberWithDecimals(
    num number,
    BuildContext context, {
    int decimals = 2,
  }) {
    final locale = Localizations.localeOf(context);
    return NumberFormat.decimalPatternDigits(
      locale: locale.toString(),
      decimalDigits: decimals,
    ).format(number);
  }

  /// Formatea un porcentaje
  /// Ejemplo: 0.1234 -> "12.34%" (en), "12,34%" (es)
  static String formatPercent(num number, BuildContext context) {
    final locale = Localizations.localeOf(context);
    return NumberFormat.percentPattern(locale.toString()).format(number);
  }

  /// Formatea un número compacto (1K, 1M, etc.)
  /// Ejemplo: 1234567 -> "1.2M" (en), "1,2M" (es)
  static String formatNumberCompact(num number, BuildContext context) {
    final locale = Localizations.localeOf(context);
    return NumberFormat.compact(locale: locale.toString()).format(number);
  }

  // ============================================================================
  // FORMATEO DE MONEDAS
  // ============================================================================

  /// Formatea una cantidad como moneda
  /// Ejemplo: 1234.56 -> "$1,234.56" (USD), "1.234,56 €" (EUR)
  static String formatCurrency(
    num amount,
    String currencyCode,
    BuildContext context,
  ) {
    final locale = Localizations.localeOf(context);
    return NumberFormat.currency(
      locale: locale.toString(),
      symbol: _getCurrencySymbol(currencyCode),
      decimalDigits: 2,
    ).format(amount);
  }

  /// Formatea una cantidad como moneda con código ISO
  /// Ejemplo: 1234.56 -> "USD 1,234.56"
  static String formatCurrencyWithCode(
    num amount,
    String currencyCode,
    BuildContext context,
  ) {
    final locale = Localizations.localeOf(context);
    return NumberFormat.currency(
      locale: locale.toString(),
      name: currencyCode,
      symbol: currencyCode,
      decimalDigits: 2,
    ).format(amount);
  }

  /// Obtiene el símbolo de moneda según el código ISO
  static String _getCurrencySymbol(String currencyCode) {
    switch (currencyCode.toUpperCase()) {
      case 'USD':
        return '\$';
      case 'EUR':
        return '€';
      case 'GBP':
        return '£';
      case 'JPY':
        return '¥';
      case 'MXN':
        return '\$';
      case 'ARS':
        return '\$';
      case 'COP':
        return '\$';
      case 'CLP':
        return '\$';
      default:
        return currencyCode; // Fallback al código ISO
    }
  }

  // ============================================================================
  // FORMATEO DE DISTANCIAS Y MEDIDAS
  // ============================================================================

  /// Formatea una distancia en metros a una representación legible
  /// Ejemplo: 1500 -> "1.5 km", 500 -> "500 m"
  static String formatDistance(num meters, BuildContext context) {
    if (meters >= 1000) {
      final km = meters / 1000;
      return context.tr(
        LocaleKeys.distanceKm,
        args: {'distance': formatNumberWithDecimals(km, context, decimals: 1)},
      );
    } else {
      return context.tr(
        LocaleKeys.distanceM,
        args: {'distance': formatNumber(meters, context)},
      );
    }
  }

  /// Formatea un peso en gramos a una representación legible
  /// Ejemplo: 1500 -> "1.5 kg", 500 -> "500 g"
  static String formatWeight(num grams, BuildContext context) {
    if (grams >= 1000) {
      final kg = grams / 1000;
      return context.tr(
        LocaleKeys.weightKg,
        args: {'weight': formatNumberWithDecimals(kg, context, decimals: 1)},
      );
    } else {
      return context.tr(
        LocaleKeys.weightG,
        args: {'weight': formatNumber(grams, context)},
      );
    }
  }

  // ============================================================================
  // UTILIDADES DE LOCALE
  // ============================================================================

  /// Obtiene el código de idioma actual (es, en, fr, etc.)
  static String getCurrentLanguageCode(BuildContext context) {
    return Localizations.localeOf(context).languageCode;
  }

  /// Obtiene el locale completo actual (es_ES, en_US, etc.)
  static Locale getCurrentLocale(BuildContext context) {
    return Localizations.localeOf(context);
  }

  /// Verifica si el idioma actual es RTL (Right-to-Left)
  static bool isRTL(BuildContext context) {
    final languageCode = getCurrentLanguageCode(context);
    return ['ar', 'he', 'fa', 'ur'].contains(languageCode);
  }
}
