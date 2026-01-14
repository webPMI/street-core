import 'package:flutter/material.dart';
import '/core/widgets/drawer/my_drawer.dart';
import '/core/widgets/my_text.dart';
import '/core/widgets/cache_stats_widget.dart';
import '/core/services/cache_service.dart';
import '/core/helpers/responsive/responsive_builder.dart';
import '/core/lang/locale_keys.dart';
import '/core/helpers/snackbar_helper.dart';

class AdminPage extends StatelessWidget {
  const AdminPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      drawer: MyDrawer(),
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.admin_panel_settings),
            const SizedBox(width: 8),
            const MyText(LocaleKeys.adminPage),
          ],
        ),
      ),
      body: ResponsiveBuilder(
        builder: (context, device) {
          return SingleChildScrollView(
            padding: EdgeInsets.all(
              device.value(mobile: 16, tablet: 24, desktop: 32),
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1200),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    MyText(
                      LocaleKeys.systemMonitoring,
                      istitle: true,
                      fontSize: device.value(mobile: 24, tablet: 28, desktop: 32),
                    ),
                    const SizedBox(height: 8),
                    MyText(
                      LocaleKeys.monitorSystemPerformance,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(height: 32),

                    // Cache Statistics Section
                    if (device.isDesktop)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: CacheStatsWidget(
                              cacheService: CacheService.instance,
                              autoRefresh: true,
                              refreshInterval: const Duration(seconds: 5),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: CacheStatsWidget(
                              cacheService: CacheService.instance,
                              compact: true,
                              autoRefresh: true,
                              refreshInterval: const Duration(seconds: 5),
                            ),
                          ),
                        ],
                      )
                    else
                      Column(
                        children: [
                          CacheStatsWidget(
                            cacheService: CacheService.instance,
                            autoRefresh: true,
                            refreshInterval: const Duration(seconds: 5),
                          ),
                          const SizedBox(height: 16),
                          CacheStatsWidget(
                            cacheService: CacheService.instance,
                            compact: true,
                            autoRefresh: true,
                            refreshInterval: const Duration(seconds: 5),
                          ),
                        ],
                      ),

                    const SizedBox(height: 32),

                    // Cache Actions Section
                    _buildCacheActionsCard(context, theme),

                    const SizedBox(height: 32),

                    // Info Section
                    _buildInfoCard(context, theme),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCacheActionsCard(BuildContext context, ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.settings,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 12),
                const MyText(
                  LocaleKeys.cacheActions,
                  istitle: true,
                ),
              ],
            ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    CacheService.instance.clearAll();
                    SnackBarHelper.showSuccess(context, LocaleKeys.cacheClearedSuccessfully);
                  },
                  icon: const Icon(Icons.clear_all),
                  label: const MyText(LocaleKeys.clearAllCache),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    CacheService.instance.cleanupExpired();
                    SnackBarHelper.showSuccess(context, LocaleKeys.expiredEntriesCleanedUp);
                  },
                  icon: const Icon(Icons.cleaning_services),
                  label: const MyText(LocaleKeys.cleanupExpired),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    CacheService.instance.invalidatePattern('site_config_');
                    SnackBarHelper.showSuccess(context, LocaleKeys.siteConfigCacheInvalidated);
                  },
                  icon: const Icon(Icons.refresh),
                  label: const MyText(LocaleKeys.refreshSiteConfig),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context, ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 12),
                const MyText(
                  LocaleKeys.aboutCache,
                  istitle: true,
                ),
              ],
            ),
            const SizedBox(height: 16),
            const MyText(
              LocaleKeys.cacheSystemDescription,
            ),
            const SizedBox(height: 12),
            const MyText(
              LocaleKeys.cacheRecommendations,
              istitle: true,
              fontSize: 14,
            ),
            const SizedBox(height: 8),
            _buildInfoRow(
              icon: Icons.check_circle_outline,
              text: LocaleKeys.hitRateExcellent,
              theme: theme,
            ),
            _buildInfoRow(
              icon: Icons.check_circle_outline,
              text: LocaleKeys.hitRateGood,
              theme: theme,
            ),
            _buildInfoRow(
              icon: Icons.warning_amber,
              text: LocaleKeys.hitRateWarning,
              theme: theme,
            ),
            _buildInfoRow(
              icon: Icons.warning_amber,
              text: LocaleKeys.utilizationWarning,
              theme: theme,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String text,
    required ThemeData theme,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: MyText(
              text,
              fontSize: 13,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
