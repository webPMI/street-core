/// API URIs and Route paths for the Competitions module
///
/// All competition-related backend endpoints and navigation routes.
/// Following Monolith-by-Features architecture (ADR-005).
library;

import '../../config/env.dart';

class CompetitionsUris {
  static const String _api = '/api/${Env.apiVersion}';

  // ============================================================================
  // NAVIGATION ROUTES
  // ============================================================================

  /// Route: Public competitions list
  static const String publicRoute = '/competitions';

  /// Route: Public competition detail
  static String publicDetailRoute(String id) => '/competitions/$id';

  /// Route: Dashboard competitions list (private)
  static const String route = '/dashboard/competitions';

  /// Route: Create competition (private)
  static const String createRoute = '/dashboard/competitions/create';

  /// Route: Edit competition (private)
  static String editRoute(String id) => '/dashboard/competitions/edit/$id';

  // ============================================================================
  // COMPETITIONS CRUD
  // ============================================================================

  /// GET - List all competitions (public)
  static const String list = '$_api/competitions';

  /// GET - Upcoming competitions (public)
  static const String upcoming = '$_api/competitions/upcoming';

  /// GET - Live competitions (public)
  static const String live = '$_api/competitions/live';

  /// GET - Search competitions (public)
  static const String search = '$_api/competitions/search';

  /// GET - Featured competitions (public)
  static const String featured = '$_api/competitions/featured';

  /// GET - Nearby competitions (public)
  static const String nearby = '$_api/competitions/nearby';

  /// GET - User's competitions (protected)
  static const String myCompetitions = '$_api/competitions/my';

  /// POST - Create competition (protected)
  static const String create = '$_api/competitions';

  /// GET - Competition details (public)
  static String detail(String id) => '$_api/competitions/$id';

  /// PUT - Update competition (protected)
  static String update(String id) => '$_api/competitions/$id';

  /// DELETE - Delete competition (protected)
  static String delete(String id) => '$_api/competitions/$id';

  // ============================================================================
  // COMPETITION LIFECYCLE
  // ============================================================================

  /// GET - Validate if competition can be started (protected)
  static String validateStart(String id) => '$_api/competitions/$id/validate-start';

  /// POST - Start competition (protected) - upcoming → live
  static String start(String id) => '$_api/competitions/$id/start';

  /// POST - End competition (protected) - live → completed
  static String end(String id) => '$_api/competitions/$id/end';

  /// POST - Postpone competition (protected) - upcoming/live → postponed
  static String postpone(String id) => '$_api/competitions/$id/postpone';

  /// POST - Publish results (protected)
  static String publishResults(String id) =>
      '$_api/competitions/$id/publish-results';

  // ============================================================================
  // REGISTRATION
  // ============================================================================

  /// POST - Register to competition (protected)
  static String register(String id) => '$_api/competitions/$id/register';

  /// DELETE - Unregister from competition (protected)
  static String unregister(String id) => '$_api/competitions/$id/register';

  // ============================================================================
  // PARTICIPANTS
  // ============================================================================

  /// GET - List participants (public)
  static String participants(String id) =>
      '$_api/competitions/$id/participants';

  /// GET - Participant count (public)
  static String participantCount(String id) =>
      '$_api/competitions/$id/participants/count';

  // ============================================================================
  // SCORING
  // ============================================================================

  /// GET - Get competition scores (public)
  static String getScores(String id) => '$_api/competitions/$id/scores';

  /// POST - Submit scores (protected)
  static String submitScores(String id) => '$_api/competitions/$id/scores';

  /// GET - Get scores by athlete (public)
  static String getScoresByAthlete(String competitionId, String athleteId) =>
      '$_api/competitions/$competitionId/scores/athlete/$athleteId';

  /// GET - Get scores by round (public)
  static String getScoresByRound(String competitionId, String roundId) =>
      '$_api/competitions/$competitionId/scores/round/$roundId';

  // ============================================================================
  // LEADERBOARD
  // ============================================================================

  /// GET - Get leaderboard (public)
  static String leaderboard(String id) => '$_api/competitions/$id/leaderboard';

  /// POST - Force leaderboard update (protected - admin/organizer)
  static String updateLeaderboard(String id) =>
      '$_api/competitions/$id/leaderboard/update';

  // ============================================================================
  // CATEGORIES
  // ============================================================================

  /// GET - List competition categories (public)
  static String categories(String competitionId) =>
      '$_api/competitions/$competitionId/categories';

  /// POST - Create category (protected)
  static String createCategory(String competitionId) =>
      '$_api/competitions/$competitionId/categories';

  /// GET - Category details (public)
  static String categoryDetail(String competitionId, String categoryId) =>
      '$_api/competitions/$competitionId/categories/$categoryId';

  /// PUT - Update category (protected)
  static String updateCategory(String competitionId, String categoryId) =>
      '$_api/competitions/$competitionId/categories/$categoryId';

  /// DELETE - Delete category (protected)
  static String deleteCategory(String competitionId, String categoryId) =>
      '$_api/competitions/$competitionId/categories/$categoryId';

  // ============================================================================
  // CATEGORY PARTICIPANTS
  // ============================================================================

  /// POST - Add participant to category (protected)
  static String addParticipant(String competitionId, String categoryId) =>
      '$_api/competitions/$competitionId/categories/$categoryId/participants';

  /// DELETE - Remove participant from category (protected)
  static String removeParticipant(
    String competitionId,
    String categoryId,
    String participantId,
  ) =>
      '$_api/competitions/$competitionId/categories/$categoryId/participants/$participantId';

  // ============================================================================
  // CATEGORY JUDGES
  // ============================================================================

  /// POST - Add judge to category (protected)
  static String addJudge(String competitionId, String categoryId) =>
      '$_api/competitions/$competitionId/categories/$categoryId/judges';

  /// DELETE - Remove judge from category (protected)
  static String removeJudge(
    String competitionId,
    String categoryId,
    String judgeId,
  ) =>
      '$_api/competitions/$competitionId/categories/$categoryId/judges/$judgeId';

  // ============================================================================
  // CATEGORY SCORING
  // ============================================================================

  /// GET - Get category scores (public)
  static String categoryScores(String competitionId, String categoryId) =>
      '$_api/competitions/$competitionId/categories/$categoryId/scores';

  /// POST - Submit category score (protected)
  static String submitCategoryScore(String competitionId, String categoryId) =>
      '$_api/competitions/$competitionId/categories/$categoryId/scores';

  /// PUT - Update a score (protected)
  static String updateScore(
    String competitionId,
    String categoryId,
    String scoreId,
  ) =>
      '$_api/competitions/$competitionId/categories/$categoryId/scores/$scoreId';

  /// GET - Category leaderboard/ranking (public)
  static String categoryLeaderboard(String competitionId, String categoryId) =>
      '$_api/competitions/$competitionId/categories/$categoryId/leaderboard';

  // ============================================================================
  // CATEGORY JUDGE INVITATIONS
  // ============================================================================

  /// GET - List category judge invitations (protected)
  static String categoryJudgeInvitations(
    String competitionId,
    String categoryId,
  ) =>
      '$_api/competitions/$competitionId/categories/$categoryId/judge-invitations';

  /// POST - Invite judge to category (protected)
  static String inviteJudgeToCategory(
    String competitionId,
    String categoryId,
  ) =>
      '$_api/competitions/$competitionId/categories/$categoryId/judge-invitations';

  // ============================================================================
  // JUDGE INVITATIONS
  // ============================================================================

  /// GET - My judge invitations (protected)
  static const String myJudgeInvitations =
      '$_api/competitions/judge-invitations/my';

  /// POST - Respond to judge invitation (protected)
  static String respondToInvitation(String invitationId) =>
      '$_api/competitions/judge-invitations/$invitationId/respond';

  /// GET - List competition judge invitations (protected - admin/organizer)
  static String judgeInvitations(String competitionId) =>
      '$_api/competitions/$competitionId/judge-invitations';

  /// POST - Create judge invitation (protected - admin/organizer)
  static String createJudgeInvitation(String competitionId) =>
      '$_api/competitions/$competitionId/judge-invitations';

  /// DELETE - Cancel judge invitation (protected - admin/organizer)
  static String cancelJudgeInvitation(
    String competitionId,
    String invitationId,
  ) =>
      '$_api/competitions/$competitionId/judge-invitations/$invitationId';

  // ============================================================================
  // HEATS
  // ============================================================================

  /// GET - Get all heats for a competition (public)
  static String getCompetitionHeats(String competitionId) =>
      '$_api/competitions/$competitionId/heats';

  /// GET - Get single heat by ID (public)
  static String getHeat(String competitionId, String heatId) =>
      '$_api/competitions/$competitionId/heats/$heatId';

  /// GET - Get heats for a round (public)
  static String getRoundHeats(String competitionId, String roundId) =>
      '$_api/competitions/$competitionId/rounds/$roundId/heats';

  /// GET - Get heats for a category and round (public)
  static String getCategoryHeats(
    String competitionId,
    String roundId,
    String categoryId,
  ) =>
      '$_api/competitions/$competitionId/rounds/$roundId/categories/$categoryId/heats';

  /// POST - Generate heats for a round (protected - admin/organizer)
  static String generateHeats(String competitionId, String roundId) =>
      '$_api/competitions/$competitionId/rounds/$roundId/heats/generate';

  /// POST - Complete a heat (protected - admin/organizer)
  static String completeHeat(String competitionId, String heatId) =>
      '$_api/competitions/$competitionId/heats/$heatId/complete';

  /// POST - Reset heats for a round (protected - admin/organizer)
  static String resetHeats(String competitionId, String roundId) =>
      '$_api/competitions/$competitionId/rounds/$roundId/heats/reset';
}
