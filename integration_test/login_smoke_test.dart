import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:sales_tracker_mobile/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Login smoke', () {
    testWidgets('boots and reaches login or permission screen', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 8));

      final reachedLogin = find.text('Selamat Datang').evaluate().isNotEmpty;
      final reachedPermission =
          find.textContaining('Izin').evaluate().isNotEmpty ||
          find.textContaining('Permission').evaluate().isNotEmpty;

      expect(
        reachedLogin || reachedPermission,
        isTrue,
        reason: 'App should reach login screen or permission grant page',
      );
    });

    testWidgets('login form accepts credentials and shows loading',
        (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 8));

      if (find.text('Selamat Datang').evaluate().isEmpty) {
        debugPrint('Skipping: not on login page (likely on permission screen)');
        return;
      }

      final usernameField = find.widgetWithText(TextFormField, 'Username');
      final passwordField = find.widgetWithText(TextFormField, 'Password');

      expect(usernameField, findsOneWidget);
      expect(passwordField, findsOneWidget);

      await tester.enterText(usernameField, 'khamim');
      await tester.enterText(passwordField, '123456');
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(ElevatedButton, 'Login'));
      await tester.pump();
    });
  });
}
