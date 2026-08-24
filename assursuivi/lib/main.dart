import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'services/local_database_service.dart';
import 'services/local_auth_service.dart';
import 'providers/subscription_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/theme_provider.dart';
import 'utils/app_theme.dart';
import 'screens/dashboard_screen.dart';
import 'screens/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('fr_FR', null);

  // 1. Initialisation des services
  final localDb = LocalDatabaseService();
  final localAuth = LocalAuthService();

  final subscriptionProvider = SubscriptionProvider(dbService: localDb);
  final authProvider = AuthProvider(authService: localAuth);
  final themeProvider = ThemeProvider();

  await subscriptionProvider.loadData();
  await authProvider.init();
  await themeProvider.init();

  runApp(AssurSuiviApp(
    subscriptionProvider: subscriptionProvider,
    authProvider: authProvider,
    themeProvider: themeProvider,
  ));
}

class AssurSuiviApp extends StatelessWidget {
  final SubscriptionProvider subscriptionProvider;
  final AuthProvider authProvider;
  final ThemeProvider themeProvider;

  const AssurSuiviApp({
    super.key,
    required this.subscriptionProvider,
    required this.authProvider,
    required this.themeProvider,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: themeProvider,
      builder: (context, _) {
        return MaterialApp(
          title: 'AssurSuivi',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeProvider.themeMode,
          locale: const Locale('fr', 'FR'),
          supportedLocales: const [
            Locale('fr', 'FR'),
            Locale('fr', ''),
            Locale('en', 'US'),
            Locale('en', ''),
          ],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: AuthGate(
            authProvider: authProvider,
            subscriptionProvider: subscriptionProvider,
            themeProvider: themeProvider,
          ),
        );
      },
    );
  }
}

class AuthGate extends StatelessWidget {
  final AuthProvider authProvider;
  final SubscriptionProvider subscriptionProvider;
  final ThemeProvider themeProvider;

  const AuthGate({
    super.key,
    required this.authProvider,
    required this.subscriptionProvider,
    required this.themeProvider,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: authProvider,
      builder: (context, _) {
        if (authProvider.isLoading) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (authProvider.isAuthenticated) {
          return DashboardScreen(
            provider: subscriptionProvider,
            authProvider: authProvider,
            themeProvider: themeProvider,
          );
        }

        return LoginScreen(authProvider: authProvider);
      },
    );
  }
}
