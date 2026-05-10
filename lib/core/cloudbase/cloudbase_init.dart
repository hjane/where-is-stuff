import 'package:cloudbase_flutter/cloudbase_flutter.dart';
import 'package:flutter/foundation.dart';

class TCBConfig {
  static const String envId = 'where-is-stuff-d7gge0yv963acd056';
  static const String region = 'ap-shanghai';
  static const String accessKey = 'eyJhbGciOiJSUzI1NiIsImtpZCI6IjlkMWRjMzFlLWI0ZDAtNDQ4Yi1hNzZmLWIwY2M2M2Q4MTQ5OCJ9.eyJpc3MiOiJodHRwczovL3doZXJlLWlzLXN0dWZmLWQ3Z2dlMHl2OTYzYWNkMDU2LmFwLXNoYW5naGFpLnRjYi1hcGkudGVuY2VudGNsb3VkYXBpLmNvbSIsInN1YiI6ImFub24iLCJhdWQiOiJ3aGVyZS1pcy1zdHVmZi1kN2dnZTB5djk2M2FjZDA1NiIsImV4cCI6NDA4MjA3MDkzMSwiaWF0IjoxNzc4Mzg3NzMxLCJub25jZSI6InhxY01QdnE3UVcyTlFPejhWNDdfVXciLCJhdF9oYXNoIjoieHFjTVB2cTdRVzJOUU96OFY0N19VdyIsIm5hbWUiOiJBbm9ueW1vdXMiLCJzY29wZSI6ImFub255bW91cyIsInByb2plY3RfaWQiOiJ3aGVyZS1pcy1zdHVmZi1kN2dnZTB5djk2M2FjZDA1NiIsIm1ldGEiOnsicGxhdGZvcm0iOiJQdWJsaXNoYWJsZUtleSJ9LCJ1c2VyX3R5cGUiOiIiLCJjbGllbnRfdHlwZSI6ImNsaWVudF91c2VyIiwiaXNfc3lzdGVtX2FkbWluIjpmYWxzZX0.LpPJLRvNiKDT9TdGhi5eL0riQdjHd5nTqFItA6RthWH0bblEPDgF9y5cGCSmbNwwL5UqnTnQcV5ZB5TQHLbLOJQbiJJ7ZKvHzj1Ov3hrO9IbALuCtOzTbrwVIST4z5iP9hWq3SLHZRlYS8p8mmT4_qkW-VRqooj7aaLT7vsywypHllqy-UG_oKEV8TPhU6hR03MaOpGkk-EWyBtmlVohbPa53njVYW7yusIz_mGeEc1p_1Ane6kVQgZwW02ms2WAlZIY_ASbIeMvtoAecwM4vmhOw2TZEdDJr5brGGxKv5jem1ZTj2vP6woUGjPx2CTTyYpGgbnZkFEUUPil0929pw';

  static String get debugInfo {
    return 'TCBConfig(envId: $envId, region: $region)';
  }
}

enum CloudBaseInitState {
  uninitialized,
  initializing,
  initialized,
  error,
}

class CloudBaseState {
  final CloudBaseInitState state;
  final String? errorMessage;

  const CloudBaseState({
    required this.state,
    this.errorMessage,
  });

  bool get isUninitialized => state == CloudBaseInitState.uninitialized;
  bool get isInitializing => state == CloudBaseInitState.initializing;
  bool get isInitialized => state == CloudBaseInitState.initialized;
  bool get isError => state == CloudBaseInitState.error;

  @override
  String toString() {
    return 'CloudBaseState(state: $state, errorMessage: $errorMessage)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CloudBaseState &&
        other.state == state &&
        other.errorMessage == errorMessage;
  }

  @override
  int get hashCode => Object.hash(state, errorMessage);
}

class CloudBaseService {
  static final CloudBaseService _instance = CloudBaseService._internal();

  factory CloudBaseService() => _instance;

  CloudBaseApp? _app;
  CloudBaseAuth? _auth;
  CloudBaseInitState _initState = CloudBaseInitState.uninitialized;
  String? _lastError;

  CloudBaseService._internal();

  CloudBaseApp get app {
    if (_app == null) {
      throw StateError('CloudBase 未初始化。请先调用 initialize() 方法。');
    }
    return _app!;
  }

  CloudBaseAuth get auth {
    if (_auth == null) {
      throw StateError('CloudBase 未初始化。请先调用 initialize() 方法。');
    }
    return _auth!;
  }

  bool get isInitialized => _initState == CloudBaseInitState.initialized;

  CloudBaseInitState get initState => _initState;

  String? get lastError => _lastError;

  CloudBaseState get currentState {
    return CloudBaseState(
      state: _initState,
      errorMessage: _lastError,
    );
  }

  Future<void> initialize({
    required String envId,
    String region = 'ap-shanghai',
    required String accessKey,
  }) async {
    if (_initState == CloudBaseInitState.initializing) {
      debugPrint('[CloudBase] 正在初始化中，请勿重复调用');
      return;
    }

    if (_initState == CloudBaseInitState.initialized) {
      debugPrint('[CloudBase] 已初始化，跳过重复初始化');
      return;
    }

    _initState = CloudBaseInitState.initializing;
    _lastError = null;

    debugPrint('[CloudBase] 开始初始化...');
    debugPrint('[CloudBase] 环境ID: $envId');
    debugPrint('[CloudBase] 地域: $region');

    try {
      _app = await CloudBase.init(
        env: envId,
        region: region,
        accessKey: accessKey,
        authConfig: const AuthConfig(
          detectSessionInUrl: true,
        ),
      );

      _auth = _app!.auth();

      _initState = CloudBaseInitState.initialized;

      debugPrint('[CloudBase] 初始化成功！');
      debugPrint('[CloudBase] App实例: $_app');
      debugPrint('[CloudBase] Auth实例: $_auth');
    } catch (e, stackTrace) {
      _initState = CloudBaseInitState.error;
      _lastError = e.toString();

      debugPrint('[CloudBase] 初始化失败！');
      debugPrint('[CloudBase] 错误信息: $e');
      debugPrint('[CloudBase] 堆栈跟踪: $stackTrace');

      rethrow;
    }
  }

  Future<void> dispose() async {
    debugPrint('[CloudBase] 开始销毁实例...');

    _app = null;
    _auth = null;
    _initState = CloudBaseInitState.uninitialized;
    _lastError = null;

    debugPrint('[CloudBase] 实例已销毁');
  }

  void resetForTesting() {
    _app = null;
    _auth = null;
    _initState = CloudBaseInitState.uninitialized;
    _lastError = null;
  }

  @override
  String toString() {
    return 'CloudBaseService(initState: $_initState, hasApp: ${_app != null}, hasAuth: ${_auth != null})';
  }
}
