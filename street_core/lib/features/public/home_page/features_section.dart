import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:street_core/core/lang/context_tr.dart';
import 'package:street_core/core/lang/locale_keys.dart';

import '../../../core/helpers/icon_mapper.dart';
import '../../../core/helpers/responsive/responsive_builder.dart';
import '../../../core/router/navigation_service.dart';
import '../../../core/widgets/my_text.dart';
import '../../../data/models/site_config/site_config_models.dart';
import '../site_config/site_config.dart';
import 'featured_card.dart';

/// Features Section Widget for HomePage
///
/// Displays either custom features from config or default platform features.
/// Has its own BlocBuilder for optimized rebuilds.
//---Sección de características: Muestra los servicios principales de la plataforma
class FeaturesSection extends StatelessWidget {
  const FeaturesSection({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SiteConfigCubit, SiteConfigState>(
      // Only rebuild when features change
      buildWhen: (previous, current) {
        final prevFeatures = previous.landingTexts?.features;
        final currFeatures = current.landingTexts?.features;
        return prevFeatures?.length != currFeatures?.length;
      },
      builder: (context, state) {
        final landingTexts = state.landingTexts;
        return _FeaturesContent(landingTexts: landingTexts);
      },
    );
  }
}

/// Internal content widget for FeaturesSection
class _FeaturesContent extends StatelessWidget {
  const _FeaturesContent({this.landingTexts});
  final LandingTexts? landingTexts;

  @override
  Widget build(BuildContext context) {
    // Standardized context usage
    final isMobile = context.isMobile;
    final isTablet = context.isTablet;

    // Desktop starts at 1200 in standard system, but we keep > 900 for legacy logic alignment
    final isDesktop = context.screenWidth >= 900;

    //---Verifica si existen características personalizadas desde la base de datos
    final hasCustomFeatures =
        landingTexts?.features != null && landingTexts!.features!.isNotEmpty;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: context.responsive(mobile: 24, tablet: 48, desktop: 64),
        vertical: context.responsive(mobile: 48, tablet: 64, desktop: 80),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            children: [
              const SizedBox(height: 16),

              MyText(
                context.tr(LocaleKeys.findYourNextAdventure),
             
                textAlign: TextAlign.center,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              SizedBox(height: isMobile ? 32 : 48),

              // Feature cards
              if (hasCustomFeatures)
                _buildDynamicFeatures(
                  context,
                  landingTexts!.features!,
                  isMobile,
                  isTablet,
                  isDesktop,
                )
              else
                _buildDefaultFeatures(context, isMobile, isTablet, isDesktop),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDynamicFeatures(
    BuildContext context,
    List<FeatureItem> features,
    bool isMobile,
    bool isTablet,
    bool isDesktop,
  ) {
    if (isDesktop) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: features.take(4).map((feature) {
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: FeatureCard(
                icon: IconMapper.fromString(feature.icon),
                title: feature.title ?? '',
                description: feature.description ?? '',
                onTap: () {}, // Features don't have action URLs yet
              ),
            ),
          );
        }).toList(),
      );
    } else if (isTablet) {
      return Wrap(
        spacing: 16,
        runSpacing: 16,
        children: features.map((feature) {
          return SizedBox(
            width: (context.screenWidth - 128) / 2,
            child: FeatureCard(
              icon: IconMapper.fromString(feature.icon),
              title: feature.title ?? '',
              description: feature.description ?? '',
              onTap: () {},
            ),
          );
        }).toList(),
      );
    } else {
      return Column(
        children: features.map((feature) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: FeatureCard(
              icon: IconMapper.fromString(feature.icon),
              title: feature.title ?? '',
              description: feature.description ?? '',
              onTap: () {},
            ),
          );
        }).toList(),
      );
    }
  }

  //---Características por defecto en caso de no tener configuración dinámica
  Widget _buildDefaultFeatures(
    BuildContext context,
    bool isMobile,
    bool isTablet,
    bool isDesktop,
  ) {
    final defaultFeatures = [
      _FeatureData(
        icon: Icons.sports,
        title: context.tr(LocaleKeys.clubs),
        description: context.tr(LocaleKeys.browseClubs),
        route: '/public/clubs',
      ),
      _FeatureData(
        icon: Icons.store,
        title: context.tr(LocaleKeys.market),
        description: context.tr(LocaleKeys.browseMarket),
        route: '/public/market',
      ),
      _FeatureData(
        icon: Icons.event,
        title: context.tr(LocaleKeys.events),
        description: context.tr(LocaleKeys.browseEvents),
        route: '/public/events',
      ),
      _FeatureData(
        icon: Icons.sports_gymnastics_rounded,
        title: context.tr(LocaleKeys.athletes),
        description: context.tr(LocaleKeys.exploreAllRiders),
        route: '/public/riders',
      ),
    ];

    if (isDesktop) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: defaultFeatures
            .map(
              (feature) => Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: FeatureCard(
                    icon: feature.icon,
                    title: feature.title,
                    description: feature.description,
                    onTap: () => NavigationService().go(context, feature.route),
                  ),
                ),
              ),
            )
            .toList(),
      );
    } else if (isTablet) {
      return Wrap(
        spacing: 16,
        runSpacing: 16,
        children: defaultFeatures.map((feature) {
          return SizedBox(
            width: (context.screenWidth - 128) / 2,
            child: FeatureCard(
              icon: feature.icon,
              title: feature.title,
              description: feature.description,
              onTap: () => NavigationService().go(context, feature.route),
            ),
          );
        }).toList(),
      );
    } else {
      return Column(
        children: defaultFeatures
            .map(
              (feature) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: FeatureCard(
                  icon: feature.icon,
                  title: feature.title,
                  description: feature.description,
                  onTap: () => NavigationService().go(context, feature.route),
                ),
              ),
            )
            .toList(),
      );
    }
  }
}

/// Helper class for default feature data
class _FeatureData {
  _FeatureData({
    required this.icon,
    required this.title,
    required this.description,
    required this.route,
  });
  final IconData icon;
  final String title;
  final String description;
  final String route;
}
