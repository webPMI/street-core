/// URI constants for tournament endpoints
class TournamentsUris {
  // Base path
  static const String _base = '/tournaments';

  // Tournament CRUD
  static const String list = _base;
  static const String upcoming = '$_base/upcoming';
  static const String live = '$_base/live';
  static String byStatus(String status) => '$_base/status/$status';
  static String byOrganizer(String organizerId) => '$_base/organizer/$organizerId';
  static String detail(String id) => '$_base/$id';
  static const String create = _base;
  static String update(String id) => '$_base/$id';
  static String delete(String id) => '$_base/$id';

  // Standings
  static String standings(String tournamentId) => '$_base/$tournamentId/standings';
  static String topStandings(String tournamentId) => '$_base/$tournamentId/standings/top';
  static String updateStandings(String tournamentId) => '$_base/$tournamentId/standings/update';

  // Competitions
  static String addCompetition(String tournamentId) => '$_base/$tournamentId/competitions';

  // Registrations (for future implementation)
  static String register(String tournamentId) => '$_base/$tournamentId/register';
  static String unregister(String tournamentId) => '$_base/$tournamentId/register';
}
