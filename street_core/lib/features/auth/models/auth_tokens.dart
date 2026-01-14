/// Authentication tokens returned from login/register.
class AuthTokens {
  const AuthTokens({
    required this.accessToken,
    required this.refreshToken,
  });

  /// Create from JSON response.
  factory AuthTokens.fromJson(Map<String, dynamic> json) {
    return AuthTokens(
      accessToken: json['access_token'] as String? ?? '',
      refreshToken: json['refresh_token'] as String? ?? '',
    );
  }

  final String accessToken;
  final String refreshToken;

  /// Check if tokens are valid (not empty).
  bool get isValid => accessToken.isNotEmpty && refreshToken.isNotEmpty;

  /// Convert to JSON.
  Map<String, dynamic> toJson() {
    return {
      'access_token': accessToken,
      'refresh_token': refreshToken,
    };
  }
}
