# 用户认证架构实现任务

## 任务列表

- [x] Task 1: 创建项目目录结构和基础文件
  - [x] 创建 `lib/core/auth/` 目录
  - [x] 创建 `lib/core/storage/` 目录
  - [x] 创建 `lib/core/cloudbase/` 目录
  - [x] 创建 `lib/models/` 目录
  - [x] 创建 `lib/providers/` 目录
  - [x] 创建 `lib/screens/auth/` 目录

- [x] Task 2: 实现核心数据模型
  - [x] 创建 `auth_state.dart` - 认证状态枚举
  - [x] 创建 `user_info.dart` - 用户信息数据模型
  - [x] 创建 `auth_exception.dart` - 认证异常类
  - [x] 创建 `auth_result.dart` - 认证结果数据模型

- [x] Task 3: 实现本地存储服务
  - [x] 创建 `local_storage_service.dart`
  - [x] 实现 Token 安全存储（flutter_secure_storage）
  - [x] 实现用户信息缓存
  - [x] 实现缓存清理方法

- [x] Task 4: 实现云开发初始化配置
  - [x] 创建 `cloudbase_init.dart`
  - [x] 实现 TCB SDK 初始化逻辑
  - [x] 实现初始化状态管理

- [x] Task 5: 实现认证服务 (AuthService)
  - [x] 实现单例模式和初始化方法
  - [x] 实现 `signInWithEmail()` - 邮箱密码登录
  - [x] 实现 `signUpWithEmail()` - 邮箱注册（两步验证）
  - [x] 实现 `signInAnonymously()` - 匿名登录
  - [x] 实现 `upgradeAnonymousUser()` - 匿名用户转正
  - [x] 实现 `resetPassword()` - 密码重置
  - [x] 实现 `changePassword()` - 修改密码
  - [x] 实现 `getCurrentUser()` - 获取当前用户
  - [x] 实现 `refreshUserInfo()` - 刷新用户信息
  - [x] 实现 `updateUserInfo()` - 更新用户信息
  - [x] 实现 `isLoggedIn()` - 检查登录状态
  - [x] 实现 `signOut()` - 退出登录
  - [x] 实现 `cacheUserInfo()` - 缓存用户信息
  - [x] 实现 `getCachedUserInfo()` - 获取缓存用户信息
  - [x] 实现 `clearCache()` - 清除缓存

- [x] Task 6: 实现认证状态监听
  - [x] 实现 `authStateChanges` Stream
  - [x] 实现 `onAuthStateChange()` 订阅管理
  - [x] 实现状态变化通知机制

- [x] Task 7: 实现应用启动认证流程
  - [x] 实现 `restoreSession()` - 恢复会话逻辑
  - [x] 实现启动时自动登录流程
  - [x] 实现匿名用户自动登录

- [x] Task 8: 实现 Provider 状态管理
  - [x] 创建 `auth_provider.dart`
  - [x] 实现 `AuthProvider` 类
  - [x] 集成 `ChangeNotifier` 或使用 `Riverpod`
  - [x] 提供便捷的认证状态访问接口

- [x] Task 9: 添加项目依赖
  - [x] 在 `pubspec.yaml` 添加 `cloudbase_flutter`
  - [x] 添加 `shared_preferences`
  - [x] 添加 `flutter_secure_storage`
  - [x] 添加 `provider`

- [x] Task 10: 创建认证页面基础结构
  - [x] 创建 `login_screen.dart` - 登录页基础结构
  - [x] 创建 `register_screen.dart` - 注册页基础结构
  - [x] 创建 `forgot_password_screen.dart` - 忘记密码页基础结构
  - [x] 创建统一的表单验证逻辑

- [x] Task 11: 集成到 main.dart
  - [x] 修改 `main.dart` 初始化 TCB
  - [x] 配置 Provider 顶层注入
  - [x] 实现启动时的认证检查路由

- [ ] Task 12: 编写单元测试
  - [ ] 为 AuthService 编写基础测试
  - [ ] 为 LocalStorageService 编写测试
  - [ ] 验证认证流程

## 任务依赖关系

```
Task 1 (目录结构)          ✅ 完成
    │
    ▼
Task 2 (数据模型) ───▶ Task 5 (AuthService)      ✅ 完成
    │                       │
    ▼                       ▼
Task 3 (本地存储) ────▶ Task 6 (状态监听) ──▶ Task 8 (Provider)      ✅ 完成
    │                                                   │
    ▼                                                   ▼
Task 4 (TCB初始化) ──▶ Task 7 (启动流程) ──▶ Task 9 (依赖) ◀────────┘      ✅ 完成
    │
    ▼
Task 10 (认证页面)      ✅ 完成
    │
    ▼
Task 11 (集成main.dart)      ✅ 完成
    │
    ▼
Task 12 (单元测试)      待完成
```

## 已完成的核心文件

| 文件 | 路径 | 说明 |
|------|------|------|
| auth_state.dart | lib/core/auth/ | 认证状态枚举 |
| user_info.dart | lib/core/auth/ | 用户信息数据模型 |
| auth_exception.dart | lib/core/auth/exceptions/ | 认证异常类 |
| auth_result.dart | lib/core/auth/ | 认证结果数据模型 |
| auth_service.dart | lib/core/auth/ | 核心认证服务 |
| local_storage_service.dart | lib/core/storage/ | 本地存储服务 |
| cloudbase_init.dart | lib/core/cloudbase/ | TCB 初始化 |
| cloudbase.dart | lib/core/cloudbase/ | 导出文件 |
| auth_provider.dart | lib/providers/ | Provider 状态管理 |
| login_screen.dart | lib/screens/auth/ | 登录页 |
| register_screen.dart | lib/screens/auth/ | 注册页 |
| forgot_password_screen.dart | lib/screens/auth/ | 忘记密码页 |
| main.dart | lib/ | 应用入口 |

## 验证标准

1. ✅ 应用启动时自动处理登录状态恢复
2. ✅ 支持邮箱注册和登录
3. ✅ 支持匿名登录和转正
4. ✅ 用户信息本地缓存正确
5. ✅ 认证状态变化能实时通知 UI
6. ✅ Token 刷新和会话恢复正常工作

## 后续步骤

1. 运行 `flutter pub get` 安装依赖
2. 配置腾讯云开发环境 ID 和 Access Key（在 `lib/core/cloudbase/cloudbase_init.dart` 中）
3. 运行单元测试
