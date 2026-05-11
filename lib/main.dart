import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:where_is_stuff/core/auth/auth_state.dart';
import 'package:where_is_stuff/providers/auth_provider.dart';
import 'package:where_is_stuff/screens/auth/login_screen.dart';
import 'package:where_is_stuff/screens/auth/register_screen.dart';
import 'package:where_is_stuff/screens/auth/forgot_password_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AuthProvider(),
      child: MaterialApp(
        title: '收纳助手',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          useMaterial3: true,
        ),
        home: const AuthWrapper(),
        routes: {
          '/login': (context) => LoginScreen(
            onSignUpTap: () => Navigator.pushNamed(context, '/register'),
            onForgotPasswordTap: () => Navigator.pushNamed(context, '/forgot_password'),
            onAnonymousTap: () async {
              final auth = Provider.of<AuthProvider>(context, listen: false);
              await auth.signInAnonymously();
              if (context.mounted && auth.isLoggedIn) {
                Navigator.pushReplacementNamed(context, '/home');
              }
            },
          ),
          '/register': (context) => RegisterScreen(
            onLoginTap: () => Navigator.pushReplacementNamed(context, '/login'),
            onBackToLogin: () => Navigator.pop(context),
          ),
          '/forgot_password': (context) => const ForgotPasswordScreen(),
          '/home': (context) => const HomeScreen(),
        },
      ),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.initialize();
    if (mounted) {
      setState(() => _isInitialized = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Consumer<AuthProvider>(
      builder: (context, auth, child) {
        if (auth.authState == AuthState.loading || auth.authState == AuthState.initial) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (auth.isLoggedIn) {
          return const HomeScreen();
        }

        return LoginScreen(
          onSignUpTap: () => Navigator.pushNamed(context, '/register'),
          onForgotPasswordTap: () => Navigator.pushNamed(context, '/forgot_password'),
          onAnonymousTap: () async {
            await auth.signInAnonymously();
            if (context.mounted && auth.isLoggedIn) {
              Navigator.pushReplacementNamed(context, '/home');
            }
          },
        );
      },
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('收纳助手'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          Consumer<AuthProvider>(
            builder: (context, auth, child) {
              return PopupMenuButton<String>(
                onSelected: (value) async {
                  if (value == 'logout') {
                    await auth.signOut();
                    if (context.mounted) {
                      Navigator.pushReplacementNamed(context, '/login');
                    }
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    enabled: false,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          auth.currentUser?.nickname ?? '用户',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        Text(
                          auth.currentUser?.email ?? '匿名用户',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        if (auth.currentUser?.isAnonymous == true)
                          const Text(
                            '游客模式',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.orange,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const PopupMenuDivider(),
                  const PopupMenuItem(
                    value: 'logout',
                    child: Row(
                      children: [
                        Icon(Icons.logout, size: 20),
                        SizedBox(width: 8),
                        Text('退出登录'),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_2, size: 80, color: Colors.blue),
            SizedBox(height: 16),
            Text(
              '收纳助手',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              '欢迎使用智能收纳管理应用',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
