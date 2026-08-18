import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vitalert/main.dart';

void main() {
  testWidgets('Vitalert full navigation smoke test', (WidgetTester tester) async {
    // Set a realistic mobile surface size for testing
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    // Build our app and trigger a frame.
    await tester.pumpWidget(const VitalertApp());
    await tester.pump(const Duration(milliseconds: 200));

    // Verify Floor Overview is displayed
    expect(find.text('Floor Overview'), findsOneWidget);
    expect(find.text('Pedro Garcia'), findsWidgets);
    expect(find.text('ACTIVE PATIENTS'), findsOneWidget);

    // Tap on Pedro Garcia patient card to open vitals
    await tester.tap(find.text('Pedro Garcia').first);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));

    // Verify Patient Vitals screen is loaded
    expect(find.text('Critical — Heart Rate'), findsOneWidget);
    expect(find.text('ACKNOWLEDGE'), findsOneWidget);
    expect(find.text('HEART RATE'), findsWidgets);
    expect(find.text('BLOOD OXYGEN'), findsOneWidget);

    // Tap ACKNOWLEDGE
    await tester.tap(find.text('ACKNOWLEDGE'));
    await tester.pump(const Duration(milliseconds: 300));

    // Verify acknowledgment state
    expect(find.textContaining('Alert acknowledged by Rosa M.'), findsOneWidget);

    // Tap Back button
    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));

    // Back to Dashboard
    expect(find.text('Floor Overview'), findsOneWidget);

    // Tap on Alerts tab in bottom nav
    await tester.tap(find.byIcon(Icons.notifications_outlined));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Alerts'), findsWidgets);
    expect(find.text('Today, Oct 24'), findsOneWidget);

    // Tap on Log tab in bottom nav
    await tester.tap(find.byIcon(Icons.assignment_outlined));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Hourly Readings'), findsOneWidget);
    expect(find.text('Alert Events'), findsOneWidget);
  });
}
