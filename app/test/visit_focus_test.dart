import 'package:carebridge/api.dart';
import 'package:carebridge/main.dart';
import 'package:carebridge/localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class VisitApi extends Api {
  int translations = 0;
  final bool confirmed;
  VisitApi({this.confirmed = false});
  Map<String, dynamic> get profile => {
    'allergies': {'status': 'known', 'detail': 'Penicillin'},
    'medications': {'status': 'unknown', 'detail': ''},
  };
  Map<String, dynamic> get card => {
    'id': 'fictional',
    'createdAt': '2026-11-07T10:00:00Z',
    'mode': confirmed ? 'ai' : 'original',
    'confirmedAt': confirmed ? '2026-11-07T11:00:00Z' : null,
    'snapshot': {
      'symptoms': 'Fictional pain',
      'onset': 'Yesterday',
      'profile': profile,
      'journals': [],
    },
    'translation': confirmed
        ? {
            'symptomsKo': '가상 통증',
            'onsetKo': '어제',
            'allergiesKo': '페니실린',
            'medicationsKo': '모름',
            'journalKo': [],
          }
        : null,
  };
  @override
  Future<dynamic> request(
    String path, {
    String method = 'GET',
    Object? body,
  }) async {
    if (path == '/api/profile') return profile;
    if (path == '/api/journals') return [];
    if (path == '/api/cards') return [card];
    if (path.endsWith('/translate')) {
      expect(body, {'consent': true});
      translations++;
      throw Exception('Fictional provider failure');
    }
    throw Exception('Unexpected $path');
  }
}

class HistoryVisitApi extends VisitApi {
  @override
  Future<dynamic> request(
    String path, {
    String method = 'GET',
    Object? body,
  }) async {
    if (path == '/api/journals') {
      return [
        {
          'id': 'old',
          'date': '2026-11-07',
          'condition': 'okay',
          'sleep': 7,
          'note': 'OPTIONAL HISTORY FIXTURE',
        },
      ];
    }
    return super.request(path, method: method, body: body);
  }
}

Widget screen(VisitApi api) => MaterialApp(
  home: Scaffold(
    body: SingleChildScrollView(
      child: VisitCards(api: api, ko: false, aiReady: true),
    ),
  ),
);
void main() {
  setUp(() {
    MoriLanguage.current.value = 'en';
    MoriLanguage.catalog = {};
  });
  testWidgets('past records stay collapsed and empty history adds no step', (
    tester,
  ) async {
    await tester.pumpWidget(screen(HistoryVisitApi()));
    await tester.pumpAndSettle();
    expect(find.text('OPTIONAL HISTORY FIXTURE'), findsNothing);
    final attach = find.text('Attach past records (optional)');
    await tester.ensureVisible(attach);
    await tester.tap(attach);
    await tester.pumpAndSettle();
    expect(find.text('OPTIONAL HISTORY FIXTURE'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(screen(VisitApi()));
    await tester.pumpAndSettle();
    expect(find.text('Attach past records (optional)'), findsNothing);
  });
  testWidgets(
    'profile before saving, cancellation sends nothing, failure preserves original',
    (tester) async {
      final api = VisitApi();
      await tester.pumpWidget(screen(api));
      await tester.pumpAndSettle();
      expect(find.text('Allergies: Penicillin'), findsOneWidget);
      expect(find.text('Medication: Unknown'), findsOneWidget);
      await tester.ensureVisible(find.text('Open card'));
      await tester.tap(find.text('Open card'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Translate with AI'));
      await tester.tap(find.text('Translate with AI'));
      await tester.pumpAndSettle();
      expect(find.text('Send this card for translation?'), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(api.translations, 0);
      await tester.tap(find.text('Translate with AI'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Agree and translate'));
      await tester.pumpAndSettle();
      expect(api.translations, 1);
      expect(find.text('Fictional pain'), findsOneWidget);
      expect(find.textContaining('Fictional provider failure'), findsOneWidget);
    },
  );
  testWidgets('reviewed card disables retranslation', (tester) async {
    final api = VisitApi(confirmed: true);
    await tester.pumpWidget(screen(api));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Open card'));
    await tester.tap(find.text('Open card'));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<FilledButton>(
            find.widgetWithText(FilledButton, 'Translate with AI'),
          )
          .onPressed,
      isNull,
    );
    expect(api.translations, 0);
  });
}
