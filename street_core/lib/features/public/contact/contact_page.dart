import '../../../../core/widgets/buttons/animated_primary_button.dart';

import '../../../../core/helpers/responsive/responsive_builder.dart';
import '../../../../core/helpers/snackbar_helper.dart';
import '../../../../core/helpers/validators.dart';
import '../../../../core/lang/locale_keys.dart';
import '../../../../core/widgets/form/form_item_config.dart';
import '../../../../core/widgets/my_form.dart';
import '../../../../core/widgets/my_text.dart';
import '../../../../core/widgets/drawer/my_drawer.dart';
import 'contact_cubit.dart';
import 'contact_state.dart';
import '../site_config/site_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:url_launcher/url_launcher.dart';

import '../home_page/footer.dart';

/// ContactPage - Public contact form with dynamic configuration
///
/// Features:
/// - Uses MyForm for declarative form building
/// - Self-contained: Provides its own ContactConfigCubit via GetIt
/// - Uses SiteConfigCubit (global) for social media links
/// - Dynamic contact info from backend configuration
/// - Responsive layout (desktop/mobile)
/// - Clickable contact items (email, phone, WhatsApp)
class ContactPage extends StatefulWidget {
  const ContactPage({super.key});

  @override
  State<ContactPage> createState() => _ContactPageState();
}

class _ContactPageState extends State<ContactPage> {
  late final ContactCubit _contactCubit;

  /// Contact message categories matching backend enum
  static const List<String> _categories = [
    'general',
    'support',
    'sales',
    'feedback',
    'other',
  ];

  /// Form field configuration - Matches backend validation exactly:
  /// - name: required, min=2, max=100
  /// - email: required, email format, max=100
  /// - phone: optional, max=20
  /// - subject: required, min=5, max=200
  /// - message: required, min=10, max=5000
  /// - category: optional, oneof=general|support|sales|feedback|other
  static final List<FormItemConfig> _formItems = [
    FormItemConfig.text(
      id: 'name',
      label: LocaleKeys.name,
      hintText: LocaleKeys.enterYourName,
      icon: Icons.person_outline,
      isRequired: true,
      autofillHints: const [AutofillHints.name],
      validator:
          RequiredValidator() & MinLengthValidator(2) & MaxLengthValidator(100),
      maxLength: 50,
    ),
    FormItemConfig.email(
      id: 'email',
      label: LocaleKeys.email,
      hintText: LocaleKeys.enterYourEmail,
      icon: Icons.email_outlined,
    ),
    FormItemConfig.phone(
      id: 'phone',
      label: LocaleKeys.phone,
      hintText: LocaleKeys.enterYourPhone,
      icon: Icons.phone_outlined,
      maxLength: 20,
    ),
    FormItemConfig.text(
      id: 'subject',
      label: LocaleKeys.subject,
      hintText: LocaleKeys.enterSubject,
      icon: Icons.subject,
      isRequired: true,
      validator:
          RequiredValidator() & MinLengthValidator(5) & MaxLengthValidator(200),
      maxLength: 100,
    ),
    FormItemConfig.dropdown(
      id: 'category',
      label: LocaleKeys.category,
      hintText: LocaleKeys.selectCategory,
      icon: Icons.category_outlined,
      options: _categories,
      isRequired: false,
    ),
    FormItemConfig.textarea(
      id: 'message',
      label: LocaleKeys.message,
      hintText: LocaleKeys.writeYourMessage,
      icon: Icons.message_outlined,
      maxLines: 6,
      isRequired: true,
      validator:
          RequiredValidator() &
          MinLengthValidator(10) &
          MaxLengthValidator(5000),
      maxLength: 500,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _contactCubit = GetIt.I<ContactCubit>();
    // Load contact info on init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      GetIt.I<SiteConfigCubit>().loadContactInfo();
    });
  }

  @override
  void dispose() {
    _contactCubit.close();
    super.dispose();
  }

  void _handleSubmit(Map<String, dynamic> data) {
    _contactCubit.submitMessage(
      name: (data['name'] as String?)?.trim() ?? '',
      email: (data['email'] as String?)?.trim() ?? '',
      phone: (data['phone'] as String?)?.trim(),
      subject: (data['subject'] as String?)?.trim() ?? '',
      message: (data['message'] as String?)?.trim() ?? '',
      category: data['category'] as String?,
    );
  }

  void _onContactStateChanged(BuildContext context, ContactState state) {
    if (state is ContactSubmitSuccess) {
      SnackBarHelper.showSuccess(context, state.message);
      _contactCubit.reset();
    } else if (state is ContactSubmitError) {
      SnackBarHelper.showError(context, state.message);
    }
  }

  Future<void> _launchUrl(String url) async {
    if (url.isEmpty) return;

    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _launchEmail(String email) async {
    if (email.isEmpty) return;
    await _launchUrl('mailto:$email');
  }

  Future<void> _launchPhone(String phone) async {
    if (phone.isEmpty) return;
    await _launchUrl('tel:$phone');
  }

  Future<void> _launchWhatsApp(String whatsapp) async {
    if (whatsapp.isEmpty) return;
    final cleanNumber = whatsapp.replaceAll(RegExp(r'[^\d+]'), '');
    await _launchUrl('https://wa.me/$cleanNumber');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDesktop = context.isDesktop;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.contact_mail),
            const SizedBox(width: 8),
            const MyText(LocaleKeys.contact),
          ],
        ),
      ),
      drawer: MyDrawer(),
      body: MultiBlocProvider(
        providers: [
          BlocProvider<ContactCubit>.value(value: _contactCubit),
        ],
        child: BlocListener<ContactCubit, ContactState>(
          listener: _onContactStateChanged,
          child: RefreshIndicator(
            onRefresh: () async {
              await GetIt.I<SiteConfigCubit>().refreshContactInfo();
            },
            child: SingleChildScrollView(
              child: Center(
                child: Column(
                  children: [
                    ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 900),
                    child: Padding(
                      padding: EdgeInsets.all(context.isMobile ? 18.0 : 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 24),

                          // Header
                          const MyText(
                            LocaleKeys.contactUs,
                            istitle: true,
                            fontSize: 28,
                          ),
                          const SizedBox(height: 8),
                          MyText(
                            LocaleKeys.getInTouch,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),

                          const SizedBox(height: 32),

                          // Contact form and info - responsive layout
                          if (isDesktop)
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: _buildContactForm(theme),
                                ),
                                const SizedBox(width: 32),
                                Expanded(
                                  flex: 2,
                                  child: _buildContactInfo(theme),
                                ),
                              ],
                            )
                          else
                            Column(
                              children: [
                                _buildContactForm(theme),
                                const SizedBox(height: 32),
                                _buildContactInfo(theme),
                              ],
                            ),

                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ),
                  Footer(),
                ],
              ),
            ),
          ),
            ),
        ),
      ),
    );
  }

  Widget _buildContactForm(ThemeData theme) {
    return BlocBuilder<ContactCubit, ContactState>(
      builder: (context, state) {
        final isLoading = state is ContactSubmitting;

        return MyForm(
          formItems: _formItems,
          onSubmit: _handleSubmit,
          title: LocaleKeys.sendUsMessage,
          buttonText: LocaleKeys.sendMessage,
          isLoading: isLoading,
          isScrollable: false,
          padding: EdgeInsets.zero,
          spacing: 16,
        );
      },
    );
  }

  Widget _buildContactInfo(ThemeData theme) {
    return BlocBuilder<SiteConfigCubit, SiteConfigState>(
      builder: (context, state) {
        if (state.isLoadingContact) {
          return Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(48),
              child: Center(
                child: CircularProgressIndicator(
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
          );
        }

        if (state.errorContact != null) {
          return Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Icon(
                    Icons.error_outline,
                    color: theme.colorScheme.error,
                    size: 48,
                  ),
                  const SizedBox(height: 16),
                  MyText(
                    LocaleKeys.errorLoadingContact,
                    color: theme.colorScheme.error,
                  ),
                  const SizedBox(height: 16),
                  AnimatedPrimaryButton(
                    child: MyText(LocaleKeys.retry),
                    onPressed: () =>
                        GetIt.I<SiteConfigCubit>().refreshContactInfo(),
                  ),
                ],
              ),
            ),
          );
        }

        final contactInfo = state.safeContactInfo;

        return Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const MyText(LocaleKeys.contactInfo, istitle: true),
                const SizedBox(height: 24),

                // Email
                if (contactInfo.email?.isNotEmpty ?? false)
                  _buildInfoItem(
                    icon: Icons.email_outlined,
                    title: LocaleKeys.email,
                    value: contactInfo.email!,
                    theme: theme,
                    onTap: () => _launchEmail(contactInfo.email!),
                  ),

                // Phone
                if (contactInfo.phone?.isNotEmpty ?? false) ...[
                  const SizedBox(height: 16),
                  _buildInfoItem(
                    icon: Icons.phone_outlined,
                    title: LocaleKeys.phone,
                    value: contactInfo.phone!,
                    theme: theme,
                    onTap: () => _launchPhone(contactInfo.phone!),
                  ),
                ],

                // WhatsApp
                if (contactInfo.whatsapp?.isNotEmpty ?? false) ...[
                  const SizedBox(height: 16),
                  _buildInfoItem(
                    icon: Icons.chat_outlined,
                    title: 'WhatsApp',
                    value: contactInfo.whatsapp!,
                    theme: theme,
                    onTap: () => _launchWhatsApp(contactInfo.whatsapp!),
                    isWhatsApp: true,
                  ),
                ],

                // Address
                if (contactInfo.address?.isNotEmpty ?? false) ...[
                  const SizedBox(height: 16),
                  _buildInfoItem(
                    icon: Icons.location_on_outlined,
                    title: LocaleKeys.address,
                    value: contactInfo.address!,
                    theme: theme,
                  ),
                ],

                // Business hours
                if (contactInfo.businessHours?.isNotEmpty ?? false) ...[
                  const SizedBox(height: 16),
                  _buildInfoItem(
                    icon: Icons.access_time_outlined,
                    title: LocaleKeys.businessHours,
                    value: contactInfo.businessHours!,
                    theme: theme,
                  ),
                ],

                const SizedBox(height: 32),

                // Social media section
                _buildSocialMediaSection(theme),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSocialMediaSection(ThemeData theme) {
    return BlocBuilder<SiteConfigCubit, SiteConfigState>(
      builder: (context, state) {
        if (!state.hasBasicConfig) {
          return const SizedBox.shrink();
        }

        final social = state.basicConfig?.socialMedia;
        final hasAnySocial =
            (social?.safeFacebook.isNotEmpty ?? false) ||
            (social?.safeInstagram.isNotEmpty ?? false) ||
            (social?.safeTwitter.isNotEmpty ?? false) ||
            (social?.safeYouTube.isNotEmpty ?? false);

        if (!hasAnySocial || social == null) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const MyText(LocaleKeys.followUs, istitle: true),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (social.safeFacebook.isNotEmpty)
                  _buildSocialButton(
                    icon: Icons.facebook,
                    url: social.safeFacebook,
                    theme: theme,
                    color: const Color(0xFF1877F2),
                  ),
                if (social.safeInstagram.isNotEmpty)
                  _buildSocialButton(
                    icon: Icons.camera_alt,
                    url: social.safeInstagram,
                    theme: theme,
                    color: const Color(0xFFE4405F),
                  ),
                if (social.safeTwitter.isNotEmpty)
                  _buildSocialButton(
                    icon: Icons.close,
                    url: social.safeTwitter,
                    theme: theme,
                    color: Colors.black,
                  ),
                if (social.safeYouTube.isNotEmpty)
                  _buildSocialButton(
                    icon: Icons.play_arrow,
                    url: social.safeYouTube,
                    theme: theme,
                    color: const Color(0xFFFF0000),
                  ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String title,
    required String value,
    required ThemeData theme,
    VoidCallback? onTap,
    bool isWhatsApp = false,
  }) {
    final content = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isWhatsApp
                ? const Color(0xFF25D366).withValues(alpha: 0.1)
                : theme.colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color: isWhatsApp
                ? const Color(0xFF25D366)
                : theme.colorScheme.primary,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              MyText(
                title,
                fontSize: 12,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: 2),
              MyText(
                value,
                noTranslation: true,
                color: onTap != null
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurface,
              ),
            ],
          ),
        ),
        if (onTap != null)
          Icon(
            Icons.arrow_forward_ios,
            size: 14,
            color: theme.colorScheme.onSurfaceVariant,
          ),
      ],
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: content,
        ),
      );
    }

    return content;
  }

  Widget _buildSocialButton({
    required IconData icon,
    required String url,
    required ThemeData theme,
    required Color color,
  }) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: () => _launchUrl(url),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.all(12),
          child: Icon(icon, color: Colors.white, size: 22),
        ),
      ),
    );
  }
}
