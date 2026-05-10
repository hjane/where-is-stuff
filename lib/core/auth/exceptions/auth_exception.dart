class AuthException implements Exception {
  final String code;
  final String message;

  const AuthException({required this.code, required this.message});

  static const String invalidCredentials = 'invalid_credentials';
  static const String userNotFound = 'user_not_found';
  static const String emailAlreadyExists = 'email_already_exists';
  static const String passwordTooWeak = 'password_too_weak';
  static const String networkError = 'network_error';
  static const String sessionExpired = 'session_expired';
  static const String unknownError = 'unknown_error';

  @override
  String toString() => 'AuthException($code): $message';
}
