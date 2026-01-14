// Renombramos AppRoutes para usar las rutas directamente en el código de go_router,
// pero mantenemos los paths como constantes si lo deseas:
abstract class AppRoutes {
  //Routes of app
  static const String splash = '/loading';
  static const String home = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String dashboard = '/dashboard';
  static const String chat = '/dashboard/chat';

  // Admin Extra Routes
  static const String clubMembers = '/club-members';
  static const String liveCompetitions = '/competitions/live';
  static const String judges = '/judges';
  static const String clubAnalytics = '/analytics/clubs';
  static const String competitionAnalytics = '/analytics/competitions';
  static const String rankings = '/rankings';
  static const String sportTypesSettings = '/settings/sports';
  static const String competitionFormats = '/settings/formats';
  static const String judgingCriteria = '/settings/criteria';

  // Public routes (no authentication required)
  static const String publicAthletes = '/athletes';
  static const String publicAthleteDetail = '/athletes/:id';
  static const String publicClubs = '/clubs';
  static const String publicClubDetail = '/clubs/:id';
  static const String publicMarket = '/market';
  static const String publicMarketDetail = '/market/:id';
  static const String publicEvents = '/events';
  static const String publicEventDetail = '/events/:id';
  static const String publicTournaments = '/tournaments';
  static const String publicTournamentDetail = '/tournaments/:id';
  static const String contact = '/contact';

  // Legal pages
  static const String legal = '/legal';
  static const String privacyPolicy = '/privacy-policy';
  static const String termsOfService = '/terms-of-service';
  static const String cookiePolicy = '/cookie-policy';
  static const String refundPolicy = '/refund-policy';
  static const String dataProtection = '/data-protection';
}
