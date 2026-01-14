import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:street_core/core/router/go_router.dart';
import 'package:street_core/core/router/app_routes.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  
  test('Router should have essential routes registered', () {
    final routes = router.configuration.routes;

    // Helper to find route by path (handling nested routes if any)
    bool hasPath(List<RouteBase> routeList, String path) {
      for (final route in routeList) {
        if (route is GoRoute && route.path == path) {
          return true;
        }
        if (route.routes.isNotEmpty && hasPath(route.routes, path)) {
          return true;
        }
      }
      return false;
    }

    expect(hasPath(routes, AppRoutes.home), isTrue, reason: 'Home route missing');
    expect(hasPath(routes, AppRoutes.login), isTrue, reason: 'Login route missing');
    expect(hasPath(routes, AppRoutes.contact), isTrue, reason: 'Contact route missing');
  });
}
