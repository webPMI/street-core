import '../../../../core/di/injection.dart';
import '../../../../core/helpers/responsive/responsive_builder.dart';
import '../../../../core/lang/context_tr.dart';
import '../../../../core/lang/locale_keys.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/widgets/my_text.dart';
import '../../../data/models/site_config/site_config_models.dart';
import '../components/public_layout.dart';
import '../site_config/site_config.dart';
import './widgets/legal_content_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Página principal de textos legales
///
/// Muestra todas las políticas legales en un formato con tabs:
/// - Política de Privacidad
/// - Términos de Servicio
/// - Política de Cookies
/// - Política de Reembolso
/// - Protección de Datos
///
/// Features:
/// - Carga datos desde SiteConfigCubit (on-demand, 24h cache)
/// - Diseño responsive (tabs en desktop, dropdown en mobile)
/// - Dentro de PublicLayout
class LegalPage extends StatelessWidget {
  const LegalPage({super.key, this.initialSection});

  /// Sección inicial a mostrar (opcional)
  final LegalSection? initialSection;

  @override
  Widget build(BuildContext context) {
    // Provide SiteConfigCubit locally (not in main.dart)
    return BlocProvider<SiteConfigCubit>.value(
      value: getIt<SiteConfigCubit>()..loadLegalTexts(),
      child: PublicLayout(
        child: _LegalPageContent(initialSection: initialSection),
      ),
    );
  }
}

/// Enum para las secciones legales
enum LegalSection { privacy, terms, cookies, refund, dataProtection }

/// Extensión para obtener metadata de cada sección
extension LegalSectionExtension on LegalSection {
  String get titleKey {
    switch (this) {
      case LegalSection.privacy:
        return LocaleKeys.privacyPolicy;
      case LegalSection.terms:
        return LocaleKeys.termsOfService;
      case LegalSection.cookies:
        return LocaleKeys.cookiePolicy;
      case LegalSection.refund:
        return LocaleKeys.refundPolicy;
      case LegalSection.dataProtection:
        return LocaleKeys.dataProtection;
    }
  }

  IconData get icon {
    switch (this) {
      case LegalSection.privacy:
        return Icons.privacy_tip_outlined;
      case LegalSection.terms:
        return Icons.gavel_outlined;
      case LegalSection.cookies:
        return Icons.cookie_outlined;
      case LegalSection.refund:
        return Icons.money_off_outlined;
      case LegalSection.dataProtection:
        return Icons.security_outlined;
    }
  }

  String get route {
    switch (this) {
      case LegalSection.privacy:
        return AppRoutes.privacyPolicy;
      case LegalSection.terms:
        return AppRoutes.termsOfService;
      case LegalSection.cookies:
        return AppRoutes.cookiePolicy;
      case LegalSection.refund:
        return AppRoutes.refundPolicy;
      case LegalSection.dataProtection:
        return AppRoutes.dataProtection;
    }
  }

  String? getContent(LegalTexts? legalTexts) {
    if (legalTexts == null) return null;
    switch (this) {
      case LegalSection.privacy:
        return legalTexts.privacyPolicy;
      case LegalSection.terms:
        return legalTexts.termsConditions;
      case LegalSection.cookies:
        return legalTexts.cookiesPolicy;
      case LegalSection.refund:
        return legalTexts.refundPolicy;
      case LegalSection.dataProtection:
        return legalTexts.dataProtection;
    }
  }
}

class _LegalPageContent extends StatefulWidget {
  const _LegalPageContent({this.initialSection});
  final LegalSection? initialSection;

  @override
  State<_LegalPageContent> createState() => _LegalPageContentState();
}

class _LegalPageContentState extends State<_LegalPageContent>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  static const List<LegalSection> _sections = LegalSection.values;

  @override
  void initState() {
    super.initState();
    final initialIndex = widget.initialSection != null
        ? _sections.indexOf(widget.initialSection!)
        : 0;
    _tabController = TabController(
      length: _sections.length,
      vsync: this,
      initialIndex: initialIndex >= 0 ? initialIndex : 0,
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

    return ResponsiveBuilder(
      builder: (context, device) {
        return SizedBox(
          width: getWidth(context),
          height: getHeight(context),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: Card(
              margin: EdgeInsets.all(
                device.value(mobile: 8, tablet: 16, desktop: 24),
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header
                  _buildHeader(context, theme, device),

                  // Tab Bar
                  _buildTabBar(context, theme, device),

                  // Content - BlocBuilder only wraps dynamic content
                  Expanded(
                    child: BlocBuilder<SiteConfigCubit, SiteConfigState>(
                      // Only rebuild when legal texts change
                      buildWhen: (previous, current) =>
                          previous.isLoadingLegal != current.isLoadingLegal ||
                          previous.hasLegalTexts != current.hasLegalTexts ||
                          previous.errorLegal != current.errorLegal,
                      builder: (context, state) {
                        return RefreshIndicator(
                          onRefresh: () async {
                            await context.read<SiteConfigCubit>().refreshLegalTexts();
                          },
                          child: TabBarView(
                            controller: _tabController,
                            children: _sections.map((section) {
                              return _buildSectionContent(
                                context,
                                state,
                                section,
                              );
                            }).toList(),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(
    BuildContext context,
    ThemeData theme,
    ResponsiveDevice device,
  ) {
    return Container(
      padding: EdgeInsets.all(
        device.value(mobile: 16, tablet: 20, desktop: 24),
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.08),
        border: Border(
          bottom: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.policy_outlined,
            color: theme.colorScheme.primary,
            size: device.value(mobile: 28, tablet: 32, desktop: 36),
          ),
          SizedBox(width: device.spacing),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const MyText(LocaleKeys.legalInformation, istitle: true),
                if (!device.isMobile) ...[
                  const SizedBox(height: 4),
                  MyText(
                    LocaleKeys.legalInformationSubtitle,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ],
              ],
            ),
          ),
          // Refresh button
          IconButton(
            onPressed: () {
              context.read<SiteConfigCubit>().refreshLegalTexts();
            },
            icon: const Icon(Icons.refresh),
            tooltip: context.tr(LocaleKeys.refresh),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar(
    BuildContext context,
    ThemeData theme,
    ResponsiveDevice device,
  ) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        border: Border(
          bottom: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
      ),
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        labelColor: theme.colorScheme.primary,
        unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
        indicatorColor: theme.colorScheme.primary,
        indicatorWeight: 3,
        tabs: _sections.map((section) {
          return Tab(
            icon: Icon(section.icon, size: 20),
            text: device.isMobile ? null : context.tr(section.titleKey),
            iconMargin: const EdgeInsets.only(bottom: 4),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSectionContent(
    BuildContext context,
    SiteConfigState state,
    LegalSection section,
  ) {
    // Loading
    if (state.isLoadingLegal) {
      return LegalContentView(
        titleKey: section.titleKey,
        icon: section.icon,
        isLoading: true,
        showHeader: false,
      );
    }

    // Error
    if (state.errorLegal != null) {
      return LegalContentView(
        titleKey: section.titleKey,
        icon: section.icon,
        errorMessage: state.errorLegal,
        onRetry: () => context.read<SiteConfigCubit>().refreshLegalTexts(),
        showHeader: false,
      );
    }

    // Loaded
    if (state.hasLegalTexts) {
      final content = section.getContent(state.legalTexts);
      return LegalContentView(
        titleKey: section.titleKey,
        icon: section.icon,
        content: content,
        shareRoute: section.route,
        showHeader: false,
      );
    }

    // Initial/unknown state
    return LegalContentView(
      titleKey: section.titleKey,
      icon: section.icon,
      isLoading: true,
      showHeader: false,
    );
  }
}
