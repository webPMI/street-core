// ============================================================================
// Versión compacta del selector (si prefieres algo más simple)
// ============================================================================
import '/core/lang/context_tr.dart';
import '/core/theme/app_theme.dart';
import '/core/theme/bloc/theme_cubit.dart';
import '/core/theme/bloc/theme_state.dart';
import '../widgets/my_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../lang/locale_keys.dart';

class CompactThemeSelector extends StatelessWidget {
  const CompactThemeSelector({super.key});

  @override
  Widget build(BuildContext context) {
    final themeCubit = context.read<ThemeCubit>();

    return BlocBuilder<ThemeCubit, ThemeState>(
      builder: (context, state) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Botón para cambiar tema
            IconButton(
              tooltip: context.tr(LocaleKeys.changeTheme),
              icon: const Icon(Icons.color_lens),
              onPressed: () {
                _showThemeDialog(context, themeCubit, state.themeName);
              },
            ),
            // Switch para Light/Dark
            Tooltip(
              message: context.tr(
                themeCubit.isDarkMode ? LocaleKeys.lightMode : LocaleKeys.darkMode,
              ),
              child: Switch(
                value: themeCubit.isDarkMode,
                onChanged: (bool value) {
                  themeCubit.toggleMode();
                },
              ),
            ),
          ],
        );
      },
    );
  }

  void _showThemeDialog(
    BuildContext context,
    ThemeCubit themeCubit,
    String currentTheme,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const MyText(LocaleKeys.selectTheme),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView(
              shrinkWrap: true,
              children: AppTheme.allThemes.keys.map((themeName) {
                final isSelected = currentTheme == themeName;
                return ListTile(
                  leading: Icon(
                    themeName.contains('Light')
                        ? Icons.wb_sunny
                        : Icons.nightlight_round,
                  ),
                  title: MyText(themeName, textAlign: TextAlign.start),
                  trailing: isSelected ? const Icon(Icons.check) : null,
                  selected: isSelected,
                  onTap: () {
                    themeCubit.setTheme(themeName);
                    Navigator.of(context).pop();
                  },
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }
}
