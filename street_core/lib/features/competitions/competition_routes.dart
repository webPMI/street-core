class CompetitionRoutes {
  // Competitions Management (Public routes - no dashboard prefix)
  static const String competitions = '/competitions'; // Dashboard
  static const String competitionsList = '/competitions/list'; // List view
  static const String competitionsDocumentation = '/competitions/docs'; // Documentation
  static const String competitionDetail = '/competitions/:id';
  static const String competitionRegister = '/competitions/:id/register';

  // Competition Categories (Public routes)
  static const String categoryDetail =
      '/competitions/:competitionId/categories/:categoryId';
  static const String categoryRanking =
      '/competitions/:competitionId/categories/:categoryId/ranking';
  static const String categoryCreate =
      '/competitions/:competitionId/categories/create';
  static const String categoryEdit =
      '/competitions/:competitionId/categories/:categoryId/edit';

  static String get myCompetitions => '/dashboard/my-competitions';
  // Competitions Management (Dashboard/Private routes)
  // NOTE: Relative paths for router, absolute paths for navigation
  static const String dashboardCompetitions =
      'competitions'; // Relative for router (Dashboard with tabs)
  static const String dashboardCompetitionsList = 'list'; // Nested: competitions list view
  static const String competitionCreate = 'create'; // Nested under competitions
  static const String competitionEdit = 'edit/:id'; // Nested under competitions

  // Judge Management (Dashboard/Private routes)
  static const String myJudgeInvitations =
      'judge/invitations'; // Relative for router
  static const String judgeScoring =
      'competitions/:competitionId/categories/:categoryId/scoring'; // Relative for router

  // Absolute paths for navigation (use these when calling NavigationService.go)
  static String get dashboardCompetitionsNav => '/dashboard/competitions';
  static String get dashboardCompetitionsListNav => '/dashboard/competitions/list';
  static String get competitionCreateNav => '/dashboard/competitions/create';
  static String competitionEditNav(String id) =>
      '/dashboard/competitions/edit/$id';
  static String get myJudgeInvitationsNav => '/dashboard/judge/invitations';

  // Helper for judge scoring
  static String getJudgeScoring(String competitionId, String categoryId) =>
      '/dashboard/competitions/$competitionId/categories/$categoryId/scoring';

  // Helper methods for building routes with parameters
  static String getCompetitionDetail(String id) => '/competitions/$id';
  static String getCompetitionRegister(String id) =>
      '/competitions/$id/register';
  static String getCategoryDetail(String competitionId, String categoryId) =>
      '/competitions/$competitionId/categories/$categoryId';
  static String getCategoryRanking(String competitionId, String categoryId) =>
      '/competitions/$competitionId/categories/$categoryId/ranking';
  static String getCategoryCreate(String competitionId) =>
      '/competitions/$competitionId/categories/create';
  static String getCategoryEdit(String competitionId, String categoryId) =>
      '/competitions/$competitionId/categories/$categoryId/edit';
}
