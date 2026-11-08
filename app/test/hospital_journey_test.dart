import 'package:carebridge/hospitals.dart';
import 'package:carebridge/localization.dart';
import 'package:carebridge/google_auth_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'location_recovery_test.dart' show DirectoryApi;

void main() {
  testWidgets(
    'clinic CTA works without expansion and guest reviews lead to sign in',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      MoriLanguage.current.value = 'en';
      Map<String, dynamic>? selected;
      bool signIn = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: Hospitals(
                api: DirectoryApi(),
                ko: false,
                canReadExperiences: false,
                onPrepare: (h) => selected = h,
                onSignIn: () => signIn = true,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final cta = find.text('Prepare for this visit');
      await tester.ensureVisible(cta);
      await tester.tap(cta);
      expect(selected?['name'], '강이비인후과의원');
      expect(find.text('Naver Map'), findsNothing);
      expect(find.text('Kakao Map'), findsNothing);
      expect(find.textContaining('Registered doctors'), findsOneWidget);
      final reviews = find.text('Mori visit experiences');
      await tester.ensureVisible(reviews);
      await tester.tap(reviews);
      await tester.pumpAndSettle();
      expect(
        find.text('FORMAT EXAMPLE · Not an actual review'),
        findsOneWidget,
      );
      await tester.tap(find.text('Sign in'));
      await tester.pumpAndSettle();
      expect(signIn, isTrue);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('unconfigured Google does not pretend to offer working login', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: GoogleAuthButton(
          api: DirectoryApi(),
          onLogin: (_) => fail('No login expected'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Continue with Google'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
