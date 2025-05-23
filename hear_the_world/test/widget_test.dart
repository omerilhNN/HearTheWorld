// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:hear_the_world/main.dart';
import 'package:hear_the_world/screens/welcome_screen.dart';

void main() {
  testWidgets('App launches and shows welcome screen', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(MyApp());

    // Verify that the welcome screen appears
    expect(find.byType(WelcomeScreen), findsOneWidget);
    
    // Verify that the app title appears
    expect(find.text('Hear The World'), findsOneWidget);
    
    // Verify that the Get Started button appears
    expect(find.text('Get Started'), findsOneWidget);
  });
}
