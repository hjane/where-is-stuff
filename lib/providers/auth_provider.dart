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

  AuthState get authState {
    debugPrint('[AuthProvider] authState getter: $_authState');
    return _authState;
  }
  UserInfo? get currentUser {
    debugPrint('[AuthProvider] currentUser getter: ${_currentUser?.id ?? 'null'}');
    return _currentUser;
  }
  String? get errorMessage {
    debugPrint('[AuthProvider] errorMessage getter: $_errorMessage');
    return _errorMessage;
  }
  bool get isLoading {
    debugPrint('[AuthProvider] isLoading getter: $_isLoading');
    return _isLoading;
  }
  bool get isAuthenticated {
    debugPrint('[AuthProvider] isAuthenticated getter: ${_authState == AuthState.authenticated}');
    return _authState == AuthState.authenticated;
  }
  bool get isAnonymous {
    debugPrint('[AuthProvider] isAnonymous getter: ${_authState == AuthState.anonymous}');
    return _authState == AuthState.anonymous;
  }
  bool get isLoggedIn {
    debugPrint('[AuthProvider] isLoggedIn getter: ${isAuthenticated || isAnonymous}');
    return isAuthenticated || isAnonymous;
  }

  Future<void> initialize() async {
    debugPrint('========================================');
    debugPrint('[AuthProvider] ========== 初始化开始 ==========');

    _setLoading(true);

    try {
      debugPrint('[AuthProvider] 步骤1: 初始化 AuthService...');
      await _authService.initialize();
      debugPrint('[AuthProvider] AuthService 初始化完成');

      debugPrint('[AuthProvider] 步骤2: 尝试恢复会话...');
      final restored = await _authService.restoreSession();
      debugPrint('[AuthProvider] 会话恢复结果: $restored');

      if (restored) {
        debugPrint('[AuthProvider] 会话恢复成功');
        _currentUser = await _authService.getCurrentUser();
        debugPrint('[AuthProvider] 当前用户: ${_currentUser?.id ?? 'null'}');

        _authState = _currentUser?.isAnonymous == true
            ? AuthState.anonymous
            : AuthState.authenticated;
        debugPrint('[AuthProvider] 认证状态: $_authState');
      } else {
        debugPrint('[AuthProvider] 无缓存会话，执行匿名登录...');
        final result = await _authService.signInAnonymously();
        debugPrint('[AuthProvider] 匿名登录结果: isSuccess=${result.isSuccess}');

        if (result.isSuccess) {
          _currentUser = result.user;
          _authState = AuthState.anonymous;
          debugPrint('[AuthProvider] 匿名登录成功');
          debugPrint('[AuthProvider] 认证状态: $_authState');
        } else {
          _authState = AuthState.unauthenticated;
          _errorMessage = result.error?.message;
          debugPrint('[AuthProvider] 匿名登录失败: $_errorMessage');
          debugPrint('[AuthProvider] 认证状态: $_authState');
        }
      }
    } catch (e, stackTrace) {
      debugPrint('[AuthProvider] ========== 初始化异常 ==========');
      debugPrint('[AuthProvider] 错误: $e');
      debugPrint('[AuthProvider] 堆栈: $stackTrace');
      _errorMessage = e.toString();
      _authState = AuthState.unauthenticated;
      debugPrint('[AuthProvider] 认证状态: $_authState');
    } finally {
      _setLoading(false);
      debugPrint('[AuthProvider] ========== 初始化完成 ==========');
      debugPrint('========================================');
    }

    debugPrint('[AuthProvider] 注册认证状态监听...');
    _listenToAuthChanges();
  }

  Future<bool> signInWithEmail(String email, String password) async {
    debugPrint('----------------------------------------');
    debugPrint('[AuthProvider] signInWithEmail: $email');

    _setLoading(true);
    _clearError();

    try {
      debugPrint('[AuthProvider] 调用 AuthService.signInWithEmail...');
      final result = await _authService.signInWithEmail(email, password);
      debugPrint('[AuthProvider] 结果: isSuccess=${result.isSuccess}');

      if (result.isSuccess) {
        _currentUser = result.user;
        _authState = AuthState.authenticated;
        debugPrint('[AuthProvider] 登录成功: ${_currentUser?.id}');
        debugPrint('[AuthProvider] 新状态: $_authState');
        notifyListeners();
        debugPrint('[AuthProvider] signInWithEmail: 成功');
        debugPrint('----------------------------------------');
        return true;
      } else {
        _errorMessage = result.error?.message ?? '登录失败';
        debugPrint('[AuthProvider] 登录失败: $_errorMessage');
        debugPrint('[AuthProvider] signInWithEmail: 失败');
        debugPrint('----------------------------------------');
        return false;
      }
    } catch (e, stackTrace) {
      debugPrint('[AuthProvider] 异常: $e');
      debugPrint('[AuthProvider] 堆栈: $stackTrace');
      _errorMessage = e.toString();
      debugPrint('[AuthProvider] signInWithEmail: 异常');
      debugPrint('----------------------------------------');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<AuthResult> signUpWithEmail(String email, String password, String nickname) async {
    debugPrint('----------------------------------------');
    debugPrint('[AuthProvider] signUpWithEmail: $email, nickname=$nickname');

    _setLoading(true);
    _clearError();

    try {
      debugPrint('[AuthProvider] 调用 AuthService.signUpWithEmail...');
      final result = await _authService.signUpWithEmail(email, password, nickname);
      debugPrint('[AuthProvider] 结果: isSuccess=${result.isSuccess}');

      debugPrint('[AuthProvider] signUpWithEmail: ${result.isSuccess ? '成功(待验证)' : '失败'}');
      debugPrint('----------------------------------------');
      return result;
    } catch (e, stackTrace) {
      debugPrint('[AuthProvider] 异常: $e');
      debugPrint('[AuthProvider] 堆栈: $stackTrace');
      _errorMessage = e.toString();
      debugPrint('[AuthProvider] signUpWithEmail: 异常');
      debugPrint('----------------------------------------');
      return AuthResult.failure(AuthException(code: 'unknown', message: e.toString()));
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> verifyEmailCode(String code) async {
    debugPrint('----------------------------------------');
    debugPrint('[AuthProvider] verifyEmailCode: ${code.substring(0, 2)}***');

    _setLoading(true);
    _clearError();

    try {
      debugPrint('[AuthProvider] 调用 AuthService.verifyEmailCode...');
      final result = await _authService.verifyEmailCode(code);
      debugPrint('[AuthProvider] 结果: isSuccess=${result.isSuccess}');

      if (result.isSuccess) {
        _currentUser = result.user;
        _authState = AuthState.authenticated;
        debugPrint('[AuthProvider] 验证成功: ${_currentUser?.id}');
        debugPrint('[AuthProvider] 新状态: $_authState');
        notifyListeners();
        debugPrint('[AuthProvider] verifyEmailCode: 成功');
        debugPrint('----------------------------------------');
        return true;
      } else {
        _errorMessage = result.error?.message ?? '验证失败';
        debugPrint('[AuthProvider] 验证失败: $_errorMessage');
        debugPrint('[AuthProvider] verifyEmailCode: 失败');
        debugPrint('----------------------------------------');
        return false;
      }
    } catch (e, stackTrace) {
      debugPrint('[AuthProvider] 异常: $e');
      debugPrint('[AuthProvider] 堆栈: $stackTrace');
      _errorMessage = e.toString();
      debugPrint('[AuthProvider] verifyEmailCode: 异常');
      debugPrint('----------------------------------------');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> signInAnonymously() async {
    debugPrint('----------------------------------------');
    debugPrint('[AuthProvider] signInAnonymously');

    _setLoading(true);
    _clearError();

    try {
      debugPrint('[AuthProvider] 调用 AuthService.signInAnonymously...');
      final result = await _authService.signInAnonymously();
      debugPrint('[AuthProvider] 结果: isSuccess=${result.isSuccess}');

      if (result.isSuccess) {
        _currentUser = result.user;
        _authState = AuthState.anonymous;
        debugPrint('[AuthProvider] 匿名登录成功: ${_currentUser?.id}');
        debugPrint('[AuthProvider] 新状态: $_authState');
        notifyListeners();
        debugPrint('[AuthProvider] signInAnonymously: 成功');
        debugPrint('----------------------------------------');
        return true;
      } else {
        _errorMessage = result.error?.message ?? '匿名登录失败';
        debugPrint('[AuthProvider] 匿名登录失败: $_errorMessage');
        debugPrint('[AuthProvider] signInAnonymously: 失败');
        debugPrint('----------------------------------------');
        return false;
      }
    } catch (e, stackTrace) {
      debugPrint('[AuthProvider] 异常: $e');
      debugPrint('[AuthProvider] 堆栈: $stackTrace');
      _errorMessage = e.toString();
      debugPrint('[AuthProvider] signInAnonymously: 异常');
      debugPrint('----------------------------------------');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<AuthResult> upgradeAnonymousUser(String email, String password, String nickname) async {
    debugPrint('----------------------------------------');
    debugPrint('[AuthProvider] upgradeAnonymousUser: $email');

    _setLoading(true);
    _clearError();

    try {
      debugPrint('[AuthProvider] 调用 AuthService.upgradeAnonymousUser...');
      final result = await _authService.upgradeAnonymousUser(email, password, nickname);
      debugPrint('[AuthProvider] 结果: isSuccess=${result.isSuccess}');

      debugPrint('[AuthProvider] upgradeAnonymousUser: ${result.isSuccess ? '成功(待验证)' : '失败'}');
      debugPrint('----------------------------------------');
      return result;
    } catch (e, stackTrace) {
      debugPrint('[AuthProvider] 异常: $e');
      debugPrint('[AuthProvider] 堆栈: $stackTrace');
      _errorMessage = e.toString();
      debugPrint('[AuthProvider] upgradeAnonymousUser: 异常');
      debugPrint('----------------------------------------');
      return AuthResult.failure(AuthException(code: 'unknown', message: e.toString()));
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> sendResetPasswordEmail(String email) async {
    debugPrint('----------------------------------------');
    debugPrint('[AuthProvider] sendResetPasswordEmail: $email');

    _setLoading(true);
    _clearError();

    try {
      debugPrint('[AuthProvider] 调用 AuthService.resetPassword...');
      final result = await _authService.resetPassword(email);
      debugPrint('[AuthProvider] 结果: isSuccess=${result.isSuccess}');

      debugPrint('[AuthProvider] sendResetPasswordEmail: ${result.isSuccess ? '成功' : '失败'}');
      debugPrint('----------------------------------------');
      return result.isSuccess;
    } catch (e, stackTrace) {
      debugPrint('[AuthProvider] 异常: $e');
      debugPrint('[AuthProvider] 堆栈: $stackTrace');
      _errorMessage = e.toString();
      debugPrint('[AuthProvider] sendResetPasswordEmail: 异常');
      debugPrint('----------------------------------------');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> confirmResetPassword(String code, String newPassword) async {
    debugPrint('----------------------------------------');
    debugPrint('[AuthProvider] confirmResetPassword');

    _setLoading(true);
    _clearError();

    try {
      debugPrint('[AuthProvider] 调用 AuthService.confirmResetPassword...');
      final result = await _authService.confirmResetPassword(code, newPassword);
      debugPrint('[AuthProvider] 结果: isSuccess=${result.isSuccess}');

      if (result.isSuccess) {
        debugPrint('[AuthProvider] confirmResetPassword: 成功');
        debugPrint('----------------------------------------');
        return true;
      } else {
        _errorMessage = result.error?.message ?? '重置失败';
        debugPrint('[AuthProvider] confirmResetPassword: 失败');
        debugPrint('----------------------------------------');
        return false;
      }
    } catch (e, stackTrace) {
      debugPrint('[AuthProvider] 异常: $e');
      debugPrint('[AuthProvider] 堆栈: $stackTrace');
      _errorMessage = e.toString();
      debugPrint('[AuthProvider] confirmResetPassword: 异常');
      debugPrint('----------------------------------------');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> signOut() async {
    debugPrint('----------------------------------------');
    debugPrint('[AuthProvider] signOut');

    _setLoading(true);

    try {
      debugPrint('[AuthProvider] 调用 AuthService.signOut...');
      await _authService.signOut();
      _currentUser = null;
      _authState = AuthState.unauthenticated;
      debugPrint('[AuthProvider] 退出成功');
      debugPrint('[AuthProvider] 新状态: $_authState');
    } catch (e, stackTrace) {
      debugPrint('[AuthProvider] 异常: $e');
      debugPrint('[AuthProvider] 堆栈: $stackTrace');
      _errorMessage = e.toString();
    } finally {
      _setLoading(false);
      debugPrint('[AuthProvider] signOut: 完成');
      debugPrint('----------------------------------------');
    }
  }

  Future<void> refreshUserInfo() async {
    debugPrint('[AuthProvider] refreshUserInfo');

    try {
      debugPrint('[AuthProvider] 调用 AuthService.refreshUserInfo...');
      _currentUser = await _authService.refreshUserInfo();
      debugPrint('[AuthProvider] 新用户信息: ${_currentUser?.id ?? 'null'}');
      notifyListeners();
    } catch (e, stackTrace) {
      debugPrint('[AuthProvider] 异常: $e');
      debugPrint('[AuthProvider] 堆栈: $stackTrace');
      _errorMessage = e.toString();
    }
  }

  void cancelPendingVerification() {
    debugPrint('[AuthProvider] cancelPendingVerification');
    _authService.clearPendingVerification();
  }

  void _setLoading(bool value) {
    debugPrint('[AuthProvider] _setLoading: $_isLoading -> $value');
    _isLoading = value;
    notifyListeners();
  }

  void _clearError() {
    debugPrint('[AuthProvider] _clearError: $_errorMessage -> null');
    _errorMessage = null;
  }

  void _listenToAuthChanges() {
    debugPrint('[AuthProvider] _listenToAuthChanges: 开始监听...');
    _authService.authStateChanges.listen((state) {
      debugPrint('========================================');
      debugPrint('[AuthProvider] ====== 认证状态变化 ======');
      debugPrint('[AuthProvider] 新状态: $state');
      debugPrint('[AuthProvider] 旧状态: $_authState');

      _authState = state;

      if (state == AuthState.authenticated || state == AuthState.anonymous) {
        debugPrint('[AuthProvider] 刷新用户信息...');
        refreshUserInfo();
      }

      notifyListeners();
      debugPrint('[AuthProvider] ====== 状态变化结束 ======');
      debugPrint('========================================');
    });
  }

  @override
  void dispose() {
    debugPrint('[AuthProvider] dispose');
    _authService.dispose();
    super.dispose();
  }
}
