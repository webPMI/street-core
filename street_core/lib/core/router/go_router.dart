import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../features/auth/auth.dart';
import '../../features/dashboard/not_found_dashboard_page.dart';
import '../../features/public/components/public_layout.dart';

import '../../features/public/not_found_public_page.dart';
import '../seo/seo_route_observer.dart'; // Ya es relativa
// Relative path
// Relative path

import 'app_routes.dart'; // Relative path
//import '/core/seo/seo.dart';
import 'package:go_router/go_router.dart';

import 'dashboard_routes.dart';
import 'public_routes.dart';
import 'redirect.dart' as redirect_helper;

// Saved Route to navigate

final GoRouter router = GoRouter(
  // 1. Ruta de inicio para comprobar la sesión
  initialLocation: AppRoutes.home,

  // 2. 🎯 Redirección: El corazón del "Auth Guard"
  redirect: redirect_helper.redirect,

  // 3. SEO: Actualiza meta tags automáticamente al navegar (solo en web)
  observers: [SeoRouteObserver()],

  // 4. 🎯 Error Handler: Context-aware 404 pages
  errorPageBuilder: (context, state) {
    // Check if user is authenticated to show correct 404 page
    try {
      final authState = context.read<AuthCubit>().state;
      final isAuthenticated =
          authState is AuthAuthenticated || authState is AuthSuccess;

      if (isAuthenticated) {
        return MaterialPage(
          key: state.pageKey,
          child: const NotFoundDashboardPage(),
        );
      }
    } catch (_) {
      // If AuthCubit is not available, show public 404
    }
    return MaterialPage(key: state.pageKey, child: const NotFoundPublicPage());
  },

  routes: <RouteBase>[
    // 4. Rutas No Protegidas (Autenticación)
    ShellRoute(
      routes: publicRoutes,
      builder: (context, state, child) {
        return PublicLayout(child: child);
      },
    ),
    // 5. 🎯 Rutas Protegidas (Dashboard y Anidamiento)
    ...privateRoutes,
  ],
);
