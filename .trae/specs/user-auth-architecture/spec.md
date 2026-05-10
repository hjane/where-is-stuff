# 收纳助手 - 用户认证架构设计规范

## Why

收纳助手需要完善的用户系统支持会员体系、积分系统和数据云同步功能。产品文档要求支持邮箱注册登录、匿名登录、用户信息管理等功能。腾讯云开发（TCB）提供完整的认证服务，需要设计合理的架构来满足产品需求，同时遵循 TCB Flutter SDK 的官方 API 规范。

## What Changes

- 设计用户认证系统架构（登录、注册、匿名登录）
- 设计用户信息管理方案（获取、更新、本地缓存）
- 设计用户状态与服务器同步策略
- 设计密码重置流程
- 建立应用层认证服务层，封装 TCB SDK 调用

## Impact

- Affected specs: MVP阶段核心功能（用户系统）
- Affected code: 新建 `lib/core/auth/` 目录，包含认证服务层、数据模型、本地存储等

## ADDED Requirements

### Requirement: 匿名登录支持

应用应支持未登录用户先体验基础功能，后续再绑定正式账号。

#### Scenario: 匿名用户首次启动
- **WHEN** 用户首次打开应用且未登录
- **THEN** 系统自动创建匿名会话，加载应用首页
- **AND** 用户可使用基础功能（创建房间、家具、物品）
- **AND** 用户操作数据暂存本地

#### Scenario: 匿名用户注册/登录
- **WHEN** 匿名用户选择注册或登录
- **THEN** 调用 `signUp` 时传入 `anonymousToken` 实现匿名用户转正
- **AND** 转正后自动合并本地数据至该用户账号

#### Scenario: 匿名用户升级为正式用户
- **WHEN** 匿名用户通过邮箱注册成为正式用户
- **THEN** 系统自动关联原匿名会话数据
- **AND** 用户历史操作记录保留

### Requirement: 邮箱注册与登录

应用支持用户通过邮箱和密码进行注册和登录。

#### Scenario: 邮箱注册流程
- **WHEN** 用户输入邮箱和密码提交注册
- **THEN** 调用 `auth.signUp(SignUpReq)` 发送验证码
- **AND** 用户输入验证码后调用 `verifyOtp` 完成注册
- **AND** 注册成功后自动登录

#### Scenario: 邮箱密码登录
- **WHEN** 用户输入邮箱和密码
- **THEN** 调用 `auth.signInWithPassword()` 直接登录
- **AND** 登录成功后缓存用户信息

#### Scenario: 登录失败处理
- **WHEN** 用户输入错误的邮箱或密码
- **THEN** 显示错误提示（用户名或密码错误）
- **AND** 不暴露具体是邮箱不存在还是密码错误

### Requirement: 密码重置

用户可通过邮箱验证码重置密码。

#### Scenario: 发送重置密码验证码
- **WHEN** 用户在登录页点击"忘记密码"
- **THEN** 提示用户输入注册邮箱
- **AND** 调用相关 API 发送重置验证码

#### Scenario: 重置密码
- **WHEN** 用户输入邮箱收到的验证码和新密码
- **THEN** 验证通过后更新密码
- **AND** 跳转至登录页

### Requirement: 用户信息管理

用户可查看和更新自己的个人信息。

#### Scenario: 获取用户信息
- **WHEN** 应用启动或用户进入个人中心
- **THEN** 调用 `auth.getSession()` 获取当前会话和用户信息
- **AND** 从返回的 `User` 对象中获取用户基本信息

#### Scenario: 更新用户信息
- **WHEN** 用户修改昵称、头像等个人信息
- **THEN** 调用用户更新 API 更新服务器数据
- **AND** 同时更新本地缓存

### Requirement: 本地缓存用户信息

应用在本地缓存用户登录状态和信息，减少网络请求。

#### Scenario: 缓存登录状态
- **WHEN** 用户登录成功
- **THEN** 将 `refreshToken` 和用户基本信息存储至本地
- **AND** 存储位置：使用 Flutter `shared_preferences` 或 `flutter_secure_storage`

#### Scenario: 启动时恢复登录状态
- **WHEN** 应用冷启动
- **THEN** 从本地读取缓存的 `refreshToken`
- **AND** 调用 `auth.setSession()` 恢复会话
- **AND** 调用 `auth.getSession()` 验证并获取最新用户信息

#### Scenario: 本地缓存数据与服务器同步策略
- **WHEN** 用户登录后
  - 本地缓存用户基本信息（userId, email, nickname, avatarUrl, memberStatus, points）
  - 本地缓存 `refreshToken` 用于会话恢复
- **WHEN** 应用启动时
  - 优先使用本地缓存展示用户信息（快速响应）
  - 后台调用 `getSession()` 获取最新服务器数据
  - 如服务器数据与本地不一致，以服务器为准并更新本地缓存
- **WHEN** Token 过期时
  - SDK 自动使用 `refreshToken` 刷新会话
  - 刷新成功则继续使用
  - 刷新失败则清除本地缓存，引导用户重新登录

### Requirement: 登录状态监听

应用实时监听用户登录状态变化。

#### Scenario: 监听登录状态
- **WHEN** 应用启动
- **THEN** 调用 `auth.onAuthStateChange()` 监听状态变化
- **AND** 状态包括：`signedIn`、`signedOut`、`tokenRefreshed`、`userUpdated`
- **AND** 根据状态变化更新 UI 或执行相应逻辑

#### Scenario: 退出登录
- **WHEN** 用户主动退出登录
- **THEN** 调用 `auth.signOut()` 清除服务端会话
- **AND** 清除本地缓存的登录信息和用户数据
- **AND** 跳转至登录页或首页（根据产品决策）

## MODIFIED Requirements

### Requirement: 游客模式 vs 登录模式

产品文档中提到免费用户可体验基础功能，需要明确游客模式和登录模式的数据边界。

#### 游客模式（未登录/匿名用户）
- 可创建最多 3 个房间、10 个家具（符合免费会员限制）
- 数据仅保存在本地
- 使用匿名会话标识

#### 登录模式（正式用户）
- 根据会员等级享受不同功能限制
- 数据支持云同步（基础会员及以上）
- 可使用积分功能

## REMOVED Requirements

无

## Architecture Design

### 目录结构设计

```
lib/
├── core/
│   ├── auth/
│   │   ├── auth_service.dart          # 认证服务封装
│   │   ├── auth_state.dart             # 认证状态枚举
│   │   ├── user_info.dart             # 用户信息数据模型
│   │   └── exceptions/
│   │       └── auth_exception.dart     # 认证异常类
│   ├── storage/
│   │   └── local_storage_service.dart  # 本地存储服务
│   └── cloudbase/
│       └── cloudbase_init.dart         # TCB 初始化配置
├── models/
│   └── user_profile.dart              # 用户资料模型
├── providers/
│   └── auth_provider.dart             # 状态管理（Provider/Riverpod）
├── screens/
│   └── auth/
│       ├── login_screen.dart           # 登录页
│       ├── register_screen.dart        # 注册页
│       └── forgot_password_screen.dart # 忘记密码页
└── main.dart
```

### 核心服务设计

#### AuthService 职责

```dart
class AuthService {
  // 单例模式
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;

  // 初始化
  Future<void> initialize();

  // 登录相关
  Future<AuthResult> signInWithEmail(String email, String password);
  Future<AuthResult> signUpWithEmail(String email, String password, String nickname);
  Future<AuthResult> signInAnonymously();
  Future<AuthResult> upgradeAnonymousUser(String email, String password, String nickname);

  // 密码管理
  Future<void> resetPassword(String email);
  Future<void> changePassword(String oldPassword, String newPassword);

  // 用户信息
  Future<UserInfo?> getCurrentUser();
  Future<UserInfo?> refreshUserInfo();
  Future<void> updateUserInfo(UserInfo userInfo);

  // 会话管理
  Future<bool> isLoggedIn();
  Future<void> signOut();
  Stream<AuthState> get authStateChanges;

  // 本地缓存
  Future<void> cacheUserInfo(UserInfo userInfo);
  Future<UserInfo?> getCachedUserInfo();
  Future<void> clearCache();
}
```

#### 认证流程图

```
┌─────────────────────────────────────────────────────────────┐
│                        应用启动                              │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                    1. 检查本地缓存                            │
│  ┌─────────────────┐    ┌─────────────────┐                 │
│  │ 有缓存的Token    │───▶│ 2. 尝试恢复会话   │                 │
│  └─────────────────┘    └─────────────────┘                 │
│           │                         │                        │
│           │                         ▼                        │
│           │              ┌─────────────────┐                 │
│           │              │   getSession    │                 │
│           │              └─────────────────┘                 │
│           │                     │                            │
│           ▼                     ▼                            │
│  ┌─────────────────┐    ┌─────────────────┐                 │
│  │ 无缓存或恢复失败 │    │   会话恢复成功   │                 │
│  └─────────────────┘    └─────────────────┘                 │
│           │                     │                            │
│           ▼                     ▼                            │
│  ┌─────────────────┐    ┌─────────────────┐                 │
│  │ 匿名登录         │    │ 刷新用户信息     │                 │
│  │ signInAnonymous │    │ 更新本地缓存     │                 │
│  └─────────────────┘    └─────────────────┘                 │
│           │                     │                            │
│           └──────────┬──────────┘                           │
│                      ▼                                        │
│  ┌─────────────────────────────────────────────────────────┐ │
│  │                      进入首页                            │ │
│  └─────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────┘
```

#### 注册流程（邮箱+验证码）

```
┌──────────────┐     ┌──────────────┐     ┌──────────────┐
│  用户输入     │     │  发送验证码   │     │  验证并注册   │
│  邮箱+密码   │ ──▶ │  signUp()   │ ──▶ │ verifyOtp()  │
└──────────────┘     └──────────────┘     └──────────────┘
                                                  │
                                                  ▼
                                          ┌──────────────┐
                                          │  自动登录    │
                                          │  缓存信息    │
                                          └──────────────┘
```

#### 匿名用户转正流程

```
┌──────────────┐     ┌──────────────┐     ┌──────────────┐
│  匿名登录     │     │  绑定邮箱     │     │  验证并转正   │
│  已有Token   │ ──▶ │  signUp()   │ ──▶ │ verifyOtp()  │
│              │     │anonymousToken│     │              │
└──────────────┘     └──────────────┘     └──────────────┘
                                                  │
                                                  ▼
                                          ┌──────────────┐
                                          │  数据迁移    │
                                          │  合并本地数据 │
                                          └──────────────┘
```

### 数据模型设计

```dart
class UserInfo {
  final String id;           // 用户唯一标识
  final String? email;        // 邮箱（可为null，匿名用户）
  final String? nickname;     // 昵称
  final String? avatarUrl;   // 头像URL
  final Gender? gender;       // 性别
  final bool isAnonymous;     // 是否匿名用户
  final MemberStatus memberStatus;  // 会员状态
  final int points;           // 积分
  final DateTime createdAt;   // 创建时间
  final DateTime? updatedAt; // 更新时间
}

enum MemberStatus {
  free,      // 免费会员
  basic,     // 基础会员
  premium,   // 高级会员
}

enum AuthState {
  initial,
  authenticated,
  unauthenticated,
  anonymous,
}
```

### 本地存储设计

```dart
// 使用 flutter_secure_storage 存储敏感信息
// 使用 shared_preferences 存储一般配置

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
```

### 状态同步策略

| 场景 | 同步策略 | 说明 |
|------|----------|------|
| 登录成功 | 立即同步 | 缓存用户信息和Token |
| 应用冷启动 | 先缓存后服务器 | 优先展示缓存，后台同步最新数据 |
| Token即将过期 | 自动刷新 | SDK自动处理，失败则引导重新登录 |
| 用户信息更新 | 立即同步 | 写入服务器后更新本地缓存 |
| 网络断开 | 本地优先 | 操作暂存本地，网络恢复后同步 |
| 匿名转正 | 数据迁移 | 将本地数据关联至新用户 |

## 技术选型说明

### SDK 版本

- 使用 `cloudbase_flutter` 最新稳定版
- 参考官方文档示例代码

### 状态管理

- 建议使用 `Provider` 或 `Riverpod` 管理认证状态
- 核心 Provider：`AuthProvider` 监听认证状态变化

### 依赖包

```yaml
dependencies:
  flutter:
    sdk: flutter
  cloudbase_flutter: ^latest
  shared_preferences: ^latest
  flutter_secure_storage: ^latest
  provider: ^latest
```

### 错误处理

```dart
class AuthException implements Exception {
  final String code;
  final String message;

  // 常见错误码
  static const String invalidCredentials = 'invalid_credentials';
  static const String userNotFound = 'user_not_found';
  static const String emailAlreadyExists = 'email_already_exists';
  static const String passwordTooWeak = 'password_too_weak';
  static const String networkError = 'network_error';
}
```

## 后续扩展

### 微信登录

```dart
Future<AuthResult> signInWithWeChat() async {
  final result = await auth.signInWithOAuth(
    SignInWithOAuthReq(provider: 'wechat'),
  );
  if (result.isSuccess) {
    // 引导用户打开授权页面
    await launchUrl(Uri.parse(result.data!.url!));
  }
}
```

### 会员系统集成

- 用户登录后从服务器获取最新会员状态
- 会员等级影响功能权限（房间数、家具数限制等）
- 积分余额实时从服务器同步

### 数据迁移策略

- 匿名用户转正时，本地数据（房间、家具、物品）需要重新关联 `userId`
- 建议：匿名用户操作时使用本地临时 `userId`，转正后更新为正式 `userId`
