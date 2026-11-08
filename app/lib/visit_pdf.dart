import 'visit_body_map.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// Explicit export selection only; never read the full private profile here.
const visitPersonalFields = <String, String>{
  'name': '이름 / Name',
  'nationality': '국적 / Nationality',
  'organization': '한국 학교·회사 / School or company in Korea',
  'address': '한국 거주 주소 / Home address in Korea',
  'location': '현재 위치 (직접 입력·실시간 아님) / Location (manual, not live)',
  'activity': '현재 활동 (저장한 내용) / Saved activity',
  'symptoms': '프로필에 저장한 증상 / Symptoms saved in profile',
  'message': '미리 작성한 도움 메시지 / Saved help message',
  'contact1': '비상연락처 1 / Emergency contact 1',
  'contact2': '비상연락처 2 / Emergency contact 2',
  'contact3': '비상연락처 3 / Emergency contact 3',
};
String visitPersonalValue(Map profile, String key) {
  if (key.startsWith('contact') && profile['contacts'] is List) {
    final index = int.tryParse(key.substring(7));
    final contacts = profile['contacts'] as List;
    if (index == null || index < 1 || index > contacts.length) return '';
    final contact = contacts[index - 1];
    if (contact is! Map) return '';
    return [
      contact['name'],
      contact['phone'],
    ].map((v) => '${v ?? ''}'.trim()).where((v) => v.isNotEmpty).join(' · ');
  }
  return '${profile[key] ?? ''}'.trim();
}

Map<String, String> selectedVisitPersonalInfo(Map profile, Set<String> keys) =>
    {
      for (final key in visitPersonalFields.keys)
        if (keys.contains(key) && visitPersonalValue(profile, key).isNotEmpty)
          key: visitPersonalValue(profile, key),
    };

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
  for (var i = 0; i < chars.length;) {
    var end = (i + 260).clamp(0, chars.length);
    if (end < chars.length) {
      // Prefer field boundaries so short personal-info rows stay intact.
      final newline = chars.sublist(i, end).lastIndexOf(10);
      if (newline > 0) end = i + newline + 1;
    }
    yield String.fromCharCodes(chars.sublist(i, end));
    i = end;
  }
}

class VisitSection {
  final String title, body;
  final bool prominent;
  const VisitSection(this.title, this.body, {this.prominent = false});
}

String visitStatus(Map<String, dynamic> card) => card['translation'] == null
    ? '원문만 / Original only'
    : card['confirmedAt'] != null
    ? card['confirmationKind'] == 'source_input'
          ? '원문 입력 확인 / Source input checked · AI 번역 의료진 미검증 / Not clinically verified'
          : '준비표 저장 / Sheet saved · AI 번역 의료진 미검증 / Not clinically verified'
    : 'AI 초안 · 미확인 / Unreviewed AI draft';

/// The UI and PDF share full, saved values. No excerpt can silently lose text.
List<VisitSection> visitSections(Map<String, dynamic> card) {
  final s = card['snapshot'] as Map;
  final tr = card['translation'] as Map?;
  final reviewed = card['confirmedAt'] != null && tr != null;
  final i = s['intake'] as Map? ?? {};
  final originals = [
    VisitSection(
      '방문 이유 / Symptoms · 원문',
      '${s['symptoms']}',
      prominent: !reviewed,
    ),
    VisitSection(
      '시작 시점·경과 / Onset · 원문',
      '${s['onset']}',
      prominent: !reviewed,
    ),
    VisitSection(
      '알레르기 / Allergies · 원문',
      reportedKnowledge(s['profile']?['allergies']),
    ),
    VisitSection(
      '복용약 / Medicines · 원문',
      reportedKnowledge(s['profile']?['medications']),
    ),
  ];
  final korean = tr == null
      ? <VisitSection>[]
      : [
          VisitSection(
            '방문 이유 / Symptoms · 한국어',
            '${tr['symptomsKo']}',
            prominent: reviewed,
          ),
          VisitSection(
            '시작 시점·경과 / Onset · 한국어',
            '${tr['onsetKo']}',
            prominent: reviewed,
          ),
          VisitSection('알레르기 / Allergies · 한국어', '${tr['allergiesKo']}'),
          VisitSection('복용약 / Medicines · 한국어', '${tr['medicationsKo']}'),
        ];
  final measurements = <String>[
    if ('${i['bodySite'] ?? ''}'.trim().isNotEmpty)
      '부위 / Body site: ${i['bodySite']}',
    if (visitBodyRegions.containsKey(i['bodyRegion']))
      '선택 부위 / Selected area: ${visitBodyRegions[i['bodyRegion']]}',
    if (i['painScore'] != null)
      '통증 / Pain: ${i['painScore']}/10 (본인 보고 / Self-reported)',
    if (i['temperatureC'] != null)
      '체온 / Temperature: ${i['temperatureC']} °C (직접 측정 / Self-measured)',
    if ('${i['measuredAt'] ?? ''}'.trim().isNotEmpty)
      '측정 시점·방법 / Measured: ${i['measuredAt']}',
  ];
  return [
    if (reviewed) ...korean,
    ...originals,
    if (tr != null && !reviewed) ...[
      const VisitSection(
        '번역 상태 / Translation status',
        '아래는 확인하지 않은 AI 초안입니다. / Unreviewed AI draft below.',
      ),
      ...korean,
    ],
    if (card['personalInfo'] is Map &&
        selectedVisitPersonalInfo(
          card['personalInfo'],
          visitPersonalFields.keys.toSet(),
        ).isNotEmpty)
      VisitSection(
        '한국에서의 내 정보 / My information in Korea · 사용자 선택 원문 / Selected original text',
        selectedVisitPersonalInfo(
              card['personalInfo'],
              visitPersonalFields.keys.toSet(),
            ).entries
            .map((e) => '${visitPersonalFields[e.key]}: ${e.value}')
            .join('\n'),
      ),
    if (measurements.isNotEmpty)
      VisitSection('선택 입력 / Optional details', measurements.join('\n')),
  ];
}

List<VisitSection> visitAttachments(Map<String, dynamic> card) {
  final s = card['snapshot'] as Map;
  final tr = card['translation'] as Map?;
  return [
    for (final j in (s['journals'] as List? ?? []))
      VisitSection(
        '${j['date']} · 첨부 기록 / Attached record',
        '컨디션 / Condition: ${j['condition']} · 수면 / Sleep: ${j['sleep']} h\n${j['note']}'
            '${tr == null ? '' : (tr['journalKo'] as List? ?? []).where((t) => t['id'] == j['id']).map((t) => '\n한국어 (${visitStatus(card)}): ${t['textKo']}').join()}',
      ),
  ];
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
  );
  final intake = card['snapshot']['intake'] as Map? ?? {};
  final stamp = (exportedAt ?? DateTime.now()).toLocal().toString();
  final attachments = visitAttachments(card);
  const ink = PdfColor.fromInt(0xff193b32);
  pw.Widget text(String value, [double size = 9]) =>
      pw.Text(value, style: pw.TextStyle(fontSize: size, lineSpacing: 2));
  Iterable<pw.Widget> section(VisitSection item) sync* {
    final chunks = reportChunks(item.body).toList();
    yield pw.Padding(
      padding: const pw.EdgeInsets.only(top: 9),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          pw.Text(
            item.title,
            style: pw.TextStyle(
              fontSize: 9,
              color: ink,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 3),
          text(chunks.first, item.prominent ? 14 : 10),
        ],
      ),
    );
    for (final chunk in chunks.skip(1)) {
      yield text(chunk, item.prominent ? 14 : 10);
    }
  }

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
      header: (context) => context.pageNumber == 1
          ? pw.SizedBox()
          : text('MORI · 계속 / Continued · ${visitStatus(card)}', 8),
      footer: (context) => pw.Column(
        children: [
          pw.Divider(),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              text('환자 작성 자료 · 의료기관 공식 기록 아님 / Patient reported', 7),
              text('${context.pageNumber} / ${context.pagesCount}', 8),
            ],
          ),
        ],
      ),
      build: (context) => [
        pw.Text(
          'MORI | 진료 준비표',
          style: pw.TextStyle(
            fontSize: 22,
            color: ink,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        text(
          'VISIT PREPARATION${card['sample'] == true ? ' · 가상 예시 / TEST SAMPLE' : ''}',
        ),
        pw.SizedBox(height: 8),
        if (visitDestination(card).isNotEmpty) text(visitDestination(card), 10),
        if ('${intake['patientName'] ?? ''}'.trim().isNotEmpty)
          text('성명 / Name: ${intake['patientName']}'),
        pw.SizedBox(height: 5),
        text(visitStatus(card)),
        text(
          '저장 / Saved: ${card['createdAt']} · 준비표 저장 / Sheet saved: ${card['confirmedAt'] ?? '미확인 / Not reviewed'}',
          7,
        ),
        for (final item in visitSections(card)) ...section(item),
        pw.SizedBox(height: 12),
        text(
          '환자 입력·번역이며 진단이 아닙니다. AI 번역은 의료진 검수를 받지 않았습니다. 미입력은 이상 없음을 뜻하지 않습니다.\nPatient-reported, not a diagnosis. AI translation has not been clinically verified. Missing does not mean normal.',
          7,
        ),
        text('내보냄 / Exported: $stamp', 7),
        if (attachments.isNotEmpty) ...[
          pw.NewPage(),
          pw.Text(
            '선택 첨부 / Optional attachments',
            style: pw.TextStyle(fontSize: 17, color: ink),
          ),
          text(
            '사용자가 이번 방문을 위해 직접 선택한 기록입니다. / Records selected by the patient for this visit.',
          ),
          for (final item in attachments) ...section(item),
        ],
      ],
    ),
  );
  return doc.save();
}

/// Same full saved content as the PDF, readable without a PDF viewer.
class ClinicalVisitView extends StatelessWidget {
  final Map<String, dynamic> card;
  const ClinicalVisitView({super.key, required this.card});
  @override
  Widget build(BuildContext context) {
    final i = card['snapshot']['intake'] as Map? ?? {};
    final attachments = visitAttachments(card);
    Widget section(VisitSection item) => Padding(
      padding: const EdgeInsets.only(top: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            item.title,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          SelectableText(
            item.body,
            style: TextStyle(fontSize: item.prominent ? 21 : 16, height: 1.45),
          ),
        ],
      ),
    );
    return SingleChildScrollView(
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 760),
          color: Colors.white,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'MORI | 진료 준비표 / VISIT PREPARATION',
                style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold),
              ),
              if (visitDestination(card).isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: SelectableText(visitDestination(card)),
                ),
              if ('${i['patientName'] ?? ''}'.trim().isNotEmpty)
                Text('성명 / Name: ${i['patientName']}'),
              const SizedBox(height: 10),
              Text(visitStatus(card)),
              Text(
                '저장 / Saved: ${card['createdAt']}',
                style: const TextStyle(fontSize: 11),
              ),
              for (final item in visitSections(card)) section(item),
              if (attachments.isNotEmpty) ...[
                const Divider(height: 32),
                const Text('선택 첨부 / Optional attachments'),
                for (final item in attachments) section(item),
              ],
              const SizedBox(height: 20),
              const Text(
                '환자 작성 자료 · 의료기관 공식 기록·진단 아님. AI 번역은 의료진 검수를 받지 않았습니다.\nPatient reported, not an official medical record or diagnosis. AI translation has not been clinically verified.',
                style: TextStyle(fontSize: 11),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
