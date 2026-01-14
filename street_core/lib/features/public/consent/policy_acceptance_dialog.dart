import '../../../core/di/injection.dart';
import '../../../core/helpers/responsive/responsive_builder.dart';
import '../../../core/lang/context_tr.dart';
import '../../../core/lang/locale_keys.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/widgets/my_text.dart';
import '../../../data/models/site_config/site_config_models.dart';
import '../site_config/site_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Dialog para aceptar políticas durante el registro
///
/// Features:
/// - Carga políticas desde el backend (SiteConfigCubit - 24h cache)
/// - Tabs para navegar entre políticas
/// - Botón de aceptar que cierra y retorna true
/// - Enlaces a páginas completas de cada política
class PolicyAcceptanceDialog extends StatelessWidget {
  const PolicyAcceptanceDialog({super.key});

  /// Muestra el diálogo y retorna true si el usuario acepta
  static Future<bool> show(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => BlocProvider<SiteConfigCubit>.value(
        value: getIt<SiteConfigCubit>()..loadLegalTexts(),
        child: const PolicyAcceptanceDialog(),
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveBuilder(
      builder: (context, device) {
        // Tamaño del diálogo según dispositivo
        final dialogWidth = device.value(
          mobile: device.width * 0.95,
          tablet: 600.0,
          desktop: 700.0,
        );
        final dialogHeight = device.value(
          mobile: device.height * 0.85,
          tablet: 500.0,
          desktop: 550.0,
        );

        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: SizedBox(
            width: dialogWidth,
            height: dialogHeight,
            child: const _PolicyDialogContent(),
          ),
        );
      },
    );
  }
}

class _PolicyDialogContent extends StatefulWidget {
  const _PolicyDialogContent();

  @override
  State<_PolicyDialogContent> createState() => _PolicyDialogContentState();
}

class _PolicyDialogContentState extends State<_PolicyDialogContent>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Políticas requeridas para registro
  static const List<_PolicyTab> _requiredPolicies = [
    _PolicyTab(
      key: 'privacy',
      titleKey: LocaleKeys.privacyPolicy,
      icon: Icons.privacy_tip_outlined,
      route: AppRoutes.privacyPolicy,
    ),
    _PolicyTab(
      key: 'terms',
      titleKey: LocaleKeys.termsOfService,
      icon: Icons.gavel_outlined,
      route: AppRoutes.termsOfService,
    ),
    _PolicyTab(
      key: 'cookies',
      titleKey: LocaleKeys.cookiePolicy,
      icon: Icons.cookie_outlined,
      route: AppRoutes.cookiePolicy,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: _requiredPolicies.length,
      vsync: this,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        // Header
        _buildHeader(context, theme),

        // Tab bar
        _buildTabBar(context, theme),

        // Content - only this rebuilds when state changes
        Expanded(
          child: BlocBuilder<SiteConfigCubit, SiteConfigState>(
            // Only rebuild when legal texts change
            buildWhen: (previous, current) =>
                previous.isLoadingLegal != current.isLoadingLegal ||
                previous.hasLegalTexts != current.hasLegalTexts ||
                previous.errorLegal != current.errorLegal,
            builder: (context, state) {
              return TabBarView(
                controller: _tabController,
                children: _requiredPolicies.map((policy) {
                  return _buildPolicyContent(context, theme, state, policy);
                }).toList(),
              );
            },
          ),
        ),

        // Footer with actions
        _buildFooter(context, theme),
      ],
    );
  }

  Widget _buildHeader(BuildContext context, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.08),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.policy_outlined,
            color: theme.colorScheme.primary,
            size: 28,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const MyText(LocaleKeys.termsAndPolicies, istitle: true),
                const SizedBox(height: 2),
                MyText(
                  LocaleKeys.pleaseReadAndAccept,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          // Close button
          IconButton(
            onPressed: () => Navigator.of(context).pop(false),
            icon: const Icon(Icons.close),
            tooltip: context.tr(LocaleKeys.close),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar(BuildContext context, ThemeData theme) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        border: Border(
          bottom: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
      ),
      child: TabBar(
        controller: _tabController,
        labelColor: theme.colorScheme.primary,
        unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
        indicatorColor: theme.colorScheme.primary,
        indicatorWeight: 3,
        tabs: _requiredPolicies.map((policy) {
          return Tab(
            icon: Icon(policy.icon, size: 20),
            text: context.tr(policy.titleKey),
            iconMargin: const EdgeInsets.only(bottom: 4),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPolicyContent(
    BuildContext context,
    ThemeData theme,
    SiteConfigState state,
    _PolicyTab policy,
  ) {
    // Loading
    if (state.isLoadingLegal) {
      return const Center(child: CircularProgressIndicator());
    }

    // Get content
    String? content;
    if (state.hasLegalTexts) {
      content = _getPolicyContent(state.legalTexts, policy.key);
    }

    // Error
    if (state.errorLegal != null) {
      return _buildEmptyContent(context, theme, policy);
    }

    // Empty
    if (content == null || content.isEmpty) {
      return _buildEmptyContent(context, theme, policy);
    }

    // Content
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Row(
            children: [
              Icon(policy.icon, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Expanded(child: MyText(policy.titleKey, istitle: true)),
            ],
          ),
          const SizedBox(height: 16),

          // Content
          SelectableText(
            _processContent(content),
            style: theme.textTheme.bodyMedium?.copyWith(
              height: 1.6,
              color: theme.colorScheme.onSurface,
            ),
          ),

          const SizedBox(height: 24),

          // Link to full page
          Center(
            child: TextButton.icon(
              onPressed: () {
                Navigator.of(context).pop(false);
                // Navegar a la página completa
                Navigator.of(context).pushNamed(policy.route);
              },
              icon: const Icon(Icons.open_in_new, size: 16),
              label: const MyText(LocaleKeys.viewFullPolicy),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyContent(
    BuildContext context,
    ThemeData theme,
    _PolicyTab policy,
  ) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.description_outlined,
            size: 48,
            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 12),
          MyText(
            LocaleKeys.noContentAvailable,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () {
              context.read<SiteConfigCubit>().refreshLegalTexts();
            },
            icon: const Icon(Icons.refresh, size: 18),
            label: const MyText(LocaleKeys.retry),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(BuildContext context, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
        border: Border(
          top: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
      ),
      child: Row(
        children: [
          // Info text
          Expanded(
            child: MyText(
              LocaleKeys.byAcceptingYouAgree,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(width: 16),

          // Cancel button
          OutlinedButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const MyText(LocaleKeys.cancel),
          ),
          const SizedBox(width: 12),

          // Accept button
          FilledButton.icon(
            onPressed: () => Navigator.of(context).pop(true),
            icon: const Icon(Icons.check, size: 18),
            label: const MyText(LocaleKeys.acceptAll),
          ),
        ],
      ),
    );
  }

  String? _getPolicyContent(LegalTexts? legalTexts, String key) {
    if (legalTexts == null) return null;
    switch (key) {
      case 'privacy':
        return legalTexts.privacyPolicy;
      case 'terms':
        return legalTexts.termsConditions;
      case 'cookies':
        return legalTexts.cookiesPolicy;
      default:
        return null;
    }
  }

  /// Procesa HTML básico a texto plano
  String _processContent(String text) {
    return text
        .replaceAllMapped(
          RegExp('<h[1-6][^>]*>(.*?)</h[1-6]>', caseSensitive: false),
          (match) => '\n\n${match.group(1)?.toUpperCase() ?? ""}\n\n',
        )
        .replaceAllMapped(
          RegExp('<p[^>]*>(.*?)</p>', caseSensitive: false, dotAll: true),
          (match) => '${match.group(1) ?? ""}\n\n',
        )
        .replaceAll(RegExp(r'<br\s*/?>'), '\n')
        .replaceAllMapped(
          RegExp('<li[^>]*>(.*?)</li>', caseSensitive: false),
          (match) => '\u2022 ${match.group(1) ?? ""}\n',
        )
        .replaceAll(RegExp('<[^>]+>'), '')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll(RegExp(' +'), ' ')
        .replaceAll(RegExp(r'\n{3,}'), '\n\n')
        .trim();
  }
}

/// Tab de política
class _PolicyTab {
  const _PolicyTab({
    required this.key,
    required this.titleKey,
    required this.icon,
    required this.route,
  });
  final String key;
  final String titleKey;
  final IconData icon;
  final String route;
}
