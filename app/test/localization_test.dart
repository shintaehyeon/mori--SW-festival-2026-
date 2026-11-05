import 'dart:convert';
import 'dart:io';
import 'package:carebridge/localization.dart';
import 'package:carebridge/hospital_name.dart';
import 'package:carebridge/hospitals.dart';
import 'package:carebridge/main.dart';
import 'package:carebridge/api.dart';
import 'package:carebridge/visit_pdf.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

class EmptyApi extends Api {
  @override
  Future<dynamic> request(
    String path, {
    String method = 'GET',
    Object? body,
  }) async => <dynamic>[];
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    MoriLanguage.catalog = jsonDecode(
      File('assets/i18n/catalog.json').readAsStringSync(),
    );
    MoriLanguage.current.value = 'en';
  });
  tearDown(() => MoriLanguage.current.value = 'en');
  test('every authored UI message is present in all six language resources', () {
    for (final row in MoriLanguage.catalog.entries) {
      expect(
        (row.value as Map).keys.toSet(),
        MoriLanguage.names.keys.toSet(),
        reason: row.key,
      );
      for (final code in MoriLanguage.names.keys) {
        expect(
          (row.value[code] as String).trim(),
          isNotEmpty,
          reason: '$code ${row.key}',
        );
      }
    }
    // Existing literal bilingual calls cannot silently fall back in new locales.
    final pattern = RegExp(
      r"\bt\(\s*'((?:\\.|[^'\\])*)'\s*,\s*'((?:\\.|[^'\\])*)'\s*,?\s*\)",
    );
    for (final file
        in Directory('lib')
            .listSync(recursive: true)
            .whereType<File>()
            .where((f) => f.path.endsWith('.dart'))) {
      for (final match in pattern.allMatches(file.readAsStringSync())) {
        final key = match[1]!.replaceAll(r'\n', '\n').replaceAll(r"\'", "'");
        if (key.contains(r'$')) continue; // dynamic labels tested separately
        expect(
          MoriLanguage.catalog.containsKey(key),
          isTrue,
          reason: '${file.path}: $key',
        );
      }
    }
  });
  test(
    'official hospital names remain exact, non-Latin department search works',
    () {
      final h = {
        'name': '군산병원',
        'address': '전북 군산시',
        'type': '병원',
        'departments': [
          {'name': '내과'},
        ],
      };
      expect(romanizedHospitalName('군산병원'), 'Gunsan Byeongwon');
      for (final q in [
        '군산',
        'Gunsan',
        '内科',
        'Nội khoa',
        'Médecine interne',
        'Internal medicine',
      ]) {
        expect(hospitalMatchesQuery(h, q), isTrue, reason: q);
      }
      for (final code in MoriLanguage.names.keys) {
        MoriLanguage.current.value = code;
        expect(localizedHospitalReading('군산병원'), contains('Gunsan'));
      }
      expect(h['name'], '군산병원');
    },
  );
  test(
    'dynamic labels and unknown state translate without changing entered text',
    () {
      for (final code in ['zh', 'ja', 'vi', 'fr']) {
        MoriLanguage.current.value = code;
        expect(tr('Contact name 2'), contains('2'));
        expect(tr('Contact name 2'), isNot(contains('Contact name')));
        expect(
          tr('Your self-reported condition: unknown'),
          isNot(contains('unknown')),
        );
      }
    },
  );
  for (final code in MoriLanguage.names.keys) {
    testWidgets(
      '$code visit form fits 390px and preserves entered Unicode across rebuild',
      (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        MoriLanguage.current.value = code;
        final api = EmptyApi();
        Widget app() => MaterialApp(
          locale: Locale(MoriLanguage.current.value),
          supportedLocales: MoriLanguage.names.keys.map((e) => Locale(e)),
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          home: Scaffold(
            body: SingleChildScrollView(
              child: VisitCards(api: api, ko: code == 'ko', aiReady: false),
            ),
          ),
        );
        await tester.pumpWidget(app());
        await tester.pumpAndSettle();
        expect(
          find.text(tr('What would you like to tell the clinician?')),
          findsOneWidget,
        );
        final input = find.widgetWithText(
          TextField,
          tr('What would you like to tell the clinician?'),
        );
        const original = '가상 TEST 咳嗽 のどが痛い Đau họng fièvre 37.2';
        await tester.enterText(input, original);
        MoriLanguage.current.value = code == 'en' ? 'fr' : 'en';
        await tester.pumpWidget(app());
        await tester.pumpAndSettle();
        expect(find.text(original), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }
  test(
    'six-language original produces a PDF without mutating the snapshot',
    () async {
      const original =
          '가상 예시 / TEST ONLY / 咳嗽和发烧 / のどが痛い / Đau họng, sốt / fièvre à 37.2 °C';
      final card = <String, dynamic>{
        'sample': true,
        'createdAt': '2026-11-06',
        'confirmedAt': null,
        'translation': null,
        'snapshot': {
          'symptoms': original,
          'onset': '不清楚 / 不明 / Không rõ / Inconnu',
          'intake': {'painScore': 0, 'temperatureC': 37.2},
          'profile': {
            'allergies': {'status': 'unknown'},
            'medications': {'status': 'none'},
          },
          'journals': [],
        },
      };
      final before = jsonEncode(card);
      final pdf = await buildVisitPdf(card, exportedAt: DateTime(2026, 11, 6));
      expect(String.fromCharCodes(pdf.take(4)), '%PDF');
      expect(jsonEncode(card), before);
      File('/tmp/mori-six-language.pdf').writeAsBytesSync(pdf);
    },
  );
}
