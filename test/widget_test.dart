import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jelantah_ku/main.dart';

void main() {
  testWidgets('App renders correctly and settles async initial data', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: JelantahKuApp(),
      ),
    );

    // Settle async timers from mock data source
    await tester.pumpAndSettle();

    expect(find.text('Jelantah-Ku'), findsOneWidget);
  });
}
