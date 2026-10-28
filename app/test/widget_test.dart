import 'package:carebridge/api.dart';
import 'package:carebridge/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeApi extends Api {
  final calls = <String>[];
  final entries = <Map<String, dynamic>>[];
  Map<String, dynamic> profile = {
    'allergies': {'status': 'unknown', 'detail': ''},
    'medications': {'status': 'unknown', 'detail': ''},
  };
  @override
  Future<dynamic> request(
    String path, {
    String method = 'GET',
    Object? body,
  }) async {
    calls.add('$method $path');
    if (path == '/api/profile') {
      if (method == 'PUT') profile = Map<String, dynamic>.from(body as Map);
      return profile;
    }
    if (path == '/api/journals') {
      if (method == 'POST') {
        entries.add({
          'id': 'test-record',
          ...Map<String, dynamic>.from(body as Map),
        });
      }
      return List.of(entries);
    }
    if (path == '/api/cards') return <dynamic>[];
    throw Exception('Unexpected request $method $path');
  }
}

Widget frame(Widget child) => MaterialApp(
  home: Scaffold(body: SingleChildScrollView(child: child)),
);
void main() {
  testWidgets(
    'unknown and none remain separate and selected health profile is saved',
    (tester) async {
      final api = FakeApi();
      await tester.pumpWidget(frame(Health(api: api, ko: false)));
      await tester.pumpAndSettle();
      expect(find.text('Not sure'), findsNWidgets(2));
      expect(find.text('None'), findsNWidgets(2));
      await tester.tap(find.text('None').first);
      await tester.tap(find.text('Save profile'));
      await tester.pumpAndSettle();
      expect(api.profile['allergies']['status'], 'none');
      expect(api.profile['medications']['status'], 'unknown');
      expect(api.calls, contains('PUT /api/profile'));
      expect(find.text('Profile saved.'), findsOneWidget);
    },
  );
  testWidgets(
    'original card requires consent and AI does not run while unconfigured',
    (tester) async {
      final api = FakeApi();
      await tester.pumpWidget(
        frame(VisitCards(api: api, ko: false, aiReady: false)),
      );
      await tester.pumpAndSettle();
      final button = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Save original card'),
      );
      expect(button.onPressed, isNull);
      expect(api.calls, isNot(contains('POST /api/cards')));
      expect(api.calls.where((c) => c.contains('/translate')), isEmpty);
    },
  );
  testWidgets('daily check-in posts entered values to the API', (tester) async {
    final api = FakeApi();
    await tester.pumpWidget(frame(Health(api: api, ko: false)));
    await tester.pumpAndSettle();
    final notes = find.widgetWithText(TextField, 'Notes');
    await tester.ensureVisible(notes);
    await tester.enterText(notes, 'Fictional test note');
    final save = find.text('Save check-in');
    await tester.ensureVisible(save);
    await tester.tap(save);
    await tester.pumpAndSettle();
    expect(api.entries.single['note'], 'Fictional test note');
    expect(api.entries.single['sleep'], 7);
    expect(find.text('Check-in saved.'), findsOneWidget);
  });
}
