//Rutas publicas
import 'package:go_router/go_router.dart';
import 'package:street_core/features/auth/auth_routes.dart';
import 'app_routes.dart';
import '../../features/public/home_page/home_page.dart';
import '../../features/public/splash_screen.dart';

import '../../features/public/contact/contact_page.dart';

// Import feature routers directly (routes must be available at compile time)
import '../../features/competitions/competition_router.dart';
import '../../features/tournaments/tournament_router.dart';

final publicRoutes = <RouteBase>[
  GoRoute(
    //---Ruta raíz: Redirige a la HomePage principal
    path: AppRoutes.home,
    builder: (context, state) => const HomePage(),
  ),

  GoRoute(
    //---Ruta de contacto: Formulario para dudas o soporte
    path: AppRoutes.contact,
    builder: (context, state) => const ContactPage(),
  ),

  GoRoute(
    path: AppRoutes.splash, // Que es '/loading'
    builder: (context, state) => const SplashScreen(),
  ),
  ...publicAuthRoutes,
  // Competition public routes (compile-time)
  ...publicCompetitionRoutes,
  // Tournament public routes (compile-time)
  ...publicTournamentRoutes,
];
