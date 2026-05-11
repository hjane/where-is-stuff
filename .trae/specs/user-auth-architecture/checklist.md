# 用户认证架构实现检查清单

## 基础架构检查

- [x] 项目目录结构创建完成（core/auth/, core/storage/, core/cloudbase/, models/, providers/, screens/auth/）
- [x] `pubspec.yaml` 包含所有必需依赖（cloudbase_flutter, shared_preferences, flutter_secure_storage, provider）
- [x] TCB SDK 初始化配置正确（env, region, accessKey, authConfig）

## 数据模型检查

- [x] `auth_state.dart` 正确包含所有认证状态枚举（initial, authenticated, unauthenticated, anonymous, loading）
- [x] `user_info.dart` 包含所有必需字段（id, email, nickname, avatarUrl, gender, isAnonymous, memberStatus, points）
- [x] `auth_exception.dart` 包含常见错误码定义
- [x] `auth_result.dart` 正确封装认证结果

## 本地存储检查

- [x] Token（refreshToken）使用 `flutter_secure_storage` 安全存储
- [x] 用户基本信息使用 `shared_preferences` 存储
- [x] `LocalStorageKeys` 定义了所有存储键
- [x] `clearCache()` 方法能清除所有相关缓存
- [x] 本地存储的 Token 能正确用于会话恢复

## 认证服务检查

- [x] `AuthService` 使用单例模式
- [x] `initialize()` 方法正确初始化 TCB SDK
- [x] `signInWithEmail()` 调用 `auth.signInWithPassword()` 并正确处理结果
- [x] `signUpWithEmail()` 实现两步验证流程（signUp + verifyOtp）
- [x] `signInAnonymously()` 调用 `auth.signInAnonymously()` 并正确处理结果
- [x] `upgradeAnonymousUser()` 在注册时传入 `anonymousToken`
- [x] `resetPassword()` 实现了密码重置验证码发送
- [x] `getCurrentUser()` 调用 `auth.getSession()` 获取用户信息
- [x] `isLoggedIn()` 正确判断登录状态
- [x] `signOut()` 同时清除服务端会话和本地缓存
- [x] 所有方法正确处理错误和异常

## 会话管理检查

- [x] `setSession()` 用于恢复会话（使用缓存的 refreshToken）
- [x] `getSession()` 用于验证和获取用户信息
- [x] Token 自动刷新机制正常工作（SDK 自动处理）
- [x] 刷新失败时能正确引导用户重新登录

## 状态监听检查

- [x] `authStateChanges` Stream 正确发射状态变化
- [x] 监听 `signedIn`, `signedOut`, `tokenRefreshed`, `userUpdated` 事件
- [x] 有取消订阅的方法

## 启动流程检查

- [x] 应用启动时检查本地缓存的 Token
- [x] 有 Token 时尝试恢复会话
- [x] 恢复失败或无 Token 时自动匿名登录
- [x] 登录成功后更新本地缓存

## 缓存同步检查

- [x] 登录成功时立即缓存用户信息
- [x] 应用启动时先展示缓存数据
- [x] 后台从服务器获取最新数据并更新缓存
- [x] 服务器数据优先于本地缓存

## Provider 状态管理检查

- [x] `AuthProvider` 正确实现状态管理
- [x] UI 能通过 Provider 访问认证状态
- [x] 认证状态变化时 UI 能自动更新
- [x] 提供便捷的方法供 UI 调用

## 认证页面检查

- [x] 登录页包含邮箱和密码输入框
- [x] 登录页包含"忘记密码"链接
- [x] 登录页包含"注册"链接和"匿名登录"选项
- [x] 注册页包含邮箱、密码、确认密码、昵称输入
- [x] 注册页正确显示验证码输入步骤
- [x] 忘记密码页包含邮箱输入和发送验证码按钮
- [x] 表单验证正确（邮箱格式、密码强度等）
- [x] 加载状态和错误提示正确显示

## main.dart 集成检查

- [x] TCB SDK 在应用启动时初始化
- [x] Provider 在应用顶层正确注入
- [x] 启动时执行认证检查
- [x] 根据认证状态正确路由（已登录/未登录/匿名）

## 代码质量检查

- [x] 代码遵循 Dart/Flutter 编码规范
- [x] 所有公开方法有文档注释
- [x] 错误处理完善
- [x] 无硬编码敏感信息（敏感配置需用户自行配置）
- [x] 使用 const 构造函数优化性能

## 测试检查

- [ ] AuthService 核心方法有单元测试（环境限制，待后续补充）
- [ ] LocalStorageService 有单元测试（环境限制，待后续补充）
- [ ] 测试覆盖登录、注册、退出等核心流程（环境限制，待后续补充）

## 配置说明

⚠️ **重要**：在运行应用前，需要配置腾讯云开发的环境信息：

1. 打开 `lib/core/cloudbase/cloudbase_init.dart`
2. 修改 `TCBConfig` 类中的以下配置：
   - `envId`: 您的腾讯云开发环境 ID
   - `accessKey`: 您的 Publishable Key（从 [云开发平台](https://tcb.cloud.tencent.com/dev#/env/apikey) 获取）

```dart
class TCBConfig {
  static const String envId = 'your-env-id';        // 替换为您的环境ID
  static const String region = 'ap-shanghai';       // 地域
  static const String accessKey = 'your-access-key'; // 替换为您的 Publishable Key
}
```
