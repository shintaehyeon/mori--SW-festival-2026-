import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'api.dart';

Uri emergencySmsUri(String phone, String message) => Uri.parse(
  'sms:${Uri.encodeComponent(phone)}?body=${Uri.encodeComponent(message)}',
);

class EmergencyPage extends StatefulWidget {
  final Api api;
  final bool signedIn, ko;
  const EmergencyPage({
    super.key,
    required this.api,
    required this.signedIn,
    required this.ko,
  });
  @override
  State<EmergencyPage> createState() => _EmergencyPageState();
}

class _EmergencyPageState extends State<EmergencyPage> {
  final fields = <String, TextEditingController>{
    for (final key in [
      'name',
      'nationality',
      'organization',
      'address',
      'location',
      'activity',
      'symptoms',
      'message',
    ])
      key: TextEditingController(),
  };
  final names = List.generate(3, (_) => TextEditingController());
  final phones = List.generate(3, (_) => TextEditingController());
  bool loading = true, saving = false;
  String? updatedAt;
  String t(String en, String ko) => widget.ko ? ko : en;
  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    try {
      if (widget.signedIn) {
        final data = await widget.api.request('/api/emergency-profile');
        for (final key in fields.keys) {
          fields[key]!.text = data[key] ?? '';
        }
        final contacts = data['contacts'] as List? ?? [];
        for (var i = 0; i < contacts.length && i < 3; i++) {
          names[i].text = contacts[i]['name'];
          phones[i].text = contacts[i]['phone'];
        }
        updatedAt = data['updatedAt'];
      }
      if (fields['message']!.text.isEmpty) {
        fields['message']!.text =
            'I need help. Please call me as soon as possible. / 도움이 필요해요. 바로 전화해 주세요.';
      }
    } catch (e) {
      notice(e.toString());
    }
    if (mounted) setState(() => loading = false);
  }

  void notice(String text) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
    }
  }

  Future<void> save() async {
    setState(() => saving = true);
    try {
      final contacts = <Map<String, String>>[];
      for (var i = 0; i < 3; i++) {
        if (names[i].text.trim().isEmpty && phones[i].text.trim().isEmpty) {
          continue;
        }
        if (!RegExp(r'^\+?[0-9 ()-]{6,25}$').hasMatch(phones[i].text.trim())) {
          throw Exception(
            t(
              'Check contact phone number (include country code).',
              '연락처 전화번호를 확인해 주세요. 해외 번호는 국가번호를 포함해 주세요.',
            ),
          );
        }
        contacts.add({
          'name': names[i].text.trim(),
          'phone': phones[i].text.trim(),
        });
      }
      final now = DateTime.now().toUtc().toIso8601String();
      await widget.api.request(
        '/api/emergency-profile',
        method: 'PUT',
        body: {
          for (final entry in fields.entries)
            entry.key: entry.value.text.trim(),
          'contacts': contacts,
          'updatedAt': now,
        },
      );
      if (mounted) setState(() => updatedAt = now);
      notice(t('Saved privately to your account.', '내 계정에 비공개로 저장했어요.'));
    } catch (e) {
      notice(e.toString());
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  String message() => [
    fields['message']!.text,
    'Name / 이름: ${fields['name']!.text}',
    'Nationality / 국적: ${fields['nationality']!.text}',
    'School/company in Korea / 한국 소속: ${fields['organization']!.text}',
    'Home address (not live location) / 거주 주소: ${fields['address']!.text}',
    'Current location (manually entered) / 현재 위치(직접 입력): ${fields['location']!.text}',
    'Activity / 활동: ${fields['activity']!.text}',
    'Symptoms / 증상: ${fields['symptoms']!.text}',
    'Message prepared / 메시지 작성: ${DateTime.now().toLocal()}',
    'Last saved / 마지막 저장: ${updatedAt ?? "Not saved / 저장 전"}',
  ].join('\n');
  Future<void> open(Uri uri, {String? fallback}) async {
    try {
      if (await launchUrl(uri, mode: LaunchMode.externalApplication)) return;
    } catch (_) {}
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t('Open on a phone', '휴대전화에서 이용해 주세요')),
        content: Text(fallback ?? uri.path),
        actions: [
          TextButton(
            onPressed: () async {
              await Clipboard.setData(
                ClipboardData(text: fallback ?? uri.path),
              );
              if (context.mounted) Navigator.pop(context);
            },
            child: Text(t('Copy', '복사')),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    for (final c in [...fields.values, ...names, ...phones]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(t('Emergency & My information', '긴급 연락 · 내 정보')),
    ),
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          t('Emergency calls in Korea', '한국 긴급전화'),
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: () => open(Uri(scheme: 'tel', path: '119')),
          icon: const Icon(Icons.local_hospital),
          label: Text(t('119 · Ambulance / Fire', '119 · 구급 / 소방')),
        ),
        FilledButton.icon(
          onPressed: () => open(Uri(scheme: 'tel', path: '112')),
          icon: const Icon(Icons.local_police),
          label: Text(t('112 · Police', '112 · 경찰')),
        ),
        Text(
          t(
            'Opens your phone dialer. Calls are not placed automatically.',
            '전화 화면으로 연결돼요. 실제 통화는 휴대전화에서 시작해 주세요.',
          ),
        ),
        const Divider(height: 32),
        if (!widget.signedIn)
          Text(
            t(
              'Sign in to save your information and family contacts. Emergency calls are available without signing in.',
              '기본정보와 가족 연락처는 로그인 후 저장할 수 있어요. 긴급전화는 로그인 없이 이용할 수 있어요.',
            ),
          )
        else if (loading)
          const Center(child: CircularProgressIndicator())
        else ...[
          Text(
            t('My information in Korea', '한국에서의 내 정보'),
            style: Theme.of(context).textTheme.titleLarge,
          ),
          for (final spec in [
            ['name', 'Full name / 이름'],
            ['nationality', 'Nationality / 국적'],
            ['organization', 'School or company in Korea / 한국 학교·회사'],
            ['address', 'Home address in Korea / 한국 거주 주소'],
            ['location', 'Current location (manual) / 현재 위치(직접 입력)'],
            ['activity', 'What I am doing / 현재 활동'],
            ['symptoms', 'Where / how I feel unwell / 아픈 부위·증상'],
            ['message', 'Saved help message / 미리 작성한 도움 메시지'],
          ])
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 7),
              child: TextField(
                controller: fields[spec[0]],
                maxLines: spec[0] == 'message' || spec[0] == 'symptoms' ? 3 : 1,
                decoration: InputDecoration(labelText: spec[1]),
              ),
            ),
          Text(
            t('Family / trusted contacts (up to 3)', '가족 · 신뢰하는 연락처 (최대 3명)'),
            style: Theme.of(context).textTheme.titleLarge,
          ),
          for (var i = 0; i < 3; i++)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    TextField(
                      controller: names[i],
                      decoration: InputDecoration(
                        labelText: t(
                          'Contact name ${i + 1}',
                          '연락처 이름 ${i + 1}',
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: phones[i],
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: t(
                          'Phone with country code',
                          '전화번호 (국가번호 포함)',
                        ),
                        hintText: '+82 10 ...',
                      ),
                    ),
                    Row(
                      children: [
                        TextButton.icon(
                          onPressed: () {
                            final phone = phones[i].text.replaceAll(
                              RegExp(r'[ ()-]'),
                              '',
                            );
                            if (phone.isEmpty) {
                              notice(
                                t(
                                  'Enter a phone number first.',
                                  '전화번호를 먼저 입력해 주세요.',
                                ),
                              );
                              return;
                            }
                            open(
                              emergencySmsUri(phone, message()),
                              fallback: message(),
                            );
                          },
                          icon: const Icon(Icons.sms),
                          label: Text(t('Prepare SMS', '도움 문자 보내기')),
                        ),
                        TextButton.icon(
                          onPressed: () {
                            final phone = phones[i].text.replaceAll(
                              RegExp(r'[ ()-]'),
                              '',
                            );
                            if (phone.isNotEmpty) {
                              open(Uri(scheme: 'tel', path: phone));
                            }
                          },
                          icon: const Icon(Icons.call),
                          label: Text(t('Call', '전화')),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          FilledButton(
            onPressed: saving ? null : save,
            child: Text(t('Save information & contacts', '내 정보 · 연락처 저장')),
          ),
          Text(
            t(
              'SMS opens with your message and current form information. Review the recipient and message, then send in your messaging app. Opening it does not mean it was delivered. Location is manually entered; family cannot track you live.',
              '문자 앱에서 수신자와 내용(현재 입력된 정보 포함)을 확인하고 전송해 주세요. 문자 앱을 여는 것만으로 전송·수신이 완료되지 않아요. 위치는 직접 입력하며 실시간 가족 위치 공유는 제공하지 않아요.',
            ),
          ),
          if (updatedAt != null)
            Text(
              '${t('Last saved', '마지막 저장')}: ${DateTime.tryParse(updatedAt!)?.toLocal() ?? updatedAt}',
            ),
        ],
      ],
    ),
  );
}
