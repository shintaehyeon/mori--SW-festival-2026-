import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:carebridge/visit_sheet_page.dart';
import 'package:carebridge/localization.dart';
import 'package:carebridge/api.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  setUp(() {
    MoriLanguage.catalog = jsonDecode(
      File('assets/i18n/catalog.json').readAsStringSync(),
    );
    MoriLanguage.current.value = 'fr';
  });
  tearDown(() => MoriLanguage.current.value = 'en');
  testWidgets(
    'failed export retains sheet and permits retry without duplicate taps',
    (tester) async {
      final first = Completer<bool>();
      var calls = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: VisitSheetPage(
            bytes: Uint8List.fromList([1, 2]),
            card: {
              'createdAt': '2026-11-08',
              'snapshot': {
                'symptoms': 'EXEMPLE FICTIF',
                'onset': 'Hier',
                'profile': {
                  'allergies': {'status': 'unknown'},
                  'medications': {'status': 'none'},
                },
                'journals': [],
              },
            },
            exportPdf: (_) {
              calls++;
              return calls == 1 ? first.future : Future.value(true);
            },
          ),
        ),
      );
      await tester.tap(find.byType(FilledButton));
      await tester.pump();
      expect(
        tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNull,
      );
      first.completeError(Exception('platform failure'));
      await tester.pumpAndSettle();
      expect(
        find.text(
          tr(
            'PDF export was not completed. Try again; you can still show this screen.',
          ),
        ),
        findsOneWidget,
      );
      expect(find.textContaining('EXEMPLE FICTIF'), findsWidgets);
      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();
      expect(calls, 2);
      expect(
        find.text(
          tr(
            'PDF export requested. Check your downloads or complete the share dialog.',
          ),
        ),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );
  test(
    'network failure offers localized recovery and never retries a POST automatically',
    () async {
      var calls = 0;
      final api = Api(
        client: MockClient((_) async {
          calls++;
          throw http.ClientException('offline');
        }),
      );
      await expectLater(
        api.request('/api/cards', method: 'POST', body: {}),
        throwsA(predicate((e) => e.toString().contains('Connexion perdue'))),
      );
      expect(calls, 1);
    },
  );
  test(
    'timeout advises checking saved cards to avoid duplicate creation',
    () async {
      final api = Api(
        client: MockClient((_) => Completer<http.Response>().future),
        requestTimeout: const Duration(milliseconds: 1),
      );
      await expectLater(
        api.request('/api/cards', method: 'POST'),
        throwsA(predicate((e) => e.toString().contains('fiches enregistrées'))),
      );
    },
  );
}
