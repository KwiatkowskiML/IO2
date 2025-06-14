// === frontend/lib/main.dart ===
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:resellio/app/config/app_router.dart';
import 'package:resellio/app/config/app_theme.dart';
import 'package:resellio/core/network/api_client.dart';
import 'package:resellio/core/repositories/auth_repository.dart';
import 'package:resellio/core/repositories/cart_repository.dart';
import 'package:resellio/core/repositories/event_repository.dart';
import 'package:resellio/core/repositories/resale_repository.dart';
import 'package:resellio/core/repositories/ticket_repository.dart';
import 'package:resellio/core/repositories/user_repository.dart';
import 'package:resellio/core/services/auth_service.dart';
import 'package:resellio/core/services/cart_service.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        Provider<ApiClient>(
          create: (_) => ApiClient('http://localhost:8080/api'),
        ),
        Provider<AuthRepository>(
          create: (context) => ApiAuthRepository(context.read<ApiClient>()),
        ),
        Provider<EventRepository>(
          create: (context) => ApiEventRepository(context.read<ApiClient>()),
        ),
        Provider<CartRepository>(
          create: (context) => ApiCartRepository(context.read<ApiClient>()),
        ),
        Provider<TicketRepository>(
          create: (context) => ApiTicketRepository(context.read<ApiClient>()),
        ),
        Provider<ResaleRepository>(
          create: (context) => ApiResaleRepository(context.read<ApiClient>()),
        ),
        Provider<UserRepository>(
          create: (context) => ApiUserRepository(context.read<ApiClient>()),
        ),
        ChangeNotifierProvider(
          create: (context) => AuthService(
            context.read<AuthRepository>(),
          ),
        ),
        ChangeNotifierProvider(
          create: (context) => CartService(context.read<CartRepository>()),
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
    final authService = Provider.of<AuthService>(context);

    return MaterialApp.router(
      title: 'Resellio',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.lightTheme,
      themeMode: ThemeMode.light,
      routerConfig: AppRouter.createRouter(authService),
      debugShowCheckedModeBanner: false,
    );
  }
}
