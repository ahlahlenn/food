import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nourish/main.dart';

void main() {
  testWidgets('Nourish app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: NourishApp()));
    await tester.pumpAndSettle();
  });
}
