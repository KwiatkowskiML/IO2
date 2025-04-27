import 'package:flutter/material.dart';
import 'package:resellio/app/config/app_router.dart';
import 'package:resellio/app/config/app_theme.dart';

void main() {
  runApp(const ResellioApp());
}

class ResellioApp extends StatelessWidget {
  const ResellioApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Resellio',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.lightTheme,
      themeMode: ThemeMode.dark,
      routerConfig: AppRouter.router,
      debugShowCheckedModeBanner: false,
    );
  }
}