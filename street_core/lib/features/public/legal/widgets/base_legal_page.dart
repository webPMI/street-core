import '../../../../../core/di/injection.dart';
import '../../../../../core/helpers/responsive/responsive_builder.dart';
import '../../../../../core/lang/locale_keys.dart';
import '../../../../../core/widgets/my_text.dart';
import '../../components/public_layout.dart';
import '../../site_config/site_config.dart';
import './legal_content_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../legal_page.dart'; // For LegalSection enum

/// Base Legal Page Widget
///
/// Generic reusable widget for all individual legal pages.
/// Eliminates code duplication across privacy_policy_page, terms_of_service_page, etc.
///
/// Usage:
/// ```dart
/// class PrivacyPolicyPage extends StatelessWidget {
///   const PrivacyPolicyPage({super.key});
///
///   @override
///   Widget build(BuildContext context) {
///     return BaseLegalPage(section: LegalSection.privacy);
///   }
/// }
/// ```
class BaseLegalPage extends StatelessWidget {
  const BaseLegalPage({
    super.key,
    required this.section,
  });

  /// The legal section to display
  final LegalSection section;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<SiteConfigCubit>.value(
      value: getIt<SiteConfigCubit>()..loadLegalTexts(),
      child: PublicLayout(
        child: _BaseLegalPageContent(section: section),
      ),
    );
  }
}

class _BaseLegalPageContent extends StatefulWidget {
  const _BaseLegalPageContent({required this.section});

  final LegalSection section;

  @override
  State<_BaseLegalPageContent> createState() => _BaseLegalPageContentState();
}

class _BaseLegalPageContentState extends State<_BaseLegalPageContent> {
  @override
  void initState() {
    super.initState();
    // TODO: SEO - Uncomment when SeoHelper is available
    // SeoHelper.updateMetaTags(
    //   SeoMetadataTemplates.forSection(widget.section),
    //   widget.section.route,
    // );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ResponsiveBuilder(
      builder: (context, device) {
        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: Card(
              margin: EdgeInsets.all(
                device.value(mobile: 8, tablet: 16, desktop: 24),
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  // Back navigation - static, no rebuild needed
                  _buildBackHeader(context, theme, device),

                  // Content - only this rebuilds when state changes
                  Expanded(
                    child: BlocBuilder<SiteConfigCubit, SiteConfigState>(
                      // Only rebuild when legal texts change
                      buildWhen: (previous, current) =>
                          previous.isLoadingLegal != current.isLoadingLegal ||
                          previous.hasLegalTexts != current.hasLegalTexts ||
                          previous.errorLegal != current.errorLegal,
                      builder: (context, state) {
                        String? content;
                        bool isLoading = state.isLoadingLegal;
                        String? errorMessage = state.errorLegal;

                        if (state.hasLegalTexts) {
                          content = widget.section.getContent(state.legalTexts);
                        }

                        return LegalContentView(
                          titleKey: widget.section.titleKey,
                          icon: widget.section.icon,
                          content: content,
                          shareRoute: widget.section.route,
                          isLoading: isLoading,
                          errorMessage: errorMessage,
                          onRetry: () {
                            context.read<SiteConfigCubit>().refreshLegalTexts();
                          },
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

  Widget _buildBackHeader(
    BuildContext context,
    ThemeData theme,
    ResponsiveDevice device,
  ) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: device.value(mobile: 8, tablet: 12, desktop: 16),
        vertical: 8,
      ),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
      ),
      child: Row(
        children: [
          TextButton.icon(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back, size: 18),
            label: MyText(LocaleKeys.back),
          ),
        ],
      ),
    );
  }
}
