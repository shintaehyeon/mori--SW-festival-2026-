import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'api.dart';
import 'mori.dart';

class FriendsPage extends StatefulWidget {
  final Api api;
  final bool ko;
  const FriendsPage({super.key, required this.api, required this.ko});
  @override
  State<FriendsPage> createState() => _FriendsPageState();
}

class _FriendsPageState extends State<FriendsPage> {
  Map<String, dynamic>? settings, avatar;
  List<dynamic> friends = [], people = [], requests = [], messages = [];
  bool busy = false, loading = true;
  String? error;
  Timer? timer;
  String t(String en, String ko) => widget.ko ? ko : en;
  @override
  void initState() {
    super.initState();
    load();
    timer = Timer.periodic(const Duration(seconds: 30), (_) => load());
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  Future<void> load() async {
    try {
      final data = await Future.wait([
        widget.api.request('/api/social/settings'),
        widget.api.request('/api/social/friends'),
        widget.api.request('/api/social/online'),
        widget.api.request('/api/social/requests'),
        widget.api.request('/api/social/messages'),
        widget.api.request('/api/avatar'),
      ]);
      if (mounted) {
        setState(() {
          settings = Map<String, dynamic>.from(data[0]);
          friends = data[1];
          people = data[2];
          requests = data[3];
          messages = data[4];
          avatar = Map<String, dynamic>.from(data[5]);
          loading = false;
          error = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          error = e.toString();
          loading = false;
          people = [];
          friends = [];
          requests = [];
          messages = [];
        });
      }
    }
  }

  Future<void> act(Future<void> Function() action) async {
    if (busy) return;
    setState(() => busy = true);
    try {
      await action();
      await load();
    } catch (e) {
      if (mounted) setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> edit() async {
    if (settings == null || avatar == null) return;
    var visibility = settings!['visibility'] as String,
        condition = settings!['condition'] as String;
    var share = settings!['shareStatus'] == true;
    final name = TextEditingController(text: avatar!['name']),
        note = TextEditingController(text: settings!['note']);
    final v = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, change) => AlertDialog(
          title: Text(t('My friend profile', '친구에게 보이는 내 모리')),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: name,
                  maxLength: 20,
                  decoration: InputDecoration(
                    labelText: t('Mori nickname', '모리 닉네임'),
                  ),
                ),
                Wrap(
                  spacing: 8,
                  children: [
                    for (final v in ['private', 'public'])
                      ChoiceChip(
                        label: Text(
                          v == 'public'
                              ? t('Public', '공개')
                              : t('Private', '비공개'),
                        ),
                        selected: visibility == v,
                        onSelected: (_) => change(() => visibility = v),
                      ),
                  ],
                ),
                Text(
                  t(
                    'Public: signed-in people see your nickname and recent connection, and may invite you. Private: no discovery or online/status sharing.',
                    '공개: 로그인한 이용자가 닉네임·최근 접속을 보고 초대할 수 있어요. 비공개: 발견 목록과 친구의 접속·상태 표시를 숨겨요.',
                  ),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: share,
                  onChanged: (v) => change(() => share = v),
                  title: Text(
                    t(
                      'Separately share my entered condition with accepted friends',
                      '수락한 친구에게 입력한 컨디션을 별도로 공유',
                    ),
                  ),
                  subtitle: Text(
                    t(
                      'This may reveal health information. No journals, medications, watch data or location are shared.',
                      '건강 상태가 알려질 수 있어요. 건강일지·약·워치 기록·위치는 공유하지 않아요.',
                    ),
                  ),
                ),
                if (share) ...[
                  Wrap(
                    spacing: 4,
                    children: [
                      for (final c in ['unknown', 'good', 'okay', 'low'])
                        ChoiceChip(
                          label: Text(conditionLabel(c)),
                          selected: condition == c,
                          onSelected: (_) => change(() => condition = c),
                        ),
                    ],
                  ),
                  TextField(
                    controller: note,
                    maxLength: 80,
                    decoration: InputDecoration(
                      labelText: t(
                        'A short status to share',
                        '친구에게 보여줄 상태 한마디',
                      ),
                    ),
                  ),
                ],
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
                if (name.text.trim().isNotEmpty) {
                  Navigator.pop(context, {
                    'visibility': visibility,
                    'shareStatus': share,
                    'condition': condition,
                    'note': note.text.trim(),
                    'name': name.text.trim(),
                  });
                }
              },
              child: Text(t('Save', '저장')),
            ),
          ],
        ),
      ),
    );
    if (v == null || !mounted) return;
    await act(() async {
      await widget.api.request(
        '/api/avatar',
        method: 'PUT',
        body: {...avatar!, 'name': v['name']},
      );
      await widget.api.request(
        '/api/social/settings',
        method: 'PUT',
        body: {...v}..remove('name'),
      );
    });
  }

  String conditionLabel(String c) =>
      {
        'unknown': t('Not shared yet', '아직 모름'),
        'good': t('Feeling good', '좋아요'),
        'okay': t('Okay', '보통이에요'),
        'low': t('Having a hard day', '힘들어요'),
      }[c] ??
      c;
  Future<void> inviteCode() async {
    await act(() async {
      final r = await widget.api.request(
        '/api/social/invites',
        method: 'POST',
        body: {},
      );
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(t('My invitation', '내 친구 초대장')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SelectableText(r['code']),
              Text(
                t(
                  'Share this code with one trusted friend. It expires in 7 days and can be accepted once. Making a new code cancels the previous code.',
                  '믿는 친구 1명에게 이 코드를 전달하세요. 7일간 유효하며 한 번만 수락할 수 있어요. 새 코드를 만들면 이전 코드는 취소됩니다.',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: r['code']));
                if (context.mounted) Navigator.pop(context);
              },
              child: Text(t('Copy code', '코드 복사')),
            ),
          ],
        ),
      );
    });
  }

  Future<void> acceptCode() async {
    final code = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t('Accept invitation', '초대 코드로 친구 연결')),
        content: TextField(
          controller: code,
          maxLength: 32,
          decoration: InputDecoration(labelText: t('Invitation code', '초대 코드')),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(t('Cancel', '취소')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, code.text.trim()),
            child: Text(t('Accept & bind', '수락 · 친구 연결')),
          ),
        ],
      ),
    );
    if (result != null && result.isNotEmpty) {
      await act(() async {
        await widget.api.request(
          '/api/social/accept',
          method: 'POST',
          body: {'code': result},
        );
      });
    }
  }

  Future<void> compose(Map<String, dynamic> friend) async {
    final text = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, change) => AlertDialog(
          title: Text(
            '${friend['nickname']} · ${t('A little encouragement', '짧은 응원')}',
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: text,
                maxLength: 20,
                maxLines: 1,
                onChanged: (_) => change(() {}),
                decoration: InputDecoration(
                  labelText: t('Up to 20 characters', '20자 이내 한마디'),
                ),
              ),
              Wrap(
                spacing: 4,
                children: [
                  for (final phrase
                      in widget.ko
                          ? ['오늘 고생했어!', '힘들었지, 늘 응원해', '오늘도 네 편이야']
                          : [
                              'You did great today!',
                              'Here for you!',
                              'Take your time.',
                            ])
                    ActionChip(
                      label: Text(phrase),
                      onPressed: () => change(() => text.text = phrase),
                    ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(t('Cancel', '취소')),
            ),
            FilledButton(
              onPressed:
                  text.text.trim().isNotEmpty &&
                      text.text.trim().characters.length <= 20
                  ? () => Navigator.pop(context, text.text.trim())
                  : null,
              child: Text(t('Send', '보내기')),
            ),
          ],
        ),
      ),
    );
    if (result != null) {
      await act(() async {
        await widget.api.request(
          '/api/social/messages',
          method: 'POST',
          body: {'recipient': friend['id'], 'body': result},
        );
      });
    }
  }

  Future<void> remove(Map<String, dynamic> person, bool block) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          block
              ? t('Block this person?', '이 친구를 차단할까요?')
              : t('Disconnect this friend?', '친구 연결을 끊을까요?'),
        ),
        content: Text(
          t(
            'Your connection and stored messages between you will be removed.',
            '친구 연결과 두 사람 사이에 저장된 메시지가 삭제됩니다.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(t('Cancel', '취소')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(t('Confirm', '확인')),
          ),
        ],
      ),
    );
    if (yes == true) {
      await act(() async {
        await widget.api.request(
          '/api/social/friends/${person['id']}${block ? '/block' : ''}',
          method: 'DELETE',
          body: {},
        );
      });
    }
  }

  Widget personCard(Map<String, dynamic> p, {required bool bound}) {
    final s = p['status'];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                SizedBox(
                  width: 64,
                  height: 72,
                  child: CustomPaint(
                    painter: MoriPainter(
                      style: p['avatar']?['style'] ?? 'sprout',
                      color: p['avatar']?['color'] ?? 'mint',
                      condition: s?['condition'] ?? 'unknown',
                      phase: 0,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        p['nickname'],
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        p['online'] == null
                            ? t('Private', '비공개')
                            : p['online'] == true
                            ? t('Recently online', '최근 접속 중')
                            : t(
                                'Connection not recently confirmed',
                                '최근 접속 확인 안 됨',
                              ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (s != null) ...[
              Text(conditionLabel(s['condition'])),
              if ((s['note'] as String).isNotEmpty) Text(s['note']),
              Text(
                '${t('Status updated', '상태 작성')}: ${DateTime.tryParse(s['updatedAt'])?.toLocal() ?? s['updatedAt']}',
                style: const TextStyle(fontSize: 11),
              ),
            ] else if (bound)
              Text(t('Condition is not shared.', '친구가 컨디션을 공유하지 않았어요.')),
            Wrap(
              spacing: 4,
              children: bound
                  ? [
                      TextButton.icon(
                        onPressed: busy ? null : () => compose(p),
                        icon: const Icon(Icons.favorite_outline),
                        label: Text(t('Send 20-char cheer', '20자 응원 보내기')),
                      ),
                      TextButton(
                        onPressed: busy ? null : () => remove(p, false),
                        child: Text(t('Disconnect', '연결 해제')),
                      ),
                      TextButton(
                        onPressed: busy ? null : () => remove(p, true),
                        child: Text(t('Block', '차단')),
                      ),
                    ]
                  : [
                      TextButton(
                        onPressed: busy
                            ? null
                            : () => act(() async {
                                await widget.api.request(
                                  '/api/social/requests',
                                  method: 'POST',
                                  body: {'recipient': p['id']},
                                );
                              }),
                        child: Text(t('Invite friend', '친구 초대장 보내기')),
                      ),
                    ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(t('Mori friends', '모리 친구')),
      actions: [IconButton(onPressed: load, icon: const Icon(Icons.refresh))],
    ),
    body: loading
        ? const Center(child: CircularProgressIndicator())
        : ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(
                t('A small connection. A kind word.', '모리로 이어지고, 한마디로 응원해요.'),
                style: Theme.of(context).textTheme.titleLarge,
              ),
              Text(
                '${avatar?['name'] ?? 'Mori'} · ${settings?['visibility'] == 'public' ? t('Public', '공개') : t('Private', '비공개')}',
              ),
              Text(
                t(
                  'Recent connection = within 90 seconds; refreshed every 30 seconds. Conditions are entered and shared by the person, not diagnosed.',
                  '최근 접속은 90초 내 연결 기준이며 30초마다 갱신돼요. 컨디션은 본인이 입력·공유한 상태이며 진단이 아닙니다.',
                ),
              ),
              Wrap(
                spacing: 6,
                children: [
                  OutlinedButton(
                    onPressed: busy ? null : edit,
                    child: Text(
                      t('Nickname / privacy / condition', '닉네임 · 공개설정 · 내 상태'),
                    ),
                  ),
                  OutlinedButton(
                    onPressed: busy ? null : inviteCode,
                    child: Text(t('Create invitation', '초대 코드 만들기')),
                  ),
                  OutlinedButton(
                    onPressed: busy ? null : acceptCode,
                    child: Text(t('Accept code', '초대 코드 수락')),
                  ),
                  TextButton(
                    onPressed: busy
                        ? null
                        : () => act(() async {
                            await widget.api.request(
                              '/api/social/invites',
                              method: 'DELETE',
                              body: {},
                            );
                          }),
                    child: Text(t('Revoke my code', '내 초대 코드 취소')),
                  ),
                ],
              ),
              if (busy) const LinearProgressIndicator(),
              if (error != null)
                Text(error!, style: const TextStyle(color: Colors.red)),
              Text(
                t('Invitations received', '받은 초대장'),
                style: Theme.of(context).textTheme.titleMedium,
              ),
              if (requests.isEmpty)
                Text(t('No invitations yet.', '아직 받은 초대장이 없어요.')),
              for (final r in requests)
                ListTile(
                  title: Text(r['from']['nickname']),
                  subtitle: Text(
                    t('Wants to connect as a friend', '친구로 연결하고 싶어 해요'),
                  ),
                  trailing: Wrap(
                    children: [
                      TextButton(
                        onPressed: busy
                            ? null
                            : () => act(() async {
                                await widget.api.request(
                                  '/api/social/accept',
                                  method: 'POST',
                                  body: {'requestId': r['id']},
                                );
                              }),
                        child: Text(t('Accept', '수락')),
                      ),
                      TextButton(
                        onPressed: busy
                            ? null
                            : () => act(() async {
                                await widget.api.request(
                                  '/api/social/requests/${r['id']}',
                                  method: 'DELETE',
                                  body: {},
                                );
                              }),
                        child: Text(t('Decline', '거절')),
                      ),
                    ],
                  ),
                ),
              Text(
                t('My friends', '내 친구'),
                style: Theme.of(context).textTheme.titleMedium,
              ),
              if (friends.isEmpty)
                Text(
                  t(
                    'Connect after exchanging an invitation.',
                    '초대장을 주고받고 수락하면 친구가 연결돼요.',
                  ),
                ),
              for (final p in friends)
                personCard(Map<String, dynamic>.from(p), bound: true),
              Text(
                t('Public · recently online', '공개 · 최근 접속한 모리'),
                style: Theme.of(context).textTheme.titleMedium,
              ),
              if (people.isEmpty)
                Text(
                  t('No public connections to display.', '표시할 공개 접속자가 없어요.'),
                ),
              for (final p in people.where(
                (p) => !friends.any((f) => f['id'] == p['id']),
              ))
                personCard(Map<String, dynamic>.from(p), bound: false),
              Text(
                t('Short messages', '주고받은 한마디'),
                style: Theme.of(context).textTheme.titleMedium,
              ),
              if (messages.isEmpty)
                Text(t('No messages yet.', '아직 주고받은 메시지가 없어요.')),
              for (final m in messages)
                ListTile(
                  leading: Icon(
                    m['fromMe'] ? Icons.north_east : Icons.south_west,
                  ),
                  title: Text(m['body']),
                  subtitle: Text(
                    '${m['peer']} · ${DateTime.tryParse(m['createdAt'])?.toLocal() ?? m['createdAt']}',
                  ),
                ),
            ],
          ),
  );
}
