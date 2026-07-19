import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'config/api_config.dart';
import 'models/principal.dart';
import 'providers/auth_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/admin/admin_shell.dart';
import 'screens/auth/login_screen.dart';
import 'screens/customer/customer_shell.dart';
import 'screens/shop/shop_shell.dart';
import 'screens/splash_screen.dart';
import 'services/api_client.dart';
import 'theme/app_theme.dart';

class StorePassApp extends StatefulWidget {
  const StorePassApp({super.key});

  @override
  State<StorePassApp> createState() => _StorePassAppState();
}

class _StorePassAppState extends State<StorePassApp> {
  late final ApiConfig _apiConfig;
  late final ApiClient _apiClient;
  late final AuthProvider _authProvider;
  late final ThemeProvider _themeProvider;
  late final Future<void> _bootstrap;

  @override
  void initState() {
    super.initState();
    _apiConfig = ApiConfig();
    _apiClient = ApiClient(_apiConfig);
    _authProvider = AuthProvider(_apiClient);
    _themeProvider = ThemeProvider();
    _bootstrap = _init();
  }

  Future<void> _init() async {
    await _apiConfig.load();
    await _apiClient.init();
    await _themeProvider.load();
    await _authProvider.restore();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _apiConfig),
        ChangeNotifierProvider.value(value: _authProvider),
        ChangeNotifierProvider.value(value: _themeProvider),
        Provider.value(value: _apiClient),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, theme, _) => MaterialApp(
          title: 'StorePass',
          debugShowCheckedModeBanner: false,
          themeMode: theme.mode,
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          home: FutureBuilder<void>(
            future: _bootstrap,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const SplashScreen();
              }
              return const _AuthGate();
            },
          ),
        ),
      ),
    );
  }
}

class _AuthGate extends StatelessWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    switch (auth.status) {
      case AuthStatus.unknown:
        return const SplashScreen();
      case AuthStatus.signedOut:
        return const LoginScreen();
      case AuthStatus.signedIn:
        return switch (auth.principal?.role) {
          Role.admin => const AdminShell(),
          Role.shop => const ShopShell(),
          _ => const CustomerShell(),
        };
    }
  }
}
