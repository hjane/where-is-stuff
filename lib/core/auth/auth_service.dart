import 'dart:async';
import 'package:cloudbase_flutter/cloudbase_flutter.dart';
import 'package:flutter/foundation.dart';
import '../cloudbase/cloudbase_init.dart';
import '../storage/local_storage_service.dart';
import 'auth_state.dart';
import 'user_info.dart';
import 'auth_result.dart';
import 'exceptions/auth_exception.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  CloudBaseService get _cloudBase => CloudBaseService();
  LocalStorageService get _storage => LocalStorageService();

  bool _isInitialized = false;
  String? _anonymousToken;
  StreamController<AuthState>? _authStateController;
  UserInfo? _currentUser;

  Future<void> initialize() async {
    if (_isInitialized) return;
    
    await _storage.initialize();
    
    await _cloudBase.initialize(
      envId: TCBConfig.envId,
      region: TCBConfig.region,
      accessKey: TCBConfig.accessKey,
    );
    
    _initAuthStateListener();
    
    _isInitialized = true;
  }

  Future<AuthResult> signInWithEmail(String email, String password) async {
    try {
      final result = await _cloudBase.auth.signInWithPassword(
        SignInWithPasswordReq(
          email: email,
          password: password,
        ),
      );
      
      if (result.isSuccess) {
        final user = _convertToUserInfo(result.data?.user);
        await _cacheUserInfo(user, result.data?.session?.accessToken);
        return AuthResult.success(user: user, sessionToken: result.data?.session?.accessToken);
      } else {
        return AuthResult.failure(_convertError(result.error));
      }
    } catch (e) {
      return AuthResult.failure(AuthException(code: 'unknown', message: e.toString()));
    }
  }

  Future<AuthResult> signUpWithEmail(String email, String password, String nickname) async {
    try {
      final signUpResult = await _cloudBase.auth.signUp(
        SignUpReq(
          email: email,
          password: password,
          nickname: nickname,
        ),
      );
      
      if (signUpResult.error != null) {
        return AuthResult.failure(_convertError(signUpResult.error));
      }
      
      return AuthResult.success(
        user: UserInfo(
          id: '',
          email: email,
          nickname: nickname,
          isAnonymous: false,
          memberStatus: MemberStatus.free,
          points: 0,
          createdAt: DateTime.now(),
        ),
      );
    } catch (e) {
      return AuthResult.failure(AuthException(code: 'unknown', message: e.toString()));
    }
  }

  Future<AuthResult> verifyEmailCode(String email, String code, {String? anonymousToken}) async {
    try {
      final result = await _cloudBase.auth.signInWithOtp(
        SignInWithOtpReq(
          email: email,
          options: SignInWithOtpReqOptions(
            shouldCreateUser: anonymousToken != null ? true : true,
          ),
        ),
      );
      
      if (result.error != null) {
        return AuthResult.failure(_convertError(result.error));
      }
      
      final verifyResult = await result.data!.verifyOtp!(
        VerifyOtpParams(token: code),
      );
      
      if (verifyResult.isSuccess) {
        final user = _convertToUserInfo(verifyResult.data?.user);
        await _cacheUserInfo(user, verifyResult.data?.session?.accessToken);
        return AuthResult.success(user: user);
      } else {
        return AuthResult.failure(_convertError(verifyResult.error));
      }
    } catch (e) {
      return AuthResult.failure(AuthException(code: 'unknown', message: e.toString()));
    }
  }

  Future<AuthResult> signInAnonymously() async {
    try {
      final result = await _cloudBase.auth.signInAnonymously();
      
      if (result.isSuccess) {
        _anonymousToken = result.data?.session?.accessToken;
        final user = _convertToUserInfo(result.data?.user);
        await _cacheUserInfo(user, result.data?.session?.accessToken);
        return AuthResult.success(user: user, sessionToken: result.data?.session?.accessToken);
      } else {
        return AuthResult.failure(_convertError(result.error));
      }
    } catch (e) {
      return AuthResult.failure(AuthException(code: 'unknown', message: e.toString()));
    }
  }

  Future<AuthResult> upgradeAnonymousUser(String email, String password, String nickname) async {
    try {
      final result = await _cloudBase.auth.signUp(
        SignUpReq(
          email: email,
          password: password,
          nickname: nickname,
          anonymousToken: _anonymousToken,
        ),
      );
      
      if (result.error != null) {
        return AuthResult.failure(_convertError(result.error));
      }
      
      return AuthResult.success(
        user: UserInfo(
          id: '',
          email: email,
          nickname: nickname,
          isAnonymous: false,
          memberStatus: MemberStatus.free,
          points: 0,
          createdAt: DateTime.now(),
        ),
      );
    } catch (e) {
      return AuthResult.failure(AuthException(code: 'unknown', message: e.toString()));
    }
  }

  Future<AuthResult> resetPassword(String email) async {
    try {
      final result = await _cloudBase.auth.signInWithOtp(
        SignInWithOtpReq(email: email),
      );
      
      if (result.error != null) {
        return AuthResult.failure(_convertError(result.error));
      }
      
      return AuthResult.success();
    } catch (e) {
      return AuthResult.failure(AuthException(code: 'unknown', message: e.toString()));
    }
  }

  Future<AuthResult> changePassword(String oldPassword, String newPassword) async {
    try {
      final currentUser = await _cloudBase.auth.getCurrentUser();
      if (currentUser == null) {
        return AuthResult.failure(
          const AuthException(code: 'not_logged_in', message: '用户未登录'),
        );
      }

      final result = await _cloudBase.auth.updateUser(
        UpdateUserReq(
          updatePasswordReq: UpdatePasswordReq(
            oldPassword: oldPassword,
            newPassword: newPassword,
          ),
        ),
      );

      if (result.error != null) {
        return AuthResult.failure(_convertError(result.error));
      }

      return AuthResult.success();
    } catch (e) {
      return AuthResult.failure(AuthException(code: 'unknown', message: e.toString()));
    }
  }

  Future<UserInfo?> getCurrentUser() async {
    try {
      if (_currentUser != null) {
        return _currentUser;
      }
      return await getCachedUserInfo();
    } catch (e) {
      debugPrint('[AuthService] getCurrentUser error: $e');
      return null;
    }
  }

  Future<UserInfo?> refreshUserInfo() async {
    try {
      final currentUser = await _cloudBase.auth.getCurrentUser();
      if (currentUser == null) {
        return null;
      }

      final userInfo = _convertToUserInfo(currentUser);
      await _cacheUserInfo(userInfo, null);
      _currentUser = userInfo;
      return userInfo;
    } catch (e) {
      debugPrint('[AuthService] refreshUserInfo error: $e');
      return null;
    }
  }

  Future<void> updateUserInfo(UserInfo userInfo) async {
    try {
      await _cacheUserInfo(userInfo, null);
      _currentUser = userInfo;
    } catch (e) {
      debugPrint('[AuthService] updateUserInfo error: $e');
      rethrow;
    }
  }

  Future<bool> isLoggedIn() async {
    try {
      final hasToken = await _storage.hasRefreshToken();
      if (!hasToken) {
        return false;
      }

      final currentUser = await _cloudBase.auth.getCurrentUser();
      return currentUser != null;
    } catch (e) {
      debugPrint('[AuthService] isLoggedIn error: $e');
      return false;
    }
  }

  Future<void> signOut() async {
    try {
      await _cloudBase.auth.signOut();
      await clearCache();
      _anonymousToken = null;
    } catch (e) {
      debugPrint('[AuthService] signOut error: $e');
      rethrow;
    }
  }

  Stream<AuthState> get authStateChanges {
    if (_authStateController == null) {
      _authStateController = StreamController<AuthState>.broadcast();
    }
    return _authStateController!.stream;
  }

  Future<void> restoreSession() async {
    try {
      final cachedUser = await getCachedUserInfo();
      if (cachedUser != null) {
        _currentUser = cachedUser;
        _authStateController?.add(AuthState.authenticated);
      }
    } catch (e) {
      debugPrint('[AuthService] restoreSession error: $e');
    }
  }

  Future<void> _cacheUserInfo(UserInfo? user, String? token) async {
    if (user == null) return;

    try {
      await _storage.saveUserId(user.id);
      await _storage.saveUserEmail(user.email);
      await _storage.saveUserNickname(user.nickname);
      await _storage.saveUserAvatar(user.avatarUrl);
      await _storage.saveMemberStatus(user.memberStatus.index);
      await _storage.savePoints(user.points);
      await _storage.saveIsAnonymous(user.isAnonymous);
      await _storage.saveLastSyncTime(DateTime.now());

      if (token != null) {
        await _storage.saveRefreshToken(token);
      }

      _currentUser = user;
    } catch (e) {
      debugPrint('[AuthService] _cacheUserInfo error: $e');
    }
  }

  Future<UserInfo?> getCachedUserInfo() async {
    try {
      final data = await _storage.getCachedUserData();
      if (data.isEmpty || data['userId'] == null) {
        return null;
      }

      return UserInfo(
        id: data['userId'] as String,
        email: data['email'] as String?,
        nickname: data['nickname'] as String?,
        avatarUrl: data['avatar'] as String?,
        isAnonymous: data['isAnonymous'] as bool? ?? false,
        memberStatus: MemberStatus.values[data['memberStatus'] as int? ?? 0],
        points: data['points'] as int? ?? 0,
        createdAt: DateTime.now(),
      );
    } catch (e) {
      debugPrint('[AuthService] getCachedUserInfo error: $e');
      return null;
    }
  }

  Future<void> clearCache() async {
    try {
      await _storage.clearUserData();
      await _storage.deleteRefreshToken();
      _currentUser = null;
    } catch (e) {
      debugPrint('[AuthService] clearCache error: $e');
    }
  }

  UserInfo? _convertToUserInfo(User? user) {
    if (user == null) return null;
    return UserInfo(
      id: user.id ?? '',
      email: user.email,
      nickname: user.nickname,
      avatarUrl: user.avatarUrl,
      gender: _convertGender(user.gender),
      isAnonymous: user.isAnonymous ?? false,
      memberStatus: MemberStatus.free,
      points: 0,
      createdAt: DateTime.tryParse(user.createdAt ?? '') ?? DateTime.now(),
    );
  }

  AuthException _convertError(AuthError? error) {
    if (error == null) {
      return const AuthException(code: 'unknown', message: 'Unknown error');
    }
    return AuthException(code: error.code ?? 'unknown', message: error.message ?? 'Unknown error');
  }

  Gender? _convertGender(dynamic gender) {
    if (gender == null) return null;
    if (gender.toString().contains('male')) return Gender.male;
    if (gender.toString().contains('female')) return Gender.female;
    return null;
  }

  void _initAuthStateListener() {
    _authStateController = StreamController<AuthState>.broadcast();
    _cloudBase.auth.onAuthStateChange((event, session, info) {
      switch (event) {
        case AuthStateChangeEvent.signedIn:
          _authStateController?.add(AuthState.authenticated);
          break;
        case AuthStateChangeEvent.signedOut:
          _authStateController?.add(AuthState.unauthenticated);
          break;
        case AuthStateChangeEvent.tokenRefreshed:
          _authStateController?.add(AuthState.authenticated);
          break;
        case AuthStateChangeEvent.userUpdated:
          _authStateController?.add(AuthState.authenticated);
          break;
        default:
          break;
      }
    });
  }

  Future<void> dispose() async {
    await _authStateController?.close();
    _authStateController = null;
    _currentUser = null;
    _anonymousToken = null;
    _isInitialized = false;
  }
}
