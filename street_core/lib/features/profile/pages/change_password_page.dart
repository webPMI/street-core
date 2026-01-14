import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/helpers/snackbar_helper.dart';
import '../../../core/lang/context_tr.dart';
import '../../../core/lang/locale_keys.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/router/navigation_service.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/my_password_field.dart';
import '../../../core/widgets/my_text.dart';
import '../repositories/profile_repository.dart';

/// Change Password Page
///
/// Allows users to change their password securely with:
/// - Current password verification
/// - New password with strength indicator
/// - Password confirmation
/// - Form validation
class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscureCurrentPassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleChangePassword() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final profileRepository = context.read<ProfileRepository>();

      await profileRepository.changePassword(
        currentPassword: _currentPasswordController.text,
        newPassword: _newPasswordController.text,
      );

      if (!mounted) return;

      // Show success message
      SnackBarHelper.showSuccess(
        context,
        context.tr(LocaleKeys.passwordChangedSuccessfully),
      );

      // Navigate to login (user has been logged out automatically)
      Future<void>.delayed(const Duration(seconds: 2), () {
        if (!mounted) return;
        NavigationService().go(context, AppRoutes.login);
      });
    } catch (e) {
      if (!mounted) return;

      setState(() => _isLoading = false);

      SnackBarHelper.showError(
        context,
        e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const MyText(LocaleKeys.changePassword),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: AppSpacing.edgeInsetsLG,
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Security Icon
                Icon(Icons.lock_outline, size: 80, color: colorScheme.primary),
                const SizedBox(height: AppSpacing.lg),

                // Title
                MyText(
                  LocaleKeys.changeYourPassword,

                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.sm),

                // Subtitle
                MyText(
                  LocaleKeys.passwordChangeDescription,
                  selectable: false,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.xl),

                // Current Password
                TextFormField(
                  controller: _currentPasswordController,
                  obscureText: _obscureCurrentPassword,
                  decoration: InputDecoration(
                    labelText: context.tr(LocaleKeys.currentPassword),
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureCurrentPassword
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscureCurrentPassword = !_obscureCurrentPassword;
                        });
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return context.tr(LocaleKeys.fieldRequired);
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.lg),
                // NEW PASSWORD
                MyPasswordField(
                  controller: _newPasswordController,
                  isNew: true,
                ),
                // New Password -- REPEATED FOR CLARITY --
                MyPasswordField(
                  controller: _confirmPasswordController,
                  isRepeat: true,
                  pass: _newPasswordController,
                ),

                // Submit Button
                FilledButton(
                  onPressed: _isLoading ? null : _handleChangePassword,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.md,
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const MyText(LocaleKeys.changePassword, selectable: false),
                ),
                const SizedBox(height: AppSpacing.md),

                // Cancel Button
                OutlinedButton(
                  onPressed: _isLoading
                      ? null
                      : () => NavigationService().pop(context),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.md,
                    ),
                  ),
                   child: const MyText(LocaleKeys.cancel, selectable: false),
                ),
                const SizedBox(height: AppSpacing.xl),

                // Security Tips
                Container(
                  padding: AppSpacing.edgeInsetsMD,
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(
                      color: colorScheme.primary.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.tips_and_updates,
                            color: colorScheme.primary,
                            size: 20,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          MyText(
                            LocaleKeys.securityTips,
                            selectable: false,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      _buildSecurityTip(LocaleKeys.passwordMinLength),
                      _buildSecurityTip(LocaleKeys.passwordHasUppercase),
                      _buildSecurityTip(LocaleKeys.passwordHasLowercase),
                      _buildSecurityTip(LocaleKeys.passwordHasNumber),
                      _buildSecurityTip(LocaleKeys.passwordHasSpecial),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSecurityTip(String tip) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xs),
      child: Row(
        children: [
          Icon(
            Icons.check_circle,
            size: 16,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Text(context.tr(tip), style: Theme.of(context).textTheme.bodySmall),
          ),
        ],
      ),
    );
  }
}
