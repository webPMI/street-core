import 'package:flutter/material.dart';
import 'package:street_core/core/theme/theme_selector_compact.dart';
import 'package:street_core/core/widgets/my_text.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/widgets/drawer/drawer_item.dart';
import '../../core/lang/locale_keys.dart';

class PublicDrawer {
  static List<DrawerItem> items = [
    DrawerItem(icon: Icons.home, labelKey: 'home', route: AppRoutes.home),

    DrawerItem(
      icon: Icons.contact_mail,
      labelKey: 'contact',
      route: AppRoutes.contact,
    ),
    DrawerItem(isDivider: true),
    DrawerItem(
      child: ListTile(
        title: MyText(LocaleKeys.theme),
        trailing: CompactThemeSelector(),
      ),
    ),
  ];

  List<DrawerItem> getDrawer() {
    return items;
  }

  //finish here
}
