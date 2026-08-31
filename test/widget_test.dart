import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nammalvar_iyerkai_angadi/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: NammalvarApp(),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Admin Master Dashboard'), findsOneWidget);
  });
}
