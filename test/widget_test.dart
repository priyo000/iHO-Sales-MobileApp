import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sales_tracker_mobile/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const ProviderScope(child: SalesTrackerApp()));

    // Verify that we start at the login page (or whatever initial route is).
    // For now just checking if it builds without crashing.
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
