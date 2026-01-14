class TournamentRoutes {
  // Tournaments Management (Public routes)
  static const String tournaments = '/tournaments'; // List view
  static const String tournamentDetail = '/tournaments/:id';
  static const String tournamentStandings = '/tournaments/:id/standings';

  // Tournaments Management (Dashboard/Private routes)
  static const String myTournaments = 'my-tournaments'; // Relative for router
  static const String dashboardTournaments = 'tournaments'; // Relative for router
  static const String tournamentCreate = 'create'; // Nested under tournaments
  static const String tournamentEdit = 'edit/:id'; // Nested under tournaments

  // Absolute paths for navigation (use these when calling NavigationService.go)
  static String get myTournamentsNav => '/dashboard/my-tournaments';
  static String get dashboardTournamentsNav => '/dashboard/tournaments';
  static String get tournamentCreateNav => '/dashboard/tournaments/create';
  static String tournamentEditNav(String id) => '/dashboard/tournaments/edit/$id';

  // Helper methods for building routes with parameters
  static String getTournamentDetail(String id) => '/tournaments/$id';
  static String getTournamentStandings(String id) => '/tournaments/$id/standings';
}
