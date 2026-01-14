import '/features/public/home_page/footer.dart';

import '../../../core/helpers/snackbar_helper.dart';
import '../../../core/lang/context_tr.dart';
import '../../../core/lang/locale_keys.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/widgets/form/form_item_config.dart';
import '../../../core/widgets/my_text.dart';
import '../../../core/widgets/drawer/my_drawer.dart';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/helpers/validators.dart';
import '../../../../core/widgets/my_container.dart';
import '../../../../core/widgets/my_form.dart';
import '../../auth/auth.dart';
import '../components/policy_acceptance_dialog.dart';

/// Register Page - Uses MyForm with AuthCubit
class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  // Policy checkbox state (not part of form data)
  bool _acceptPolicy = false;

  // Build form configuration
  List<FormItemConfig> _buildFormItems() {
    return [
      // Personal Information Section
      FormItemConfig(
        id: 'firstName',
        type: FormFieldType.text,
        label: LocaleKeys.name,
        hintText: LocaleKeys.firstName,
        isRequired: true,
        autofillHints: const [AutofillHints.name],
        validator: RequiredValidator(),
        maxLength: 30,
      ),
      FormItemConfig(
        id: 'lastName',
        type: FormFieldType.text,
        label: LocaleKeys.lastName,
        hintText: LocaleKeys.lastName,
        autofillHints: const [AutofillHints.familyName],
        maxLength: 30,
      ),

      // Contact Section
      FormItemConfig(
        id: 'phone',
        type: FormFieldType.text,
        label: LocaleKeys.phone,
        hintText: LocaleKeys.phone,
        autofillHints: const [AutofillHints.telephoneNumber],
      ),
      FormItemConfig(
        hintText: LocaleKeys.gender,
        id: 'gender',
        type: FormFieldType.dropdown,
        label: LocaleKeys.selectGender,
        defaultValue: LocaleKeys.other,
        options: const [LocaleKeys.female, LocaleKeys.male, LocaleKeys.other],
      ),
      FormItemConfig.country(id: 'country', label: LocaleKeys.countryOfBorn),
      FormItemConfig(
        id: 'email',
        type: FormFieldType.email,
        label: LocaleKeys.email,
        hintText: LocaleKeys.email,
        isRequired: true,
        autofillHints: const [AutofillHints.email],
        validator: EmailValidator(),
        maxLength: 50,
      ),

      // Security Section
      FormItemConfig(
        id: 'password',
        type: FormFieldType.password,
        hintText: LocaleKeys.password,
        label: LocaleKeys.password,
        isRequired: true,
        validator: PasswordValidator(),
      ),
      FormItemConfig(
        id: 'confirmPassword',
        type: FormFieldType.password,
        hintText: LocaleKeys.confirmPassword,
        label: LocaleKeys.confirmPassword,
        isRequired: true,
      ),
    ];
  }

  void _handleRegister(Map<String, dynamic> data) {
    // Validate policy acceptance
    if (!_acceptPolicy) {
      SnackBarHelper.showWarning(context, LocaleKeys.acceptPoliciesRequired);
      return;
    }

    // Validate password confirmation
    if (data['password'] != data['confirmPassword']) {
      SnackBarHelper.showError(context, LocaleKeys.passwordsDontMatch);
      return;
    }

    // Remove confirmPassword (not needed for API)
    data.remove('confirmPassword');

    // Sanitize input
    if (data['firstName'] != null) {
      data['firstName'] = data['firstName'].toString().trim();
    }
    if (data['lastName'] != null) {
      data['lastName'] = data['lastName'].toString().trim();
    }
    if (data['email'] != null) {
      data['email'] = data['email'].toString().trim().toLowerCase();
    }
    if (data['phone'] != null) {
      data['phone'] = data['phone'].toString().trim();
    }
    if (data['password'] != null) {
      data['password'] = data['password'].toString().trim();
    }

    // Use AuthCubit for registration
    context.read<AuthCubit>().register(data);
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.person_add),
            const SizedBox(width: 8),
            const MyText(LocaleKeys.register),
          ],
        ),
      ),
      drawer: MyDrawer(),
      body: BlocConsumer<AuthCubit, AuthState>(
        listener: (context, state) {
          if (state is AuthSuccess) {
            SnackBarHelper.showSuccess(context, LocaleKeys.successRegister);
            // Navigate to home after successful registration
            context.go(AppRoutes.home);
          } else if (state is AuthError) {
            SnackBarHelper.showError(context, state.message);
          }
        },
        builder: (context, state) {
          final isLoading = state is AuthLoading;

          return ListView(
            children: [
              // MyForm handles form UI and validation
              MyForm(
                title: LocaleKeys.register,
                buttonText: LocaleKeys.register,
                formItems: _buildFormItems(),
                isLoading: isLoading,
                footerWidget: _buildPolicySection(context),
                onSubmit: _handleRegister,
              ),

              const SizedBox(height: 24),

              // Login link
              _buildLoginLink(context),
              const SizedBox(height: 34),
              Footer(),
            ],
          );
        },
      ),
    );
  }

  // Policy section - outside of MyForm since it's not a form field
  Widget _buildPolicySection(BuildContext context) {
    final theme = Theme.of(context);

    return MyContainer(
      maxWidth: 500,
      margin: 16,
      padding: 12,
      color: _acceptPolicy
          ? theme.colorScheme.primaryContainer.withValues(alpha: 0.3)
          : theme.colorScheme.surfaceContainerHighest,
      borderRadius: 12,
      borderColor: _acceptPolicy
          ? theme.colorScheme.primary
          : theme.colorScheme.outline.withValues(alpha: 0.3),

      child: Row(
        children: [
          // Checkbox with animation
          Transform.scale(
            scale: 1.1,
            child: Checkbox(
              value: _acceptPolicy,
              onChanged: (value) {
                if ((value ?? false) && !_acceptPolicy) {
                  // Si intenta marcar, mostrar diálogo primero
                  _showPolicyDialog(context);
                } else {
                  setState(() {
                    _acceptPolicy = value ?? false;
                  });
                }
              },
              activeColor: theme.colorScheme.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Text and link
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    const MyText(LocaleKeys.iHaveReadAndAccept),
                    TextButton(
                      onPressed: () => _showPolicyDialog(context),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        visualDensity: VisualDensity.compact,
                      ),
                      child: MyText(
                        LocaleKeys.termsAndPolicies,
                        style: TextStyle(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w600,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ),
                if (_acceptPolicy)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Row(
                      children: [
                        Icon(
                          Icons.check_circle,
                          size: 14,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 4),
                        MyText(
                          LocaleKeys.policiesAccepted,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          // View policies button
          IconButton(
            onPressed: () => _showPolicyDialog(context),
            icon: Icon(
              Icons.open_in_new,
              size: 20,
              color: theme.colorScheme.primary,
            ),
            tooltip: context.tr(LocaleKeys.viewPolicies),
          ),
        ],
      ),
    );
  }

  Future<void> _showPolicyDialog(BuildContext context) async {
    final accepted = await PolicyAcceptanceDialog.show(context);
    if (!mounted) return;
    if (accepted) {
      setState(() {
        _acceptPolicy = true;
      });
    }
  }

  Widget _buildLoginLink(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const MyText(LocaleKeys.alreadyHaveAccount),
        TextButton(
          onPressed: () => context.go(AppRoutes.login),
          child: const MyText(LocaleKeys.logIn, selectable: false),
        ),
      ],
    );
  }
}
