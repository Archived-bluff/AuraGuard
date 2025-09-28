import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swipe_app/main.dart';

void main() {
  testWidgets('Dashboard shows 3 buttons', (WidgetTester tester) async {
    // Build the app
    await tester.pumpWidget(DoorbellApp());

    // Verify buttons exist
    expect(find.text('Daily Review'), findsOneWidget);
    expect(find.text('Suspicious Activity Recordings'), findsOneWidget);
    expect(find.text('User Account'), findsOneWidget);
  });
}
