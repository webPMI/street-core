import 'package:go_router/go_router.dart';

import '../../core/router/app_routes.dart';
import '../dashboard/forgot_password_page.dart';
import '../public/login_page.dart';
import '../public/register/register_page.dart';

final List publicAuthRoutes = [
  GoRoute(
    path: AppRoutes.forgotPassword,
    builder: (context, state) => const ForgotPasswordPage(),
  ),
  GoRoute(
    //---Ruta de registro: Pantalla de registro de nuevos usuarios
    path: AppRoutes.register,
    builder: (context, state) => const RegisterPage(),
  ),
  GoRoute(
    //---Ruta de acceso: Pantalla de login
    path: AppRoutes.login,
    builder: (context, state) => const LoginPage(),
  ),
];
