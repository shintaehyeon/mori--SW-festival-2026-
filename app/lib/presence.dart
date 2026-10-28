import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'api.dart';

class PresencePanel extends StatefulWidget {
  final Api api;
  final bool ko;
  const PresencePanel({super.key, required this.api, required this.ko});
  @override
  State<PresencePanel> createState() => _PresencePanelState();
}

class _PresencePanelState extends State<PresencePanel>
    with WidgetsBindingObserver {
  final clientId =
      '${DateTime.now().microsecondsSinceEpoch}-${Random.secure().nextInt(1 << 30)}';
  Timer? timer;
  Map<String, dynamic> settings = {
    'enabled': false,
    'organizationType': 'school',
    'organization': '',
    'region': '',
  };
  bool ready = false, working = false, visible = true, checking = false;
  Map<String, dynamic>? status;
  String? error;
  String t(String en, String ko) => widget.ko ? ko : en;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    initialize();
    timer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (visible) refresh();
    });
  }

  Future<void> initialize() async {
    try {
      final r = await widget.api.request('/api/presence/settings');
      if (!mounted) return;
      setState(() {
        settings = Map<String, dynamic>.from(r);
        ready = true;
      });
      await refresh();
    } catch (_) {
      if (mounted) {
        setState(() => error = t('Connection unavailable', '연결을 확인할 수 없어요'));
      }
    }
  }

  Future<void> refresh() async {
    if (checking || !visible) return;
    checking = true;
    try {
      final r = await widget.api.request(
        '/api/presence',
        method: 'POST',
        body: {'clientId': clientId},
      );
      if (mounted) {
        setState(() {
          status = Map<String, dynamic>.from(r);
          error = null;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          status = null;
          error = t(
            'Connection unavailable · count unknown',
            '연결 끊김 · 접속 수 확인 불가',
          );
        });
      }
    } finally {
      checking = false;
    }
  }

  Future<void> leave() async {
    try {
      await widget.api.request(
        '/api/presence',
        method: 'DELETE',
        body: {'clientId': clientId},
      );
    } catch (_) {}
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    visible = state == AppLifecycleState.resumed;
    if (visible) {
      refresh();
    } else {
      leave();
    }
  }

  Future<void> update(Map<String, dynamic> value) async {
    setState(() => working = true);
    try {
      await widget.api.request(
        '/api/presence/settings',
        method: 'PUT',
        body: value,
      );
      if (mounted) setState(() => settings = value);
      await refresh();
    } catch (_) {
      if (mounted) setState(() => error = t('Unable to save', '설정을 저장하지 못했어요'));
    } finally {
      if (mounted) setState(() => working = false);
    }
  }

  Future<void> edit() async {
    final organization = TextEditingController(text: settings['organization']);
    final region = TextEditingController(text: settings['region']);
    var kind = settings['organizationType'] as String;
    var enabled = settings['enabled'] == true;
    String? validation;
    final value = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, change) => AlertDialog(
          title: Text(t('My organization & region', '내 소속 · 지역 등록')),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Wrap(
                  spacing: 6,
                  children: [
                    for (final k in ['school', 'work', 'other'])
                      ChoiceChip(
                        label: Text(
                          {
                            'school': t('School', '학교'),
                            'work': t('Work', '직장'),
                            'other': t('Other', '기타'),
                          }[k]!,
                        ),
                        selected: kind == k,
                        onSelected: (_) => change(() => kind = k),
                      ),
                  ],
                ),
                TextField(
                  controller: organization,
                  maxLength: 120,
                  decoration: InputDecoration(
                    labelText: t('School / company name', '학교 · 회사 이름'),
                    hintText: t(
                      'Use the full official name',
                      '예: 한동대학교, 포항공과대학교',
                    ),
                  ),
                ),
                TextField(
                  controller: region,
                  maxLength: 120,
                  decoration: InputDecoration(
                    labelText: t('Area (city / district)', '활동 지역 (시 · 구)'),
                    hintText: t('e.g. 포항시 북구', '예: 포항시 북구'),
                  ),
                ),
                Text(
                  t(
                    'Use the same organization and area spelling to join the same group. No automatic location tracking.',
                    '같은 소속·지역 이름으로 등록해야 같은 그룹으로 집계돼요. 위치를 자동 추적하지 않습니다.',
                  ),
                  style: const TextStyle(fontSize: 12),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    t('Include my connection in counts', '내 접속을 그룹 집계에 포함'),
                  ),
                  value: enabled,
                  onChanged: (v) => change(() => enabled = v),
                ),
                if (validation != null)
                  Text(validation!, style: const TextStyle(color: Colors.red)),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(t('Cancel', '취소')),
            ),
            FilledButton(
              onPressed: () {
                if (enabled &&
                    organization.text.trim().isEmpty &&
                    region.text.trim().isEmpty) {
                  change(
                    () => validation = t(
                      'Enter an organization or area.',
                      '소속 또는 지역을 입력해 주세요.',
                    ),
                  );
                  return;
                }
                Navigator.pop(context, {
                  'enabled': enabled,
                  'organizationType': kind,
                  'organization': organization.text.trim(),
                  'region': region.text.trim(),
                });
              },
              child: Text(t('Save', '등록 · 저장')),
            ),
          ],
        ),
      ),
    );
    if (value != null && mounted) await update(value);
  }

  @override
  void dispose() {
    timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    unawaited(leave());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 16),
    child: Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.groups_outlined),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  status == null
                      ? t('Community · checking connections', '커뮤니티 · 접속 확인 중')
                      : '${t('Community · recently online', '커뮤니티 · 최근 접속')} ${status!['count']} ${t('people', '명')}',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              IconButton(
                tooltip: t('Refresh', '새로고침'),
                onPressed: ready ? refresh : initialize,
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
          Text(
            t(
              'Self-declared · active within 90 seconds · one per account. No enrollment or employment verification.',
              '직접 등록한 소속 · 최근 90초 내 연결 · 계정당 1명. 재학·재직 인증은 아닙니다.',
            ),
            style: const TextStyle(fontSize: 12),
          ),
          if (status?['organizationCount'] != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                '${status!['organization']} · ${status!['organizationCount']} ${t('online', '명 접속')}',
              ),
            ),
          if (status?['regionCount'] != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                '${status!['region']} · ${status!['regionCount']} ${t('online', '명 접속')}',
              ),
            ),
          TextButton.icon(
            onPressed: ready && !working ? edit : null,
            icon: const Icon(Icons.edit_location_alt_outlined),
            label: Text(
              t('Register school / workplace / area', '내 학교 · 직장 · 지역 등록'),
            ),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            dense: true,
            title: Text(t('Include me in my groups', '내 그룹 접속 수에 포함')),
            subtitle: Text(
              t(
                'Only aggregate counts are shared; no health information or member list.',
                '총계만 공유하며 닉네임·건강정보·접속자 명단은 공개하지 않아요.',
              ),
            ),
            value: settings['enabled'] == true,
            onChanged: ready && !working
                ? (v) {
                    if (v &&
                        (settings['organization'] as String).isEmpty &&
                        (settings['region'] as String).isEmpty) {
                      edit();
                    } else {
                      update({...settings, 'enabled': v});
                    }
                  }
                : null,
          ),
          if (status?['includesMe'] == true)
            Text(
              t('You are included.', '나도 포함된 숫자예요.'),
              style: const TextStyle(fontSize: 12),
            ),
          if (error != null)
            Text(
              error!,
              style: const TextStyle(color: Colors.red, fontSize: 12),
            ),
        ],
      ),
    ),
  );
}
