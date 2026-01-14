// ============================================================================
// theme_selector.dart
// ============================================================================
import '/core/theme/app_theme.dart';
import '/core/theme/bloc/theme_cubit.dart';
import '/core/theme/bloc/theme_state.dart';
import '../widgets/my_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ThemeSelector extends StatelessWidget {
  const ThemeSelector({super.key});

  @override
  Widget build(BuildContext context) {
    final themeCubit = context.read<ThemeCubit>();

    return BlocBuilder<ThemeCubit, ThemeState>(
      builder: (context, state) {
        // Agrupamos los temas por categoría
        final groupedThemes = AppTheme.themeCategories;

        return SingleChildScrollView(
          child: Column(
            children: [
              // Selector principal de tema
              ListTile(
                leading: const Icon(Icons.palette),
                title: const MyText('theme', textAlign: TextAlign.start, selectable: false),
                trailing: DropdownButton<String>(
                  value: state.themeName,
                  onChanged: (String? newTheme) {
                    if (newTheme != null) {
                      themeCubit.setTheme(newTheme);
                    }
                  },
                  items: AppTheme.allThemes.keys.map((String themeName) {
                    return DropdownMenuItem<String>(
                      value: themeName,
                      child: MyText(themeName, selectable: false),
                    );
                  }).toList(),
                ),
              ),

              // Toggle rápido Light/Dark
              ListTile(
                leading: Icon(
                  themeCubit.isDarkMode ? Icons.dark_mode : Icons.light_mode,
                ),
                title: MyText(
                  themeCubit.isDarkMode ? 'dark_mode' : 'light_mode',
                  textAlign: TextAlign.start,
                  selectable: false,
                ),
                trailing: Switch(
                  value: themeCubit.isDarkMode,
                  onChanged: (bool value) {
                    themeCubit.toggleMode();
                  },
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(16),
                child: MyText('available_themes', selectable: false),
              ),

              ...groupedThemes.entries.map((entry) {
                return ExpansionTile(
                  leading: _getThemeIcon(entry.key),
                  title: MyText(entry.key, textAlign: TextAlign.start, selectable: false),
                  children: entry.value.map((themeName) {
                    final isSelected = state.themeName == themeName;
                    return ListTile(
                      leading: Icon(
                        themeName.contains('Light')
                            ? Icons.wb_sunny
                            : Icons.nightlight_round,
                        color: isSelected
                            ? Theme.of(context).colorScheme.primary
                            : null,
                      ),
                      title: MyText(
                        themeName,
                        textAlign: TextAlign.start,
                        selectable: false,
                        color: isSelected
                            ? Theme.of(context).colorScheme.primary
                            : null,
                      ),
                      trailing: isSelected
                          ? Icon(
                              Icons.check_circle,
                              color: Theme.of(context).colorScheme.primary,
                            )
                          : null,
                      selected: isSelected,
                      onTap: () {
                        themeCubit.setTheme(themeName);
                      },
                    );
                  }).toList(),
                );
              }),
            ],
          ),
        );
      },
    );
  }

  Icon _getThemeIcon(String themeName) {
    switch (themeName) {
      case 'Calm':
        return const Icon(Icons.water);
      case 'Warm':
        return const Icon(Icons.wb_twilight);
      case 'Natural':
        return const Icon(Icons.forest);
      case 'Sport':
        return const Icon(Icons.sports_motorsports);
      case 'Business':
        return const Icon(Icons.business_center);
      case 'Energetic':
        return const Icon(Icons.bolt);
      case 'Accessibility':
        return const Icon(Icons.accessibility_new);
      default:
        return const Icon(Icons.palette);
    }
  }
}
