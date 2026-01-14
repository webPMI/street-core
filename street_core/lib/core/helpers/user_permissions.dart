import '../../data/models/user_model.dart';

/// Helper class for checking user permissions and roles
class UserPermissions {
  /// Check if user has admin role
  static bool isAdmin(UserModel? user) {
    if (user == null) return false;
    return user.role.toLowerCase() == 'admin';
  }

  /// Check if user has premium status
  static bool isPremium(UserModel? user) {
    if (user == null) return false;
    return user.isPremium == true;
  }

  /// Check if user has any of the specified roles
  static bool hasAnyRole(UserModel? user, List<String> roles) {
    if (user == null) return false;
    return roles.any((role) => user.role.toLowerCase() == role.toLowerCase());
  }

  /// Check if user has specific role
  static bool hasRole(UserModel? user, String role) {
    if (user == null) return false;
    return user.role.toLowerCase() == role.toLowerCase();
  }

  /// Check if user can access admin features
  static bool canAccessAdmin(UserModel? user) {
    return isAdmin(user);
  }

  /// Check if user can manage users
  static bool canManageUsers(UserModel? user) {
    return isAdmin(user);
  }

  /// Check if user can edit content
  static bool canEditContent(UserModel? user) {
    return isAdmin(user) || isPremium(user);
  }

  /// Check if user can delete content
  static bool canDeleteContent(UserModel? user) {
    return isAdmin(user);
  }

  /// Check if user can create events
  static bool canCreateEvents(UserModel? user) {
    if (user == null) return false;
    return true; // All authenticated users can create events
  }

  /// Check if user can create clubs
  static bool canCreateClubs(UserModel? user) {
    if (user == null) return false;
    return true; // All authenticated users can create clubs
  }
}
