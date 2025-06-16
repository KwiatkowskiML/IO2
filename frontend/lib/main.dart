import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:resellio/app/config/app_router.dart';
import 'package:resellio/app/config/app_theme.dart';
import 'package:resellio/core/network/api_client.dart';
import 'package:resellio/core/repositories/repositories.dart';
import 'package:resellio/core/services/auth_service.dart';
import 'package:resellio/presentation/cart/cubit/cart_cubit.dart';

const String apiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://localhost:8080/api',
);

void main() {
  runApp(
    MultiProvider(
      providers: [
        Provider<ApiClient>(
          create: (_) => ApiClient(apiBaseUrl),
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
        Provider<AdminRepository>(
          create: (context) => ApiAdminRepository(context.read<ApiClient>()),
        ),
        ChangeNotifierProvider(
          create: (context) => AuthService(
            context.read<AuthRepository>(),
            context.read<UserRepository>(),
          ),
        ),
        BlocProvider(
          create: (context) =>
              CartCubit(context.read<CartRepository>())..fetchCart(),
        ),
      ],
      child: const ResellioApp(),
    ),
  );
}

class ResellioApp extends StatefulWidget {
  const ResellioApp({super.key});

  @override
  State<ResellioApp> createState() => _ResellioAppState();
}

class _ResellioAppState extends State<ResellioApp> {
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeAuth();
  }

  Future<void> _initializeAuth() async {
    // Wait for AuthService to potentially load stored token
    await Future.microtask(() {});
    if (mounted) {
      setState(() {
        _isInitialized = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return MaterialApp(
        home: Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
      );
    }

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
