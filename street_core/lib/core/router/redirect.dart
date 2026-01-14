import 'dart:async';

import '../helpers/user_permissions.dart';
import '/core/router/app_routes.dart';
import '/core/router/navigation_service.dart';
import '/features/auth/auth.dart';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

FutureOr<String?> redirect(BuildContext context, GoRouterState state) async {
  //
  final NavigationService routeService = NavigationService();
  // Leemos el estado actual del AuthCubit
  final authState = context.read<AuthCubit>().state;
  final bool isAuthenticated =
      authState is AuthAuthenticated || authState is AuthSuccess;
  final bool isCheckingSession =
      authState is AuthCheckingSession || authState is AuthLoading;
  // Rutas que no requieren autenticación
  final bool isPublicRoute = !state.matchedLocation.contains(
    AppRoutes.dashboard,
  );

  // 2.1 Si está revisando la sesión
  // GOLDEN RULE: NO redirigir a splash si estamos en una ruta pública válida
  // Esto permite que las URLs públicas se mantengan al recargar la página
  if (isCheckingSession) {
    // Si es una ruta pública, permitir quedarse en ella mientras verifica sesión
    if (isPublicRoute && state.matchedLocation != AppRoutes.home) {
      return null; // Mantener la ruta pública actual
    }
    // Solo ir a splash si estamos en home o en una ruta protegida
    return state.matchedLocation == AppRoutes.splash ? null : AppRoutes.splash;
  }

  // 2.2 Si está autenticado
  if (isAuthenticated) {
    // Check permissions for admin routes
    final userState = context.read<UserCubit>().state;
    if (userState is UserLoaded) {
      final user = userState.user;

      // Admin routes require admin role
      final isAdminRoute = state.matchedLocation.startsWith('/dashboard/admin');
      if (isAdminRoute && !UserPermissions.isAdmin(user)) {
        // Redirect to dashboard if user is not admin
        return AppRoutes.dashboard;
      }
    }

    // 🚀 Lógica de redirección a la última ruta guardada
    // GOLDEN RULE: Solo restaurar si el usuario está INTENCIONALMENTE en rutas genéricas
    // NO restaurar si está en una ruta específica (evita perder la URL al recargar)
    final currentPath = state.matchedLocation;
    final shouldRestoreRoute =
        currentPath == AppRoutes.home || // Solo desde home (/)
        currentPath == AppRoutes.login || // O desde login
        currentPath == AppRoutes.dashboard; // O desde dashboard base

    if (shouldRestoreRoute) {
      final lastRoute = await routeService.getRoute();
      // Si hay una última ruta guardada diferente a la actual, navegar a ella
      if (lastRoute != null &&
          lastRoute != currentPath &&
          lastRoute.startsWith('/dashboard')) {
        // NO limpiar la ruta aquí - se limpiará automáticamente
        // cuando el usuario navegue a otra ruta
        return lastRoute;
      }
    }

    // GOLDEN RULE: Si estás en una ruta específica (pública o privada), MANTENERLA
    return null; // Permanecer en la ruta actual
  }

  // 2.3 Si NO está autenticado
  if (!isAuthenticated) {
    // Si el usuario intenta acceder a cualquier ruta pública, permitir acceso
    // Si intenta acceder a ruta protegida, redirigir a Login
    return isPublicRoute ? null : AppRoutes.login;
  }

  return null; // Caso por defecto
}
