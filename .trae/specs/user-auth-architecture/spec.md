# 收纳助手 - 用户认证架构设计规范

## Why

收纳助手需要完善的用户系统支持会员体系、积分系统和数据云同步功能。产品文档要求支持邮箱注册登录、匿名登录、用户信息管理等功能。腾讯云开发（TCB）提供完整的认证服务，需要设计合理的架构来满足产品需求，同时遵循 TCB Flutter SDK 的官方 API 规范。

## What Changes

- 设计用户认证系统架构（登录、注册、匿名登录）
- 设计用户信息管理方案（获取、更新、本地缓存）
- 设计用户状态与服务器同步策略
- 设计密码重置流程
- 建立应用层认证服务层，封装 TCB SDK 调用
- 增加详细的调试日志，方便测试和问题排查
- 编写单元测试，覆盖核心功能

## Impact

- Affected specs: MVP阶段核心功能（用户系统）
- Affected code: 新建 `lib/core/auth/` 目录，包含认证服务层、数据模型、本地存储等

## 调试日志说明

为方便测试和问题排查，所有核心服务都添加了详细的调试日志：

### AuthService 日志标签
- `[AuthService]` - 所有方法调用
- `==========` 分隔符标记重要流程节点
- `------` 分隔符标记方法调用边界

### LocalStorageService 日志标签
- `[LocalStorage]` - 所有存储操作

### AuthProvider 日志标签
- `[AuthProvider]` - 状态管理相关

## 测试说明

单元测试位于 `test/auth_test.dart`，覆盖：
- UserInfo 数据模型
- AuthState 状态枚举
- AuthResult 结果封装
- AuthException 异常处理
- 表单验证逻辑
- 会员等级限制

## 技术选型

| 组件 | 技术方案 | 说明 |
|------|----------|------|
| 云服务 | cloudbase_flutter | 腾讯云开发 Flutter SDK |
| 安全存储 | flutter_secure_storage | 加密存储 Token |
| 配置存储 | shared_preferences | 用户配置信息 |
| 状态管理 | Provider | 状态管理框架 |
