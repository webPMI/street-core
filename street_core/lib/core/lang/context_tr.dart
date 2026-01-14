import 'bloc/locale_cubit.dart'; // Relative path
import 'translation.dart'; // Relative path
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// An extension on [BuildContext] to provide a convenient way to access
/// translation functionality using `context.tr('your_key')`.
extension TranslateX on BuildContext {
  /// Translates a given [key] into the currently selected locale's string.
  ///
  /// [args] can be used to replace placeholders (e.g., `{'name': 'John'}`).
  /// Uses [LocaleBloc] for the current locale and [Tr] for translation.
  String tr(String key, {Map<String, String>? args}) {
    // Get current locale from LocaleCubit state.
    final locale = read<LocaleBloc>().state.locale;
    // Translate using Tr class.
    return Tr(locale).call(key, params: args);
  }
}
