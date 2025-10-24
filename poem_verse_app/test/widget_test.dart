// This is a basic test file for the Flutter project.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:poem_verse_app/main.dart';

void main() {
  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const PoemVerseApp());

    // Verify that our app starts up without crashing.
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}