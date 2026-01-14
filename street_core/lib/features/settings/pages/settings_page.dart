import 'package:street_core/core/widgets/drawer/my_drawer.dart';

import '../../../core/di/injection.dart';
import '../../../core/helpers/responsive/responsive_builder.dart';
import '../../../core/lang/locale_keys.dart';
import '../../../core/lang/language_selector.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/services/app_info_service.dart';
import '../../../core/theme/theme_selector.dart';
import '../../../core/widgets/my_text.dart';
import '../../auth/auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../profile/profile_routes.dart';
import '../settings_routes_config.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.settings),
            const SizedBox(width: 8),
            MyText(LocaleKeys.settings),
          ],
        ),
      ),
      drawer: MyDrawer(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            _buildHeader(context, theme),
            const SizedBox(height: 20),

            // Settings Layout
            ResponsiveBuilder(
              mobile: (context, device) => _buildMobileLayout(context, theme),
              tablet: (context, device) => _buildTabletLayout(context, theme),
              desktop: (context, device) => _buildDesktopLayout(context, theme),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.settings,
                size: 32,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  MyText(LocaleKeys.settingsNav, istitle: true,),
                  const SizedBox(height: 4),
                  MyText(
                    LocaleKeys.customizeYourExperience,
                    color: theme.colorScheme.onSurfaceVariant,
                    selectable: false,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopLayout(BuildContext context, ThemeData theme) {
    // In Desktop, we can show 3 columns: Account, App Prefs, Support/Admin
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            children: [
              _buildSection(
                context,
                theme,
                title: LocaleKeys.account,
                icon: Icons.security,
                color: Colors.blue,
                child: _buildAccountContent(context),
              ),
            ],
          ),
        ),
        const SizedBox(width: 24),
        Expanded(
          child: Column(
            children: [
              _buildSection(
                context,
                theme,
                title: LocaleKeys.preferences,
                icon: Icons.tune,
                color: Colors.purple,
                child: _buildPreferencesContent(context, theme),
              ),
            ],
          ),
        ),
        const SizedBox(width: 24),
        Expanded(
          child: Column(
            children: [
              _buildSection(
                context,
                theme,
                title: LocaleKeys.support,
                icon: Icons.help_outline,
                color: Colors.teal,
                child: _buildSupportContent(context),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTabletLayout(BuildContext context, ThemeData theme) {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          Expanded(
            child: _buildSection(
              context,
              theme,
              title: LocaleKeys.account,
              icon: Icons.security,
              color: Colors.blue,
              child: _buildAccountContent(context),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildSection(
              context,
              theme,
              title: LocaleKeys.preferences,
              icon: Icons.tune,
              color: Colors.purple,
              child: _buildPreferencesContent(context, theme),
            ),
          ),
          ],
        ),
        const SizedBox(height: 16),
        _buildSection(
          context,
          theme,
          title: LocaleKeys.support,
          icon: Icons.help_outline,
          color: Colors.teal,
          child: _buildSupportContent(context),
        ),
      ],
    );
  }

  Widget _buildMobileLayout(BuildContext context, ThemeData theme) {
    return Column(
      children: [
        _buildSection(
          context,
          theme,
          title: LocaleKeys.account,
          icon: Icons.security,
          color: Colors.blue,
          child: _buildAccountContent(context),
        ),
        const SizedBox(height: 16),
        _buildSection(
          context,
          theme,
          title: LocaleKeys.preferences,
          icon: Icons.tune,
          color: Colors.purple,
          child: _buildPreferencesContent(context, theme),
        ),
        const SizedBox(height: 16),
        _buildSection(
          context,
          theme,
          title: LocaleKeys.support,
          icon: Icons.help_outline,
          color: Colors.teal,
          child: _buildSupportContent(context),
        ),
      ],
    );
  }

  Widget _buildSection(
    BuildContext context,
    ThemeData theme, {
    required String title,
    required IconData icon,
    required Color color,
    required Widget child,
  }) {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Icon(icon, color: color),
                const SizedBox(width: 12),
                MyText(title,),
              ],
            ),
          ),
          Padding(padding: const EdgeInsets.all(16), child: child),
        ],
      ),
    );
  }

  // --- CONTENT BUILDERS ---

  Widget _buildAccountContent(BuildContext context) {
    return Column(
      children: [
        _buildItem(
          context,
          icon: Icons.person_outline,
          title: LocaleKeys.editProfile,
          onTap: () => context.push(ProfileRoutes.profileEdit),
        ),
        const Divider(),
        _buildItem(
          context,
          icon: Icons.vpn_key,
          title: LocaleKeys.changePassword,
          onTap: () => context.push(ProfileRoutes.changePassword),
        ),
        const Divider(),
        _buildItem(
          context,
          icon: Icons.lock,
          title: LocaleKeys.privacySettings,
          onTap: () => context.push(SettingsRoutes.privacy),
        ),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.delete_forever, color: Colors.red),
          title: MyText(
            LocaleKeys.deleteAccount,
            selectable: false,
            style: const TextStyle(color: Colors.red),
          ),
          onTap: () {
            _showDeleteConfirmation(context);
          },
        ),
      ],
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: MyText(LocaleKeys.deleteAccount),
        content: MyText(LocaleKeys.deleteAccountConfirmation),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: MyText(LocaleKeys.cancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              _performDelete(context);
            },
            child: MyText(LocaleKeys.delete, style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _performDelete(BuildContext context) {
    // Call Cubit
    context.read<AuthCubit>().deleteAccount();
  }

  Widget _buildPreferencesContent(BuildContext context, ThemeData theme) {
    return Column(
      children: [
        const ThemeSelector(),
        const SizedBox(height: 16),
        const LanguageSelector(),
        const SizedBox(height: 16),
        const Divider(),
        _buildItem(
          context,
          icon: Icons.notifications,
          title: LocaleKeys.notifications,
          onTap: () => context.push(SettingsRoutes.notifications),
        ),
        const Divider(),
        _buildItem(
          context,
          icon: Icons.data_usage,
          title: LocaleKeys.dataUsage,
          onTap: () => context.push(SettingsRoutes.data),
        ),
      ],
    );
  }

  Widget _buildSupportContent(BuildContext context) {
    return Column(
      children: [
        _buildItem(
          context,
          icon: Icons.help,
          title: LocaleKeys.helpCenter,
          onTap: () => context.push(SettingsRoutes.help),
        ),
        const Divider(),
        _buildItem(
          context,
          icon: Icons.description_outlined,
          title: LocaleKeys.termsOfService,
          onTap: () => Navigator.pushNamed(context, AppRoutes.termsOfService),
        ),
        const Divider(),
        _buildItem(
          context,
          icon: Icons.privacy_tip_outlined,
          title: LocaleKeys.privacyPolicy,
          onTap: () => Navigator.pushNamed(context, AppRoutes.privacyPolicy),
        ),
        const Divider(),
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: Center(
            child: MyText(
              LocaleKeys.appVersion,
              args: {'version': getIt<AppInfoService>().getVersionString()},
              style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: theme.colorScheme.primary, size: 20),
      ),
      title: MyText(title, selectable: false),
      trailing: const Icon(Icons.chevron_right, size: 20),
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
    );
  }
}
