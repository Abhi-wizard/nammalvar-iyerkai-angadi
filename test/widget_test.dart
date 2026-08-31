import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nammalvar_iyerkai_angadi/features/auth/presentation/auth_providers.dart';
import 'package:nammalvar_iyerkai_angadi/features/auth/data/auth_repository.dart';
import 'package:nammalvar_iyerkai_angadi/main.dart';

void main() {
  testWidgets('1. Shows LoginScreen when unauthenticated', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: NammalvarApp(),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('SIGN IN'), findsOneWidget);
    expect(find.text('Nammalvar Iyerkai Angadi'), findsOneWidget);
  });

  testWidgets('2. Shows MainNavigationShell when authenticated as Admin', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentProfileProvider.overrideWith(
            (ref) => AuthNotifier(ref.watch(authRepositoryProvider))
              ..state = AuthRepository.mockProfiles[0],
          ),
        ],
        child: const NammalvarApp(),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Admin Master Dashboard'), findsOneWidget);
  });
}
