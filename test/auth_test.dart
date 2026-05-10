import 'package:flutter_test/flutter_test.dart';
import 'package:where_is_stuff/core/auth/user_info.dart';
import 'package:where_is_stuff/core/auth/auth_state.dart';
import 'package:where_is_stuff/core/auth/auth_result.dart';
import 'package:where_is_stuff/core/auth/exceptions/auth_exception.dart';

void main() {
  group('UserInfo Tests', () {
    test('UserInfo should create with required fields', () {
      final user = UserInfo(
        id: 'test-id-123',
        email: 'test@example.com',
        nickname: 'TestUser',
        isAnonymous: false,
        memberStatus: MemberStatus.free,
        points: 100,
        createdAt: DateTime(2024, 1, 1),
      );

      expect(user.id, 'test-id-123');
      expect(user.email, 'test@example.com');
      expect(user.nickname, 'TestUser');
      expect(user.isAnonymous, false);
      expect(user.memberStatus, MemberStatus.free);
      expect(user.points, 100);
    });

    test('UserInfo copyWith should work correctly', () {
      final user = UserInfo(
        id: 'test-id-123',
        email: 'test@example.com',
        nickname: 'TestUser',
        isAnonymous: false,
        memberStatus: MemberStatus.free,
        points: 100,
        createdAt: DateTime(2024, 1, 1),
      );

      final updatedUser = user.copyWith(
        nickname: 'NewName',
        points: 200,
      );

      expect(updatedUser.id, 'test-id-123');
      expect(updatedUser.nickname, 'NewName');
      expect(updatedUser.points, 200);
      expect(updatedUser.email, 'test@example.com');
    });

    test('UserInfo toJson should serialize correctly', () {
      final user = UserInfo(
        id: 'test-id-123',
        email: 'test@example.com',
        nickname: 'TestUser',
        avatarUrl: 'https://example.com/avatar.png',
        gender: Gender.male,
        isAnonymous: false,
        memberStatus: MemberStatus.basic,
        points: 150,
        createdAt: DateTime(2024, 1, 1),
      );

      final json = user.toJson();

      expect(json['id'], 'test-id-123');
      expect(json['email'], 'test@example.com');
      expect(json['nickname'], 'TestUser');
      expect(json['avatarUrl'], 'https://example.com/avatar.png');
      expect(json['gender'], 'male');
      expect(json['isAnonymous'], false);
      expect(json['memberStatus'], 1);
      expect(json['points'], 150);
    });

    test('UserInfo fromJson should deserialize correctly', () {
      final json = {
        'id': 'test-id-456',
        'email': 'test2@example.com',
        'nickname': 'TestUser2',
        'avatarUrl': 'https://example.com/avatar2.png',
        'gender': 'female',
        'isAnonymous': true,
        'memberStatus': 2,
        'points': 300,
        'createdAt': '2024-02-01T00:00:00.000',
      };

      final user = UserInfo.fromJson(json);

      expect(user.id, 'test-id-456');
      expect(user.email, 'test2@example.com');
      expect(user.nickname, 'TestUser2');
      expect(user.avatarUrl, 'https://example.com/avatar2.png');
      expect(user.gender, Gender.female);
      expect(user.isAnonymous, true);
      expect(user.memberStatus, MemberStatus.premium);
      expect(user.points, 300);
    });

    test('MemberStatus should have correct values', () {
      expect(MemberStatus.values.length, 3);
      expect(MemberStatus.free.index, 0);
      expect(MemberStatus.basic.index, 1);
      expect(MemberStatus.premium.index, 2);
    });

    test('Gender should have correct values', () {
      expect(Gender.values.length, 2);
      expect(Gender.male.index, 0);
      expect(Gender.female.index, 1);
    });
  });

  group('AuthState Tests', () {
    test('AuthState should have all required values', () {
      expect(AuthState.values.length, 5);
      expect(AuthState.values.contains(AuthState.initial), true);
      expect(AuthState.values.contains(AuthState.authenticated), true);
      expect(AuthState.values.contains(AuthState.unauthenticated), true);
      expect(AuthState.values.contains(AuthState.anonymous), true);
      expect(AuthState.values.contains(AuthState.loading), true);
    });
  });

  group('AuthResult Tests', () {
    test('AuthResult.success should create success result', () {
      final user = UserInfo(
        id: 'test-id',
        email: 'test@example.com',
        nickname: 'Test',
        isAnonymous: false,
        memberStatus: MemberStatus.free,
        points: 0,
        createdAt: DateTime.now(),
      );

      final result = AuthResult.success(
        user: user,
        sessionToken: 'test-token-123',
      );

      expect(result.isSuccess, true);
      expect(result.user, user);
      expect(result.sessionToken, 'test-token-123');
      expect(result.error, null);
    });

    test('AuthResult.failure should create failure result', () {
      final error = AuthException(
        code: 'invalid_credentials',
        message: 'Invalid email or password',
      );

      final result = AuthResult.failure(error);

      expect(result.isSuccess, false);
      expect(result.user, null);
      expect(result.sessionToken, null);
      expect(result.error, error);
    });

    test('AuthResult.success with no user should work', () {
      final result = AuthResult.success();

      expect(result.isSuccess, true);
      expect(result.user, null);
      expect(result.sessionToken, null);
      expect(result.error, null);
    });
  });

  group('AuthException Tests', () {
    test('AuthException should create with code and message', () {
      final exception = AuthException(
        code: 'user_not_found',
        message: 'User does not exist',
      );

      expect(exception.code, 'user_not_found');
      expect(exception.message, 'User does not exist');
    });

    test('AuthException error codes should be defined', () {
      expect(AuthException.invalidCredentials.isNotEmpty, true);
      expect(AuthException.userNotFound.isNotEmpty, true);
      expect(AuthException.emailAlreadyExists.isNotEmpty, true);
      expect(AuthException.passwordTooWeak.isNotEmpty, true);
      expect(AuthException.networkError.isNotEmpty, true);
      expect(AuthException.sessionExpired.isNotEmpty, true);
      expect(AuthException.unknownError.isNotEmpty, true);
    });

    test('AuthException toString should format correctly', () {
      final exception = AuthException(
        code: 'test_code',
        message: 'Test message',
      );

      final str = exception.toString();
      expect(str.contains('test_code'), true);
      expect(str.contains('Test message'), true);
    });
  });

  group('Form Validation Tests', () {
    test('Email validation regex should work', () {
      final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');

      expect(emailRegex.hasMatch('test@example.com'), true);
      expect(emailRegex.hasMatch('user.name@domain.co'), true);
      expect(emailRegex.hasMatch('invalid-email'), false);
      expect(emailRegex.hasMatch('missing@domain'), false);
      expect(emailRegex.hasMatch('@domain.com'), false);
    });

    test('Password validation should check minimum length', () {
      bool isValidPassword(String password) {
        return password.length >= 6;
      }

      expect(isValidPassword('123456'), true);
      expect(isValidPassword('abcdef'), true);
      expect(isValidPassword('12345'), false);
      expect(isValidPassword(''), false);
    });

    test('Password confirmation should match', () {
      bool passwordsMatch(String password, String confirm) {
        return password == confirm;
      }

      expect(passwordsMatch('password123', 'password123'), true);
      expect(passwordsMatch('password123', 'different'), false);
    });
  });

  group('MemberStatus Logic Tests', () {
    test('Room limit based on member status', () {
      int getRoomLimit(MemberStatus status) {
        switch (status) {
          case MemberStatus.free:
            return 3;
          case MemberStatus.basic:
            return 10;
          case MemberStatus.premium:
            return -1; // unlimited
        }
      }

      expect(getRoomLimit(MemberStatus.free), 3);
      expect(getRoomLimit(MemberStatus.basic), 10);
      expect(getRoomLimit(MemberStatus.premium), -1);
    });

    test('Furniture limit based on member status', () {
      int getFurnitureLimit(MemberStatus status) {
        switch (status) {
          case MemberStatus.free:
            return 10;
          case MemberStatus.basic:
            return 50;
          case MemberStatus.premium:
            return -1;
        }
      }

      expect(getFurnitureLimit(MemberStatus.free), 10);
      expect(getFurnitureLimit(MemberStatus.basic), 50);
      expect(getFurnitureLimit(MemberStatus.premium), -1);
    });
  });
}
