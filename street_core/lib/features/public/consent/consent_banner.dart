import 'consent_cubit.dart';
import 'consent_state.dart';
import '../site_config/site_config.dart';
import '/core/router/app_routes.dart';
import '/core/widgets/buttons/animated_primary_button.dart';
import '/core/widgets/my_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '/core/lang/locale_keys.dart';

class ConsentBanner extends StatelessWidget {
  const ConsentBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ConsentCubit, ConsentState>(
      builder: (context, state) {
        // If unknown (and not loading), show banner.
        // If accepted or rejected, hide it.
        if (!state.isUnknown || state.isLoading) {
          return const SizedBox.shrink();
        }

        final theme = Theme.of(context);
        final isDark = theme.brightness == Brightness.dark;

        return Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 20,
                  offset: const Offset(0, -5),
                ),
              ],
              border: Border(
                top: BorderSide(
                  color: isDark ? Colors.white12 : Colors.black12,
                ),
              ),
            ),
            child: SafeArea(
              top: false,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1200),
                child: Center(
                  child: SizedBox(
                    width: double.infinity,
                    child: Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 24,
                      runSpacing: 16,
                      children: [
                        // Text section
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 600),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const MyText(
                                LocaleKeys.respectYourPrivacy,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                margin: 8,
                              ),
                              MyText(
                                LocaleKeys.acceptCookiesMessage,
                                fontSize: 14,
                                color: theme.colorScheme.onSurfaceVariant,
                                height: 1.5,
                              ),
                              const SizedBox(height: 8),
                              _buildLinks(context, theme),
                            ],
                          ),
                        ),

                        // Buttons section
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            OutlinedButton(
                              onPressed: () {
                                _showAdvancedSettings(context);
                              },
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 16,
                                ),
                              ),
                              child: const MyText(LocaleKeys.configurationOfPrivacy),
                            ),
                            OutlinedButton(
                              onPressed: () {
                                context.read<ConsentCubit>().rejectAll();
                              },
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 16,
                                ),
                              ),
                              child: const MyText(LocaleKeys.cancel),
                            ),
                            SizedBox(
                              width: 160,
                              child: AnimatedPrimaryButton(
                                onPressed: () {
                                  context.read<ConsentCubit>().acceptAll();
                                },
                                child: const Center(
                                  child: MyText(LocaleKeys.acceptAll),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _showAdvancedSettings(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => BlocProvider.value(
        value: context.read<ConsentCubit>(),
        child: const _AdvancedConsentDialog(),
      ),
    );
  }

  Widget _buildLinks(BuildContext context, ThemeData theme) {
    // Only show links if legal config is loaded, otherwise just generic text
    return BlocBuilder<SiteConfigCubit, SiteConfigState>(
      builder: (context, state) {
        if (!state.hasLegalTexts) return const SizedBox.shrink();

        return Wrap(
          spacing: 16,
          children: [
            _LinkButton(
              text: LocaleKeys.termsOfService,
              onTap: () => context.push(AppRoutes.cookiePolicy),
            ),
            if (state.legalTexts?.privacyPolicy != null)
              _LinkButton(
                text: LocaleKeys.privacyPolicy,
                onTap: () => context.push(AppRoutes.privacyPolicy),
              ),
          ],
        );
      },
    );
  }
}

class _LinkButton extends StatelessWidget {
  const _LinkButton({required this.text, required this.onTap});
  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      child: Padding(
        // Hit area
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: MyText(
          text,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.primary,
            decoration: TextDecoration.underline,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _AdvancedConsentDialog extends StatelessWidget {
  const _AdvancedConsentDialog();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AlertDialog(
      title: const MyText(LocaleKeys.configurationOfPrivacy),
      backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      content: SizedBox(
        width: double.maxFinite,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: SingleChildScrollView(
            child: BlocBuilder<ConsentCubit, ConsentState>(
              builder: (context, state) {
                final config = state.config;

                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ////----- Switch items for each consent type
                    _SwitchItem(
                      title: LocaleKeys.necessaryCookies,
                      description:
                          config?.safeCookieConsentText.isNotEmpty ?? false
                          ? config!.safeCookieConsentText
                          : "necessary.coockies.description",
                      value: state.cookiesAccepted,
                      onChanged: null, // Always disabled (true)
                    ),
                    const Divider(),
                    // ----- Analytics cookies
                    _SwitchItem(
                      title: LocaleKeys.analyticsCookies,
                      description:
                          config?.safeAnalyticsConsentText.isNotEmpty ?? false
                          ? config!.safeAnalyticsConsentText
                          : 'analytics.cookies.description',
                      value: state.analyticsAccepted,
                      onChanged: (val) =>
                          context.read<ConsentCubit>().toggleAnalytics(val),
                    ),
                    const Divider(),
                    _SwitchItem(
                      title: LocaleKeys.locationCookies,
                      description:
                          config?.safeLocationConsentText.isNotEmpty ?? false
                          ? config!.safeLocationConsentText
                          : 'location.cookies.description',
                      value: state.locationAccepted,
                      onChanged: (val) =>
                          context.read<ConsentCubit>().toggleLocation(val),
                    ),
                    const Divider(),
                    _SwitchItem(
                      title: LocaleKeys.marketingCookies,
                      description:
                          config?.safeMarketingConsentText.isNotEmpty ?? false
                          ? config!.safeMarketingConsentText
                          : 'marketing.cookies.description',
                      value: state.marketingAccepted,
                      onChanged: (val) =>
                          context.read<ConsentCubit>().toggleMarketing(val),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            context.read<ConsentCubit>().rejectAll();
            Navigator.of(context).pop();
          },
          child: const MyText(LocaleKeys.rejectAll),
        ),
        FilledButton(
          onPressed: () {
            context.read<ConsentCubit>().savePreferences();
            Navigator.of(context).pop();
          },
          child: const MyText(LocaleKeys.saveSelection),
        ),
      ],
    );
  }
}

class _SwitchItem extends StatelessWidget {
  const _SwitchItem({
    required this.title,
    required this.description,
    required this.value,
    required this.onChanged,
  });
  final String title;
  final String description;
  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      title: MyText(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: MyText(description, style: const TextStyle(fontSize: 12)),
      ),
      value: value,
      onChanged: onChanged,
      activeTrackColor: Theme.of(context).colorScheme.primary,
    );
  }
}
