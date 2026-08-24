import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:assursuivi/main.dart';
import 'package:assursuivi/providers/subscription_provider.dart';
import 'package:assursuivi/providers/auth_provider.dart';
import 'package:assursuivi/providers/theme_provider.dart';
import 'package:assursuivi/services/local_database_service.dart';
import 'package:assursuivi/services/local_auth_service.dart';

import 'package:local_auth/local_auth.dart';
import 'package:assursuivi/services/biometric_service.dart';

class MockBiometricService implements BiometricService {
  @override
  Future<bool> isBiometricAvailable() async => false;

  @override
  Future<bool> isBiometricEnabled() async => false;

  @override
  Future<bool> authenticate({String reason = ''}) async => false;

  @override
  Future<List<BiometricType>> getAvailableBiometrics() async => [];

  @override
  Future<void> setBiometricEnabled(bool enabled) async {}
}

void main() {
  testWidgets('AssurSuivi smoke test - démarre sur l\'écran d\'authentification avec ThemeProvider', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final db = LocalDatabaseService();
    final auth = LocalAuthService();

    final subscriptionProvider = SubscriptionProvider(dbService: db);
    final authProvider = AuthProvider(
      authService: auth,
      biometricService: MockBiometricService(),
    );
    final themeProvider = ThemeProvider();

    await subscriptionProvider.loadData();
    await authProvider.init();
    await themeProvider.init();

    await tester.pumpWidget(AssurSuiviApp(
      subscriptionProvider: subscriptionProvider,
      authProvider: authProvider,
      themeProvider: themeProvider,
    ));
    await tester.pump();

    expect(find.text('AssurSuivi'), findsWidgets);
  });
}
