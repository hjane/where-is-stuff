import 'package:flutter/foundation.dart';
import '../core/auth/auth_service.dart';
import '../core/auth/auth_state.dart';
import '../core/auth/user_info.dart';
import '../core/auth/auth_result.dart';
import '../core/auth/exceptions/auth_exception.dart';

class AuthProvider extends ChangeNotifier {
  static final AuthProvider _instance = AuthProvider._internal();
  factory AuthProvider() => _instance;
  AuthProvider._internal();

  final AuthService _authService = AuthService();

  AuthState _authState = AuthState.initial;
  UserInfo? _currentUser;
  String? _errorMessage;
  bool _isLoading = false;

  AuthState get authState => _authState;
  UserInfo? get currentUser => _currentUser;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _authState == AuthState.authenticated;
  bool get isAnonymous => _authState == AuthState.anonymous;
  bool get isLoggedIn => isAuthenticated || isAnonymous;

  Future<void> initialize() async {
    _setLoading(true);

    try {
      await _authService.initialize();

      final restored = await _authService.restoreSession();

      if (restored) {
        _currentUser = await _authService.getCurrentUser();
        _authState = _currentUser?.isAnonymous == true
            ? AuthState.anonymous
            : AuthState.authenticated;
      } else {
        final result = await _authService.signInAnonymously();
        if (result.isSuccess) {
          _currentUser = result.user;
          _authState = AuthState.anonymous;
        } else {
          _authState = AuthState.unauthenticated;
        }
      }
    } catch (e) {
      _errorMessage = e.toString();
      _authState = AuthState.unauthenticated;
    } finally {
      _setLoading(false);
    }

    _listenToAuthChanges();
  }

  Future<bool> signInWithEmail(String email, String password) async {
    _setLoading(true);
    _clearError();

    try {
      final result = await _authService.signInWithEmail(email, password);

      if (result.isSuccess) {
        _currentUser = result.user;
        _authState = AuthState.authenticated;
        notifyListeners();
        return true;
      } else {
        _errorMessage = result.error?.message ?? '登录失败';
        return false;
      }
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<AuthResult> signUpWithEmail(String email, String password, String nickname) async {
    _setLoading(true);
    _clearError();

    try {
      final result = await _authService.signUpWithEmail(email, password, nickname);
      return result;
    } catch (e) {
      _errorMessage = e.toString();
      return AuthResult.failure(AuthException(code: 'unknown', message: e.toString()));
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> verifyEmailCode(String code) async {
    _setLoading(true);
    _clearError();

    try {
      final result = await _authService.verifyEmailCode(code);

      if (result.isSuccess) {
        _currentUser = result.user;
        _authState = AuthState.authenticated;
        notifyListeners();
        return true;
      } else {
        _errorMessage = result.error?.message ?? '验证失败';
        return false;
      }
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> signInAnonymously() async {
    _setLoading(true);
    _clearError();

    try {
      final result = await _authService.signInAnonymously();

      if (result.isSuccess) {
        _currentUser = result.user;
        _authState = AuthState.anonymous;
        notifyListeners();
        return true;
      } else {
        _errorMessage = result.error?.message ?? '匿名登录失败';
        return false;
      }
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<AuthResult> upgradeAnonymousUser(String email, String password, String nickname) async {
    _setLoading(true);
    _clearError();

    try {
      final result = await _authService.upgradeAnonymousUser(email, password, nickname);
      return result;
    } catch (e) {
      _errorMessage = e.toString();
      return AuthResult.failure(AuthException(code: 'unknown', message: e.toString()));
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> sendResetPasswordEmail(String email) async {
    _setLoading(true);
    _clearError();

    try {
      final result = await _authService.resetPassword(email);
      return result.isSuccess;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> confirmResetPassword(String code, String newPassword) async {
    _setLoading(true);
    _clearError();

    try {
      final result = await _authService.confirmResetPassword(code, newPassword);
      if (result.isSuccess) {
        return true;
      } else {
        _errorMessage = result.error?.message ?? '重置失败';
        return false;
      }
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> signOut() async {
    _setLoading(true);

    try {
      await _authService.signOut();
      _currentUser = null;
      _authState = AuthState.unauthenticated;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> refreshUserInfo() async {
    try {
      _currentUser = await _authService.refreshUserInfo();
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
    }
  }

  void cancelPendingVerification() {
    _authService.clearPendingVerification();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }

  void _listenToAuthChanges() {
    _authService.authStateChanges.listen((state) {
      _authState = state;
      if (state == AuthState.authenticated || state == AuthState.anonymous) {
        refreshUserInfo();
      }
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _authService.dispose();
    super.dispose();
  }
}
