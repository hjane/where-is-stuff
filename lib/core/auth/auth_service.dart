import 'dart:async';
import 'package:cloudbase_flutter/cloudbase_flutter.dart';
import 'package:flutter/foundation.dart';
import '../cloudbase/cloudbase_init.dart';
import '../storage/local_storage_service.dart';
import 'auth_state.dart';
import 'user_info.dart';
import 'auth_result.dart';
import 'exceptions/auth_exception.dart';

typedef VerifyOtpCallback = Future<SignInRes> Function(VerifyOtpParams);

class AuthService {
  static final AuthService _instance = AuthService._internal();
  static AuthService get instance => _instance;
  factory AuthService() => _instance;
  AuthService._internal();

  CloudBaseService get _cloudBase => CloudBaseService();
  LocalStorageService get _storage => LocalStorageService();

  bool _isInitialized = false;
  String? _anonymousToken;
  String? _pendingEmail;
  VerifyOtpCallback? _pendingVerifyOtp;
  StreamController<AuthState>? _authStateController;
  UserInfo? _currentUser;

  bool get isInitialized => _isInitialized;
  String? get pendingEmail => _pendingEmail;
  bool get hasPendingVerification => _pendingVerifyOtp != null;

  Future<void> initialize() async {
    debugPrint('========================================');
    debugPrint('[AuthService] ========== 初始化开始 ==========');
    debugPrint('[AuthService] TCB配置: envId=${TCBConfig.envId}, region=${TCBConfig.region}');

    if (_isInitialized) {
      debugPrint('[AuthService] 已初始化，跳过');
      return;
    }

    try {
      debugPrint('[AuthService] 步骤1: 初始化本地存储...');
      await _storage.initialize();
      debugPrint('[AuthService] 本地存储初始化完成');

      debugPrint('[AuthService] 步骤2: 初始化CloudBase...');
      await _cloudBase.initialize(
        envId: TCBConfig.envId,
        region: TCBConfig.region,
        accessKey: TCBConfig.accessKey,
      );
      debugPrint('[AuthService] CloudBase初始化完成');
      debugPrint('[AuthService] CloudBase状态: ${_cloudBase.currentState}');

      debugPrint('[AuthService] 步骤3: 初始化认证状态监听...');
      _initAuthStateListener();
      debugPrint('[AuthService] 认证状态监听初始化完成');

      _isInitialized = true;
      debugPrint('[AuthService] ========== 初始化成功 ==========');
      debugPrint('========================================');
    } catch (e, stackTrace) {
      debugPrint('[AuthService] ========== 初始化失败 ==========');
      debugPrint('[AuthService] 错误: $e');
      debugPrint('[AuthService] 堆栈: $stackTrace');
      debugPrint('========================================');
      rethrow;
    }
  }

  Future<AuthResult> signInWithEmail(String email, String password) async {
    debugPrint('----------------------------------------');
    debugPrint('[AuthService] signInWithEmail 开始');
    debugPrint('[AuthService] 邮箱: $email');

    try {
      debugPrint('[AuthService] 调用 signInWithPassword...');
      final result = await _cloudBase.auth.signInWithPassword(
        SignInWithPasswordReq(
          email: email,
          password: password,
        ),
      );
      debugPrint('[AuthService] signInWithPassword 返回: isSuccess=${result.isSuccess}');

      if (result.isSuccess) {
        debugPrint('[AuthService] 登录成功');
        debugPrint('[AuthService] 用户信息: ${result.data?.user?.toString()}');
        debugPrint('[AuthService] Session Token: ${result.data?.session?.accessToken?.substring(0, 20)}...');

        final user = _convertToUserInfo(result.data?.user);
        debugPrint('[AuthService] 转换后的UserInfo: ${user?.toString()}');

        debugPrint('[AuthService] 缓存用户信息...');
        await _cacheUserInfo(user, result.data?.session?.accessToken);
        debugPrint('[AuthService] 缓存完成');

        debugPrint('[AuthService] signInWithEmail 完成: 成功');
        debugPrint('----------------------------------------');
        return AuthResult.success(user: user, sessionToken: result.data?.session?.accessToken);
      } else {
        debugPrint('[AuthService] 登录失败: ${result.error?.message}');
        debugPrint('[AuthService] signInWithEmail 完成: 失败');
        debugPrint('----------------------------------------');
        return AuthResult.failure(_convertError(result.error));
      }
    } catch (e, stackTrace) {
      debugPrint('[AuthService] signInWithEmail 异常: $e');
      debugPrint('[AuthService] 堆栈: $stackTrace');
      debugPrint('[AuthService] signInWithEmail 完成: 异常');
      debugPrint('----------------------------------------');
      return AuthResult.failure(AuthException(code: 'unknown', message: e.toString()));
    }
  }

  Future<AuthResult> signUpWithEmail(String email, String password, String nickname) async {
    debugPrint('----------------------------------------');
    debugPrint('[AuthService] signUpWithEmail 开始');
    debugPrint('[AuthService] 邮箱: $email');
    debugPrint('[AuthService] 昵称: $nickname');

    try {
      debugPrint('[AuthService] 调用 signUp (发送验证码)...');
      final signUpResult = await _cloudBase.auth.signUp(
        SignUpReq(
          email: email,
          password: password,
          nickname: nickname,
        ),
      );
      debugPrint('[AuthService] signUp 返回: error=${signUpResult.error}');

      if (signUpResult.error != null) {
        debugPrint('[AuthService] signUp 失败: ${signUpResult.error?.message}');
        debugPrint('[AuthService] signUpWithEmail 完成: 失败');
        debugPrint('----------------------------------------');
        return AuthResult.failure(_convertError(signUpResult.error));
      }

      _pendingEmail = email;
      _pendingVerifyOtp = signUpResult.data?.verifyOtp;
      debugPrint('[AuthService] 保存待验证信息: email=$_pendingEmail, hasVerifyOtp=${_pendingVerifyOtp != null}');

      debugPrint('[AuthService] signUpWithEmail 完成: 成功 (待验证)');
      debugPrint('----------------------------------------');
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
    } catch (e, stackTrace) {
      debugPrint('[AuthService] signUpWithEmail 异常: $e');
      debugPrint('[AuthService] 堆栈: $stackTrace');
      debugPrint('[AuthService] signUpWithEmail 完成: 异常');
      debugPrint('----------------------------------------');
      return AuthResult.failure(AuthException(code: 'unknown', message: e.toString()));
    }
  }

  Future<AuthResult> verifyEmailCode(String code, {String? anonymousToken}) async {
    debugPrint('----------------------------------------');
    debugPrint('[AuthService] verifyEmailCode 开始');
    debugPrint('[AuthService] 验证码: ${code.substring(0, 2)}***');
    debugPrint('[AuthService] 待验证邮箱: $_pendingEmail');
    debugPrint('[AuthService] hasPendingVerifyOtp: ${_pendingVerifyOtp != null}');

    try {
      if (_pendingVerifyOtp == null) {
        debugPrint('[AuthService] 没有待验证的请求');
        debugPrint('[AuthService] verifyEmailCode 完成: 失败 (无待验证请求)');
        debugPrint('----------------------------------------');
        return AuthResult.failure(
          const AuthException(code: 'no_pending_verification', message: '没有待验证的注册请求'),
        );
      }

      debugPrint('[AuthService] 调用 verifyOtp 回调...');
      final verifyResult = await _pendingVerifyOtp!(
        VerifyOtpParams(token: code),
      );
      debugPrint('[AuthService] verifyOtp 返回: isSuccess=${verifyResult.isSuccess}');

      _pendingVerifyOtp = null;
      _pendingEmail = null;

      if (verifyResult.isSuccess) {
        debugPrint('[AuthService] 验证成功');
        debugPrint('[AuthService] 用户信息: ${verifyResult.data?.user?.toString()}');

        final user = _convertToUserInfo(verifyResult.data?.user);
        debugPrint('[AuthService] 缓存用户信息...');
        await _cacheUserInfo(user, verifyResult.data?.session?.accessToken);
        debugPrint('[AuthService] 缓存完成');

        debugPrint('[AuthService] verifyEmailCode 完成: 成功');
        debugPrint('----------------------------------------');
        return AuthResult.success(user: user);
      } else {
        debugPrint('[AuthService] 验证失败: ${verifyResult.error?.message}');
        debugPrint('[AuthService] verifyEmailCode 完成: 失败');
        debugPrint('----------------------------------------');
        return AuthResult.failure(_convertError(verifyResult.error));
      }
    } catch (e, stackTrace) {
      debugPrint('[AuthService] verifyEmailCode 异常: $e');
      debugPrint('[AuthService] 堆栈: $stackTrace');
      _pendingVerifyOtp = null;
      _pendingEmail = null;
      debugPrint('[AuthService] verifyEmailCode 完成: 异常');
      debugPrint('----------------------------------------');
      return AuthResult.failure(AuthException(code: 'unknown', message: e.toString()));
    }
  }

  Future<AuthResult> signInAnonymously() async {
    debugPrint('----------------------------------------');
    debugPrint('[AuthService] signInAnonymously 开始');

    try {
      debugPrint('[AuthService] 调用 signInAnonymously...');
      final result = await _cloudBase.auth.signInAnonymously();
      debugPrint('[AuthService] signInAnonymously 返回: isSuccess=${result.isSuccess}');

      if (result.isSuccess) {
        debugPrint('[AuthService] 匿名登录成功');
        debugPrint('[AuthService] 用户ID: ${result.data?.user?.id}');
        debugPrint('[AuthService] isAnonymous: ${result.data?.user?.isAnonymous}');
        debugPrint('[AuthService] Session Token: ${result.data?.session?.accessToken?.substring(0, 20) ?? 'null'}...');

        _anonymousToken = result.data?.session?.accessToken;
        debugPrint('[AuthService] 保存 anonymousToken: ${_anonymousToken?.substring(0, 20)}...');

        final user = _convertToUserInfo(result.data?.user);
        debugPrint('[AuthService] 转换后的UserInfo: ${user?.toString()}');

        debugPrint('[AuthService] 缓存用户信息...');
        await _cacheUserInfo(user, result.data?.session?.accessToken);
        debugPrint('[AuthService] 缓存完成');

        debugPrint('[AuthService] signInAnonymously 完成: 成功');
        debugPrint('----------------------------------------');
        return AuthResult.success(user: user, sessionToken: result.data?.session?.accessToken);
      } else {
        debugPrint('[AuthService] 匿名登录失败: ${result.error?.message}');
        debugPrint('[AuthService] signInAnonymously 完成: 失败');
        debugPrint('----------------------------------------');
        return AuthResult.failure(_convertError(result.error));
      }
    } catch (e, stackTrace) {
      debugPrint('[AuthService] signInAnonymously 异常: $e');
      debugPrint('[AuthService] 堆栈: $stackTrace');
      debugPrint('[AuthService] signInAnonymously 完成: 异常');
      debugPrint('----------------------------------------');
      return AuthResult.failure(AuthException(code: 'unknown', message: e.toString()));
    }
  }

  Future<AuthResult> upgradeAnonymousUser(String email, String password, String nickname) async {
    debugPrint('----------------------------------------');
    debugPrint('[AuthService] upgradeAnonymousUser 开始');
    debugPrint('[AuthService] 邮箱: $email');
    debugPrint('[AuthService] 昵称: $nickname');
    debugPrint('[AuthService] anonymousToken: ${_anonymousToken?.substring(0, 20) ?? 'null'}...');

    try {
      debugPrint('[AuthService] 调用 signUp (带 anonymousToken)...');
      final result = await _cloudBase.auth.signUp(
        SignUpReq(
          email: email,
          password: password,
          nickname: nickname,
          anonymousToken: _anonymousToken,
        ),
      );
      debugPrint('[AuthService] signUp 返回: error=${result.error}');

      if (result.error != null) {
        debugPrint('[AuthService] signUp 失败: ${result.error?.message}');
        debugPrint('[AuthService] upgradeAnonymousUser 完成: 失败');
        debugPrint('----------------------------------------');
        return AuthResult.failure(_convertError(result.error));
      }

      _pendingEmail = email;
      _pendingVerifyOtp = result.data?.verifyOtp;
      debugPrint('[AuthService] 保存待验证信息: email=$_pendingEmail, hasVerifyOtp=${_pendingVerifyOtp != null}');

      debugPrint('[AuthService] upgradeAnonymousUser 完成: 成功 (待验证)');
      debugPrint('----------------------------------------');
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
    } catch (e, stackTrace) {
      debugPrint('[AuthService] upgradeAnonymousUser 异常: $e');
      debugPrint('[AuthService] 堆栈: $stackTrace');
      debugPrint('[AuthService] upgradeAnonymousUser 完成: 异常');
      debugPrint('----------------------------------------');
      return AuthResult.failure(AuthException(code: 'unknown', message: e.toString()));
    }
  }

  Future<AuthResult> resetPassword(String email) async {
    debugPrint('----------------------------------------');
    debugPrint('[AuthService] resetPassword 开始');
    debugPrint('[AuthService] 邮箱: $email');

    try {
      debugPrint('[AuthService] 调用 signInWithOtp (重置密码)...');
      final result = await _cloudBase.auth.signInWithOtp(
        SignInWithOtpReq(email: email),
      );
      debugPrint('[AuthService] signInWithOtp 返回: error=${result.error}');

      if (result.error != null) {
        debugPrint('[AuthService] signInWithOtp 失败: ${result.error?.message}');
        debugPrint('[AuthService] resetPassword 完成: 失败');
        debugPrint('----------------------------------------');
        return AuthResult.failure(_convertError(result.error));
      }

      _pendingEmail = email;
      _pendingVerifyOtp = result.data?.verifyOtp;
      debugPrint('[AuthService] 保存待验证信息: email=$_pendingEmail, hasVerifyOtp=${_pendingVerifyOtp != null}');

      debugPrint('[AuthService] resetPassword 完成: 成功 (待验证)');
      debugPrint('----------------------------------------');
      return AuthResult.success();
    } catch (e, stackTrace) {
      debugPrint('[AuthService] resetPassword 异常: $e');
      debugPrint('[AuthService] 堆栈: $stackTrace');
      debugPrint('[AuthService] resetPassword 完成: 异常');
      debugPrint('----------------------------------------');
      return AuthResult.failure(AuthException(code: 'unknown', message: e.toString()));
    }
  }

  Future<AuthResult> confirmResetPassword(String code, String newPassword) async {
    debugPrint('----------------------------------------');
    debugPrint('[AuthService] confirmResetPassword 开始');
    debugPrint('[AuthService] 验证码: ${code.substring(0, 2)}***');

    try {
      if (_pendingVerifyOtp == null) {
        debugPrint('[AuthService] 没有待验证的重置请求');
        debugPrint('[AuthService] confirmResetPassword 完成: 失败');
        debugPrint('----------------------------------------');
        return AuthResult.failure(
          const AuthException(code: 'no_pending_verification', message: '没有待验证的重置请求'),
        );
      }

      debugPrint('[AuthService] 调用 verifyOtp 回调...');
      final verifyResult = await _pendingVerifyOtp!(
        VerifyOtpParams(token: code),
      );
      debugPrint('[AuthService] verifyOtp 返回: isSuccess=${verifyResult.isSuccess}');

      _pendingVerifyOtp = null;
      _pendingEmail = null;

      if (verifyResult.isSuccess) {
        debugPrint('[AuthService] 密码重置验证成功');
        debugPrint('[AuthService] confirmResetPassword 完成: 成功');
        debugPrint('----------------------------------------');
        return AuthResult.success();
      } else {
        debugPrint('[AuthService] 密码重置验证失败: ${verifyResult.error?.message}');
        debugPrint('[AuthService] confirmResetPassword 完成: 失败');
        debugPrint('----------------------------------------');
        return AuthResult.failure(_convertError(verifyResult.error));
      }
    } catch (e, stackTrace) {
      debugPrint('[AuthService] confirmResetPassword 异常: $e');
      debugPrint('[AuthService] 堆栈: $stackTrace');
      _pendingVerifyOtp = null;
      _pendingEmail = null;
      debugPrint('[AuthService] confirmResetPassword 完成: 异常');
      debugPrint('----------------------------------------');
      return AuthResult.failure(AuthException(code: 'unknown', message: e.toString()));
    }
  }

  Future<AuthResult> changePassword(String oldPassword, String newPassword) async {
    debugPrint('----------------------------------------');
    debugPrint('[AuthService] changePassword 开始');

    try {
      debugPrint('[AuthService] 获取当前用户...');
      final currentUser = await _cloudBase.auth.getCurrentUser();
      if (currentUser == null) {
        debugPrint('[AuthService] 用户未登录');
        debugPrint('[AuthService] changePassword 完成: 失败');
        debugPrint('----------------------------------------');
        return AuthResult.failure(
          const AuthException(code: 'not_logged_in', message: '用户未登录'),
        );
      }
      debugPrint('[AuthService] 当前用户: ${currentUser.id}');

      debugPrint('[AuthService] 调用 updateUser (修改密码)...');
      final result = await _cloudBase.auth.updateUser(
        UpdateUserReq(
          updatePasswordReq: UpdatePasswordReq(
            oldPassword: oldPassword,
            newPassword: newPassword,
          ),
        ),
      );
      debugPrint('[AuthService] updateUser 返回: error=${result.error}');

      if (result.error != null) {
        debugPrint('[AuthService] 修改密码失败: ${result.error?.message}');
        debugPrint('[AuthService] changePassword 完成: 失败');
        debugPrint('----------------------------------------');
        return AuthResult.failure(_convertError(result.error));
      }

      debugPrint('[AuthService] changePassword 完成: 成功');
      debugPrint('----------------------------------------');
      return AuthResult.success();
    } catch (e, stackTrace) {
      debugPrint('[AuthService] changePassword 异常: $e');
      debugPrint('[AuthService] 堆栈: $stackTrace');
      debugPrint('[AuthService] changePassword 完成: 异常');
      debugPrint('----------------------------------------');
      return AuthResult.failure(AuthException(code: 'unknown', message: e.toString()));
    }
  }

  Future<UserInfo?> getCurrentUser() async {
    debugPrint('[AuthService] getCurrentUser: _currentUser=${_currentUser != null}');

    try {
      if (_currentUser != null) {
        debugPrint('[AuthService] 返回内存缓存的用户: ${_currentUser!.id}');
        return _currentUser;
      }

      debugPrint('[AuthService] 获取缓存用户信息...');
      final cachedUser = await getCachedUserInfo();
      debugPrint('[AuthService] 缓存用户: ${cachedUser?.id ?? 'null'}');
      return cachedUser;
    } catch (e) {
      debugPrint('[AuthService] getCurrentUser 错误: $e');
      return null;
    }
  }

  Future<UserInfo?> refreshUserInfo() async {
    debugPrint('----------------------------------------');
    debugPrint('[AuthService] refreshUserInfo 开始');

    try {
      debugPrint('[AuthService] 获取当前用户...');
      final currentUser = await _cloudBase.auth.getCurrentUser();
      if (currentUser == null) {
        debugPrint('[AuthService] 用户未登录或会话过期');
        debugPrint('[AuthService] refreshUserInfo 完成: null');
        debugPrint('----------------------------------------');
        return null;
      }
      debugPrint('[AuthService] 当前用户: ${currentUser.id}');

      final userInfo = _convertToUserInfo(currentUser);
      debugPrint('[AuthService] 转换后的UserInfo: ${userInfo?.toString()}');

      debugPrint('[AuthService] 缓存用户信息...');
      await _cacheUserInfo(userInfo, null);
      debugPrint('[AuthService] 缓存完成');

      _currentUser = userInfo;
      debugPrint('[AuthService] refreshUserInfo 完成: 成功');
      debugPrint('----------------------------------------');
      return userInfo;
    } catch (e, stackTrace) {
      debugPrint('[AuthService] refreshUserInfo 异常: $e');
      debugPrint('[AuthService] 堆栈: $stackTrace');
      debugPrint('[AuthService] refreshUserInfo 完成: 异常');
      debugPrint('----------------------------------------');
      return null;
    }
  }

  Future<void> updateUserInfo(UserInfo userInfo) async {
    debugPrint('----------------------------------------');
    debugPrint('[AuthService] updateUserInfo 开始');
    debugPrint('[AuthService] 用户信息: ${userInfo.toString()}');

    try {
      debugPrint('[AuthService] 缓存用户信息...');
      await _cacheUserInfo(userInfo, null);
      _currentUser = userInfo;
      debugPrint('[AuthService] 缓存完成');
      debugPrint('[AuthService] updateUserInfo 完成');
      debugPrint('----------------------------------------');
    } catch (e, stackTrace) {
      debugPrint('[AuthService] updateUserInfo 异常: $e');
      debugPrint('[AuthService] 堆栈: $stackTrace');
      debugPrint('[AuthService] updateUserInfo 完成: 异常');
      debugPrint('----------------------------------------');
      rethrow;
    }
  }

  Future<bool> isLoggedIn() async {
    debugPrint('[AuthService] isLoggedIn 开始');

    try {
      debugPrint('[AuthService] 检查本地Token...');
      final hasToken = await _storage.hasRefreshToken();
      debugPrint('[AuthService] hasToken: $hasToken');

      if (!hasToken) {
        debugPrint('[AuthService] isLoggedIn 完成: false (无Token)');
        return false;
      }

      debugPrint('[AuthService] 验证服务端会话...');
      final currentUser = await _cloudBase.auth.getCurrentUser();
      final isLoggedIn = currentUser != null;
      debugPrint('[AuthService] isLoggedIn 完成: $isLoggedIn');
      return isLoggedIn;
    } catch (e) {
      debugPrint('[AuthService] isLoggedIn 错误: $e');
      debugPrint('[AuthService] isLoggedIn 完成: false (异常)');
      return false;
    }
  }

  Future<void> signOut() async {
    debugPrint('----------------------------------------');
    debugPrint('[AuthService] signOut 开始');

    try {
      debugPrint('[AuthService] 调用 signOut (清除服务端会话)...');
      await _cloudBase.auth.signOut();
      debugPrint('[AuthService] 服务端会话已清除');

      debugPrint('[AuthService] 清除本地缓存...');
      await clearCache();
      debugPrint('[AuthService] 本地缓存已清除');

      _anonymousToken = null;
      _pendingVerifyOtp = null;
      _pendingEmail = null;
      debugPrint('[AuthService] signOut 完成');
      debugPrint('----------------------------------------');
    } catch (e, stackTrace) {
      debugPrint('[AuthService] signOut 错误: $e');
      debugPrint('[AuthService] 堆栈: $stackTrace');
      debugPrint('[AuthService] signOut 完成: 异常');
      debugPrint('----------------------------------------');
      rethrow;
    }
  }

  Stream<AuthState> get authStateChanges {
    debugPrint('[AuthService] authStateChanges 被访问');
    _authStateController ??= StreamController<AuthState>.broadcast();
    return _authStateController!.stream;
  }

  Future<bool> restoreSession() async {
    debugPrint('----------------------------------------');
    debugPrint('[AuthService] restoreSession 开始');

    try {
      debugPrint('[AuthService] 获取缓存用户信息...');
      final cachedUser = await getCachedUserInfo();
      debugPrint('[AuthService] cachedUser: ${cachedUser?.id ?? 'null'}');

      if (cachedUser != null) {
        _currentUser = cachedUser;
        debugPrint('[AuthService] 恢复缓存用户: ${cachedUser.id}');
        debugPrint('[AuthService] 发送 authenticated 状态');
        _authStateController?.add(AuthState.authenticated);
        debugPrint('[AuthService] restoreSession 完成: true');
        debugPrint('----------------------------------------');
        return true;
      }

      debugPrint('[AuthService] 无缓存用户');
      debugPrint('[AuthService] restoreSession 完成: false');
      debugPrint('----------------------------------------');
      return false;
    } catch (e, stackTrace) {
      debugPrint('[AuthService] restoreSession 错误: $e');
      debugPrint('[AuthService] 堆栈: $stackTrace');
      debugPrint('[AuthService] restoreSession 完成: false (异常)');
      debugPrint('----------------------------------------');
      return false;
    }
  }

  Future<void> _cacheUserInfo(UserInfo? user, String? token) async {
    debugPrint('[AuthService] _cacheUserInfo 开始');
    debugPrint('[AuthService] user: ${user?.id ?? 'null'}');
    debugPrint('[AuthService] token: ${token?.substring(0, 20) ?? 'null'}...');

    if (user == null) {
      debugPrint('[AuthService] user 为 null，跳过缓存');
      return;
    }

    try {
      debugPrint('[AuthService] 保存用户ID: ${user.id}');
      await _storage.saveUserId(user.id);

      debugPrint('[AuthService] 保存邮箱: ${user.email}');
      await _storage.saveUserEmail(user.email);

      debugPrint('[AuthService] 保存昵称: ${user.nickname}');
      await _storage.saveUserNickname(user.nickname);

      debugPrint('[AuthService] 保存头像: ${user.avatarUrl}');
      await _storage.saveUserAvatar(user.avatarUrl);

      debugPrint('[AuthService] 保存会员状态: ${user.memberStatus}');
      await _storage.saveMemberStatus(user.memberStatus.index);

      debugPrint('[AuthService] 保存积分: ${user.points}');
      await _storage.savePoints(user.points);

      debugPrint('[AuthService] 保存匿名状态: ${user.isAnonymous}');
      await _storage.saveIsAnonymous(user.isAnonymous);

      debugPrint('[AuthService] 保存同步时间...');
      await _storage.saveLastSyncTime(DateTime.now());

      if (token != null) {
        debugPrint('[AuthService] 保存Token...');
        await _storage.saveRefreshToken(token);
      }

      _currentUser = user;
      debugPrint('[AuthService] 更新内存缓存: ${_currentUser!.id}');
      debugPrint('[AuthService] _cacheUserInfo 完成');
    } catch (e, stackTrace) {
      debugPrint('[AuthService] _cacheUserInfo 错误: $e');
      debugPrint('[AuthService] 堆栈: $stackTrace');
    }
  }

  Future<UserInfo?> getCachedUserInfo() async {
    debugPrint('[AuthService] getCachedUserInfo 开始');

    try {
      debugPrint('[AuthService] 获取缓存数据...');
      final data = await _storage.getCachedUserData();
      debugPrint('[AuthService] 缓存数据 keys: ${data.keys.toList()}');

      if (data.isEmpty || data['userId'] == null) {
        debugPrint('[AuthService] 无有效缓存');
        debugPrint('[AuthService] getCachedUserInfo 完成: null');
        return null;
      }

      final userInfo = UserInfo(
        id: data['userId'] as String,
        email: data['email'] as String?,
        nickname: data['nickname'] as String?,
        avatarUrl: data['avatar'] as String?,
        isAnonymous: data['isAnonymous'] as bool? ?? false,
        memberStatus: MemberStatus.values[data['memberStatus'] as int? ?? 0],
        points: data['points'] as int? ?? 0,
        createdAt: DateTime.now(),
      );

      debugPrint('[AuthService] 构建UserInfo: ${userInfo.id}');
      debugPrint('[AuthService] getCachedUserInfo 完成');
      return userInfo;
    } catch (e, stackTrace) {
      debugPrint('[AuthService] getCachedUserInfo 错误: $e');
      debugPrint('[AuthService] 堆栈: $stackTrace');
      debugPrint('[AuthService] getCachedUserInfo 完成: null (异常)');
      return null;
    }
  }

  Future<void> clearCache() async {
    debugPrint('[AuthService] clearCache 开始');

    try {
      debugPrint('[AuthService] 清除用户数据...');
      await _storage.clearUserData();
      debugPrint('[AuthService] 清除Token...');
      await _storage.deleteRefreshToken();
      _currentUser = null;
      debugPrint('[AuthService] 清除内存缓存');
      debugPrint('[AuthService] clearCache 完成');
    } catch (e) {
      debugPrint('[AuthService] clearCache 错误: $e');
    }
  }

  UserInfo? _convertToUserInfo(User? user) {
    if (user == null) {
      debugPrint('[AuthService] _convertToUserInfo: user 为 null');
      return null;
    }
    debugPrint('[AuthService] _convertToUserInfo: id=${user.id}, email=${user.email}');

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
      debugPrint('[AuthService] _convertError: error 为 null');
      return const AuthException(code: 'unknown', message: 'Unknown error');
    }
    debugPrint('[AuthService] _convertError: code=${error.code}, message=${error.message}');
    return AuthException(code: error.code ?? 'unknown', message: error.message ?? 'Unknown error');
  }

  Gender? _convertGender(dynamic gender) {
    if (gender == null) return null;
    if (gender.toString().contains('male')) return Gender.male;
    if (gender.toString().contains('female')) return Gender.female;
    return null;
  }

  void _initAuthStateListener() {
    debugPrint('[AuthService] _initAuthStateListener: 创建StreamController');
    _authStateController = StreamController<AuthState>.broadcast();

    debugPrint('[AuthService] _initAuthStateListener: 注册 onAuthStateChange 监听');
    _cloudBase.auth.onAuthStateChange((event, session, info) {
      debugPrint('========================================');
      debugPrint('[AuthService] ====== 认证状态变化 ======');
      debugPrint('[AuthService] 事件: $event');
      debugPrint('[AuthService] Session: ${session?.accessToken?.substring(0, 20) ?? 'null'}...');
      debugPrint('[AuthService] Info: $info');

      switch (event) {
        case AuthStateChangeEvent.signedIn:
          debugPrint('[AuthService] >>> 触发 signedIn');
          _authStateController?.add(AuthState.authenticated);
          break;
        case AuthStateChangeEvent.signedOut:
          debugPrint('[AuthService] >>> 触发 signedOut');
          _authStateController?.add(AuthState.unauthenticated);
          break;
        case AuthStateChangeEvent.tokenRefreshed:
          debugPrint('[AuthService] >>> 触发 tokenRefreshed');
          _authStateController?.add(AuthState.authenticated);
          break;
        case AuthStateChangeEvent.userUpdated:
          debugPrint('[AuthService] >>> 触发 userUpdated');
          _authStateController?.add(AuthState.authenticated);
          break;
        default:
          debugPrint('[AuthService] >>> 未知事件: $event');
          break;
      }
      debugPrint('[AuthService] ====== 状态变化结束 ======');
      debugPrint('========================================');
    });
  }

  void clearPendingVerification() {
    debugPrint('[AuthService] clearPendingVerification');
    debugPrint('[AuthService] 清除前: email=$_pendingEmail, hasVerifyOtp=${_pendingVerifyOtp != null}');
    _pendingVerifyOtp = null;
    _pendingEmail = null;
    debugPrint('[AuthService] 清除后: email=$_pendingEmail, hasVerifyOtp=${_pendingVerifyOtp != null}');
  }

  Future<void> dispose() async {
    debugPrint('[AuthService] dispose 开始');

    await _authStateController?.close();
    _authStateController = null;
    _currentUser = null;
    _anonymousToken = null;
    _pendingVerifyOtp = null;
    _pendingEmail = null;
    _isInitialized = false;

    debugPrint('[AuthService] dispose 完成');
  }

  @override
  String toString() {
    return 'AuthService(isInitialized: $_isInitialized, hasCurrentUser: ${_currentUser != null}, hasAnonymousToken: ${_anonymousToken != null}, hasPendingVerification: $_pendingVerifyOtp != null)';
  }
}
