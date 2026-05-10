import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  late SharedPreferences _prefs;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
  );

  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
  }

  Future<void> saveRefreshToken(String token) async {
    try {
      await _secureStorage.write(key: LocalStorageKeys.refreshToken, value: token);
    } catch (e) {
      rethrow;
    }
  }

  Future<String?> getRefreshToken() async {
    try {
      return await _secureStorage.read(key: LocalStorageKeys.refreshToken);
    } catch (e) {
      return null;
    }
  }

  Future<void> deleteRefreshToken() async {
    try {
      await _secureStorage.delete(key: LocalStorageKeys.refreshToken);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> saveUserId(String userId) async {
    try {
      await _prefs.setString(LocalStorageKeys.userId, userId);
    } catch (e) {
      rethrow;
    }
  }

  Future<String?> getUserId() async {
    try {
      return _prefs.getString(LocalStorageKeys.userId);
    } catch (e) {
      return null;
    }
  }

  Future<void> saveUserEmail(String? email) async {
    try {
      if (email != null) {
        await _prefs.setString(LocalStorageKeys.userEmail, email);
      } else {
        await _prefs.remove(LocalStorageKeys.userEmail);
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<String?> getUserEmail() async {
    try {
      return _prefs.getString(LocalStorageKeys.userEmail);
    } catch (e) {
      return null;
    }
  }

  Future<void> saveUserNickname(String? nickname) async {
    try {
      if (nickname != null) {
        await _prefs.setString(LocalStorageKeys.userNickname, nickname);
      } else {
        await _prefs.remove(LocalStorageKeys.userNickname);
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<String?> getUserNickname() async {
    try {
      return _prefs.getString(LocalStorageKeys.userNickname);
    } catch (e) {
      return null;
    }
  }

  Future<void> saveUserAvatar(String? avatarUrl) async {
    try {
      if (avatarUrl != null) {
        await _prefs.setString(LocalStorageKeys.userAvatar, avatarUrl);
      } else {
        await _prefs.remove(LocalStorageKeys.userAvatar);
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<String?> getUserAvatar() async {
    try {
      return _prefs.getString(LocalStorageKeys.userAvatar);
    } catch (e) {
      return null;
    }
  }

  Future<void> saveMemberStatus(int status) async {
    try {
      await _prefs.setInt(LocalStorageKeys.memberStatus, status);
    } catch (e) {
      rethrow;
    }
  }

  Future<int> getMemberStatus() async {
    try {
      return _prefs.getInt(LocalStorageKeys.memberStatus) ?? 0;
    } catch (e) {
      return 0;
    }
  }

  Future<void> savePoints(int points) async {
    try {
      await _prefs.setInt(LocalStorageKeys.points, points);
    } catch (e) {
      rethrow;
    }
  }

  Future<int> getPoints() async {
    try {
      return _prefs.getInt(LocalStorageKeys.points) ?? 0;
    } catch (e) {
      return 0;
    }
  }

  Future<void> saveIsAnonymous(bool isAnonymous) async {
    try {
      await _prefs.setBool(LocalStorageKeys.isAnonymous, isAnonymous);
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> getIsAnonymous() async {
    try {
      return _prefs.getBool(LocalStorageKeys.isAnonymous) ?? true;
    } catch (e) {
      return true;
    }
  }

  Future<void> saveLastSyncTime(DateTime time) async {
    try {
      await _prefs.setInt(LocalStorageKeys.lastSyncTime, time.millisecondsSinceEpoch);
    } catch (e) {
      rethrow;
    }
  }

  Future<DateTime?> getLastSyncTime() async {
    try {
      final timestamp = _prefs.getInt(LocalStorageKeys.lastSyncTime);
      if (timestamp != null) {
        return DateTime.fromMillisecondsSinceEpoch(timestamp);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<void> clearAll() async {
    try {
      await _secureStorage.deleteAll();
      await _prefs.clear();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> clearUserData() async {
    try {
      await _prefs.remove(LocalStorageKeys.userId);
      await _prefs.remove(LocalStorageKeys.userEmail);
      await _prefs.remove(LocalStorageKeys.userNickname);
      await _prefs.remove(LocalStorageKeys.userAvatar);
      await _prefs.remove(LocalStorageKeys.memberStatus);
      await _prefs.remove(LocalStorageKeys.points);
      await _prefs.remove(LocalStorageKeys.isAnonymous);
      await _prefs.remove(LocalStorageKeys.lastSyncTime);
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> hasRefreshToken() async {
    try {
      final token = await getRefreshToken();
      return token != null && token.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  Future<Map<String, dynamic>> getCachedUserData() async {
    try {
      final userId = await getUserId();
      final email = await getUserEmail();
      final nickname = await getUserNickname();
      final avatar = await getUserAvatar();
      final memberStatus = await getMemberStatus();
      final points = await getPoints();
      final isAnonymous = await getIsAnonymous();
      final lastSyncTime = await getLastSyncTime();

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
      return {};
    }
  }
}
