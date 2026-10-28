import 'dart:io';
import 'package:carebridge/visit_pdf.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
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
          'symptoms':
              '가상 예시: 어제부터 목이 불편합니다. Test example: sore throat since yesterday.',
          'onset': '2026-10-28 저녁 / evening',
          'intake': {
            'patientName': '가상 환자 / Test Patient',
            'bodySite': '목 / Throat',
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
    },
  );
}
