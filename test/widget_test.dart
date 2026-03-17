import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spino/main.dart';

void main() {
  testWidgets('Spino app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: SpinoApp()));
    expect(find.text('Spino'), findsOneWidget);
  });
}
