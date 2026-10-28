import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:health/health.dart';

const wearablePolicyVersion = '2026-10-28-local-v1';
const wearablePolicy = '''모리 워치 연동 · 시제품 안내 / MORI wearable prototype
목적 / Purpose: 사용자가 선택한 건강 기록을 이 화면에서 확인하기 위해 읽습니다.
항목 / Data: 선택한 심박수(bpm), 수면 구간(분), 측정 시작·종료 시각, 원본 앱/기기 출처와 기록 식별값. 최근 24시간만 조회합니다.
처리 방식 / Processing: 이 화면의 실행 메모리에서만 처리합니다. 워치 데이터는 모리 서버·AI·가족·학교·회사에 전송하지 않습니다. 광고·보험·고용 평가에 사용하지 않습니다.
보유 / Retention: 화면을 닫거나 연결 중단 시 이 화면의 데이터를 지웁니다. OS 건강 앱의 원본은 삭제하지 않습니다. OS 권한은 별도로 남을 수 있습니다.
선택권 / Choice: 동의하지 않아도 병원 찾기와 수동 건강기록을 이용할 수 있습니다. 선택 항목별 OS 읽기 권한을 직접 설정합니다.
철회 / Withdrawal: 아래 ‘읽기 중단·화면 데이터 지우기’를 누르고, 건강 앱/Health Connect 설정에서 모리 권한을 해제하세요.
주의 / Limits: 동기화가 지연되거나 기록이 없을 수 있습니다. 무자료는 정상 상태 또는 권한 허용/거부를 확정하지 않습니다. 진단·실시간 감시·응급 자동 신고 기능이 아닙니다.
This view reads only the selected heart-rate and sleep records from the last 24 hours. Records remain in this view’s memory and are not sent to a server, AI, family, school, or employer. Closing the view clears its records, but does not delete the originals or automatically revoke OS access. Declining has no effect on manual features. No diagnosis, continuous monitoring, or automatic emergency reporting is provided.
시제품 문구 / Prototype terms: 운영 주체·문의 창구·배포 환경이 확정된 최종 개인정보처리방침은 아직 아닙니다. 운영 배포 전 확정·검토가 필요합니다.''';

class WearableSample {
  final String id, type, source, unit;
  final num value;
  final DateTime from, to;
  const WearableSample({
    required this.id,
    required this.type,
    required this.source,
    required this.unit,
    required this.value,
    required this.from,
    required this.to,
  });
}

List<WearableSample> normalizeWearableSamples(
  List<WearableSample> samples,
  DateTime start,
  DateTime end,
) {
  final unique = <String, WearableSample>{};
  for (final s in samples) {
    if (!s.value.isFinite ||
        s.value < 0 ||
        s.to.isBefore(s.from) ||
        s.to.isBefore(start) ||
        s.from.isAfter(end)) {
      continue;
    }
    final key = s.id.isEmpty
        ? '${s.source}|${s.type}|${s.from.toUtc()}|${s.to.toUtc()}|${s.value}'
        : '${s.source}|${s.type}|${s.id}';
    unique[key] = s;
  }
  final result = unique.values.toList()..sort((a, b) => b.to.compareTo(a.to));
  return result.take(500).toList();
}

abstract class WearableReader {
  bool get supported;
  Future<bool> authorize(List<HealthDataType> types);
  Future<List<WearableSample>> read(
    List<HealthDataType> types,
    DateTime start,
    DateTime end,
  );
}

class PhoneHealthReader implements WearableReader {
  final health = Health();
  @override
  bool get supported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.android);
  @override
  Future<bool> authorize(List<HealthDataType> types) async {
    await health.configure();
    return health.requestAuthorization(
      types,
      permissions: List.filled(types.length, HealthDataAccess.READ),
    );
  }

  @override
  Future<List<WearableSample>> read(
    List<HealthDataType> types,
    DateTime start,
    DateTime end,
  ) async {
    final points = await health.getHealthDataFromTypes(
      types: types,
      startTime: start,
      endTime: end,
    );
    return points
        .where((p) => p.value is NumericHealthValue)
        .map(
          (p) => WearableSample(
            id: p.uuid,
            type: p.type.name,
            source: p.sourceName,
            unit: p.unit.name,
            value: (p.value as NumericHealthValue).numericValue,
            from: p.dateFrom,
            to: p.dateTo,
          ),
        )
        .toList();
  }
}

class WearablePage extends StatefulWidget {
  final bool ko;
  final WearableReader? reader;
  const WearablePage({super.key, required this.ko, this.reader});
  @override
  State<WearablePage> createState() => _WearablePageState();
}

class _WearablePageState extends State<WearablePage> {
  late final reader = widget.reader ?? PhoneHealthReader();
  bool collection = false,
      sensitive = false,
      heart = false,
      sleep = false,
      busy = false;
  int epoch = 0;
  List<WearableSample> samples = [];
  String? status;
  DateTime? checked;
  String t(String en, String ko) => widget.ko ? ko : en;
  List<HealthDataType> get selected => [
    if (heart) HealthDataType.HEART_RATE,
    if (sleep) HealthDataType.SLEEP_ASLEEP,
  ];
  Future<void> sync() async {
    if (!reader.supported ||
        !collection ||
        !sensitive ||
        selected.isEmpty ||
        busy) {
      return;
    }
    final run = ++epoch, types = List<HealthDataType>.of(selected);
    setState(() {
      busy = true;
      status = null;
      samples = [];
    });
    try {
      final result = await reader.authorize(types);
      if (!mounted || run != epoch) return;
      if (!result) {
        setState(
          () => status = t(
            'Permission flow was not completed. Check OS settings.',
            '권한 요청을 완료하지 못했어요. OS 설정을 확인하세요.',
          ),
        );
        return;
      }
      final end = DateTime.now(),
          start = DateTime.now().subtract(const Duration(hours: 24));
      final records = await reader.read(types, start, end);
      if (!mounted || run != epoch || !collection || !sensitive) return;
      setState(() {
        samples = normalizeWearableSamples(records, start, end);
        checked = end;
        status = samples.isEmpty
            ? t(
                'No readable records. Permission, missing data, or sync delay may be the cause.',
                '읽을 수 있는 기록이 없어요. 권한·기록 유무·동기화 지연을 확인하세요.',
              )
            : t(
                'Records loaded. This is not a live watch connection.',
                '기록을 읽었어요. 실시간 워치 연결은 아닙니다.',
              );
      });
    } catch (_) {
      if (mounted && run == epoch) {
        setState(
          () => status = t(
            'Unable to read. Check Health/Health Connect availability, permissions and sync.',
            '읽지 못했어요. 건강 앱/Health Connect 설치·권한·동기화를 확인하세요.',
          ),
        );
      }
    } finally {
      if (mounted && run == epoch) setState(() => busy = false);
    }
  }

  void clear() {
    epoch++;
    setState(() {
      samples = [];
      checked = null;
      collection = false;
      sensitive = false;
      busy = false;
      status = t(
        'Reading stopped. Revoke remaining OS permission in Health / Health Connect settings.',
        '읽기를 중단했어요. OS 권한도 해제하려면 건강 앱/Health Connect 설정에서 모리를 끄세요.',
      );
    });
  }

  @override
  void dispose() {
    epoch++;
    samples = [];
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(t('Watch data & permissions', '워치 데이터 · 동의 · 권한')),
    ),
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          t('Read phone-synced health records', '휴대전화에 동기화된 건강 기록 읽기'),
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        Text(
          t(
            'Apple Watch → Apple Health → Mori\nGalaxy Watch → Samsung Health → Health Connect → Mori',
            'Apple Watch → iPhone 건강 앱 → 모리\nGalaxy Watch → Samsung Health → Health Connect → 모리',
          ),
        ),
        const SizedBox(height: 12),
        SelectableText(wearablePolicy),
        const SizedBox(height: 12),
        if (!reader.supported)
          Text(
            t(
              'Web preview cannot access HealthKit or Health Connect. Use the native iOS/Android app.',
              '웹 미리보기에서는 건강 데이터를 읽을 수 없어요. iOS/Android 앱에서 이용하세요.',
            ),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        CheckboxListTile(
          value: collection,
          onChanged: busy
              ? null
              : (v) => setState(() {
                  collection = v!;
                  samples = [];
                }),
          title: Text(
            t(
              'Optional: consent to the described collection and use',
              '[선택] 위 목적·항목·보유기간의 수집·이용에 동의',
            ),
          ),
        ),
        CheckboxListTile(
          value: sensitive,
          onChanged: busy
              ? null
              : (v) => setState(() {
                  sensitive = v!;
                  samples = [];
                }),
          title: Text(
            t(
              'Separate optional consent: processing sensitive health information',
              '[별도 선택] 심박수·수면 등 민감한 건강정보 처리에 동의',
            ),
          ),
        ),
        Text(
          t(
            'Choose data to read. No write, location, contacts, Bluetooth scan, accessibility control or background permission is requested.',
            '읽을 항목을 선택해 주세요. 쓰기·위치·연락처·블루투스 검색·접근성 제어·백그라운드 권한은 요청하지 않아요.',
          ),
        ),
        SwitchListTile(
          value: heart,
          onChanged: busy
              ? null
              : (v) => setState(() {
                  heart = v;
                  samples = [];
                }),
          title: Text(t('Heart rate', '심박수')),
        ),
        SwitchListTile(
          value: sleep,
          onChanged: busy
              ? null
              : (v) => setState(() {
                  sleep = v;
                  samples = [];
                }),
          title: Text(t('Sleep intervals', '수면 구간')),
        ),
        FilledButton(
          onPressed:
              reader.supported &&
                  collection &&
                  sensitive &&
                  selected.isNotEmpty &&
                  !busy
              ? sync
              : null,
          child: Text(
            busy
                ? t('Reading…', '읽는 중…')
                : t(
                    'Request OS permission & read last 24h',
                    'OS 권한 요청 · 최근 24시간 읽기',
                  ),
          ),
        ),
        OutlinedButton(
          onPressed: clear,
          child: Text(
            t('Stop reading & clear view data', '읽기 중단 · 화면 데이터 지우기'),
          ),
        ),
        Text(
          t(
            'iPhone: Health app → sharing/privacy → apps → Mori. Android: Settings → Health Connect → app permissions → Mori. Menu names vary by OS. Android also needs Samsung Health → Health Connect sync enabled.',
            'iPhone: 건강 앱 → 공유/개인정보 → 앱 → 모리. Android: 설정 → Health Connect → 앱 권한 → 모리. OS별 메뉴명은 다를 수 있어요. 갤럭시는 Samsung Health의 Health Connect 동기화도 켜야 합니다.',
          ),
        ),
        if (status != null)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(status!),
          ),
        if (checked != null)
          Text(
            '${t('Last read', '마지막 조회')}: ${checked!.toLocal()} · ${samples.length} ${t('records (up to 500 retained in this view)', '개 기록 (화면 내 최대 500개)')}',
          ),
        for (final s in samples.take(20))
          ListTile(
            title: Text('${s.type} · ${s.value} ${s.unit}'),
            subtitle: Text(
              '${s.from.toLocal()} ~ ${s.to.toLocal()}\n${t('Source', '출처')}: ${s.source}',
            ),
          ),
        Text(
          t(
            'No sample records are fabricated. Empty or denied access never becomes “normal”. Permission is requested again after reopening this prototype screen.',
            '가상 생체기록은 만들지 않습니다. 자료 없음이나 권한 거부를 ‘정상’으로 표시하지 않아요. 이 시제품은 화면을 다시 열 때 동의를 다시 받습니다.',
          ),
          style: const TextStyle(fontSize: 12),
        ),
      ],
    ),
  );
}
