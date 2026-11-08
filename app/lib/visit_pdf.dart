import 'visit_body_map.dart';
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

String visitDestination(Map<String, dynamic> card) {
  final d = card['snapshot']['destination'] as Map?;
  return d == null
      ? ''
      : '${d['name']}\n${d['address']}\n방문 준비용 · 예약 아님 / Planned visit, not a booking';
}

/// A visible excerpt only. The appendix retains the complete snapshot.
String visitExcerpt(dynamic value, int limit) {
  final text = (value ?? '').toString().replaceAll(RegExp(r'\s+'), ' ').trim();
  if (text.isEmpty) return '미기록 / Not recorded';
  final chars = text.runes.toList();
  if (chars.length <= limit) return text;
  return '${String.fromCharCodes(chars.take(limit))}… [발췌 / see appendix]';
}

Map<String, String> visitOverview(Map<String, dynamic> card) {
  final s = card['snapshot'];
  // Unreviewed translation remains in the appendix, never replaces the original.
  final tr = card['confirmedAt'] != null ? card['translation'] : null;
  return {
    '방문 이유·변화 / Concern & changes': visitExcerpt(
      tr?['symptomsKo'] ?? s['symptoms'],
      220,
    ),
    '시작 시점 / Onset': visitExcerpt(tr?['onsetKo'] ?? s['onset'], 80),
    '알레르기 / Allergies': visitExcerpt(
      tr?['allergiesKo'] ?? reportedKnowledge(s['profile']['allergies']),
      100,
    ),
    '복용약 / Medications': visitExcerpt(
      tr?['medicationsKo'] ?? reportedKnowledge(s['profile']['medications']),
      100,
    ),
  };
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
  final latin = pw.Font.ttf(
    await rootBundle.load('assets/fonts/NotoSans-Regular.ttf'),
  );
  final cjk = pw.Font.ttf(
    await rootBundle.load('assets/fonts/NotoSansCJK-Regular.ttf'),
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
  const ink = PdfColor.fromInt(0xff243e50);
  const pale = PdfColor.fromInt(0xffeef3f6);
  pw.Widget text(String s, {double size = 10}) =>
      pw.Text(s, style: pw.TextStyle(fontSize: size, lineSpacing: 3));
  List<pw.Widget> section(String title, String value) => [
    pw.SizedBox(height: 8),
    pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      color: pale,
      child: pw.Text(
        title,
        style: pw.TextStyle(
          fontSize: 10,
          fontWeight: pw.FontWeight.bold,
          color: ink,
        ),
      ),
    ),
    pw.SizedBox(height: 4),
    for (final chunk in reportChunks(value))
      pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 4, left: 4, right: 4),
        child: text(chunk),
      ),
  ];
  pw.Widget table(List<String> headers, List<List<String>> rows) =>
      pw.TableHelper.fromTextArray(
        headers: headers,
        data: rows,
        headerStyle: pw.TextStyle(
          fontSize: 8,
          color: ink,
          fontWeight: pw.FontWeight.bold,
        ),
        cellStyle: const pw.TextStyle(fontSize: 8, lineSpacing: 2),
        headerDecoration: const pw.BoxDecoration(color: pale),
        border: pw.TableBorder.all(color: PdfColors.grey400, width: .5),
        cellAlignment: pw.Alignment.centerLeft,
        cellPadding: const pw.EdgeInsets.all(6),
      );
  pw.Widget footer(pw.Context context) => pw.Column(
    children: [
      pw.Divider(color: PdfColors.grey400),
      pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          text('MORI · 환자 작성 진료 준비자료 / Patient-reported', size: 7),
          text('${context.pageNumber} / ${context.pagesCount}', size: 8),
        ],
      ),
    ],
  );
  doc.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(32),
      theme: pw.ThemeData.withFont(
        base: latin,
        bold: latin,
        fontFallback: [font, cjk],
      ),
      build: (context) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          pw.Text(
            'MORI | 진료 준비 요약',
            style: pw.TextStyle(
              fontSize: 21,
              color: ink,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          text(
            'PATIENT VISIT BRIEF${card['sample'] == true ? ' | 가상 예시 / TEST SAMPLE' : ''}',
            size: 10,
          ),
          pw.SizedBox(height: 8),
          text('환자 작성 자료 · 의료기관 공식 기록 아님 / Patient reported', size: 9),
          if (visitDestination(card).isNotEmpty)
            text(visitDestination(card), size: 9),
          text(
            '$status${translation != null && !reviewed ? ' | 첫 장은 원문 / Original shown here' : ''}',
            size: 9,
          ),
          pw.SizedBox(height: 8),
          table(
            ['성명 / Name', '저장 일시 / Saved', '자료 상태 / Source'],
            [
              [
                visitExcerpt(intake['patientName'], 55),
                visitExcerpt(card['createdAt'], 40),
                '환자 입력 / Patient entered',
              ],
            ],
          ),
          pw.SizedBox(height: 5),
          text(
            '불편 부위 상세 / Site detail: ${visitExcerpt(intake['bodySite'], 70)}',
            size: 9,
          ),
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.SizedBox(
                width: 118,
                child: pw.Column(
                  children: [
                    pw.SizedBox(height: 14),
                    text('불편 부위 / Body area', size: 9),
                    pw.SizedBox(height: 8),
                    pw.SvgImage(
                      svg: visitBodySvg(intake['bodyRegion'] as String?),
                      width: 114,
                      height: 114,
                    ),
                    text('앞 / Front     뒤 / Back', size: 8),
                    pw.SizedBox(height: 8),
                    text(
                      visitBodyRegions[intake['bodyRegion']] ??
                          '선택 안 함 / Not selected',
                      size: 9,
                    ),
                    pw.SizedBox(height: 4),
                    text(
                      '환자 선택 · 대략적 위치\nPatient-selected area\n좌우 구분 없음 / No side specified',
                      size: 7,
                    ),
                  ],
                ),
              ),
              pw.SizedBox(width: 12),
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                  children: [
                    for (final entry in visitOverview(card).entries)
                      ...section(entry.key, entry.value),
                  ],
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 12),
          table(
            ['관찰 항목 / Observation', '값 / Value', '근거 / Source'],
            [
              [
                '통증 / Pain',
                intake['painScore'] == null
                    ? '미기록 / Not recorded'
                    : '${intake['painScore']} / 10',
                '본인 보고 / Self-report',
              ],
              [
                '체온 / Temperature',
                intake['temperatureC'] == null
                    ? '미기록 / Not recorded'
                    : '${intake['temperatureC']} °C',
                '직접 입력 / Manual entry',
              ],
            ],
          ),
          pw.SizedBox(height: 4),
          text(
            '측정 시점·방법 / Measured: ${visitExcerpt(intake['measuredAt'], 80)}',
            size: 8,
          ),
          pw.SizedBox(height: 10),
          pw.Container(
            padding: const pw.EdgeInsets.all(8),
            color: pale,
            child: text(
              '자료 확인 / Data context\n미기록 ≠ 이상 없음. 약·알레르기는 환자 보고이며 의료진 확인 전입니다. 혈압·맥박·검사 결과·워치값은 자동으로 포함되지 않습니다.\nMissing does not mean normal. Medicines/allergies are patient-reported; no automatic device or test results.',
              size: 8,
            ),
          ),
          pw.Spacer(),
          text(
            '첫 장은 빠른 확인용입니다. 발췌된 항목, 원문, 번역 및 선택한 일상 기록 전체는 다음 장부터 확인하세요.\nOverview only. Read the appendix for full original, translation and selected records.',
            size: 8,
          ),
          pw.SizedBox(height: 8),
          text(
            '저장 / Saved: ${card['createdAt']} | 내보냄 / Exported: $stamp',
            size: 7,
          ),
          footer(context),
        ],
      ),
    ),
  );
  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(32),
      maxPages: 50,
      theme: pw.ThemeData.withFont(
        base: latin,
        bold: latin,
        fontFallback: [font, cjk],
      ),
      header: (context) => pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 8),
        child: text(
          'MORI · 전체 원문 및 기록 / SOURCE DETAILS · ${visitExcerpt(intake['patientName'], 40)}',
          size: 8,
        ),
      ),
      footer: footer,
      build: (context) => [
        if (visitDestination(card).isNotEmpty) text(visitDestination(card)),
        pw.Text(
          '${card['sample'] == true ? '가상 예시 / TEST SAMPLE - ' : ''}상세 기록 / FULL VISIT DETAILS',
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
            '이 문서는 저장 당시 환자 입력의 사본입니다. 미기록·모름·없음을 구분합니다. 사용자 번역 확인은 의료진 검수를 뜻하지 않습니다.\nSaved patient-reported snapshot. Not recorded, unknown and reported none are distinct. User translation review is not clinical verification.',
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
              '사용자 번역 확인 / User review',
              card['confirmedAt']?.toString() ?? '미확인 / Not reviewed',
            ],
            [
              '그림 선택 부위 / Diagram area',
              visitBodyRegions[intake['bodyRegion']] ?? '선택 안 함 / Not selected',
            ],
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
          cellPadding: const pw.EdgeInsets.all(4),
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
          pw.SizedBox(height: 4),
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
  doc.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(32),
      theme: pw.ThemeData.withFont(
        base: latin,
        bold: latin,
        fontFallback: [font, cjk],
      ),
      build: (context) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          pw.Text('진료 전 보충 메모', style: pw.TextStyle(fontSize: 21, color: ink)),
          text(
            'OPTIONAL PATIENT NOTES · ${card['sample'] == true ? 'TEST SAMPLE' : 'FOR THIS VISIT'}',
            size: 10,
          ),
          pw.SizedBox(height: 10),
          text(
            '성명 / Name: ${visitExcerpt(intake['patientName'], 55)}',
            size: 10,
          ),
          pw.SizedBox(height: 8),
          pw.Container(
            color: pale,
            padding: const pw.EdgeInsets.all(9),
            child: text(
              '아래는 앱에서 수집하지 않은 보충 항목입니다. 필요한 내용만 출력 후 직접 적거나 진료 중 설명하세요. 빈칸은 “없음”이 아닙니다. 이 페이지에 적은 내용은 앱에 저장되지 않습니다.\nNot collected in the app. Complete on paper if relevant. Blank does not mean none. Handwritten notes are not saved back to MORI.',
              size: 9,
            ),
          ),
          ...section(
            '01  이전 건강정보 / Previous health information',
            '기존 질환·수술·입원·관련 검사와 시기 (해당 시)\nConditions, operations, admissions or relevant tests and dates, if applicable.',
          ),
          pw.SizedBox(height: 40),
          pw.Divider(color: PdfColors.grey400),
          ...section(
            '02  약·영양제의 상세 / Medicine & supplement details',
            '앞장 복약 내용을 보충하세요. 모르는 용량은 추정하지 말고 약 봉투나 사진을 함께 보여주세요.\nAdd details to the reported medicine list; leave uncertain doses unknown.',
          ),
          table([
            '이름 / Name',
            '용량·단위 / Dose & unit',
            '빈도 / Frequency',
            '마지막 복용 / Last taken',
          ], List.generate(3, (_) => ['', '', '', ''])),
          ...section(
            '03  알레르기 반응 상세 / Allergy reaction details',
            '원인 물질·어떤 반응·발생 시점 (알고 있는 내용만)\nSubstance, reaction and timing, only if known.',
          ),
          pw.SizedBox(height: 30),
          pw.Divider(color: PdfColors.grey400),
          ...section(
            '04  오늘 확인하고 싶은 점 / Questions for this visit',
            '가장 걱정되는 점·전달하지 못한 증상·필요한 언어 지원\nMain concern, other symptoms to discuss, or language assistance needed.',
          ),
          pw.SizedBox(height: 35),
          pw.Divider(color: PdfColors.grey400),
          pw.Spacer(),
          text(
            '작성자 / Completed by: __________________    작성일 / Date: __________________',
            size: 9,
          ),
          pw.SizedBox(height: 8),
          text(
            '환자 보충 메모이며 의료진의 평가·진단·처방 기록이 아닙니다.\nPatient notes, not a clinician assessment, diagnosis or prescription.',
            size: 8,
          ),
          footer(context),
        ],
      ),
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
                  if (visitDestination(card).isNotEmpty)
                    section(
                      '방문 예정 병원 / Planned destination',
                      visitDestination(card),
                    ),
                  Text('$language · 첫 장 요약 / Overview'),
                  for (final entry in visitOverview(card).entries)
                    section(entry.key, entry.value),
                  const Text('전체 원문·번역·기록은 아래에서 확인하세요. / Full details below.'),
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
                    '통증은 0-10 본인 보고입니다. 이 수치만으로 진단·응급도를 판단하지 않습니다.\n상단 PDF 저장 · 공유 버튼을 사용하세요. / Use Save / share PDF above.',
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
