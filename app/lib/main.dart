import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'api.dart';
import 'emergency.dart';
import 'mori.dart';
import 'hospitals.dart';
import 'presence.dart';
import 'wearable.dart';
import 'friends.dart';

const ink = Color(0xFF193B32);
const green = Color(0xFF28654F);
const cream = Color(0xFFF5F7F1);
const pale = Color(0xFFEAF1E5);
const lime = Color(0xFFD8ECB0);
typedef Json = Map<String, dynamic>;
void main() => runApp(const CareBridgeApp());

class CareBridgeApp extends StatelessWidget {
  const CareBridgeApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'MORI · Puchipa',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: green),
      scaffoldBackgroundColor: cream,
      textTheme: const TextTheme(
        bodyMedium: TextStyle(color: ink, height: 1.5),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.all(15),
      ),
    ),
    home: const Workspace(),
  );
}

class Workspace extends StatefulWidget {
  const Workspace({super.key});
  @override
  State<Workspace> createState() => _WorkspaceState();
}

class _WorkspaceState extends State<Workspace> {
  final api = Api();
  Json? user;
  bool checking = true, ko = false, busy = false, aiReady = false;
  int tab = 0;
  final scroll = ScrollController();
  String t(String en, String kr) => ko ? kr : en;
  @override
  void initState() {
    super.initState();
    boot();
  }

  @override
  void dispose() {
    scroll.dispose();
    super.dispose();
  }

  Future<void> boot() async {
    try {
      await api.restore();
      final r = await api.request('/api/auth/me');
      user = Map<String, dynamic>.from(r['user']);
    } catch (_) {}
    try {
      final r = await api.request('/api/health');
      aiReady = r['aiConfigured'] == true;
    } catch (_) {}
    if (mounted) {
      setState(() => checking = false);
      if (user != null) await setupBasicInfo();
    }
  }

  Future<void> setupBasicInfo() async {
    try {
      final info = await api.request('/api/emergency-profile');
      if (!mounted || (info['name'] as String? ?? '').isNotEmpty) return;
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => EmergencyPage(api: api, signedIn: true, ko: ko),
        ),
      );
    } catch (_) {}
  }

  void notice(Object e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  Future<void> task(Future<void> Function() fn) async {
    if (busy) return;
    setState(() => busy = true);
    try {
      await fn();
    } catch (e) {
      notice(e);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> logout() async => task(() async {
    await api.request('/api/auth/logout', method: 'POST', body: {});
    await api.setToken(null);
    if (mounted) {
      setState(() {
        user = null;
        tab = 0;
      });
    }
  });
  @override
  Widget build(BuildContext context) {
    final labels = [
      t('Home', '홈'),
      t('Visit card', '방문 카드'),
      t('My health', '내 건강'),
      t('Community', '커뮤니티'),
      t('Hospitals', '병원 찾기'),
    ];
    final icons = [
      Icons.grid_view_rounded,
      Icons.description_outlined,
      Icons.favorite_border,
      Icons.people_outline,
      Icons.explore_outlined,
    ];
    final wide = MediaQuery.sizeOf(context).width > 900;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: cream,
        title: Row(
          children: [
            if (MediaQuery.sizeOf(context).width > 500)
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: green,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.add, color: lime),
              ),
            if (MediaQuery.sizeOf(context).width > 500)
              const SizedBox(width: 10),
            const Text(
              'MORI',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                letterSpacing: -1,
                color: ink,
              ),
            ),
          ],
        ),
        actions: [
          if (user != null)
            IconButton(
              tooltip: t('Mori friends', '모리 친구'),
              icon: const Icon(Icons.people_alt_outlined),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => FriendsPage(api: api, ko: ko),
                ),
              ),
            ),
          IconButton(
            tooltip: t('Watch & permissions', '워치 연동 · 권한'),
            icon: const Icon(Icons.watch_outlined),
            onPressed: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => WearablePage(ko: ko))),
          ),
          IconButton(
            tooltip: t('Emergency / My info', '긴급 연락 / 내 정보'),
            icon: const Icon(Icons.sos, color: Colors.red),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) =>
                    EmergencyPage(api: api, signedIn: user != null, ko: ko),
              ),
            ),
          ),
          TextButton.icon(
            onPressed: () => setState(() => ko = !ko),
            icon: const Icon(Icons.language, size: 18),
            label: Text(
              MediaQuery.sizeOf(context).width < 500
                  ? (ko ? 'EN' : 'KO')
                  : (ko ? 'English' : '한국어'),
            ),
          ),
          if (user != null)
            IconButton(
              tooltip: t('Sign out', '로그아웃'),
              onPressed: busy ? null : logout,
              icon: const Icon(Icons.logout),
            ),
        ],
      ),
      body: checking
          ? const Center(child: CircularProgressIndicator())
          : user == null
          ? Auth(
              api: api,
              ko: ko,
              onLogin: (u) async {
                if (mounted) setState(() => user = u);
                await setupBasicInfo();
                try {
                  final h = await api.request('/api/health');
                  if (mounted) {
                    setState(() => aiReady = h['aiConfigured'] == true);
                  }
                } catch (_) {}
              },
            )
          : Row(
              children: [
                if (wide)
                  NavigationRail(
                    selectedIndex: tab,
                    onDestinationSelected: selectTab,
                    labelType: NavigationRailLabelType.all,
                    destinations: List.generate(
                      5,
                      (i) => NavigationRailDestination(
                        icon: Icon(icons[i]),
                        label: Text(labels[i]),
                      ),
                    ),
                  ),
                Expanded(
                  child: SingleChildScrollView(
                    controller: scroll,
                    padding: EdgeInsets.all(wide ? 32 : 20),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 800),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            PresencePanel(
                              key: ValueKey(user!['id']),
                              api: api,
                              ko: ko,
                            ),
                            if (tab == 0) home(),
                            if (tab == 1)
                              VisitCards(api: api, ko: ko, aiReady: aiReady),
                            if (tab == 2) Health(api: api, ko: ko),
                            if (tab == 3)
                              Community(api: api, ko: ko, user: user!),
                            if (tab == 4) ...[
                              Hospitals(api: api, ko: ko),
                              const SizedBox(height: 24),
                              Guide(ko: ko),
                            ],
                            const SizedBox(height: 32),
                            Text(
                              '${user!['nickname']} · ${t('Private records stay private.', '개인 건강기록은 비공개입니다.')}',
                              style: const TextStyle(
                                color: Colors.black54,
                                fontSize: 12,
                              ),
                            ),
                            TextButton(
                              onPressed: busy ? null : deleteAccount,
                              child: Text(
                                t(
                                  'Delete my account and data',
                                  '계정 및 내 데이터 삭제',
                                ),
                                style: const TextStyle(
                                  color: Colors.black54,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
      bottomNavigationBar: user != null && !wide
          ? NavigationBar(
              selectedIndex: tab,
              onDestinationSelected: selectTab,
              destinations: List.generate(
                5,
                (i) => NavigationDestination(
                  icon: Icon(icons[i]),
                  label: labels[i],
                ),
              ),
            )
          : null,
    );
  }

  void selectTab(int i) {
    setState(() => tab = i);
    if (scroll.hasClients) scroll.jumpTo(0);
  }

  Future<void> deleteAccount() async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(t('Permanently delete your account?', '계정을 영구 삭제할까요?')),
        content: Text(
          t(
            'Your records, cards, posts and comments will be deleted. This cannot be undone.',
            '건강기록·카드·게시글·댓글이 삭제되며 되돌릴 수 없습니다.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: Text(t('Cancel', '취소')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(c, true),
            child: Text(t('Delete', '삭제')),
          ),
        ],
      ),
    );
    if (yes == true) {
      await task(() async {
        await api.request('/api/auth/me', method: 'DELETE');
        await api.setToken(null);
        if (mounted) setState(() => user = null);
      });
    }
  }

  Widget home() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      MoriHome(api: api, ko: ko),
      button(t('Prepare a visit card', '초진 준비 카드 만들기'), () => selectTab(1)),
      const SizedBox(height: 18),
      panel([
        const Icon(Icons.people_outline, color: green, size: 28),
        heading(t('From someone like you', '먼저 다녀온 친구에게')),
        Text(
          t(
            'Find experiences about reception, language and what to bring.',
            '접수·언어·준비물에 대한 이용 경험을 확인하세요.',
          ),
        ),
        button(t('Explore experiences', '이용 경험 보기'), () => selectTab(3)),
      ]),
      panel([
        heading(t('Your essentials, together', '나에게 필요한 건강정보')),
        Text(
          t(
            'Keep allergies, medication and daily check-ins ready for your next visit.',
            '알레르기·복용약과 일상 기록을 정리해두세요.',
          ),
        ),
        button(t('My health', '내 건강'), () => selectTab(2)),
      ]),
      if (!aiReady)
        info(
          t(
            'AI translation is not connected yet. Original-language cards and record storage are available.',
            'AI 번역은 아직 연결되지 않았습니다. 원문 카드와 기록 저장은 가능합니다.',
          ),
        ),
      Text(
        t(
          'MORI supports communication and access preparation. It does not diagnose or recommend medication.',
          '모리는 의료 이용 준비와 의사소통을 돕습니다. 진단이나 약 추천은 제공하지 않습니다.',
        ),
        style: const TextStyle(fontSize: 12, color: Colors.black54),
      ),
    ],
  );
}

Widget heading(String s) => Text(
  s,
  style: const TextStyle(
    fontSize: 23,
    fontWeight: FontWeight.w700,
    color: ink,
    letterSpacing: -.5,
  ),
);
Widget panel(List<Widget> children) => Container(
  margin: const EdgeInsets.only(bottom: 16),
  padding: const EdgeInsets.all(20),
  decoration: BoxDecoration(
    color: Colors.white,
    border: Border.all(color: const Color(0xFFDDE5D9)),
    borderRadius: BorderRadius.circular(20),
  ),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: children.expand((w) => [w, const SizedBox(height: 12)]).toList(),
  ),
);
Widget info(String s) => Container(
  margin: const EdgeInsets.only(bottom: 16),
  padding: const EdgeInsets.all(16),
  decoration: BoxDecoration(
    color: pale,
    borderRadius: BorderRadius.circular(12),
  ),
  child: Text(s, style: const TextStyle(color: green, fontSize: 13)),
);
Widget button(
  String title,
  VoidCallback? fn, {
  bool secondary = false,
}) => Padding(
  padding: const EdgeInsets.symmetric(vertical: 4),
  child: secondary
      ? OutlinedButton(
          onPressed: fn,
          child: Padding(padding: const EdgeInsets.all(12), child: Text(title)),
        )
      : FilledButton(
          onPressed: fn,
          child: Padding(padding: const EdgeInsets.all(12), child: Text(title)),
        ),
);
Widget field(
  String title,
  TextEditingController controller, {
  int lines = 1,
  bool secret = false,
  TextInputType? keyboard,
}) => Padding(
  padding: const EdgeInsets.only(bottom: 12),
  child: TextField(
    controller: controller,
    minLines: lines,
    maxLines: lines == 1 ? 1 : 4,
    obscureText: secret,
    keyboardType: keyboard,
    decoration: InputDecoration(labelText: title),
  ),
);
String today() => DateTime.now().toIso8601String().substring(0, 10);
String err(Object e) => e.toString().replaceFirst('Exception: ', '');

class Auth extends StatefulWidget {
  final Api api;
  final bool ko;
  final void Function(Json) onLogin;
  const Auth({
    super.key,
    required this.api,
    required this.ko,
    required this.onLogin,
  });
  @override
  State<Auth> createState() => _AuthState();
}

class _AuthState extends State<Auth> {
  final email = TextEditingController(),
      password = TextEditingController(),
      nickname = TextEditingController();
  bool registering = false, busy = false;
  String error = '';
  String t(String a, String b) => widget.ko ? b : a;
  @override
  void dispose() {
    email.dispose();
    password.dispose();
    nickname.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    setState(() {
      busy = true;
      error = '';
    });
    try {
      final r = await widget.api.request(
        '/api/auth/${registering ? 'register' : 'login'}',
        method: 'POST',
        body: {
          'email': email.text.trim(),
          'password': password.text,
          if (registering) 'nickname': nickname.text.trim(),
        },
      );
      if (r['token'] != null) await widget.api.setToken(r['token']);
      if (mounted) widget.onLogin(Map<String, dynamic>.from(r['user']));
    } catch (e) {
      if (mounted) setState(() => error = err(e));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.all(24),
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 450),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 30),
            const Text(
              'CARE WITHOUT BORDERS',
              style: TextStyle(letterSpacing: 2, color: green),
            ),
            const SizedBox(height: 20),
            heading(
              t(
                'A familiar hand\nin an unfamiliar place.',
                '낯선 곳에서도\n든든한 의료 길잡이.',
              ),
            ),
            const SizedBox(height: 24),
            panel([
              heading(
                registering
                    ? t('Join CareBridge', 'CareBridge 가입')
                    : t('Welcome back', '다시 만나 반가워요'),
              ),
              if (registering)
                field(t('Nickname (public)', '별명 (게시물에 공개)'), nickname),
              field(
                t('Email', '이메일'),
                email,
                keyboard: TextInputType.emailAddress,
              ),
              field(t('Password', '비밀번호'), password, secret: true),
              if (registering)
                Text(
                  t(
                    'Use 10+ characters. Prototype: email verification and password recovery are not available. Use fictional test data.',
                    '10자 이상. 시제품은 이메일 인증·비밀번호 찾기를 지원하지 않습니다. 가상 정보로 시험하세요.',
                  ),
                  style: const TextStyle(fontSize: 12),
                ),
              if (error.isNotEmpty) info(error),
              button(
                busy
                    ? t('Please wait…', '처리 중…')
                    : registering
                    ? t('Create account', '계정 만들기')
                    : t('Sign in', '로그인'),
                busy ? null : submit,
              ),
              button(
                registering
                    ? t('Already registered? Sign in', '이미 가입했나요? 로그인')
                    : t('Create an account', '새 계정 만들기'),
                busy ? null : () => setState(() => registering = !registering),
                secondary: true,
              ),
            ]),
            Text(
              t(
                'Private health records stay separate from public community posts.',
                '개인 건강기록은 공개 커뮤니티와 분리됩니다.',
              ),
              style: const TextStyle(color: Colors.black54, fontSize: 12),
            ),
          ],
        ),
      ),
    ),
  );
}

abstract class ScreenState<T extends StatefulWidget> extends State<T> {
  bool busy = false;
  String error = '', message = '';
  Future<void> run(Future<void> Function() fn) async {
    if (busy) return;
    setState(() {
      busy = true;
      error = '';
      message = '';
    });
    try {
      await fn();
    } catch (e) {
      if (mounted) setState(() => error = err(e));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  List<Widget> get feedback => [
    if (busy) const LinearProgressIndicator(),
    if (error.isNotEmpty) info(error),
    if (message.isNotEmpty) info(message),
  ];
}

class Health extends StatefulWidget {
  final Api api;
  final bool ko;
  const Health({super.key, required this.api, required this.ko});
  @override
  State<Health> createState() => _HealthState();
}

class _HealthState extends ScreenState<Health> {
  Json profile = {
    'allergies': {'status': 'unknown', 'detail': ''},
    'medications': {'status': 'unknown', 'detail': ''},
  };
  final allergy = TextEditingController(),
      medication = TextEditingController(),
      date = TextEditingController(text: today()),
      sleep = TextEditingController(text: '7'),
      note = TextEditingController();
  List<dynamic> journals = [];
  String condition = 'okay';
  bool loaded = false;
  String t(String a, String b) => widget.ko ? b : a;
  @override
  void initState() {
    super.initState();
    load();
  }

  @override
  void dispose() {
    for (final c in [allergy, medication, date, sleep, note]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> load() => run(() async {
    final values = await Future.wait([
      widget.api.request('/api/profile'),
      widget.api.request('/api/journals'),
    ]);
    if (!mounted) return;
    setState(() {
      profile = Map<String, dynamic>.from(values[0]);
      journals = values[1];
      allergy.text = profile['allergies']['detail'];
      medication.text = profile['medications']['detail'];
      loaded = true;
    });
  });
  Widget knowledge(
    String key,
    String title,
    TextEditingController controller,
  ) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      Wrap(
        spacing: 8,
        children: ['unknown', 'none', 'known']
            .map(
              (v) => ChoiceChip(
                label: Text(
                  v == 'unknown'
                      ? t('Not sure', '모름')
                      : v == 'none'
                      ? t('None', '없음')
                      : t('Add details', '있음'),
                ),
                selected: profile[key]['status'] == v,
                onSelected: busy
                    ? null
                    : (_) => setState(() => profile[key]['status'] = v),
              ),
            )
            .toList(),
      ),
      if (profile[key]['status'] == 'known')
        field(t('Details / names and doses', '상세 / 약명·용량'), controller),
    ],
  );
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      heading(t('My health', '내 건강정보')),
      const SizedBox(height: 12),
      ...feedback,
      if (!loaded) button(t('Load records', '기록 불러오기'), busy ? null : load),
      if (loaded) ...[
        panel([
          info(t('PRIVATE · Visible only to you', '비공개 · 본인만 볼 수 있어요')),
          knowledge('allergies', t('Allergies', '알레르기'), allergy),
          knowledge(
            'medications',
            t('Current medication', '현재 복용약'),
            medication,
          ),
          button(
            t('Save profile', '건강정보 저장'),
            busy
                ? null
                : () => run(() async {
                    profile['allergies']['detail'] = allergy.text;
                    profile['medications']['detail'] = medication.text;
                    await widget.api.request(
                      '/api/profile',
                      method: 'PUT',
                      body: profile,
                    );
                    if (mounted) {
                      setState(() => message = t('Profile saved.', '저장했습니다.'));
                    }
                  }),
          ),
        ]),
        panel([
          heading(t('Daily check-in', '일상 기록')),
          field(t('Date (YYYY-MM-DD)', '날짜 (YYYY-MM-DD)'), date),
          Wrap(
            spacing: 8,
            children: ['good', 'okay', 'low']
                .map(
                  (v) => ChoiceChip(
                    label: Text(
                      v == 'good'
                          ? t('Good', '좋음')
                          : v == 'okay'
                          ? t('Okay', '보통')
                          : t('Low', '좋지 않음'),
                    ),
                    selected: condition == v,
                    onSelected: (_) => setState(() => condition = v),
                  ),
                )
                .toList(),
          ),
          field(
            t('Sleep hours (0–24)', '수면 시간 (0~24)'),
            sleep,
            keyboard: TextInputType.number,
          ),
          field(t('Notes', '메모'), note, lines: 3),
          button(
            t('Save check-in', '일상 기록 저장'),
            busy
                ? null
                : () => run(() async {
                    final hours = double.tryParse(sleep.text);
                    if (hours == null) {
                      throw Exception(t('Enter sleep hours.', '수면 시간을 입력하세요.'));
                    }
                    await widget.api.request(
                      '/api/journals',
                      method: 'POST',
                      body: {
                        'date': date.text,
                        'condition': condition,
                        'sleep': hours,
                        'note': note.text,
                      },
                    );
                    final j = await widget.api.request('/api/journals');
                    if (mounted) {
                      setState(() {
                        journals = j;
                        note.clear();
                        message = t('Check-in saved.', '기록을 저장했습니다.');
                      });
                    }
                  }),
          ),
        ]),
        heading(t('Recent check-ins', '최근 기록')),
        const SizedBox(height: 12),
        if (journals.isEmpty) Text(t('No records yet.', '아직 기록이 없습니다.')),
        ...journals.map(
          (j) => panel([
            Text(
              '${j['date']} · ${j['condition']} · ${j['sleep']}h',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            Text(j['note']),
            Text(
              t(
                'Existing cards keep their saved snapshot. Delete the card separately to remove it.',
                '기존 카드의 사본은 유지됩니다. 해당 카드도 별도로 삭제하세요.',
              ),
              style: const TextStyle(fontSize: 11, color: Colors.black54),
            ),
            button(
              t('Delete check-in', '기록 삭제'),
              busy
                  ? null
                  : () => run(() async {
                      await widget.api.request(
                        '/api/journals/${j['id']}',
                        method: 'DELETE',
                      );
                      if (mounted) {
                        setState(
                          () => journals.removeWhere((v) => v['id'] == j['id']),
                        );
                      }
                    }),
              secondary: true,
            ),
          ]),
        ),
      ],
    ],
  );
}

class VisitCards extends StatefulWidget {
  final Api api;
  final bool ko, aiReady;
  const VisitCards({
    super.key,
    required this.api,
    required this.ko,
    required this.aiReady,
  });
  @override
  State<VisitCards> createState() => _VisitCardsState();
}

class _VisitCardsState extends ScreenState<VisitCards> {
  final symptoms = TextEditingController(), onset = TextEditingController();
  List<dynamic> cards = [], journals = [];
  final selected = <String>{};
  bool consent = false, reviewed = false;
  Json? current;
  final edits = <String, TextEditingController>{};
  String t(String a, String b) => widget.ko ? b : a;
  @override
  void initState() {
    super.initState();
    load();
  }

  @override
  void dispose() {
    symptoms.dispose();
    onset.dispose();
    for (final c in edits.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> load() => run(() async {
    final r = await Future.wait([
      widget.api.request('/api/cards'),
      widget.api.request('/api/journals'),
    ]);
    if (mounted) {
      setState(() {
        cards = r[0];
        journals = r[1];
      });
    }
  });
  void open(Json card) {
    for (final c in edits.values) {
      c.dispose();
    }
    edits.clear();
    final tr = card['translation'];
    if (tr != null) {
      for (final k in [
        'symptomsKo',
        'onsetKo',
        'allergiesKo',
        'medicationsKo',
      ]) {
        edits[k] = TextEditingController(text: tr[k]);
      }
      for (final j in tr['journalKo']) {
        edits[j['id']] = TextEditingController(text: j['textKo']);
      }
    }
    setState(() {
      current = card;
      reviewed = false;
      error = '';
    });
  }

  String knowledge(dynamic v) => v['status'] == 'known'
      ? v['detail']
      : v['status'] == 'none'
      ? t('None (user reported)', '없음 (사용자 입력)')
      : t('Unknown', '모름');
  String summary() {
    final c = current!, s = c['snapshot'];
    final tr = c['translation'];
    return 'CareBridge · ${c['mode'] == 'ai' ? (c['confirmedAt'] == null ? 'AI draft · unreviewed' : 'User-reviewed translation') : 'Original · not translated'}\n${c['createdAt']}\n\nSymptoms: ${s['symptoms']}\nOnset: ${s['onset']}\nAllergies: ${knowledge(s['profile']['allergies'])}\nMedication: ${knowledge(s['profile']['medications'])}\n${(s['journals'] as List).map((j) => '${j['date']} · ${j['condition']} · ${j['sleep']}h\n${j['note']}').join('\n')}\n${tr == null ? '' : '\n한국어\n증상: ${tr['symptomsKo']}\n시작: ${tr['onsetKo']}\n알레르기: ${tr['allergiesKo']}\n복용약: ${tr['medicationsKo']}\n${(tr['journalKo'] as List).map((j) => j['textKo']).join('\n')}'}';
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      heading(t('Your visit card', '나를 설명하는 방문 카드')),
      const SizedBox(height: 12),
      ...feedback,
      if (current == null) ...[
        panel([
          info(
            t('PRIVATE · Not posted to the community', '비공개 · 커뮤니티에 게시되지 않습니다'),
          ),
          field(
            t('What would you like to tell the clinician?', '의료진에게 전할 증상'),
            symptoms,
            lines: 3,
          ),
          field(t('When did it start?', '언제부터 시작됐나요?'), onset),
          Text(
            t('Select check-ins to include (up to 7)', '포함할 일상 기록 선택 (최대 7개)'),
          ),
          ...journals.map(
            (j) => CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              title: Text('${j['date']} · ${j['condition']}'),
              subtitle: Text(j['note']),
              value: selected.contains(j['id']),
              onChanged: busy
                  ? null
                  : (v) => setState(() {
                      if (v == true && selected.length < 7) {
                        selected.add(j['id']);
                      } else {
                        selected.remove(j['id']);
                      }
                    }),
            ),
          ),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            value: consent,
            onChanged: (v) => setState(() => consent = v ?? false),
            title: Text(
              t(
                'Save my health information as a private card. If I choose AI translation, selected health content is sent to the configured AI provider, without my name or email.',
                '이 정보를 비공개 카드로 저장하는 데 동의합니다. AI 번역을 선택하면 건강정보가 AI 제공자에게 전송되며 이름·이메일은 제외됩니다.',
              ),
              style: const TextStyle(fontSize: 13),
            ),
          ),
          button(
            t('Save original card', '원문 카드 저장'),
            busy || !consent
                ? null
                : () => run(() async {
                    final c = await widget.api.request(
                      '/api/cards',
                      method: 'POST',
                      body: {
                        'symptoms': symptoms.text,
                        'onset': onset.text,
                        'journalIds': selected.toList(),
                        'consent': consent,
                      },
                    );
                    if (mounted) {
                      cards.insert(0, c);
                      open(Map<String, dynamic>.from(c));
                    }
                  }),
          ),
        ]),
        heading(t('Saved cards', '저장한 카드')),
        const SizedBox(height: 12),
        ...cards.map(
          (c) => panel([
            Text(
              c['snapshot']['symptoms'],
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            Text(
              c['mode'] == 'original'
                  ? t('Original · not translated', '원문 · 번역 안 됨')
                  : c['confirmedAt'] == null
                  ? t('AI draft · review needed', 'AI 초안 · 확인 필요')
                  : t('User reviewed', '사용자 확인 완료'),
            ),
            button(
              t('Open card', '카드 열기'),
              () => open(Map<String, dynamic>.from(c)),
              secondary: true,
            ),
          ]),
        ),
      ] else ...[
        button(
          t('Back to cards', '카드 목록으로'),
          busy ? null : () => setState(() => current = null),
          secondary: true,
        ),
        panel([
          info(
            current!['mode'] == 'original'
                ? t('ORIGINAL · NOT TRANSLATED', '원문 · 번역 안 됨')
                : current!['confirmedAt'] == null
                ? t('AI DRAFT · REVIEW NEEDED', 'AI 초안 · 확인 필요')
                : t('USER REVIEWED', '사용자 확인 완료'),
          ),
          heading(t('Your original information', '입력한 원문')),
          Text(current!['snapshot']['symptoms']),
          Text('${t('Started', '시작')}: ${current!['snapshot']['onset']}'),
          Text(
            '${t('Allergies', '알레르기')}: ${knowledge(current!['snapshot']['profile']['allergies'])}',
          ),
          Text(
            '${t('Medication', '복용약')}: ${knowledge(current!['snapshot']['profile']['medications'])}',
          ),
          ...(current!['snapshot']['journals'] as List).map(
            (j) => Text('${j['date']} · ${j['sleep']}h\n${j['note']}'),
          ),
        ]),
        if (edits.isNotEmpty)
          panel([
            heading(t('Compare and edit the translation', '번역을 비교하고 수정하세요')),
            for (final item in edits.entries)
              field(
                {
                      'symptomsKo': t('Symptoms', '증상'),
                      'onsetKo': t('Onset', '시작 시점'),
                      'allergiesKo': t('Allergies', '알레르기'),
                      'medicationsKo': t('Medication', '복용약'),
                    }[item.key] ??
                    t('Selected check-in', '선택 기록'),
                item.value,
                lines: 2,
              ),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: reviewed,
              onChanged: (v) => setState(() => reviewed = v ?? false),
              title: Text(
                t(
                  'I compared the translation with my original. This is a personal review, not medical verification.',
                  '원문과 대조해 확인했습니다. 사용자 확인이며 의학적 검증을 의미하지 않습니다.',
                ),
              ),
            ),
            button(
              t('Save reviewed translation', '확인한 번역 저장'),
              busy || !reviewed
                  ? null
                  : () => run(() async {
                      final tr = Map<String, dynamic>.from(
                        current!['translation'],
                      );
                      for (final k in [
                        'symptomsKo',
                        'onsetKo',
                        'allergiesKo',
                        'medicationsKo',
                      ]) {
                        tr[k] = edits[k]!.text;
                      }
                      tr['journalKo'] = (tr['journalKo'] as List)
                          .map(
                            (j) => {
                              'id': j['id'],
                              'textKo': edits[j['id']]!.text,
                            },
                          )
                          .toList();
                      final c = await widget.api.request(
                        '/api/cards/${current!['id']}/confirm',
                        method: 'PUT',
                        body: {...tr, 'reviewed': reviewed},
                      );
                      if (mounted) open(Map<String, dynamic>.from(c));
                    }),
            ),
          ]),
        if (!widget.aiReady)
          info(
            t(
              'AI is not connected. Your original-language card remains available.',
              'AI 미연결 상태입니다. 원문 카드는 사용할 수 있습니다.',
            ),
          ),
        button(
          t('Translate with AI', 'AI로 번역하기'),
          busy || !widget.aiReady
              ? null
              : () => run(() async {
                  final c = await widget.api.request(
                    '/api/cards/${current!['id']}/translate',
                    method: 'POST',
                    body: {},
                  );
                  if (mounted) open(Map<String, dynamic>.from(c));
                }),
        ),
        button(
          t('Show large card', '큰 글씨로 보여주기'),
          () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (c) => Scaffold(
                appBar: AppBar(title: const Text('MORI')),
                body: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: SelectableText(
                    summary(),
                    style: const TextStyle(fontSize: 24, height: 1.6),
                  ),
                ),
              ),
            ),
          ),
          secondary: true,
        ),
        button(
          t('Copy saved card', '저장한 카드 복사'),
          () => run(() async {
            await Clipboard.setData(ClipboardData(text: summary()));
            if (mounted) setState(() => message = t('Copied.', '복사했습니다.'));
          }),
          secondary: true,
        ),
        Text(
          t(
            'Large view and copy use saved edits. Save changes before sharing.',
            '큰 글씨와 복사는 저장한 버전을 사용합니다. 수정 후 먼저 저장하세요.',
          ),
          style: const TextStyle(fontSize: 12),
        ),
        button(
          t('Delete card', '카드 삭제'),
          busy
              ? null
              : () => run(() async {
                  await widget.api.request(
                    '/api/cards/${current!['id']}',
                    method: 'DELETE',
                  );
                  final c = await widget.api.request('/api/cards');
                  if (mounted) {
                    setState(() {
                      cards = c;
                      current = null;
                    });
                  }
                }),
          secondary: true,
        ),
      ],
    ],
  );
}

class Community extends StatefulWidget {
  final Api api;
  final bool ko;
  final Json user;
  const Community({
    super.key,
    required this.api,
    required this.ko,
    required this.user,
  });
  @override
  State<Community> createState() => _CommunityState();
}

class _CommunityState extends ScreenState<Community> {
  final query = TextEditingController(),
      title = TextEditingController(),
      place = TextEditingController(),
      date = TextEditingController(text: today()),
      body = TextEditingController(),
      comment = TextEditingController();
  List<dynamic> posts = [], comments = [];
  Json? current;
  bool writing = false, consent = false;
  String? editId;
  String filter = '', language = 'English', method = 'translation';
  String t(String a, String b) => widget.ko ? b : a;
  @override
  void initState() {
    super.initState();
    load();
  }

  @override
  void dispose() {
    for (final c in [query, title, place, date, body, comment]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> load() => run(() async {
    final p = await widget.api.request(
      '/api/posts?q=${Uri.encodeComponent(query.text)}&language=$filter',
    );
    if (mounted) setState(() => posts = p);
  });
  Future<void> open(Json p) => run(() async {
    final c = await widget.api.request('/api/posts/${p['id']}/comments');
    if (mounted) {
      setState(() {
        current = p;
        comments = c;
      });
    }
  });
  void write([Json? p]) {
    setState(() {
      writing = true;
      editId = p?['id'];
      title.text = p?['title'] ?? '';
      place.text = p?['place'] ?? '';
      date.text = p?['visitDate'] ?? today();
      body.text = p?['body'] ?? '';
      language = p?['language'] ?? 'English';
      method = p?['method'] ?? 'translation';
      consent = false;
    });
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      heading(t('Someone has been there.', '먼저 다녀온 친구의 이야기.')),
      const SizedBox(height: 12),
      ...feedback,
      if (writing)
        panel([
          heading(
            editId == null
                ? t('Share a visit experience', '의료 이용 경험 남기기')
                : t('Edit experience', '경험 수정'),
          ),
          field(t('Title', '제목'), title),
          field(t('Clinic, pharmacy or campus service', '병원·약국·교내 기관'), place),
          field(t('Visit date (YYYY-MM-DD)', '방문일 (YYYY-MM-DD)'), date),
          DropdownButtonFormField<String>(
            initialValue: language,
            decoration: InputDecoration(
              labelText: t('Language used', '사용한 언어'),
            ),
            items: [
              'English',
              'Korean',
              'Other',
            ].map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
            onChanged: (v) => setState(() => language = v!),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: method,
            decoration: InputDecoration(
              labelText: t('Communication method', '의사소통 방법'),
            ),
            items: [
              DropdownMenuItem(
                value: 'direct',
                child: Text(t('Direct conversation', '직접 대화')),
              ),
              DropdownMenuItem(
                value: 'translation',
                child: Text(t('Translation app', '번역 앱')),
              ),
              DropdownMenuItem(
                value: 'friend',
                child: Text(t('With a friend', '친구 도움')),
              ),
            ],
            onChanged: (v) => setState(() => method = v!),
          ),
          const SizedBox(height: 12),
          field(
            t('Process, communication and tips', '이용 절차·의사소통·팁'),
            body,
            lines: 3,
          ),
          CheckboxListTile(
            value: consent,
            onChanged: (v) => setState(() => consent = v ?? false),
            title: Text(
              t(
                'This is my experience and I agree to publish it. I removed other people’s private information.',
                '직접 겪은 경험 게시에 동의하며 다른 사람의 개인정보를 제외했습니다.',
              ),
            ),
          ),
          button(
            t('Publish', '게시하기'),
            busy || !consent
                ? null
                : () => run(() async {
                    await widget.api.request(
                      editId == null ? '/api/posts' : '/api/posts/$editId',
                      method: editId == null ? 'POST' : 'PUT',
                      body: {
                        'title': title.text,
                        'body': body.text,
                        'place': place.text,
                        'visitDate': date.text,
                        'language': language,
                        'method': method,
                        'consent': consent,
                      },
                    );
                    final p = await widget.api.request('/api/posts');
                    if (mounted) {
                      setState(() {
                        posts = p;
                        writing = false;
                        current = null;
                      });
                    }
                  }),
          ),
          button(
            t('Cancel', '취소'),
            () => setState(() => writing = false),
            secondary: true,
          ),
        ])
      else if (current != null) ...[
        button(
          t('Back to community', '커뮤니티 목록으로'),
          () => setState(() => current = null),
          secondary: true,
        ),
        panel([
          heading(current!['title']),
          Text('${current!['author']} · ${current!['place']}'),
          Text(
            '${current!['visitDate']} · ${current!['language']} · ${current!['method']}',
          ),
          Text(current!['body']),
          info(
            t(
              'One person’s experience on this visit date. Confirm current language support and availability directly.',
              '해당 방문일의 개인 경험입니다. 현재 언어 지원과 운영 상황은 기관에 직접 확인하세요.',
            ),
          ),
          if (current!['authorId'] == widget.user['id']) ...[
            button(
              t('Edit my experience', '내 경험 수정'),
              () => write(current),
              secondary: true,
            ),
            button(
              t('Delete my experience', '내 경험 삭제'),
              busy
                  ? null
                  : () => run(() async {
                      await widget.api.request(
                        '/api/posts/${current!['id']}',
                        method: 'DELETE',
                      );
                      final p = await widget.api.request('/api/posts');
                      if (mounted) {
                        setState(() {
                          posts = p;
                          current = null;
                        });
                      }
                    }),
              secondary: true,
            ),
          ] else
            button(t('Report this post', '게시물 신고'), report, secondary: true),
        ]),
        heading(t('Questions & conversation', '질문과 답변')),
        const SizedBox(height: 12),
        ...comments.map(
          (c) => panel([
            Text(
              c['author'],
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            Text(c['body']),
            if (c['authorId'] == widget.user['id'])
              button(
                t('Delete comment', '댓글 삭제'),
                busy
                    ? null
                    : () => run(() async {
                        await widget.api.request(
                          '/api/comments/${c['id']}',
                          method: 'DELETE',
                        );
                        if (mounted) {
                          setState(
                            () =>
                                comments.removeWhere((v) => v['id'] == c['id']),
                          );
                        }
                      }),
                secondary: true,
              ),
          ]),
        ),
        panel([
          field(
            t(
              'Ask about reception, language or what to bring',
              '접수·언어·준비물에 관해 질문하기',
            ),
            comment,
            lines: 2,
          ),
          button(
            t('Post comment', '댓글 등록'),
            busy
                ? null
                : () => run(() async {
                    final c = await widget.api.request(
                      '/api/posts/${current!['id']}/comments',
                      method: 'POST',
                      body: {'body': comment.text},
                    );
                    if (mounted) {
                      setState(() {
                        comments.add(c);
                        comment.clear();
                      });
                    }
                  }),
          ),
        ]),
      ] else ...[
        button(t('Share a visit experience', '이용 경험 남기기'), () => write()),
        panel([
          field(t('Search experiences', '이용 경험 검색'), query),
          DropdownButtonFormField<String>(
            initialValue: filter,
            items: ['', 'English', 'Korean', 'Other']
                .map(
                  (v) => DropdownMenuItem(
                    value: v,
                    child: Text(v.isEmpty ? t('All languages', '전체 언어') : v),
                  ),
                )
                .toList(),
            onChanged: (v) => setState(() => filter = v!),
          ),
          button(t('Search', '검색'), busy ? null : load, secondary: true),
        ]),
        if (posts.isEmpty)
          info(
            t(
              'No experiences yet. Share your visit to help the next student.',
              '아직 이용 경험이 없습니다. 다음 학생을 위해 경험을 나눠주세요.',
            ),
          ),
        ...posts.map(
          (p) => panel([
            Text(
              '${p['language']} · ${p['visitDate']}',
              style: const TextStyle(color: green, fontSize: 12),
            ),
            heading(p['title']),
            Text('${p['place']} · ${p['author']}'),
            Text(p['body'], maxLines: 3, overflow: TextOverflow.ellipsis),
            button(
              '${t('Read experience', '경험 읽기')} · ${p['commentCount']}',
              busy ? null : () => open(Map<String, dynamic>.from(p)),
              secondary: true,
            ),
          ]),
        ),
      ],
    ],
  );
  Future<void> report() async {
    final reason = await showDialog<String>(
      context: context,
      builder: (c) => SimpleDialog(
        title: Text(t('Report reason', '신고 사유')),
        children: ['privacy', 'misinformation', 'spam', 'other']
            .map(
              (v) => SimpleDialogOption(
                onPressed: () => Navigator.pop(c, v),
                child: Text(v),
              ),
            )
            .toList(),
      ),
    );
    if (reason != null) {
      await run(() async {
        await widget.api.request(
          '/api/posts/${current!['id']}/reports',
          method: 'POST',
          body: {'reason': reason, 'detail': ''},
        );
        if (mounted) {
          setState(
            () => message = t(
              'Report saved for manual operator review.',
              '운영자 수동 검토를 위해 신고를 저장했습니다.',
            ),
          );
        }
      });
    }
  }
}

class Guide extends StatelessWidget {
  final bool ko;
  const Guide({super.key, required this.ko});
  String t(String a, String b) => ko ? b : a;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      heading(t('A little preparation helps.', '방문 전 차근차근 준비해요.')),
      const SizedBox(height: 16),
      panel([
        Text(
          t(
            '1. Confirm opening hours and language support directly.',
            '1. 운영시간과 언어 지원을 기관에 확인하세요.',
          ),
        ),
        Text(
          t(
            '2. Ask what identification and insurance documents to bring.',
            '2. 필요한 신분증·보험 서류를 확인하세요.',
          ),
        ),
        Text(
          t(
            '3. Prepare symptom onset, allergies and medication.',
            '3. 증상 시작 시점·알레르기·복용약을 준비하세요.',
          ),
        ),
        Text(
          t(
            '4. Compare the translated card with your original before showing it.',
            '4. 카드를 보여주기 전 원문과 번역을 비교하세요.',
          ),
        ),
      ]),
      panel([
        heading('Medical Korea'),
        Text(
          t(
            'Official information about medical services in Korea.',
            '한국 의료 이용에 관한 공식 정보',
          ),
        ),
        button(
          t('Open official website', '공식 사이트 열기'),
          () => launchUrl(Uri.parse('https://www.medicalkorea.or.kr/en/index')),
          secondary: true,
        ),
      ]),
      panel([
        heading(t('Handong University', '한동대학교')),
        Text(
          t(
            'Find current campus notices and service contact information.',
            '교내 최신 공지와 기관 연락처를 확인하세요.',
          ),
        ),
        button(
          t('Open university website', '학교 사이트 열기'),
          () => launchUrl(Uri.parse('https://www.handong.edu/')),
          secondary: true,
        ),
      ]),
      info(
        t(
          'A verified local provider directory is still being prepared. Opening hours and language support are not generated with AI.',
          '지역 의료기관 목록은 조사 중입니다. 운영시간·언어 지원을 AI로 생성하지 않습니다.',
        ),
      ),
    ],
  );
}
