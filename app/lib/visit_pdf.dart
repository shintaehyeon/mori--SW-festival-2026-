import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

String reportedKnowledge(dynamic value) => value?['status'] == 'known'
    ? '${value['detail']}'
    : value?['status'] == 'none'
    ? '없음 / None (환자 보고)'
    : '모름 / Unknown';
String intakeMetrics(Map<String, dynamic> card) {
  final i = card['snapshot']['intake'] as Map? ?? {};
  return '통증 / Pain: ${i['painScore'] == null ? '미기록 / Not recorded' : '${i['painScore']}/10 (본인 보고)'}\n체온 / Temperature: ${i['temperatureC'] == null ? '미기록 / Not recorded' : '${i['temperatureC']} °C (본인 측정)'}\n측정 시점 / Measured: ${(i['measuredAt'] ?? '').toString().trim().isEmpty ? '미기록 / Not recorded' : i['measuredAt']}';
}

Iterable<String> reportChunks(String value) sync* {
  final chars = value.runes.toList();
  if (chars.isEmpty) {
    yield '미기록 / Not recorded';
    return;
  }
  for (var i = 0; i < chars.length; i += 260) {
    yield String.fromCharCodes(
      chars.sublist(i, (i + 260).clamp(0, chars.length)),
    );
  }
}

Future<Uint8List> buildVisitPdf(
  Map<String, dynamic> card, {
  ByteData? fontData,
  DateTime? exportedAt,
}) async {
  final font = pw.Font.ttf(
    fontData ?? await rootBundle.load('assets/fonts/NanumGothic-Regular.ttf'),
  );
  final doc = pw.Document(
    title: 'MORI - Patient-reported visit preparation',
    author: 'MORI',
    creator: 'MORI',
  );
  final snapshot = Map<String, dynamic>.from(card['snapshot']);
  final intake = snapshot['intake'] as Map? ?? {};
  final translation = card['translation'] as Map?;
  final reviewed = card['confirmedAt'] != null;
  final originalOnly = translation == null;
  final stamp = (exportedAt ?? DateTime.now()).toLocal().toString();
  final status = originalOnly
      ? '원문만 / Original only'
      : reviewed
      ? '사용자 대조 확인 / User reviewed'
      : 'AI 초안 · 미확인 / Unreviewed AI draft';
  pw.Widget text(String s, {double size = 10}) =>
      pw.Text(s, style: pw.TextStyle(fontSize: size, lineSpacing: 3));
  List<pw.Widget> section(String title, String value) => [
    pw.SizedBox(height: 12),
    pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      color: PdfColors.grey200,
      child: pw.Text(
        title,
        style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
      ),
    ),
    pw.SizedBox(height: 6),
    for (final chunk in reportChunks(value))
      pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 4, left: 4, right: 4),
        child: text(chunk),
      ),
  ];
  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(32),
      maxPages: 50,
      theme: pw.ThemeData.withFont(base: font, bold: font),
      footer: (context) => pw.Padding(
        padding: const pw.EdgeInsets.only(top: 8),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            text(
              '환자 작성 자료 / Patient reported - Not a clinical record',
              size: 8,
            ),
            text('${context.pageNumber} / ${context.pagesCount}', size: 8),
          ],
        ),
      ),
      build: (context) => [
        pw.Text(
          '${card['sample'] == true ? '가상 예시 / TEST SAMPLE - ' : ''}진료 준비표 / VISIT PREPARATION',
          style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 5),
        text('MORI | 환자 작성 증상 요약 · 의료기관 공식 서식 아님', size: 10),
        pw.SizedBox(height: 10),
        pw.Container(
          padding: const pw.EdgeInsets.all(8),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.grey600),
          ),
          child: text(
            '이 문서는 환자가 입력한 정보입니다. 의료진의 진찰·문진·공식 기록을 대체하지 않습니다.\nPatient-reported information, not diagnosis, medical certification, or an official intake form.',
          ),
        ),
        pw.SizedBox(height: 10),
        pw.TableHelper.fromTextArray(
          context: context,
          headers: ['항목 / Field', '기록 / Entry'],
          data: [
            [
              '성명 / Name',
              intake['patientName']?.toString().isNotEmpty == true
                  ? intake['patientName']
                  : '미기록 / Not recorded',
            ],
            ['카드 작성 / Card saved', '${card['createdAt']}'],
            ['PDF 생성 / Exported', stamp],
            ['원문·번역 / Language status', status],
            [
              '불편한 부위 / Body site',
              intake['bodySite']?.toString().isNotEmpty == true
                  ? intake['bodySite']
                  : '미기록 / Not recorded',
            ],
            [
              '통증 / Pain (self-report)',
              intake['painScore'] == null
                  ? '미기록 / Not recorded'
                  : '${intake['painScore']} / 10',
            ],
            [
              '체온 / Temperature (self-measured)',
              intake['temperatureC'] == null
                  ? '미기록 / Not recorded'
                  : '${intake['temperatureC']} °C',
            ],
            [
              '측정 시점 / Measured at',
              intake['measuredAt']?.toString().isNotEmpty == true
                  ? intake['measuredAt']
                  : '미기록 / Not recorded',
            ],
          ],
          headerStyle: pw.TextStyle(
            fontWeight: pw.FontWeight.bold,
            fontSize: 9,
          ),
          cellStyle: const pw.TextStyle(fontSize: 9),
          headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
          cellAlignment: pw.Alignment.centerLeft,
          columnWidths: {0: const pw.FixedColumnWidth(175)},
          cellPadding: const pw.EdgeInsets.all(7),
        ),
        ...section('01  방문 이유 / Chief concern - 원문', snapshot['symptoms']),
        ...section('02  시작 시점·경과 / Onset - 원문', snapshot['onset']),
        ...section(
          '03  알레르기 / Allergies - 환자 보고',
          reportedKnowledge(snapshot['profile']['allergies']),
        ),
        ...section(
          '04  복용약 / Medications - 환자 보고',
          reportedKnowledge(snapshot['profile']['medications']),
        ),
        if (translation != null) ...[
          ...section(
            '05  한국어 번역 / Korean translation ($status)',
            '증상: ${translation['symptomsKo']}\n시작: ${translation['onsetKo']}\n알레르기: ${translation['allergiesKo']}\n복용약: ${translation['medicationsKo']}',
          ),
        ],
        ...section(
          '06  선택한 최근 기록 / Selected daily records',
          (snapshot['journals'] as List).isEmpty
              ? '선택한 기록 없음 / No records selected'
              : '환자가 선택한 기록 / Patient-selected records',
        ),
        for (final j in snapshot['journals']) ...[
          pw.SizedBox(height: 6),
          text(
            '${j['date']} | 컨디션 / Condition: ${j['condition']} | 수면 / Sleep: ${j['sleep']} h',
          ),
          for (final chunk in reportChunks(j['note'])) text(chunk),
          if (translation != null)
            for (final tr in (translation['journalKo'] as List).where(
              (tr) => tr['id'] == j['id'],
            ))
              for (final chunk in reportChunks(tr['textKo']))
                text('번역 / Translation: $chunk'),
        ],
        pw.SizedBox(height: 15),
        text(
          '통증 0 = 통증 없음, 10 = 상상할 수 있는 가장 심한 통증. 체온은 측정법·시점에 영향을 받습니다. 이 수치만으로 응급도나 질환을 판단하지 않습니다.\nPain is self-reported (0-10). No diagnosis or urgency score is generated. Wearable data is not included automatically.',
          size: 8,
        ),
      ],
    ),
  );
  return doc.save();
}

/// Browser-safe chart view; actual PDF generation uses the same saved snapshot.
class ClinicalVisitView extends StatelessWidget {
  final Map<String, dynamic> card;
  const ClinicalVisitView({super.key, required this.card});
  @override
  Widget build(BuildContext context) {
    final s = card['snapshot'],
        i = s['intake'] as Map? ?? {},
        tr = card['translation'];
    final language = tr == null
        ? '원문만 / Original only'
        : card['confirmedAt'] == null
        ? 'AI 초안 · 미확인 / Unreviewed draft'
        : '사용자 대조 확인 / User reviewed';
    Widget section(String label, String value) => Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            color: const Color(0xFFECEFF1),
            padding: const EdgeInsets.all(10),
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: SelectableText(
              value,
              style: const TextStyle(
                fontSize: 16,
                height: 1.5,
                color: Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
    return ColoredBox(
      color: const Color(0xFFE5E7E9),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 820),
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    '진료 준비표 / VISIT PREPARATION',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'MORI · 환자 작성 자료 / Patient reported\n의료기관 공식 서식·진료기록·진단서가 아닙니다.',
                    style: TextStyle(color: Colors.black87),
                  ),
                  const SizedBox(height: 16),
                  Table(
                    border: TableBorder.all(color: Colors.black26),
                    columnWidths: const {
                      0: FlexColumnWidth(1),
                      1: FlexColumnWidth(2),
                    },
                    children: [
                      for (final row in <List<String>>[
                        [
                          '성명 / Name',
                          i['patientName']?.toString().isNotEmpty == true
                              ? i['patientName']
                              : '미기록 / Not recorded',
                        ],
                        [
                          '불편 부위 / Site',
                          i['bodySite']?.toString().isNotEmpty == true
                              ? i['bodySite']
                              : '미기록 / Not recorded',
                        ],
                        [
                          '통증 / Pain',
                          i['painScore'] == null
                              ? '미기록 / Not recorded'
                              : '${i['painScore']} / 10 (본인 보고)',
                        ],
                        [
                          '체온 / Temperature',
                          i['temperatureC'] == null
                              ? '미기록 / Not recorded'
                              : '${i['temperatureC']} °C (본인 측정)',
                        ],
                        [
                          '측정 시점 / Measured',
                          i['measuredAt']?.toString().isNotEmpty == true
                              ? i['measuredAt']
                              : '미기록 / Not recorded',
                        ],
                        ['카드 작성 / Saved', '${card['createdAt']}'],
                        ['번역 / Translation', language],
                      ])
                        TableRow(
                          children: [
                            for (final text in row)
                              Padding(
                                padding: const EdgeInsets.all(10),
                                child: SelectableText(
                                  text,
                                  style: const TextStyle(
                                    color: Colors.black,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                          ],
                        ),
                    ],
                  ),
                  section('방문 이유 / Chief concern - 원문', s['symptoms']),
                  section('시작 시점 / Onset - 원문', s['onset']),
                  section(
                    '알레르기 / Allergies',
                    reportedKnowledge(s['profile']['allergies']),
                  ),
                  section(
                    '복용약 / Medications',
                    reportedKnowledge(s['profile']['medications']),
                  ),
                  if (tr != null)
                    section(
                      '한국어 번역 / Korean ($language)',
                      '${tr['symptomsKo']}\n${tr['onsetKo']}\n${tr['allergiesKo']}\n${tr['medicationsKo']}',
                    ),
                  section(
                    '선택한 일상 기록 / Selected records',
                    (s['journals'] as List).isEmpty
                        ? '선택한 기록 없음 / No records selected'
                        : (s['journals'] as List)
                              .map(
                                (j) =>
                                    '${j['date']} · ${j['condition']} · 수면 ${j['sleep']} h\n${j['note']}',
                              )
                              .join('\n\n'),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    '통증은 0-10 본인 보고입니다. 이 수치만으로 진단·응급도를 판단하지 않습니다.\n오른쪽 위 공유 버튼으로 PDF를 저장할 수 있습니다.',
                    style: TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
