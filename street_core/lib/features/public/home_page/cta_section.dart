import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/helpers/responsive/responsive_builder.dart';
import '../../../core/lang/context_tr.dart';
import '../../../core/lang/locale_keys.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/router/navigation_service.dart';
import '../../../core/widgets/my_button.dart';
import '../../../core/widgets/my_text.dart';
import '../../../data/models/site_config/site_config_models.dart';
import '../site_config/site_config.dart';

/// Call-to-Action (CTA) Section Widget for HomePage
///
/// Displays a prominent CTA with title, text, and action button.
/// Has its own BlocBuilder for optimized rebuilds.
/// Only renders if CTA content exists in config.
//---Sección CTA: Llamada a la acción final para invitar al usuario a unirse
class CTASection extends StatelessWidget {
  const CTASection({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SiteConfigCubit, SiteConfigState>(
      // Only rebuild when CTA texts change
      buildWhen: (previous, current) {
        final prevLanding = previous.landingTexts;
        final currLanding = current.landingTexts;
        return prevLanding?.ctaTitle != currLanding?.ctaTitle ||
            prevLanding?.ctaText != currLanding?.ctaText ||
            prevLanding?.ctaButtonText != currLanding?.ctaButtonText;
      },
      builder: (context, state) {
        final landingTexts = state.landingTexts;

        // Don't render if no CTA content
        if (landingTexts?.ctaTitle == null && landingTexts?.ctaText == null) {
          return const SizedBox.shrink();
        }

        return _CTAContent(landingTexts: landingTexts);
      },
    );
  }
}

/// Internal content widget for CTASection
class _CTAContent extends StatelessWidget {
  const _CTAContent({this.landingTexts});
  final LandingTexts? landingTexts;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final ctaTitle = landingTexts?.ctaTitle ?? context.tr(LocaleKeys.joinUsToday);
    final ctaText = landingTexts?.ctaText ?? context.tr(LocaleKeys.startYourJourney);
    final ctaButtonText =
        landingTexts?.ctaButtonText ?? context.tr(LocaleKeys.getStarted);

    return Container(
      padding: EdgeInsets.all(
        context.responsive(mobile: 32, tablet: 64, desktop: 64),
      ),
      color: theme.colorScheme.primaryContainer,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
            children: [
              MyText(
                ctaTitle,
                istitle: true,

                textAlign: TextAlign.center,
                color: theme.colorScheme.onPrimaryContainer,
              ),
              const SizedBox(height: 16),
              MyText(
                ctaText,
                textAlign: TextAlign.center,
                color: theme.colorScheme.onPrimaryContainer,
              ),
              const SizedBox(height: 32),
              MyButton(
                text: ctaButtonText,
                onPressed: () =>
                    NavigationService().go(context, AppRoutes.contact),
                icon: Icons.arrow_forward,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
