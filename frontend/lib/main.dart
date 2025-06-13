import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:resellio/app/config/app_router.dart';
import 'package:resellio/app/config/app_theme.dart';
import 'package:resellio/core/services/api_service.dart';
import 'package:resellio/core/services/auth_service.dart';
import 'package:resellio/core/services/cart_service.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        Provider(create: (_) => ApiService()),
        ChangeNotifierProvider(
          create: (context) => AuthService(context.read<ApiService>()),
        ),
        ChangeNotifierProvider(
          create: (context) => CartService(context.read<ApiService>()),
        ),
      ],
      child: const ResellioApp(),
    ),
  );
}

class ResellioApp extends StatelessWidget {
  const ResellioApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Listen to AuthService to rebuild the router on auth state changes
    final authService = Provider.of<AuthService>(context);

    return MaterialApp.router(
      title: 'Resellio',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.lightTheme,
      themeMode: ThemeMode.dark,
      routerConfig: AppRouter.createRouter(authService),
      debugShowCheckedModeBanner: false,
    );
  }
}
