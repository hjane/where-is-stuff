import 'user_info.dart';
import 'exceptions/auth_exception.dart';

class AuthResult {
  final bool isSuccess;
  final UserInfo? user;
  final String? sessionToken;
  final AuthException? error;

  const AuthResult._({
    required this.isSuccess,
    this.user,
    this.sessionToken,
    this.error,
  });

  factory AuthResult.success({
    UserInfo? user,
    String? sessionToken,
  }) {
    return AuthResult._(
      isSuccess: true,
      user: user,
      sessionToken: sessionToken,
    );
  }

  factory AuthResult.failure(AuthException error) {
    return AuthResult._(
      isSuccess: false,
      error: error,
    );
  }
}
