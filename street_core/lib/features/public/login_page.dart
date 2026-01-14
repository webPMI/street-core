import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:street_core/core/lang/locale_keys.dart';
import 'package:street_core/core/router/app_routes.dart';

import '../../core/helpers/snackbar_helper.dart';
import '../../core/router/navigation_service.dart';
import '../../core/widgets/drawer/my_drawer.dart';
import '../../core/widgets/form/form_item_config.dart';
import '../../core/widgets/my_form.dart';
import '../../core/widgets/my_text.dart';
import '../auth/bloc/auth_cubit.dart';
import '../auth/bloc/auth_state.dart';

/// LoginPage using MyForm for consistent form handling
//---Página de inicio de sesión: Formulario de email y contraseña
class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  //---Configuración de los campos del formulario de login
  List<FormItemConfig> _buildFormItems() {
    return [
      FormItemConfig.email(
        id: 'email',
        label: LocaleKeys.email,
        hintText: LocaleKeys.enterEmail,
        defaultValue: 'admin@fitriders.com',
      ),
      FormItemConfig.password(
        id: 'password',
        label: LocaleKeys.password,
        hintText: LocaleKeys.writeYourPassword,
        defaultValue: 'Aa-1234!',
      ),
    ];
  }

  //---Lógica de autenticación al presionar el botón de ingresar
  void _handleLogin(BuildContext context, Map<String, dynamic> data) {
    final email = (data['email'] as String?)?.trim().toLowerCase() ?? '';
    final password = (data['password'] as String?)?.trim() ?? '';

    context.read<AuthCubit>().login(email, password);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.login),
            const SizedBox(width: 8),
            const MyText(LocaleKeys.logIn),
          ],
        ),
      ),
      drawer: MyDrawer(),
      body: BlocConsumer<AuthCubit, AuthState>(
        listener: (context, state) {
          if (state is AuthSuccess) {
            SnackBarHelper.showSuccess(context, LocaleKeys.loginSuccessful);
          } else if (state is AuthError) {
            SnackBarHelper.showError(context, state.message);
          }
        },
        builder: (context, state) {
          final isLoading = state is AuthLoading;

          return SingleChildScrollView(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 30),

                  // Login Form
                  SizedBox(
                    width: 400,
                    child: MyForm(
                      title: LocaleKeys.logIn,
                      showTitle: false,
                      formItems: _buildFormItems(),
                      onSubmit: (data) => _handleLogin(context, data),
                      isLoading: isLoading,
                      buttonText: LocaleKeys.logIn,
                      spacing: 16,
                      footerWidget: _buildForgotPassword(context),
                    ),
                  ),

                  // Error message
                  if (state is AuthError)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: MyText(state.message, color: Colors.red),
                    ),

                  const SizedBox(height: 30),

                  // Register link
                  _buildRegisterLink(context),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  //---Enlace para recuperar la contraseña olvidada
  Widget _buildForgotPassword(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 16),
      child: TextButton(
        onPressed: () {
          context.push(AppRoutes.forgotPassword);
        },
        child: const MyText(
          LocaleKeys.forgotPassword,
          width: 250,
          alignment: Alignment.center,
          selectable: false,
        ),
      ),
    );
  }

  //---Enlace para redirigir al registro de nuevos usuarios
  Widget _buildRegisterLink(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const MyText(LocaleKeys.noAccountYet),
        TextButton(
          onPressed: () => NavigationService().go(context, AppRoutes.register),
          child: const MyText(LocaleKeys.register, selectable: false),
        ),
      ],
    );
  }
}
