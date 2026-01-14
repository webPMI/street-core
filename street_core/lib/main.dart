import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'core/helpers/logger.dart';
import 'core/lang/bloc/locale_state.dart'; // Relative path
import 'core/lang/context_tr.dart'; // Relative path
import 'core/router/app_routes.dart'; // Relative path
import 'core/router/navigation_service.dart'; // Relative path
import 'core/theme/bloc/theme_cubit.dart'; // Relative path

import 'core/lang/locale_keys.dart'; // Add this import
import 'core/di/injection.dart';
import 'core/lang/bloc/locale_cubit.dart';
import 'core/location/bloc/location_cubit.dart';
import 'core/widgets/help_guide/bloc/guide_cubit.dart';
import 'core/router/go_router.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/bloc/theme_state.dart'; // Relative path
import 'features/auth/bloc/auth_cubit.dart'; // Relative path
import 'features/auth/bloc/auth_state.dart'; // Relative path
import 'features/auth/bloc/user_cubit.dart'; // Relative path
import 'features/public/consent/consent_cubit.dart'; // Relative path
import 'features/public/site_config/site_config.dart'; // Relative path

//frontend STREET CORE application
/// The main entry point of the Flutter application.
/// Initializes dependency injection and runs the [MyApp] widget.
Future<void> main() async {
try {
    //---Asegura que los servicios de Flutter estén listos
  WidgetsFlutterBinding.ensureInitialized();
  //---Inicializa datos de locale para formateo de fechas
  await initializeDateFormatting();
  //---Configura la inyección de dependencias (GetIt)
  await setupDependencyInjection();
  // HERRAMIENTAS DE DESARROLLO
  runApp(const MyApp());
} catch (e) {
  AppLogger.error('Fatal error during app initialization', error: e, tag: 'Main');
}
}

/// The root widget of the Street Core application.
///
/// Sets up app structure, theme, and global state management.
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Provides global BLoC/Cubit instances to the widget tree.
    return MultiBlocProvider(
      providers: [
        // ===== GLOBAL CUBITS (needed throughout the app) =====
        BlocProvider(create: (_) => getIt<LocaleBloc>()),
        BlocProvider(create: (_) => getIt<ThemeCubit>()),
        // Location Cubit (Global)
        BlocProvider(create: (_) => getIt<LocationCubit>()),
        // Consent Cubit (Global)
        BlocProvider(create: (_) => getIt<ConsentCubit>()),
        // Help Guide Cubit (Global) - Manages contextual help system
        BlocProvider(create: (_) => getIt<GuideCubit>()),
        BlocProvider(create: (_) => getIt<AuthCubit>()..initialize()),
        BlocProvider<UserCubit>.value(value: getIt<UserCubit>()),
        // SiteConfigCubit - unified config for header/footer, legal, contact, landing
        BlocProvider<SiteConfigCubit>.value(value: getIt<SiteConfigCubit>()),
      ],
      //---Escucha los cambios de autenticación
      child: BlocBuilder<LocaleBloc, LocaleState>(
        builder: (context, state) {
          return BlocListener<AuthCubit, AuthState>(
            listener: (context, state) async {
              if (state is AuthAuthenticated) {
                // GOLDEN RULE: Solo redirigir si el usuario está en una ruta de autenticación
                // NO redirigir si está restaurando sesión en una ruta específica
                final currentLocation = router
                    .routerDelegate
                    .currentConfiguration
                    .uri
                    .toString();
                final isOnAuthRoute =
                    currentLocation == AppRoutes.login ||
                    currentLocation == AppRoutes.register ||
                    currentLocation == AppRoutes.home ||
                    currentLocation == AppRoutes.splash;

                if (isOnAuthRoute) {
                  // Solo redirigir cuando el usuario viene de login/register
                  final route = await NavigationService().getRoute();
                  router.go(route ?? AppRoutes.dashboard);
                }
                // Si está en otra ruta (ej: /competitions/123), mantenerla
              } else if (state is AuthUnauthenticated) {
                router.refresh();
              }
            },
            child: BlocBuilder<LocaleBloc, LocaleState>(
              builder: (context, state) {
                return BlocBuilder<ThemeCubit, ThemeState>(
                  builder: (context, themeState) {
                    final baseName = themeState.baseThemeName;
                    final lightThemeName = '$baseName Light';
                    final darkThemeName = '$baseName Dark';
                    return MaterialApp.router(
                      debugShowCheckedModeBanner: false,
                      title: context.tr(LocaleKeys.appTitle),

                      // THEME SYSTEM - Material Design 3
                      // Define both light and dark themes
                      theme: AppTheme.getTheme(lightThemeName),
                      darkTheme: AppTheme.getTheme(darkThemeName),

                      // Control which theme to use based on current state
                      themeMode: themeState.isDark
                          ? ThemeMode.dark
                          : ThemeMode.light,

                      // Theme transition animation
                      themeAnimationDuration: const Duration(milliseconds: 300),
                      themeAnimationCurve: Curves.easeInOut,

                      // ROUTING
                      routerConfig: router,
                    );
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }
}
