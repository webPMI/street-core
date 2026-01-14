import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/lang/context_tr.dart';
import '../../../core/lang/locale_keys.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/router/navigation_service.dart';
import '../../../core/widgets/my_text.dart';
import '../site_config/site_config.dart';

/// Footer widget for public pages
///
/// Displays company info and legal links.
/// Uses SiteConfigCubit for on-demand loading (company + social only).
/// TTL: 2 hours
///
/// Optimized: Only company name text rebuilds when state changes.
/// Legal links are static and never rebuild.
//---Pie de página: Información de la empresa y enlaces legales
class Footer extends StatelessWidget {
  const Footer({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Load config on first build (safe because cubit skips if already loaded)
    context.read<SiteConfigCubit>().loadBasicConfig();

    return Container(
      padding: const EdgeInsets.all(32),
      color: theme.colorScheme.surfaceContainerHighest,
      child: Center(
        child: Column(
          children: [
            // Company name - only this rebuilds when state changes
            BlocBuilder<SiteConfigCubit, SiteConfigState>(
              // Only rebuild when company name changes
              buildWhen: (previous, current) {
                final prevName = previous.basicConfig?.companyInfo.safeName;
                final currName = current.basicConfig?.companyInfo.safeName;
                return prevName != currName;
              },
              builder: (context, state) {
                final companyName = state.hasBasicConfig
                    ? (state.basicConfig!.companyInfo.safeName.isNotEmpty
                          ? state.basicConfig!.companyInfo.safeName
                          : context.tr(LocaleKeys.appTitle))
                    : context.tr(LocaleKeys.appTitle);

                return Column(
                  children: [
                    MyText(companyName, istitle: true),
                    const SizedBox(height: 16),
                  ],
                );
              },
            ),

            //---Enlaces legales estáticos (Contacto, Privacidad, Términos)
            Wrap(
              spacing: 24,
              runSpacing: 16,
              alignment: WrapAlignment.center,
              children: [
                _FooterLink(
                  labelKey: LocaleKeys.contactUs,
                  onPressed: () =>
                      NavigationService().go(context, AppRoutes.contact),
                ),
                _FooterLink(
                  labelKey: LocaleKeys.termsOfService,
                  onPressed: () =>
                      NavigationService().go(context, AppRoutes.termsOfService),
                ),
                _FooterLink(
                  labelKey: LocaleKeys.privacyPolicy,
                  onPressed: () =>
                      NavigationService().go(context, AppRoutes.privacyPolicy),
                ),
                _FooterLink(
                  labelKey: LocaleKeys.legalInformation,
                  onPressed: () =>
                      NavigationService().go(context, AppRoutes.legal),
                ),
                _FooterLink(
                  labelKey: LocaleKeys.cookiePolicy,
                  onPressed: () =>
                      NavigationService().go(context, AppRoutes.cookiePolicy),
                ),
              ],
            ),

            // Copyright - uses BlocBuilder only for company name
            const SizedBox(height: 16),
            BlocBuilder<SiteConfigCubit, SiteConfigState>(
              buildWhen: (previous, current) {
                final prevName = previous.basicConfig?.companyInfo.safeName;
                final currName = current.basicConfig?.companyInfo.safeName;
                return prevName != currName;
              },
              builder: (context, state) {
                final companyName = state.hasBasicConfig
                    ? (state.basicConfig!.companyInfo.safeName.isNotEmpty
                          ? state.basicConfig!.companyInfo.safeName
                          : context.tr(LocaleKeys.appTitle))
                    : context.tr(LocaleKeys.appTitle);

                return MyText(
                  '\u00a9 ${DateTime.now().year} $companyName',
                  noTranslation: true,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// Individual footer link button
class _FooterLink extends StatelessWidget {
  const _FooterLink({required this.labelKey, required this.onPressed});
  final String labelKey;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      child: MyText(labelKey, selectable: false),
    );
  }
}
