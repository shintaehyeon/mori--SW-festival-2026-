import 'package:carebridge/main.dart';
import 'package:carebridge/hospitals.dart';
import 'package:carebridge/localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'location_recovery_test.dart' show DirectoryApi;

class EntryApi extends DirectoryApi {
  int profileRequests = 0;
  @override
  Future<void> restore() async {}
  @override
  Future<dynamic> request(
    String path, {
    String method = 'GET',
    Object? body,
  }) async {
    if (path == '/api/auth/me') throw Exception('Signed out');
    if (path == '/api/health') return {'aiConfigured': false};
    if (path == '/api/emergency-profile') {
      profileRequests++;
      return {};
    }
    if (path == '/api/cards' || path == '/api/journals') return [];
    if (path == '/api/profile') {
      return {
        'allergies': {'status': 'unknown', 'detail': ''},
        'medications': {'status': 'unknown', 'detail': ''},
      };
    }
    return super.request(path, method: method, body: body);
  }
}

void main() {
  setUp(() {
    MoriLanguage.current.value = 'en';
    MoriLanguage.catalog = {};
  });
  for (final registered in [true, false]) {
    testWidgets(
      registered
          ? 'new account returns to emergency and clinic entry'
          : 'existing sign in resumes selected visit',
      (tester) async {
        final api = EntryApi();
        await tester.pumpWidget(MaterialApp(home: Workspace(api: api)));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Find a clinic'));
        await tester.pumpAndSettle();
        tester.widget<Hospitals>(find.byType(Hospitals)).onPrepare!({
          'id': 'fixture',
          'name': 'Fixture clinic',
          'address': 'Pohang',
        });
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.text('Sign in'));
        await tester.tap(find.text('Sign in'));
        await tester.pumpAndSettle();
        final auth = tester.widget<Auth>(find.byType(Auth));
        if (registered) {
          auth.onRegistered!({'id': 'fixture-user', 'isGuest': false});
        } else {
          auth.onLogin({'id': 'fixture-user', 'isGuest': false});
        }
        await tester.pumpAndSettle();
        if (registered) {
          expect(find.text('Find a clinic'), findsOneWidget);
          expect(find.text('EMERGENCY'), findsOneWidget);
          expect(find.byType(VisitCards), findsNothing);
        } else {
          expect(find.byType(VisitCards), findsOneWidget);
          expect(find.text('Fixture clinic'), findsOneWidget);
        }
        expect(api.profileRequests, 0);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
