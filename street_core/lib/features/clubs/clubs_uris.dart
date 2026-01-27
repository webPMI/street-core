/// URIs for clubs feature
class ClubsUris {
  static const String baseUrl = '/api/v1/clubs';

  // Club endpoints
  static const String list = baseUrl;
  static String clubDetail(String id) => '$baseUrl/$id';
  static const String create = baseUrl;
  static String clubEdit(String id) => '$baseUrl/$id/edit';
  static String delete(String id) => '$baseUrl/$id';

  // Admin endpoints
  static const String adminList = '$baseUrl/admin';
  static String adminApprove(String id) => '$baseUrl/admin/$id/approve';
  static String adminReject(String id) => '$baseUrl/admin/$id/reject';
  static String adminSuspend(String id) => '$baseUrl/admin/$id/suspend';
  static String adminActivate(String id) => '$baseUrl/admin/$id/activate';

  // UI Routes (navigation)
  static String editRoute(String id) => '/admin/clubs/edit/$id';
  static String detailRoute(String id) => '/clubs/$id';
}
