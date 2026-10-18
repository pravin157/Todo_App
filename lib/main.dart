import 'package:flutter/material.dart';
import 'screens/auth_screen.dart';
import 'screens/home_screen.dart';
import 'services/auth_service.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AuthService.instance.init();
  runApp(const TodoApp());
}

class TodoApp extends StatelessWidget {
  const TodoApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeController = AppThemeController.instance;
    final authService = AuthService.instance;

    return AnimatedBuilder(
      animation: Listenable.merge([themeController, authService]),
      builder: (context, _) {
        return MaterialApp(
          title: 'TaskFlow Pro',
          debugShowCheckedModeBanner: false,
          theme: themeController.getDarkTheme(),
          darkTheme: themeController.getDarkTheme(),
          themeMode: ThemeMode.dark,
          home: !authService.isInitialized
              ? const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                )
              : authService.isAuthenticated
                  ? const HomeScreen()
                  : const AuthScreen(),
        );
      },
    );
  }
}
