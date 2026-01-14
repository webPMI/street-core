import 'package:flutter/material.dart';
import 'translations/es.dart';

/// Provides translation functionality with parameter substitution.
///
/// Usage examples:
/// - `context.tr(LocaleKeys.keyName)`
/// - `context.tr('welcome.message')`
/// - `context.tr('hello.user', params: {'name': 'John'})`
/// - `Tr.of(locale, 'key.name')`
/// ```
class Tr {
  Tr(this.locale);
  final Locale locale;

  /// Returns the translation map for the current locale
  Map<String, String> get _map {
    switch (locale.languageCode) {
      case 'es':
        return spanish;
      /*       case 'en':
        return english; */
      default:
        return spanish; // Default fallback to English
    }
  }

  /// Translates a key with optional parameter substitution
  /// Placeholders like `{paramName}` in the translation string are replaced.
  /// E.g., `tr('welcome_user', params: {'name': 'John'})`
  /// ```
  String call(String key, {Map<String, String>? params}) {
    if (!_map.containsKey(key)) {
      /*       if (kDebugMode) {
        debugPrint(
          '⚠️ [MISSING TRANSLATION - ${locale.languageCode}] Key: "$key" | Locale: "${locale.languageCode}"',
        );
      } */
      return key;
    }

    var value = _map[key]!;
    if (params != null) {
      params.forEach((k, v) => value = value.replaceAll('{$k}', v));
    }
    return value;
  }

  /// Static method for translation.
  ///
  /// Useful when a [BuildContext] is not available.
  static String of(Locale locale, String key, {Map<String, String>? params}) {
    return Tr(locale).call(key, params: params);
  }
}
