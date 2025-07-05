// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:markora/main.dart';

void main() {
  testWidgets('Markora app starts correctly', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const ProviderScope(child: MarkoraApp()));

    // Verify that the app starts without errors
    await tester.pumpAndSettle();
    
    // Check for main UI elements
    expect(find.byType(Scaffold), findsAtLeastNWidgets(1));
  });
}
