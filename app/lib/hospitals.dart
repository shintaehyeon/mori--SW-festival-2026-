import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'api.dart';

class Hospitals extends StatefulWidget {
  final Api api;
  final bool ko;
  const Hospitals({super.key, required this.api, required this.ko});
  @override
  State<Hospitals> createState() => _HospitalsState();
}

class _HospitalsState extends State<Hospitals> {
  final query = TextEditingController();
  Map<String, dynamic>? data;
  String? error;
  bool busy = false;
  String t(String en, String ko) => widget.ko ? ko : en;
  @override
  void initState() {
    super.initState();
    load();
  }

  @override
  void dispose() {
    query.dispose();
    super.dispose();
  }

  Future<void> load() async {
    setState(() => busy = true);
    try {
      final r = await widget.api.request(
        '/api/hospitals?q=${Uri.encodeComponent(query.text.trim())}',
      );
      if (mounted) {
        setState(() {
          data = Map<String, dynamic>.from(r);
          error = null;
        });
      }
    } catch (e) {
      if (mounted) setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> open(Uri uri) async {
    try {
      if (await launchUrl(uri, mode: LaunchMode.externalApplication)) return;
    } catch (_) {}
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(t('Unable to open on this device.', '이 기기에서 열 수 없어요.')),
        ),
      );
    }
  }

  Future<void> reviews(String hospital) async {
    try {
      final results = await widget.api.request(
        '/api/posts?q=${Uri.encodeComponent(hospital)}',
      );
      final posts = (results as List)
          .where((p) => p['place'] == hospital)
          .toList();
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(t('Mori community experiences', '모리 이용자 방문 경험')),
          content: SizedBox(
            width: 500,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(hospital),
                  Text(
                    t(
                      'Self-reported experiences, not verified visits or nationality. Match uses the exact institution name. Write an experience in Community using this name.',
                      '자가 작성 경험이며 방문·국적을 인증하지 않았습니다. 병원명이 정확히 일치하는 글만 표시합니다. 커뮤니티에서 이 병원명으로 경험을 남길 수 있어요.',
                    ),
                  ),
                  if (posts.isEmpty)
                    Text(
                      t(
                        'No experiences yet. We do not generate sample reviews.',
                        '아직 등록된 경험이 없어요. 가상 후기는 표시하지 않습니다.',
                      ),
                    ),
                  for (final p in posts)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            p['title'],
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text('${p['language']} · ${p['visitDate']}'),
                          Text(p['body']),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(t('Close', '닫기')),
            ),
          ],
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(
        t('Find care in Pohang', '포항 의료기관 찾기'),
        style: Theme.of(context).textTheme.headlineSmall,
      ),
      Text(
        t(
          'Official HIRA snapshot · 2026-09-30. Not live availability. Confirm by phone before visiting.',
          '심평원 공식자료 · 2026-09-30 기준. 실시간 진료 가능 정보가 아니에요. 방문 전 전화로 확인하세요.',
        ),
      ),
      const SizedBox(height: 12),
      TextField(
        controller: query,
        onSubmitted: (_) => load(),
        decoration: InputDecoration(
          labelText: t(
            'Hospital / department / area (Korean)',
            '병원명 · 진료과 · 동네 검색',
          ),
          hintText: '내과 / 이비인후과 / 흥해',
          suffixIcon: IconButton(
            onPressed: busy ? null : load,
            icon: const Icon(Icons.search),
          ),
        ),
      ),
      if (busy) const LinearProgressIndicator(),
      if (error != null)
        Text(error!, style: const TextStyle(color: Colors.red)),
      if (data != null) ...[
        Text(
          '${data!['total']} ${t('results · showing up to 100', '곳 · 최대 100곳 표시')}',
        ),
        for (final h in data!['hospitals'])
          Card(
            child: ExpansionTile(
              title: Text(h['name']),
              subtitle: Text(
                '${h['type']} · ${h['doctors']} ${t('doctors', '의사')}\n${h['address']}',
              ),
              childrenPadding: const EdgeInsets.all(16),
              expandedCrossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${t('Registered departments', '신고 진료과목')}: ${(h['departments'] as List).map((d) => '${d['name']} (${d['specialists']})').join(', ')}',
                ),
                Text(
                  t(
                    'Parentheses: specialist count. A listed department with 0 specialists is not a specialist qualification.',
                    '괄호는 과목별 전문의 수입니다. 진료과목 표기가 해당 과 전문의 보유를 뜻하지는 않아요.',
                  ),
                ),
                if (h['beds'] != null)
                  Text(
                    '${t('General inpatient beds', '일반입원실 병상')}: ${(h['beds']['일반입원실상급병상수'] as int) + (h['beds']['일반입원실일반병상수'] as int)} · ${t('Reported ER beds', '신고 응급실 병상')}: ${h['beds']['응급실병상수']}',
                  ),
                Text(
                  t(
                    'Language support: unverified. Bed counts do not indicate available beds or emergency acceptance.',
                    '외국어 지원: 미확인. 병상 수는 빈 병상이나 현재 응급환자 수용 여부가 아닙니다.',
                  ),
                ),
                Wrap(
                  spacing: 8,
                  children: [
                    if ((h['phone'] as String).isNotEmpty)
                      TextButton.icon(
                        onPressed: () =>
                            open(Uri(scheme: 'tel', path: h['phone'])),
                        icon: const Icon(Icons.call),
                        label: Text(h['phone']),
                      ),
                    TextButton(
                      onPressed: () => open(
                        Uri.https('www.google.com', '/maps/search/', {
                          'api': '1',
                          'query': '${h['name']} ${h['address']}',
                        }),
                      ),
                      child: Text(t('Google Maps / reviews', '구글지도 · 후기')),
                    ),
                    TextButton(
                      onPressed: () => open(
                        Uri.https(
                          'map.naver.com',
                          '/p/search/${h['name']} ${h['address']}',
                        ),
                      ),
                      child: Text(t('Naver Map', '네이버지도')),
                    ),
                    TextButton(
                      onPressed: () => open(
                        Uri.https('map.kakao.com', '/', {
                          'q': '${h['name']} ${h['address']}',
                        }),
                      ),
                      child: Text(t('Kakao Map', '카카오지도')),
                    ),
                  ],
                ),
                TextButton.icon(
                  onPressed: () => reviews(h['name']),
                  icon: const Icon(Icons.forum_outlined),
                  label: Text(t('Mori visit experiences', '모리 방문 경험 보기')),
                ),
                Text(
                  t(
                    'External map reviews open on the provider’s site. We have not imported reviews or verified reviewer nationality.',
                    '외부 지도에서 후기를 확인합니다. 후기 원문을 수집하지 않았으며 작성자 국적은 확인할 수 없어요.',
                  ),
                ),
              ],
            ),
          ),
        Text('${data!['source']} · ${data!['license']}'),
      ],
    ],
  );
}
