import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

class LocalStorageKeys {
  static const String refreshToken = 'auth_refresh_token';
  static const String userId = 'auth_user_id';
  static const String userEmail = 'auth_user_email';
  static const String userNickname = 'auth_user_nickname';
  static const String userAvatar = 'auth_user_avatar';
  static const String memberStatus = 'auth_member_status';
  static const String points = 'auth_points';
  static const String isAnonymous = 'auth_is_anonymous';
  static const String lastSyncTime = 'auth_last_sync_time';
}

class LocalStorageService {
  static final LocalStorageService _instance = LocalStorageService._internal();
  factory LocalStorageService() => _instance;
  LocalStorageService._internal();

  SharedPreferences? _prefs;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
  );

  Future<void> initialize() async {
    debugPrint('[LocalStorage] ========== 初始化开始 ==========');
    try {
      _prefs = await SharedPreferences.getInstance();
      debugPrint('[LocalStorage] SharedPreferences 初始化完成');
      debugPrint('[LocalStorage] 所有Keys: ${LocalStorageKeys.refreshToken}, ${LocalStorageKeys.userId}, ...');
      debugPrint('[LocalStorage] ========== 初始化成功 ==========');
    } catch (e) {
      debugPrint('[LocalStorage] ========== 初始化失败 ==========');
      debugPrint('[LocalStorage] 错误: $e');
      rethrow;
    }
  }

  Future<void> saveRefreshToken(String token) async {
    debugPrint('[LocalStorage] saveRefreshToken: ${token.substring(0, 20)}...');
    try {
      await _secureStorage.write(key: LocalStorageKeys.refreshToken, value: token);
      debugPrint('[LocalStorage] Token 保存成功');
    } catch (e) {
      debugPrint('[LocalStorage] Token 保存失败: $e');
      rethrow;
    }
  }

  Future<String?> getRefreshToken() async {
    debugPrint('[LocalStorage] getRefreshToken');
    try {
      final token = await _secureStorage.read(key: LocalStorageKeys.refreshToken);
      debugPrint('[LocalStorage] Token: ${token?.substring(0, 20) ?? 'null'}...');
      return token;
    } catch (e) {
      debugPrint('[LocalStorage] Token 读取失败: $e');
      return null;
    }
  }

  Future<void> deleteRefreshToken() async {
    debugPrint('[LocalStorage] deleteRefreshToken');
    try {
      await _secureStorage.delete(key: LocalStorageKeys.refreshToken);
      debugPrint('[LocalStorage] Token 删除成功');
    } catch (e) {
      debugPrint('[LocalStorage] Token 删除失败: $e');
      rethrow;
    }
  }

  Future<void> saveUserId(String userId) async {
    debugPrint('[LocalStorage] saveUserId: $userId');
    try {
      await _prefs?.setString(LocalStorageKeys.userId, userId);
      debugPrint('[LocalStorage] UserId 保存成功');
    } catch (e) {
      debugPrint('[LocalStorage] UserId 保存失败: $e');
      rethrow;
    }
  }

  Future<String?> getUserId() async {
    debugPrint('[LocalStorage] getUserId');
    try {
      final userId = _prefs?.getString(LocalStorageKeys.userId);
      debugPrint('[LocalStorage] UserId: $userId');
      return userId;
    } catch (e) {
      debugPrint('[LocalStorage] UserId 读取失败: $e');
      return null;
    }
  }

  Future<void> saveUserEmail(String? email) async {
    debugPrint('[LocalStorage] saveUserEmail: $email');
    try {
      if (email != null) {
        await _prefs?.setString(LocalStorageKeys.userEmail, email);
        debugPrint('[LocalStorage] Email 保存成功');
      } else {
        await _prefs?.remove(LocalStorageKeys.userEmail);
        debugPrint('[LocalStorage] Email 移除成功 (null)');
      }
    } catch (e) {
      debugPrint('[LocalStorage] Email 保存失败: $e');
      rethrow;
    }
  }

  Future<String?> getUserEmail() async {
    debugPrint('[LocalStorage] getUserEmail');
    try {
      final email = _prefs?.getString(LocalStorageKeys.userEmail);
      debugPrint('[LocalStorage] Email: $email');
      return email;
    } catch (e) {
      debugPrint('[LocalStorage] Email 读取失败: $e');
      return null;
    }
  }

  Future<void> saveUserNickname(String? nickname) async {
    debugPrint('[LocalStorage] saveUserNickname: $nickname');
    try {
      if (nickname != null) {
        await _prefs?.setString(LocalStorageKeys.userNickname, nickname);
        debugPrint('[LocalStorage] Nickname 保存成功');
      } else {
        await _prefs?.remove(LocalStorageKeys.userNickname);
        debugPrint('[LocalStorage] Nickname 移除成功 (null)');
      }
    } catch (e) {
      debugPrint('[LocalStorage] Nickname 保存失败: $e');
      rethrow;
    }
  }

  Future<String?> getUserNickname() async {
    debugPrint('[LocalStorage] getUserNickname');
    try {
      final nickname = _prefs?.getString(LocalStorageKeys.userNickname);
      debugPrint('[LocalStorage] Nickname: $nickname');
      return nickname;
    } catch (e) {
      debugPrint('[LocalStorage] Nickname 读取失败: $e');
      return null;
    }
  }

  Future<void> saveUserAvatar(String? avatarUrl) async {
    debugPrint('[LocalStorage] saveUserAvatar: $avatarUrl');
    try {
      if (avatarUrl != null) {
        await _prefs?.setString(LocalStorageKeys.userAvatar, avatarUrl);
        debugPrint('[LocalStorage] Avatar 保存成功');
      } else {
        await _prefs?.remove(LocalStorageKeys.userAvatar);
        debugPrint('[LocalStorage] Avatar 移除成功 (null)');
      }
    } catch (e) {
      debugPrint('[LocalStorage] Avatar 保存失败: $e');
      rethrow;
    }
  }

  Future<String?> getUserAvatar() async {
    debugPrint('[LocalStorage] getUserAvatar');
    try {
      final avatar = _prefs?.getString(LocalStorageKeys.userAvatar);
      debugPrint('[LocalStorage] Avatar: $avatar');
      return avatar;
    } catch (e) {
      debugPrint('[LocalStorage] Avatar 读取失败: $e');
      return null;
    }
  }

  Future<void> saveMemberStatus(int status) async {
    debugPrint('[LocalStorage] saveMemberStatus: $status');
    try {
      await _prefs?.setInt(LocalStorageKeys.memberStatus, status);
      debugPrint('[LocalStorage] MemberStatus 保存成功');
    } catch (e) {
      debugPrint('[LocalStorage] MemberStatus 保存失败: $e');
      rethrow;
    }
  }

  Future<int> getMemberStatus() async {
    debugPrint('[LocalStorage] getMemberStatus');
    try {
      final status = _prefs?.getInt(LocalStorageKeys.memberStatus) ?? 0;
      debugPrint('[LocalStorage] MemberStatus: $status');
      return status;
    } catch (e) {
      debugPrint('[LocalStorage] MemberStatus 读取失败: $e');
      return 0;
    }
  }

  Future<void> savePoints(int points) async {
    debugPrint('[LocalStorage] savePoints: $points');
    try {
      await _prefs?.setInt(LocalStorageKeys.points, points);
      debugPrint('[LocalStorage] Points 保存成功');
    } catch (e) {
      debugPrint('[LocalStorage] Points 保存失败: $e');
      rethrow;
    }
  }

  Future<int> getPoints() async {
    debugPrint('[LocalStorage] getPoints');
    try {
      final points = _prefs?.getInt(LocalStorageKeys.points) ?? 0;
      debugPrint('[LocalStorage] Points: $points');
      return points;
    } catch (e) {
      debugPrint('[LocalStorage] Points 读取失败: $e');
      return 0;
    }
  }

  Future<void> saveIsAnonymous(bool isAnonymous) async {
    debugPrint('[LocalStorage] saveIsAnonymous: $isAnonymous');
    try {
      await _prefs?.setBool(LocalStorageKeys.isAnonymous, isAnonymous);
      debugPrint('[LocalStorage] IsAnonymous 保存成功');
    } catch (e) {
      debugPrint('[LocalStorage] IsAnonymous 保存失败: $e');
      rethrow;
    }
  }

  Future<bool> getIsAnonymous() async {
    debugPrint('[LocalStorage] getIsAnonymous');
    try {
      final isAnonymous = _prefs?.getBool(LocalStorageKeys.isAnonymous) ?? true;
      debugPrint('[LocalStorage] IsAnonymous: $isAnonymous');
      return isAnonymous;
    } catch (e) {
      debugPrint('[LocalStorage] IsAnonymous 读取失败: $e');
      return true;
    }
  }

  Future<void> saveLastSyncTime(DateTime time) async {
    debugPrint('[LocalStorage] saveLastSyncTime: ${time.toIso8601String()}');
    try {
      await _prefs?.setInt(LocalStorageKeys.lastSyncTime, time.millisecondsSinceEpoch);
      debugPrint('[LocalStorage] LastSyncTime 保存成功');
    } catch (e) {
      debugPrint('[LocalStorage] LastSyncTime 保存失败: $e');
      rethrow;
    }
  }

  Future<DateTime?> getLastSyncTime() async {
    debugPrint('[LocalStorage] getLastSyncTime');
    try {
      final timestamp = _prefs?.getInt(LocalStorageKeys.lastSyncTime);
      if (timestamp != null) {
        final time = DateTime.fromMillisecondsSinceEpoch(timestamp);
        debugPrint('[LocalStorage] LastSyncTime: ${time.toIso8601String()}');
        return time;
      }
      debugPrint('[LocalStorage] LastSyncTime: null');
      return null;
    } catch (e) {
      debugPrint('[LocalStorage] LastSyncTime 读取失败: $e');
      return null;
    }
  }

  Future<void> clearAll() async {
    debugPrint('[LocalStorage] ========== clearAll 开始 ==========');
    try {
      debugPrint('[LocalStorage] 清除所有加密存储...');
      await _secureStorage.deleteAll();
      debugPrint('[LocalStorage] 清除所有 SharedPreferences...');
      await _prefs?.clear();
      debugPrint('[LocalStorage] ========== clearAll 完成 ==========');
    } catch (e) {
      debugPrint('[LocalStorage] clearAll 失败: $e');
      rethrow;
    }
  }

  Future<void> clearUserData() async {
    debugPrint('[LocalStorage] ========== clearUserData 开始 ==========');
    try {
      await _prefs?.remove(LocalStorageKeys.userId);
      debugPrint('[LocalStorage] userId 已清除');
      await _prefs?.remove(LocalStorageKeys.userEmail);
      debugPrint('[LocalStorage] userEmail 已清除');
      await _prefs?.remove(LocalStorageKeys.userNickname);
      debugPrint('[LocalStorage] userNickname 已清除');
      await _prefs?.remove(LocalStorageKeys.userAvatar);
      debugPrint('[LocalStorage] userAvatar 已清除');
      await _prefs?.remove(LocalStorageKeys.memberStatus);
      debugPrint('[LocalStorage] memberStatus 已清除');
      await _prefs?.remove(LocalStorageKeys.points);
      debugPrint('[LocalStorage] points 已清除');
      await _prefs?.remove(LocalStorageKeys.isAnonymous);
      debugPrint('[LocalStorage] isAnonymous 已清除');
      await _prefs?.remove(LocalStorageKeys.lastSyncTime);
      debugPrint('[LocalStorage] lastSyncTime 已清除');
      debugPrint('[LocalStorage] ========== clearUserData 完成 ==========');
    } catch (e) {
      debugPrint('[LocalStorage] clearUserData 失败: $e');
      rethrow;
    }
  }

  Future<bool> hasRefreshToken() async {
    debugPrint('[LocalStorage] hasRefreshToken');
    try {
      final token = await getRefreshToken();
      final hasToken = token != null && token.isNotEmpty;
      debugPrint('[LocalStorage] hasRefreshToken: $hasToken');
      return hasToken;
    } catch (e) {
      debugPrint('[LocalStorage] hasRefreshToken 失败: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>> getCachedUserData() async {
    debugPrint('[LocalStorage] ========== getCachedUserData 开始 ==========');
    try {
      final userId = await getUserId();
      debugPrint('[LocalStorage] 获取 userId: ${userId ?? 'null'}');
      final email = await getUserEmail();
      debugPrint('[LocalStorage] 获取 email: ${email ?? 'null'}');
      final nickname = await getUserNickname();
      debugPrint('[LocalStorage] 获取 nickname: ${nickname ?? 'null'}');
      final avatar = await getUserAvatar();
      debugPrint('[LocalStorage] 获取 avatar: ${avatar ?? 'null'}');
      final memberStatus = await getMemberStatus();
      debugPrint('[LocalStorage] 获取 memberStatus: $memberStatus');
      final points = await getPoints();
      debugPrint('[LocalStorage] 获取 points: $points');
      final isAnonymous = await getIsAnonymous();
      debugPrint('[LocalStorage] 获取 isAnonymous: $isAnonymous');
      final lastSyncTime = await getLastSyncTime();
      debugPrint('[LocalStorage] 获取 lastSyncTime: ${lastSyncTime?.toIso8601String() ?? 'null'}');

      debugPrint('[LocalStorage] ========== getCachedUserData 完成 ==========');
      return {
        'userId': userId,
        'email': email,
        'nickname': nickname,
        'avatar': avatar,
        'memberStatus': memberStatus,
        'points': points,
        'isAnonymous': isAnonymous,
        'lastSyncTime': lastSyncTime,
      };
    } catch (e) {
      debugPrint('[LocalStorage] getCachedUserData 失败: $e');
      debugPrint('[LocalStorage] ========== getCachedUserData 完成 (空Map) ==========');
      return {};
    }
  }

  Future<void> printAllStoredData() async {
    debugPrint('[LocalStorage] ========== 打印所有存储数据 ==========');
    final data = await getCachedUserData();
    data.forEach((key, value) {
      debugPrint('[LocalStorage] $key: $value');
    });
    final hasToken = await hasRefreshToken();
    debugPrint('[LocalStorage] hasToken: $hasToken');
    debugPrint('[LocalStorage] ========== 打印完成 ==========');
  }
}
