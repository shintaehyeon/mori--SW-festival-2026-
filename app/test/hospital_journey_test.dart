import 'package:carebridge/hospitals.dart';
import 'package:carebridge/localization.dart';
import 'package:carebridge/google_auth_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'location_recovery_test.dart' show DirectoryApi;

void main() {
  test(
    'Korean hospital names and addresses ignore spacing in any UI language',
    () {
      MoriLanguage.current.value = 'fr';
      final hospital = {
        'name': '양덕이비인후과의원',
        'address': '경상북도 포항시 북구 천마로 74',
        'departments': <Map>[],
      };
      for (final query in [
        '양덕',
        '양덕이비인후과',
        '양덕 이비인후과',
        '천마로74',
        'yang duk',
        'Yang Duk',
        'yangduk',
        'yang deok',
        'yang-deok',
        'Yangdeok',
      ]) {
        expect(hospitalMatchesQuery(hospital, query), isTrue);
      }
      expect(hospitalMatchesQuery(hospital, '없는병원'), isFalse);
      expect(
        hospitalMatchesQuery({
          'name': '강이비인후과의원',
          'address': '',
          'departments': [],
        }, 'yang duk'),
        isFalse,
      );
      MoriLanguage.current.value = 'en';
    },
  );

  testWidgets(
    'clinic CTA works without expansion and community entry is hidden',
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
      expect(find.byType(TextField).hitTestable(), findsOneWidget);
      await tester.enterText(find.byType(TextField), '없는병원');
      await tester.pump();
      expect(find.text('Prepare for this visit'), findsNothing);
      await tester.enterText(find.byType(TextField), '강 이비인후과');
      await tester.pump();
      expect(find.text('Prepare for this visit'), findsOneWidget);

      final listAction = find.text('View clinic list');
      expect(listAction.hitTestable(), findsOneWidget);
      await tester.tap(listAction);
      await tester.pumpAndSettle();
      expect(
        find.textContaining('results · nearest').hitTestable(),
        findsOneWidget,
      );
      final cta = find.text('Prepare for this visit');
      await tester.ensureVisible(cta);
      await tester.tap(cta);
      expect(selected?['name'], '강이비인후과의원');
      expect(find.text('Naver Map'), findsNothing);
      expect(find.text('Kakao Map'), findsNothing);
      expect(find.textContaining('Registered doctors'), findsOneWidget);
      expect(find.text('Mori visit experiences'), findsNothing);
      expect(signIn, isFalse);
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
