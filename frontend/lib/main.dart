import 'package:flutter/material.dart';
import 'package:resellio/app/config/app_router.dart';
import 'package:resellio/app/config/app_theme.dart';

void main() {
  // WidgetsFlutterBinding.ensureInitialized(); // Needed for async setup before runApp

  runApp(const ResellioApp());
}

class ResellioApp extends StatelessWidget {
  const ResellioApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Resellio',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      routerConfig: AppRouter.router,
      debugShowCheckedModeBanner: false,
    );
  }
}