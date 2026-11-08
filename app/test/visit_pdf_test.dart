import 'package:carebridge/visit_body_map.dart';
import 'dart:io';
import 'package:carebridge/visit_pdf.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'compact French card preserves both languages and omits empty extras',
    () async {
      final card = <String, dynamic>{
        'sample': true,
        'createdAt': '2026-11-08',
        'confirmedAt': '2026-11-08',
        'translation': {
          'symptomsKo': '이틀 전부터 목이 아픕니다.',
          'onsetKo': '이틀 전',
          'allergiesKo': '모름',
          'medicationsKo': '없음',
          'journalKo': [],
        },
        'snapshot': {
          'symptoms': 'EXEMPLE FICTIF : J’ai mal à la gorge depuis deux jours.',
          'onset': 'Depuis deux jours.',
          'destination': {'name': '가상 테스트 병원', 'address': '가상 주소'},
          'profile': {
            'allergies': {'status': 'unknown'},
            'medications': {'status': 'none'},
          },
          'journals': [],
        },
      };
      final sections = visitSections(card);
      expect(sections.first.body, '이틀 전부터 목이 아픕니다.');
      expect(sections.any((s) => s.body.contains('EXEMPLE FICTIF')), isTrue);
      expect(
        sections.any((s) => s.title.contains('Optional details')),
        isFalse,
      );
      expect(visitAttachments(card), isEmpty);
      await File(
        '/tmp/mori-compact-fr.pdf',
      ).writeAsBytes(await buildVisitPdf(card));
      card['confirmedAt'] = null;
      expect(visitSections(card).first.body, contains('EXEMPLE FICTIF'));
      expect(
        visitSections(card).any((s) => s.body.contains('Unreviewed AI draft')),
        isTrue,
      );
      await File(
        '/tmp/mori-compact-unreviewed.pdf',
      ).writeAsBytes(await buildVisitPdf(card));
      card['translation'] = null;
      await File(
        '/tmp/mori-compact-original.pdf',
      ).writeAsBytes(await buildVisitPdf(card));
    },
  );
  test('body diagram marks only explicit supported selections', () {
    expect(visitBodySvg(null), isNot(contains('#f7c1ad')));
    expect(visitBodySvg('unknown'), isNot(contains('#f7c1ad')));
    expect(visitBodySvg('neck'), contains('cx="50" cy="40"'));
    expect(visitBodySvg('back'), contains('cx="150" cy="82"'));
  });
  test('overview preserves unknown and uses translation only after review', () {
    final card = <String, dynamic>{
      'confirmedAt': null,
      'translation': {'symptomsKo': '번역'},
      'snapshot': {
        'symptoms': 'original',
        'onset': 'unknown',
        'profile': {
          'allergies': {'status': 'unknown'},
          'medications': {'status': 'none'},
        },
      },
    };
    expect(visitOverview(card).values.first, 'original');
    expect(visitOverview(card).values, contains('모름 / Unknown'));
    card['confirmedAt'] = '2026-11-04';
    expect(visitOverview(card).values.first, '번역');
    expect(visitExcerpt('가' * 400, 340), contains('see appendix'));
  });
  test(
    'visit PDF retains missing-vs-zero quantities and exports Korean fixture',
    () async {
      final card = <String, dynamic>{
        'sample': true,
        'id': 'test-only',
        'createdAt': '2026-10-29T09:00:00+09:00',
        'confirmedAt': null,
        'translation': null,
        'snapshot': {
          'destination': {
            'name': '가상 테스트 병원 / Test clinic',
            'address': '가상 주소 / Fictional address',
          },
          'symptoms':
              '가상 예시: 어제부터 목이 불편합니다. Test example: sore throat since yesterday.',
          'onset': '2026-10-28 저녁 / evening',
          'intake': {
            'patientName': '가상 환자 / Test Patient',
            'bodySite': '목 / Throat',
            'bodyRegion': 'neck',
            'painScore': 4,
            'temperatureC': 37.2,
            'measuredAt': '2026-10-29 09:00 KST, 귀 체온계 / ear thermometer',
          },
          'profile': {
            'allergies': {'status': 'unknown', 'detail': ''},
            'medications': {'status': 'none', 'detail': ''},
          },
          'journals': [
            {
              'id': 'day1',
              'date': '2026-10-28',
              'condition': 'low',
              'sleep': 6,
              'note': '가상 예시: 비타민 C 500mg 복용 / Test example: Vitamin C 500mg.',
            },
          ],
        },
      };
      final bytes = await buildVisitPdf(
        card,
        exportedAt: DateTime.parse('2026-10-29T01:00:00Z'),
      );
      expect(String.fromCharCodes(bytes.take(4)), '%PDF');
      expect(intakeMetrics(card), contains('4/10'));
      final out = File('../docs/examples/MORI_visit_sample.pdf');
      await out.parent.create(recursive: true);
      await out.writeAsBytes(bytes);
      final missing = {
        'snapshot': {
          'intake': {'painScore': 0, 'temperatureC': null, 'measuredAt': ''},
        },
      };
      expect(intakeMetrics(missing), contains('0/10'));
      expect(intakeMetrics(missing), contains('Not recorded'));
    },
  );
  test(
    'long multilingual notes paginate without truncating to a single page',
    () async {
      final card = <String, dynamic>{
        'id': 'test-long',
        'createdAt': '2026-10-29',
        'confirmedAt': null,
        'translation': null,
        'snapshot': {
          'symptoms': '가상 증상 '.padRight(2000, '가'),
          'onset': 'Yesterday',
          'profile': {
            'allergies': {'status': 'unknown'},
            'medications': {'status': 'unknown'},
          },
          'journals': List.generate(
            7,
            (i) => {
              'id': '$i',
              'date': '2026-10-28',
              'condition': 'okay',
              'sleep': 7,
              'note': '테스트 '.padRight(1000, '나'),
            },
          ),
        },
      };
      final bytes = await buildVisitPdf(card);
      expect(bytes.length, greaterThan(10000));
      await File('/tmp/mori-long-overview.pdf').writeAsBytes(bytes);
    },
  );
}
