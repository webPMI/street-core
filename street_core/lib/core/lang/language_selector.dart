// Widget de ejemplo (colócalo en SettingsPage o ProfilePage)
import '/core/lang/bloc/locale_cubit.dart';
import '/core/lang/bloc/locale_state.dart';
import '../widgets/my_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'locale_keys.dart';

class LanguageSelector extends StatelessWidget {
  const LanguageSelector({super.key});

  // 💡 Mapeo de Locale a un nombre legible en ese idioma
  String getLanguageName(Locale locale) {
    switch (locale.languageCode) {
      /*       case 'en':
        return 'English'; */
      case 'es':
        return 'Spanish';
      // Agrega más idiomas aquí si es necesario
      default:
        return locale.languageCode;
    }
  }

  @override
  Widget build(BuildContext context) {
    final localeCubit = context.read<LocaleBloc>();

    return BlocBuilder<LocaleBloc, LocaleState>(
      builder: (context, state) {
        return ListTile(
          leading: const Icon(Icons.language),
          title: const MyText(LocaleKeys.selectLanguage, selectable: false),
          trailing: DropdownButton<Locale>(
            value: state.locale,
            onChanged: (Locale? newLocale) {
              if (newLocale != null) {
                localeCubit.setLocale(newLocale);
              }
            },
            items: localeCubit.supportedLocales.map((Locale locale) {
              return DropdownMenuItem<Locale>(
                value: locale,
                child: MyText(getLanguageName(locale), selectable: false),
              );
            }).toList(),
          ),
        );
      },
    );
  }
}
