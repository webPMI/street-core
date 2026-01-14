import '../../core/lang/locale_keys.dart';
import '../../core/router/app_routes.dart';
import '../../../core/widgets/form/form_item_config.dart';
import '../../../core/widgets/my_text.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import '../../../core/helpers/snackbar_helper.dart';
import '../../core/widgets/my_form.dart';
import '../auth/bloc/auth_cubit.dart';

/// ForgotPasswordPage - Password recovery page
///
/// Allows users to request a password reset link via email.
/// Uses the existing MyForm pattern for consistent form handling.
class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  bool _emailSent = false;
  bool _isLoading = false;

  List<FormItemConfig> _buildFormItems() {
    return [
      FormItemConfig.email(
        id: 'email',
        label: LocaleKeys.email,
        hintText:LocaleKeys.enterYourEmail,
      ),
    ];
  }

  Future<void> _handlePasswordReset(Map<String, dynamic> data) async {
    final email = (data['email'] as String?)?.trim().toLowerCase() ?? '';

    setState(() {
      _isLoading = true;
    });

    try {
      final authCubit = GetIt.I<AuthCubit>();
      await authCubit.resetPassword(email);

      setState(() {
        _emailSent = true;
        _isLoading = false;
      });

      SnackBarHelper.showSuccess(context, LocaleKeys.passwordResetSent);
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      SnackBarHelper.showError(context, LocaleKeys.errorSendingEmail);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.lock_reset),
            const SizedBox(width: 8),
            const MyText(LocaleKeys.forgotPassword),
          ],
        ),
      ),
      body: Column(
        children: [
          const SizedBox(height: 30),

          // Page title
          const MyText(LocaleKeys.forgotPassword, margin: 20),

          // Show success message if email was sent
          if (_emailSent) _buildSuccessMessage(context),

          // Show form if email not sent yet
          if (!_emailSent) _buildForm(context),

          const SizedBox(height: 30),

          // Back to login link
          _buildBackToLoginLink(context),
        ],
      ),
    );
  }

  Widget _buildForm(BuildContext context) {
    return MyForm(
      title: LocaleKeys.forgotPassword,
      formItems: _buildFormItems(),
      onSubmit: _handlePasswordReset,
      isLoading: _isLoading,
      showTitle: false,
      buttonText: LocaleKeys.resetPassword,
      spacing: 16,
      footerWidget: _buildInfoText(context),
    );
  }

  Widget _buildInfoText(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 16),
      child: MyText(
        LocaleKeys.checkEmailInfo,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
        textAlign: TextAlign.center,
        width: 500,
      ),
    );
  }

  Widget _buildSuccessMessage(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      constraints: const BoxConstraints(maxWidth: 500),
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.mark_email_read_outlined,
            size: 64,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(height: 16),
          MyText(
            LocaleKeys.checkEmail,
            style: theme.textTheme.headlineSmall?.copyWith(
              color: theme.colorScheme.onPrimaryContainer,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          MyText(
            LocaleKeys.checkEmailInfo,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onPrimaryContainer,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildBackToLoginLink(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const MyText(LocaleKeys.backToLogin),
        TextButton(
          onPressed: () => context.go(AppRoutes.login),
          child: const MyText(LocaleKeys.logIn),
        ),
      ],
    );
  }
}
