// public_mobile_drawer.dart
import '../../lang/locale_keys.dart';
import '../../router/navigation_service.dart';
import '../app_logo.dart';
import '../my_text.dart';
import 'drawer_config.dart';
import 'drawer_item.dart';

import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

class MyDrawer extends StatelessWidget {
  MyDrawer({super.key});

  /// Currently active page (for highlighting)

  /// Navigation service from GetIt
  final NavigationService _navService = GetIt.I<NavigationService>();

  static const double _logoSize = 28;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    String currentLocation = '/';

    currentLocation = GoRouter.of(
      context,
    ).routeInformationProvider.value.uri.toString();

    final elements = DrawerConfig.drawerElements;
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          //---Cabecera del menú con logo y descripción de la app
          _buildHeader(context, theme),

          // Navigation items (using iterator pattern)
          ...elements.map((item) {
            final isActive = currentLocation == item.route;
            return DrawerItem(
              isDivider: item.isDivider,
              route: item.route,
              icon: item.icon,
              labelKey: item.labelKey,
              isActive: isActive,
              onTap: (item.route != null)
                  ? () {
                      Navigator.pop(context);

                      _navService.go(context, item.route!);
                    }
                  : item.onTap,
              child: item.child,
            );
          }),
        ],
      ),
    );
  }

  /// Builds the drawer header with branding
  Widget _buildHeader(BuildContext context, ThemeData theme) {
    return DrawerHeader(
      decoration: BoxDecoration(color: theme.colorScheme.primary),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          //  if (Breakpoints.mobile >= MediaQuery.of(context).size.width)
          AppLogo(
            variant: LogoVariant.vertical,
            color: Theme.of(context).colorScheme.onPrimary,
            animate: true,
            isCompact: true,
            size: _logoSize,
          ),
          const SizedBox(height: 8),
          MyText(
              LocaleKeys.appName,
            color: theme.colorScheme.onPrimary,
            istitle: true,
            selectable: false,
          ),
          const SizedBox(height: 4),
          MyText(
            overflow: TextOverflow.ellipsis,
            LocaleKeys.appDescription,
            color: theme.colorScheme.onPrimary.withValues(alpha: 0.8),
          ),
        ],
      ),
    );
  }

  //-- Muestra el icono del dashboard si se inicio sesion
}
