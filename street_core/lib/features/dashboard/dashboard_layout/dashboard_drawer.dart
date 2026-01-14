import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:street_core/core/router/navigation_service.dart';
import 'package:street_core/core/widgets/drawer/drawer_config.dart';
import 'package:street_core/features/auth/auth.dart';
import 'package:street_core/features/settings/settings_routes_config.dart';

import '../../../core/lang/locale_keys.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/theme_selector_compact.dart';
import '../../../core/widgets/drawer/drawer_item.dart';
import '../../../core/widgets/my_text.dart';

class DashboardDrawer {
  // Definimos los elementos fijos como una lista privada y constante
  static List<DrawerItem> baseElements = [
    DrawerItem(
      icon: Icons.dashboard,
      labelKey: 'dashboard',
      route: AppRoutes.dashboard,
    ),
  ];

  /// Configura el Drawer inyectando las acciones que dependen del contexto
  static void setup(BuildContext context) {
    // Creamos una nueva lista combinando el logout con los elementos base
    // Esto evita duplicados y mutaciones accidentales
    final fullMenu = [
      ...baseElements,
      DrawerItem(isDivider: true),
      DrawerItem(
        labelKey: 'settings',
        route: SettingsRoutes.settings,
        icon: Icons.settings,
      ),
      DrawerItem(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [MyText(LocaleKeys.theme), const CompactThemeSelector()],
          ),
        ),
      ),
      DrawerItem(isDivider: true),
      _buildLogoutItem(context),
    ];

    DrawerConfig.drawerElements = fullMenu;
  }

  static DrawerItem _buildLogoutItem(BuildContext context) {
    return DrawerItem(
      icon: Icons.logout,
      labelKey: LocaleKeys.logOut,

      onTap: () async {
        await context.read<AuthCubit>().logout();
        // Usamos context directamente si NavigationService lo permite
        NavigationService().go(context, AppRoutes.home);
      },
    );
  }
}
