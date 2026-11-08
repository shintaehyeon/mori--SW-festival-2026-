import 'startup_cover.dart';
import 'clinic_reviews.dart';
import 'gentle_attention.dart';
import 'voice_answer.dart';
import 'question_sources.dart';
import 'google_auth_button.dart';
import 'visit_body_map.dart';
import 'localization.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'api.dart';
import 'emergency.dart';
import 'mori.dart';
import 'tutorial.dart';
import 'hospitals.dart';
import 'visit_pdf.dart';
import 'visit_preparation.dart';
import 'visit_sheet_page.dart';

const ink = Color(0xFF193B32);
const green = Color(0xFF21664F);
const cream = Color(0xFFF6F8F2);
const pale = Color(0xFFEDF3E8);
const lime = Color(0xFFFFDEBD);
typedef Json = Map<String, dynamic>;
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await MoriLanguage.initialize();
  runApp(const CareBridgeApp());
}

class CareBridgeApp extends StatelessWidget {
  const CareBridgeApp({super.key});
  @override
  Widget build(BuildContext context) => ValueListenableBuilder<String>(
    valueListenable: MoriLanguage.current,
    builder: (context, language, _) => MaterialApp(
      locale: Locale(language),
      supportedLocales: MoriLanguage.names.keys
          .map((code) => Locale(code))
          .toList(),
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      title: 'MORI · Puchipa',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'MoriSans',
        fontFamilyFallback: const ['MoriCJK'],
        navigationBarTheme: const NavigationBarThemeData(
          labelTextStyle: WidgetStatePropertyAll(
            TextStyle(fontSize: 12, height: 1.15),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            minimumSize: const Size(48, 52),
            textStyle: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              height: 1.4,
            ),
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: green,
            backgroundColor: pale,
            side: BorderSide.none,
            minimumSize: const Size(48, 52),
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            textStyle: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              height: 1.4,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: green,
            minimumSize: const Size(48, 48),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
            textStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
        ),
        colorScheme: ColorScheme.fromSeed(
          seedColor: green,
          primary: const Color(0xFF21664F),
          surface: Colors.white,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: cream,
          foregroundColor: ink,
          surfaceTintColor: Colors.transparent,
        ),
        dividerTheme: const DividerThemeData(color: Color(0xFFE0E8DE)),
        chipTheme: const ChipThemeData(side: BorderSide.none),
        scaffoldBackgroundColor: cream,
        textTheme: const TextTheme(
          headlineSmall: TextStyle(
            color: ink,
            fontSize: 28,
            height: 1.25,
            fontWeight: FontWeight.w700,
          ),
          titleLarge: TextStyle(
            color: ink,
            fontSize: 22,
            height: 1.3,
            fontWeight: FontWeight.w700,
          ),
          titleMedium: TextStyle(
            color: ink,
            fontSize: 16,
            height: 1.4,
            fontWeight: FontWeight.w600,
          ),
          bodyMedium: TextStyle(color: ink, fontSize: 14, height: 1.5),
          bodySmall: TextStyle(
            color: Color(0xFF68796D),
            fontSize: 12,
            height: 1.45,
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFFF6F8F2),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFFDDE5D9)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFFDDE5D9)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: green, width: 1.5),
          ),
          contentPadding: const EdgeInsets.all(15),
        ),
      ),
      home: const StartupCover(child: Workspace()),
    ),
  );
}

class Workspace extends StatefulWidget {
  final Api? api;
  const Workspace({super.key, this.api});
  @override
  State<Workspace> createState() => _WorkspaceState();
}

class _WorkspaceState extends State<Workspace> {
  // Hidden for submission until tutorial playback is reliable on the demo device.
  static const bool showTutorial = false;
  static const bool showCommunity = false;
  late final Api api = widget.api ?? Api();
  Json? user;
  Map<String, dynamic>? visitHospital;
  void openGuestHospitals() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (routeContext) => Scaffold(
          appBar: AppBar(title: Text(t('Find care', '병원 찾기'))),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Hospitals(
              api: api,
              ko: ko,
              canReadExperiences: user != null && user!['isGuest'] != true,
              onSignIn: () {
                Navigator.of(routeContext).pop();
                setState(() {
                  entry = false;
                  tab = 3;
                });
              },
              onPrepare: (hospital) {
                Navigator.of(routeContext).pop();
                setState(() {
                  visitHospital = hospital;
                  entry = false;
                  tab = 1;
                });
              },
            ),
          ),
        ),
      ),
    );
  }

  bool entry = true;
  bool checking = true, busy = false, aiReady = false;
  bool get ko => MoriLanguage.current.value == 'ko';
  int tab = 0;
  final scroll = ScrollController();
  String t(String en, String kr) => tr(en, kr);
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

  Future<void> ensureEmergencySession() async {
    if (user != null) return;
    final r = await api.request(
      '/api/auth/guest',
      method: 'POST',
      body: {'consent': true},
    );
    if (r['token'] != null) await api.setToken(r['token']);
    if (mounted) setState(() => user = Map<String, dynamic>.from(r['user']));
  }

  Future<void> startGuest() => task(() async {
    final r = await api.request(
      '/api/auth/guest',
      method: 'POST',
      body: {'consent': true},
    );
    if (r['token'] != null) await api.setToken(r['token']);
    if (mounted) {
      setState(() {
        user = Map<String, dynamic>.from(r['user']);
        entry = false;
        tab = 1;
      });
    }
  });

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
      // Keep the initial emergency / regular-care choice visible on entry.
    }
  }

  Future<void> openTutorial() async {
    final start = await Navigator.of(
      context,
    ).push<bool>(MaterialPageRoute(builder: (_) => const MoriTutorial()));
    if (!mounted || start != true) return;
    setState(() {
      entry = false;
      tab = 1;
    });
  }

  Future<void> completeAuthentication(Json u, {bool registered = false}) async {
    if (!mounted) return;
    setState(() {
      user = u;
      if (registered || tab != 1) {
        entry = true;
        tab = 0;
        visitHospital = null;
      }
    });
    try {
      final h = await api.request('/api/health');
      if (mounted) setState(() => aiReady = h['aiConfigured'] == true);
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
      'Nav home',
      'Nav visit',
      'Nav health',
      'Nav community',
      'Nav hospitals',
    ].map(tr).toList();
    final icons = [
      Icons.grid_view_rounded,
      Icons.description_outlined,
      Icons.favorite_border,
      Icons.people_outline,
      Icons.explore_outlined,
    ];
    final visibleTabs = [0, 1, 2, if (showCommunity) 3, 4];
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
          IconButton(
            tooltip: t('Emergency / My info', '긴급 연락 / 내 정보'),
            icon: const Icon(Icons.sos, color: Colors.red),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => EmergencyPage(
                  api: api,
                  signedIn: user != null,
                  ko: ko,
                  onEnsureSession: ensureEmergencySession,
                ),
              ),
            ),
          ),
          LanguagePicker(
            onChanged: () {
              if (mounted) setState(() {});
            },
          ),
          if (user != null)
            IconButton(
              tooltip: t('Sign out', '로그아웃'),
              onPressed: busy ? null : logout,
              icon: const Icon(Icons.logout),
            ),
        ],
      ),
      body: entry
          ? Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                  child: Column(
                    children: [
                      Semantics(
                        label: 'MORI',
                        image: true,
                        child: SizedBox(
                          key: const ValueKey('entry-mori-character'),
                          width: 64,
                          height: 64,
                          child: const DoctorMori(),
                        ),
                      ),
                      Text(
                        t(
                          'Find a clinic. Explain your symptoms in Korean.',
                          '병원을 찾고,\n내 증상을 한국어로 전하세요.',
                        ),
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        t(
                          'Clinic visit help for Handong international students',
                          '한동대 유학생을 위한 병원 이용 도우미',
                        ),
                        textAlign: TextAlign.center,
                      ),
                      if (showTutorial)
                        TextButton.icon(
                          onPressed: openTutorial,
                          icon: const Icon(Icons.play_circle_outline),
                          label: Text(
                            t('Watch the 20-second tutorial', '20초 앱 사용법 보기'),
                          ),
                        ),
                    ],
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: entryHalf(
                            color: const Color(0xFFB3261E),
                            icon: Icons.emergency,
                            title: t('EMERGENCY', '긴급'),
                            subtitle: t('Emergency help · 119', '응급 도움 · 119'),
                            action: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => EmergencyPage(
                                  onEnsureSession: ensureEmergencySession,
                                  api: api,
                                  signedIn: user != null,
                                  ko: ko,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: entryHalf(
                            color: green,
                            icon: Icons.local_hospital_outlined,
                            title: t('Find a clinic', '병원 찾기'),
                            subtitle: t(
                              'Find a clinic · prepare a Korean visit sheet',
                              '병원 찾기 · 한국어 준비표 만들기',
                            ),
                            action: () {
                              if (user == null) {
                                openGuestHospitals();
                              } else {
                                setState(() {
                                  entry = false;
                                  tab = 4;
                                });
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            )
          : checking
          ? const Center(child: CircularProgressIndicator())
          : user == null
          ? SingleChildScrollView(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: panel([
                      heading(
                        visitHospital == null
                            ? t('How can we help today?', '어떤 도움이 필요한가요?')
                            : t(
                                'Prepare what to say next',
                                '이제 병원에 전할 말을 준비해요',
                              ),
                      ),
                      if (visitHospital != null) ...[
                        Text(
                          '${visitHospital!['name']} · ${visitHospital!['address']}',
                        ),
                        Text(
                          t(
                            'Continue as a guest. No account is needed for your visit sheet.',
                            '가입 없이 게스트로 방문 준비표를 만들 수 있어요.',
                          ),
                        ),
                      ],
                      button(
                        t('Continue as guest', '게스트로 방문 준비하기'),
                        busy ? null : startGuest,
                      ),
                      Text(
                        t(
                          'Guest sheets are stored privately on this server for up to 24 hours. Download your PDF before signing out or switching accounts. You can delete your data at any time.',
                          '게스트 준비표는 서버에 최대 24시간 비공개 보관됩니다. 로그아웃·계정 전환 전에 PDF를 내려받으세요. 언제든 데이터를 삭제할 수 있습니다.',
                        ),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black54,
                        ),
                      ),
                      TextButton(
                        onPressed: openGuestHospitals,
                        child: Text(t('Find a clinic', '병원 찾기')),
                      ),
                    ]),
                  ),
                  ExpansionTile(
                    title: Text(t('Sign in', '로그인')),
                    initiallyExpanded: tab == 3,
                    children: [
                      Auth(
                        api: api,
                        ko: ko,
                        onLogin: (u) => completeAuthentication(u),
                        onRegistered: (u) =>
                            completeAuthentication(u, registered: true),
                      ),
                    ],
                  ),
                ],
              ),
            )
          : Row(
              children: [
                if (wide)
                  NavigationRail(
                    selectedIndex: visibleTabs.indexOf(tab),
                    onDestinationSelected: (index) =>
                        selectTab(visibleTabs[index]),
                    labelType: NavigationRailLabelType.all,
                    destinations: List.generate(
                      visibleTabs.length,
                      (i) => NavigationRailDestination(
                        icon: Icon(icons[visibleTabs[i]]),
                        label: Text(labels[visibleTabs[i]]),
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
                            if (tab == 0) home(),
                            if (tab == 1)
                              VisitCards(
                                api: api,
                                ko: ko,
                                aiReady: aiReady,
                                destination: visitHospital,
                                onChooseHospital: () => selectTab(4),
                                onHome: () => selectTab(0),
                                canReview: user?['isGuest'] != true,
                              ),
                            if (tab == 2) Health(api: api, ko: ko),
                            if (showCommunity && tab == 3)
                              if (user!['isGuest'] == true)
                                panel([
                                  heading(
                                    t(
                                      'Sign in to share experiences',
                                      '방문 경험은 로그인 후 이용해요',
                                    ),
                                  ),
                                  Text(
                                    t(
                                      'Download your guest PDF before switching accounts. Guest records are not transferred.',
                                      '계정을 바꾸기 전에 게스트 PDF를 저장하세요. 게스트 기록은 이전되지 않습니다.',
                                    ),
                                  ),
                                  Auth(
                                    api: api,
                                    ko: ko,
                                    onLogin: (u) => setState(() => user = u),
                                  ),
                                ])
                              else
                                Community(api: api, ko: ko, user: user!),
                            if (tab == 4) ...[
                              Hospitals(
                                api: api,
                                ko: ko,
                                canReadExperiences: user!['isGuest'] != true,
                                onSignIn: () => selectTab(3),
                                onPrepare: (hospital) {
                                  setState(() {
                                    visitHospital = hospital;
                                    tab = 1;
                                  });
                                  scroll.jumpTo(0);
                                },
                              ),
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
      bottomNavigationBar: entry
          ? SafeArea(
              top: false,
              child: TextButton.icon(
                onPressed: showHospitalSource,
                icon: const Icon(Icons.info_outline, size: 20),
                label: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Text(
                    t(
                      'Hospital data: HIRA · 2026-09-30\nPohang 669 institutions · Source & details',
                      '병원정보 출처: 건강보험심사평가원 · 2026-09-30\n포항 669곳 · 출처 및 상세 안내',
                    ),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ),
            )
          : user != null && !wide
          ? NavigationBar(
              selectedIndex: visibleTabs.indexOf(tab),
              onDestinationSelected: (index) => selectTab(visibleTabs[index]),
              destinations: List.generate(
                visibleTabs.length,
                (i) => NavigationDestination(
                  icon: Icon(icons[visibleTabs[i]]),
                  label: labels[visibleTabs[i]],
                ),
              ),
            )
          : null,
    );
  }

  void selectTab(int i) {
    if (i == 3 && !showCommunity) return;
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

  Future<void> showHospitalSource() => showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(t('Hospital data source', '병원정보 출처')),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              t(
                'Health Insurance Review & Assessment Service (HIRA)',
                '제공기관: 건강보험심사평가원 (HIRA)',
              ),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text('전국 병의원 및 약국 현황_20260930'),
            Text(t('Source: Korea Public Data Portal', '원본 제공: 공공데이터포털')),
            const SizedBox(height: 12),
            Text(
              t(
                'Snapshot: 2026-09-30\nDownloaded: 2026-10-28\nMORI includes 669 medical institutions and 237 pharmacy records in Pohang. Pharmacy subtypes are unverified.',
                '자료 기준일: 2026-09-30\n다운로드: 2026-10-28\n포항 의료기관 669곳과 약국 237곳을 추출했습니다. 약국의 양약국·한약국 구분은 미확인입니다.',
              ),
            ),
            const SizedBox(height: 12),
            Text(
              t(
                'MORI joins institution, department and facility records and adds multilingual labels, body-area filters and straight-line distances.',
                '모리가 기관·진료과·시설 자료를 결합하고 영문 명칭·신체부위 분류·직선거리를 추가했습니다.',
              ),
            ),
            const SizedBox(height: 12),
            Text(
              t(
                'Not live opening hours, appointment availability or emergency acceptance. Language support is unverified. Registered departments and reported specialist counts are different.',
                '실시간 운영시간·예약·응급환자 수용 정보가 아닙니다. 외국어 지원은 미확인입니다. 신고 진료과와 전문의 수는 구분해 표시합니다.',
              ),
            ),
            const SizedBox(height: 12),
            Text(
              t(
                'License: Korea Open Government License Type 1 (attribution). Map: Google Maps; separate from HIRA hospital data.',
                '이용조건: 공공누리 제1유형(출처표시). 지도는 별도 Google Maps를 사용하며 병원 정보는 심평원 자료입니다.',
              ),
            ),
            TextButton.icon(
              icon: const Icon(Icons.open_in_new),
              label: Text(t('Open original dataset', '공공데이터 원본 보기')),
              onPressed: () async {
                final opened = await launchUrl(
                  Uri.parse('https://www.data.go.kr/data/15051059/fileData.do'),
                  mode: LaunchMode.externalApplication,
                );
                if (!opened && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        t(
                          'Unable to open the source website.',
                          '원본 사이트를 열 수 없습니다.',
                        ),
                      ),
                    ),
                  );
                }
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: Text(t('Close', '닫기')),
        ),
      ],
    ),
  );

  Widget entryHalf({
    required Color color,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback action,
  }) => Material(
    color: color,
    borderRadius: BorderRadius.circular(24),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: action,
      child: Semantics(
        button: true,
        label: '$title. $subtitle',
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 64, color: Colors.white),
                const SizedBox(height: 24),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    title,
                    maxLines: 1,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16, color: Colors.white),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );

  Widget home() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      panel([
        heading(
          t(
            'Find a clinic. Explain your symptoms in Korean.',
            '병원을 찾고, 내 증상을 한국어로 전하세요.',
          ),
        ),
        Text(
          t(
            'Check your original information, then show your Korean visit sheet to the clinician.',
            '내가 입력한 정보를 확인하고, 한국어 준비표를 의료진에게 보여주세요.',
          ),
        ),
        if (showTutorial)
          TextButton.icon(
            onPressed: openTutorial,
            icon: const Icon(Icons.play_circle_outline),
            label: Text(t('Watch the 20-second tutorial', '20초 앱 사용법 보기')),
          ),
        const SizedBox(height: 12),
        button(
          t('Create my Korean visit sheet', '한국어 진료 준비표 만들기'),
          () => selectTab(1),
        ),
        Text(
          t(
            'Write → Translate → Review → Show',
            '입력 → AI 번역 → 직접 확인 → 의료진에게 보여주기',
          ),
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          icon: const Icon(Icons.local_hospital_outlined),
          label: Text(t('Find a clinic', '병원 찾기')),
          onPressed: () => selectTab(4),
        ),
        TextButton.icon(
          style: TextButton.styleFrom(foregroundColor: const Color(0xFFB3261E)),
          icon: const Icon(Icons.emergency),
          label: Text(t('Emergency help · 119', '응급 도움 · 119')),
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => EmergencyPage(
                api: api,
                signedIn: user != null,
                ko: ko,
                onEnsureSession: ensureEmergencySession,
              ),
            ),
          ),
        ),
      ]),
      MoriHome(api: api, ko: ko, onHistory: () => selectTab(2)),
      const SizedBox(height: 18),
      if (showCommunity)
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
      const SizedBox(height: 16),
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
    borderRadius: BorderRadius.circular(24),
  ),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      for (var i = 0; i < children.length; i++) ...[
        if (i > 0) const SizedBox(height: 14),
        children[i],
      ],
    ],
  ),
);
Widget info(String s) => Container(
  margin: const EdgeInsets.only(bottom: 16),
  padding: const EdgeInsets.all(16),
  decoration: BoxDecoration(
    color: pale,
    borderRadius: BorderRadius.circular(16),
  ),
  child: Text(s, style: const TextStyle(color: green, fontSize: 13)),
);
Widget button(String title, VoidCallback? fn, {bool secondary = false}) =>
    Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: secondary
          ? OutlinedButton(
              onPressed: fn,
              child: Text(title, textAlign: TextAlign.center),
            )
          : FilledButton(
              onPressed: fn,
              child: Text(title, textAlign: TextAlign.center),
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
  final void Function(Json)? onRegistered;
  const Auth({
    super.key,
    required this.api,
    required this.ko,
    required this.onLogin,
    this.onRegistered,
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
  String t(String a, String b) => tr(a, b);
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
      if (mounted) {
        final complete = registering
            ? (widget.onRegistered ?? widget.onLogin)
            : widget.onLogin;
        complete(Map<String, dynamic>.from(r['user']));
      }
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
            const SizedBox(height: 12),
            const Text(
              'CARE WITHOUT BORDERS',
              style: TextStyle(letterSpacing: 2, color: green),
            ),
            const SizedBox(height: 20),
            Text(
              t('Sign in', '기록을 보관할 때 로그인하세요.'),
              style: const TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 16),
            GoogleAuthButton(api: widget.api, onLogin: widget.onLogin),
            panel([
              heading(
                registering
                    ? t('Join MORI', 'MORI 가입')
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
  String t(String a, String b) => tr(a, b);
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
              '${j['date']} · ${MoriLanguage.conditionLabel(j['condition'])} · ${j['sleep']}h',
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
  final Map<String, dynamic>? destination;
  final VoidCallback? onChooseHospital;
  final VoidCallback? onHome;
  final bool canReview;
  const VisitCards({
    super.key,
    required this.api,
    required this.ko,
    required this.aiReady,
    this.destination,
    this.onChooseHospital,
    this.onHome,
    this.canReview = false,
  });
  @override
  State<VisitCards> createState() => _VisitCardsState();
}

class _VisitCardsState extends ScreenState<VisitCards> {
  final symptoms = TextEditingController(), onset = TextEditingController();
  final course = TextEditingController(),
      triggers = TextEditingController(),
      questions = TextEditingController();
  final patientName = TextEditingController(),
      bodySite = TextEditingController(),
      temperature = TextEditingController(),
      measuredAt = TextEditingController();
  int? painScore;
  String? bodyRegion;
  List<dynamic> cards = [], journals = [];
  final reviewAnchor = GlobalKey(), clinicianAnchor = GlobalKey();
  Json? careProfile;
  final selectedPersonalInfo = <String>{};
  final selected = <String>{};
  bool consent = false, reviewed = false;
  Json? current;
  final edits = <String, TextEditingController>{};
  String t(String a, String b) => tr(a, b);
  @override
  void initState() {
    super.initState();
    load();
  }

  @override
  void dispose() {
    symptoms.dispose();
    onset.dispose();
    for (final c in [
      patientName,
      bodySite,
      temperature,
      measuredAt,
      course,
      triggers,
      questions,
    ]) {
      c.dispose();
    }
    for (final c in edits.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> load() => run(() async {
    final r = await Future.wait([
      widget.api.request('/api/cards'),
      widget.api.request('/api/journals'),
      widget.api.request('/api/profile'),
    ]);
    if (mounted) {
      setState(() {
        cards = r[0];
        journals = r[1];
        careProfile = Map<String, dynamic>.from(r[2]);
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

  Future<void> reveal(GlobalKey anchor) async {
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted || anchor.currentContext == null) return;
    await Scrollable.ensureVisible(
      anchor.currentContext!,
      duration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : const Duration(milliseconds: 250),
      alignment: 0,
    );
  }

  Future<void> translateCurrent() async {
    if (!mounted || current == null || current!['confirmedAt'] != null) return;
    setState(() => busy = false);
    final accepted = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(t('Send this card for translation?', '이 카드를 번역할까요?')),
        content: Text(
          t(
            'Your symptoms, onset, allergies, medicines and selected diary notes will be sent to the configured AI provider. Your name and email are excluded. Your original stays saved.',
            '증상·시작 시점·알레르기·복용약·선택한 일지가 설정된 AI 제공자에게 전송됩니다. 이름·이메일은 제외하며 원문은 보존됩니다.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(t('Cancel', '취소')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(t('Agree and translate', '동의하고 번역')),
          ),
        ],
      ),
    );
    if (accepted != true || !mounted) return;
    setState(() => busy = true);
    final c = await widget.api.request(
      '/api/cards/${current!['id']}/translate',
      method: 'POST',
      body: {'consent': true},
    );
    if (mounted) {
      open(Map<String, dynamic>.from(c));
      await reveal(reviewAnchor);
    }
  }

  String knowledge(dynamic v) => v['status'] == 'known'
      ? v['detail']
      : v['status'] == 'none'
      ? t('None (user reported)', '없음 (사용자 입력)')
      : t('Unknown', '모름');
  String summary() {
    final c = current!, s = c['snapshot'];
    final tr = c['translation'];
    return 'MORI · ${c['mode'] == 'ai' ? (c['confirmedAt'] == null ? 'AI draft · unreviewed' : 'Saved sheet · AI translation not clinically verified') : 'Original · not translated'}\n${c['createdAt']}\n\nSymptoms: ${s['symptoms']}\nOnset: ${s['onset']}\nAllergies: ${knowledge(s['profile']['allergies'])}\nMedication: ${knowledge(s['profile']['medications'])}\n${intakeMetrics(c)}\n${(s['journals'] as List).map((j) => '${j['date']} · ${MoriLanguage.conditionLabel(j['condition'])} · ${j['sleep']}h\n${j['note']}').join('\n')}\n${tr == null ? '' : '\n한국어\n증상: ${tr['symptomsKo']}\n시작: ${tr['onsetKo']}\n알레르기: ${tr['allergiesKo']}\n복용약: ${tr['medicationsKo']}\n${(tr['journalKo'] as List).map((j) => j['textKo']).join('\n')}'}';
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Container(
        key: const ValueKey('mori-intake-hero'),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
        margin: const EdgeInsets.only(bottom: 18),
        decoration: BoxDecoration(
          color: green,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              current == null
                  ? tr('Where does it hurt?')
                  : tr('Visit preparation chart'),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                height: 1.3,
                fontWeight: FontWeight.w800,
              ),
            ),
            if (current == null) ...[
              const SizedBox(height: 18),
              const Center(
                child: SizedBox(width: 126, height: 138, child: DoctorMori()),
              ),
              const SizedBox(height: 18),
              Text(
                tr(
                  'MORI helps you prepare your words. Answer only what you know.',
                ),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  height: 1.55,
                ),
              ),
              const SizedBox(height: 12),
            ],
            Text(
              t(
                'Write in your language. Check your original information, then show or save your sheet.',
                '내 언어로 적고, 원문 정보를 확인한 뒤 준비표를 보여주세요.',
              ),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFFE6F0E9),
                fontSize: 14,
                height: 1.55,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              t('CLINIC → SYMPTOMS → KOREAN SHEET', '병원 선택 → 증상 입력 → 한국어 준비표'),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFFD5E8CC),
                fontSize: 12,
                height: 1.5,
              ),
            ),
            if (current == null && widget.onChooseHospital != null) ...[
              const SizedBox(height: 12),
              Center(
                child: TextButton.icon(
                  key: const ValueKey('skip-mori-find-care'),
                  style: TextButton.styleFrom(foregroundColor: Colors.white),
                  onPressed: busy ? null : widget.onChooseHospital,
                  icon: const Icon(Icons.arrow_forward, size: 18),
                  label: Text(tr('Skip to find care')),
                ),
              ),
            ],
          ],
        ),
      ),
      const SizedBox(height: 12),
      if ((current == null
              ? widget.destination
              : current!['snapshot']['destination']) !=
          null)
        panel([
          heading(t('Your planned destination', '방문 예정 병원')),
          Text(
            current == null
                ? widget.destination!['name']
                : current!['snapshot']['destination']['name'],
          ),
          Text(
            current == null
                ? widget.destination!['address']
                : current!['snapshot']['destination']['address'],
          ),
          Text(
            t(
              'Visit preparation only · no appointment has been booked.',
              '방문 준비용 선택 · 예약된 상태가 아닙니다.',
            ),
          ),
        ]),
      ...feedback,
      if (current == null) ...[
        panel([
          info(
            t('PRIVATE · Not posted to the community', '비공개 · 커뮤니티에 게시되지 않습니다'),
          ),
          AnswerInput(
            onSkip: widget.onChooseHospital,
            question: tr('1. What is bothering you most?'),
            controller: symptoms,
            lines: 3,
            appendChoices: true,
            choices: const ['Sore throat', 'Stomach pain', 'Headache', 'Cough'],
          ),
          Text(
            tr(
              'Describe what you feel and where. Use your own words, not a diagnosis.',
            ),
            style: Theme.of(context).textTheme.bodySmall,
          ),
          AnswerInput(
            onSkip: widget.onChooseHospital,
            question: tr('2. When did it begin?'),
            controller: onset,
            choices: const ['Today', 'Yesterday', 'A few days ago', 'Unknown'],
          ),
          Text(
            tr(
              'A date or approximate time is enough. If unsure, write “unknown”.',
            ),
            style: Theme.of(context).textTheme.bodySmall,
          ),
          if (careProfile != null)
            panel([
              heading(tr('3. Allergies and medicines')),
              Text(
                tr(
                  'Allergies: what caused a reaction, and what happened? Medicines: include prescriptions, nonprescription medicines, vitamins and supplements. Choose none or unknown accurately.',
                ),
                style: Theme.of(context).textTheme.bodySmall,
              ),
              Text(
                '${t('Allergies', '알레르기')}: ${knowledge(careProfile!['allergies'])}',
              ),
              Text(
                '${t('Medication', '복용약')}: ${knowledge(careProfile!['medications'])}',
              ),
              TextButton.icon(
                icon: const Icon(Icons.edit_outlined),
                label: Text(
                  t('Check allergies and medicines', '알레르기·복용약 확인하기'),
                ),
                onPressed: busy
                    ? null
                    : () async {
                        await Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => Scaffold(
                              appBar: AppBar(
                                title: Text(
                                  t(
                                    'Health information for this visit',
                                    '이번 방문에 전달할 건강정보',
                                  ),
                                ),
                              ),
                              body: SingleChildScrollView(
                                padding: const EdgeInsets.all(20),
                                child: Health(api: widget.api, ko: widget.ko),
                              ),
                            ),
                          ),
                        );
                        if (mounted) await load();
                      },
              ),
            ]),
          AnswerInput(
            onSkip: widget.onChooseHospital,
            question: tr('4. What makes it better or worse? (optional)'),
            controller: triggers,
          ),
          Text(
            tr(
              'Describe only what you noticed. If you cannot tell, leave this blank.',
            ),
            style: Theme.of(context).textTheme.bodySmall,
          ),
          AnswerInput(
            onSkip: widget.onChooseHospital,
            question: tr(
              '5. What do you want to ask the clinician? (optional)',
            ),
            controller: questions,
          ),
          Text(
            tr(
              'Write your most important questions about tests, treatment or what happens next.',
            ),
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const QuestionSources(),
          ExpansionTile(
            maintainState: true,
            tilePadding: EdgeInsets.zero,
            title: Text(
              t('Add details for the clinician (optional)', '상세 정보 추가 (선택)'),
            ),
            children: [
              field(
                t('How has it changed? (optional)', '처음과 비교해 어떻게 달라졌나요? (선택)'),
                course,
                lines: 2,
              ),
              info(
                t(
                  'Write in your own language. Blank answers stay unrecorded. Review your saved original before choosing translation.',
                  '편한 언어로 적으세요. 빈 답변은 미기록으로 남습니다. 저장된 원문을 확인한 후 번역을 선택할 수 있어요.',
                ),
              ),
              heading(t('Structured visit preparation', '한눈에 보는 초진 준비')),
              field(
                t('Name (optional, for this document)', '성명 (선택 · 이 문서용)'),
                patientName,
              ),
              field(t('Body site (optional)', '불편한 부위 (선택)'), bodySite),
              DropdownButtonFormField<String>(
                initialValue: bodyRegion,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: tr('Body diagram (optional)'),
                ),
                items: [
                  DropdownMenuItem(value: '', child: Text(tr('Not recorded'))),
                  for (final entry in visitBodyRegions.entries)
                    DropdownMenuItem(
                      value: entry.key,
                      child: Text(tr('Body region: ${entry.key}')),
                    ),
                ],
                onChanged: busy
                    ? null
                    : (value) => setState(
                        () => bodyRegion = value == '' ? null : value,
                      ),
              ),
              Text(
                tr(
                  'Diagram shows a broad area only. Describe side and exact location above.',
                ),
              ),

              Text(
                t(
                  'Pain intensity (self-report): 0 no pain, 10 worst imaginable',
                  '통증 정도 (본인 보고): 0 통증 없음, 10 상상할 수 있는 가장 심한 통증',
                ),
              ),
              Wrap(
                spacing: 4,
                children: [
                  ChoiceChip(
                    label: Text(t('Not recorded', '미기록')),
                    selected: painScore == null,
                    onSelected: busy
                        ? null
                        : (_) => setState(() => painScore = null),
                  ),
                  for (var n = 0; n <= 10; n++)
                    ChoiceChip(
                      label: Text('$n'),
                      selected: painScore == n,
                      onSelected: busy
                          ? null
                          : (_) => setState(() => painScore = n),
                    ),
                ],
              ),
              TextField(
                controller: temperature,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: t(
                    'Measured temperature °C (optional)',
                    '직접 측정한 체온 °C (선택)',
                  ),
                  hintText: '37.2',
                ),
              ),
              field(
                t('When / how was it measured? (optional)', '측정 시점 · 방법 (선택)'),
                measuredAt,
              ),
              Text(
                t(
                  'Values are patient-reported, not verified vital signs or a diagnosis. Unfilled stays “not recorded”.',
                  '수치는 환자가 입력한 값이며 의료진이 확인한 활력징후나 진단이 아닙니다. 빈 항목은 미기록으로 남아요.',
                ),
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ),
          if (journals.isNotEmpty)
            ExpansionTile(
              title: Text(t('Attach past records (optional)', '과거 기록 첨부 (선택)')),
              subtitle: Text(
                t(
                  'Skip this to prepare your visit now.',
                  '첨부하지 않아도 바로 준비표를 만들 수 있어요.',
                ),
              ),
              children: [
                ...journals.map(
                  (j) => CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      '${j['date']} · ${MoriLanguage.conditionLabel(j['condition'])}',
                    ),
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
              ],
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
            t('Finish and prepare my visit sheet', '입력 완료 · 준비표 만들기'),
            busy || !consent
                ? null
                : () => run(() async {
                    if (symptoms.text.trim().length < 2 ||
                        onset.text.trim().isEmpty) {
                      throw Exception(
                        t(
                          'Enter your main concern and onset (or unknown).',
                          '방문 이유와 시작 시점(또는 모름)을 입력해 주세요.',
                        ),
                      );
                    }
                    final temp = temperature.text.trim().isEmpty
                        ? null
                        : double.tryParse(temperature.text.trim());
                    if (temperature.text.trim().isNotEmpty &&
                        (temp == null ||
                            !temp.isFinite ||
                            temp < 30 ||
                            temp > 45)) {
                      throw Exception(
                        t(
                          'Check temperature in °C (30–45).',
                          '체온을 °C로 확인해 주세요 (입력 범위 30–45).',
                        ),
                      );
                    }
                    final c = await widget.api.request(
                      '/api/cards',
                      method: 'POST',
                      body: {
                        'symptoms': composeVisitConcern(
                          symptoms.text,
                          course.text,
                          triggers.text,
                          questions.text,
                        ),
                        'onset': onset.text,
                        if (widget.destination != null)
                          'hospitalId': widget.destination!['id'],
                        'intake': {
                          'patientName': patientName.text.trim(),
                          'bodySite': bodySite.text.trim(),
                          'bodyRegion': bodyRegion,
                          'painScore': painScore,
                          'temperatureC': temp,
                          'measuredAt': measuredAt.text.trim(),
                        },
                        'journalIds': selected.toList(),
                        'consent': consent,
                      },
                    );
                    if (mounted) {
                      cards.insert(0, c);
                      open(Map<String, dynamic>.from(c));
                      if (widget.aiReady) await translateCurrent();
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
                  ? t('AI draft · review needed', 'AI 초안 · 원문 입력을 확인하세요')
                  : t(
                      'Sheet saved · AI translation not clinically verified',
                      '준비표 저장됨 · AI 번역 의료진 미검증',
                    ),
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
        SizedBox(key: reviewAnchor),
        panel([
          info(
            current!['mode'] == 'original'
                ? t('ORIGINAL · NOT TRANSLATED', '원문 · 번역 안 됨')
                : current!['confirmedAt'] == null
                ? t(
                    'AI draft · check your original input',
                    'AI 초안 · 원문 입력을 확인하세요',
                  )
                : t(
                    'Sheet saved · AI translation not clinically verified',
                    '준비표 저장됨 · AI 번역 의료진 미검증',
                  ),
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
          Text(intakeMetrics(current!)),
          ...(current!['snapshot']['journals'] as List).map(
            (j) => Text('${j['date']} · ${j['sleep']}h\n${j['note']}'),
          ),
        ]),
        if (edits.isNotEmpty && current!['confirmedAt'] == null)
          panel([
            heading(t('Check your original information', '입력한 원문을 확인하세요')),
            info(
              t(
                'AI translation · not clinically verified. You do not need to read Korean to continue.',
                'AI 번역 · 의료진 미검증. 한국어를 읽지 못해도 계속할 수 있습니다.',
              ),
            ),
            ExpansionTile(
              title: Text(t('Edit Korean text (optional)', '한국어 수정 (선택)')),
              children: [
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
              ],
            ),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: reviewed,
              onChanged: (v) => setState(() => reviewed = v ?? false),
              title: Text(
                t(
                  'I checked my original symptoms, onset, numbers, allergies and medicines. I am not verifying the Korean translation.',
                  '원문의 증상·시작 시점·수치·알레르기·복용약을 확인했습니다. 한국어 번역의 정확성을 검증하는 것은 아닙니다.',
                ),
              ),
            ),
            button(
              t('Save my visit sheet', '방문 준비표 저장'),
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
                        body: {
                          ...tr,
                          'reviewed': reviewed,
                          'confirmationKind': 'source_input',
                        },
                      );
                      if (mounted) {
                        open(Map<String, dynamic>.from(c));
                        await reveal(clinicianAnchor);
                      }
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
        if (current!['confirmedAt'] != null)
          info(
            t(
              'Your sheet is saved. Show it to your clinician. Create a new card if your original information needs correcting.',
              '준비표가 저장됐습니다. 의료진에게 보여주세요. 원문을 수정하려면 새 카드를 작성하세요.',
            ),
          ),
        if (current!['confirmedAt'] == null && current!['translation'] == null)
          button(
            t('Translate with AI', 'AI로 번역하기'),
            busy || !widget.aiReady || current!['confirmedAt'] != null
                ? null
                : () async {
                    await run(translateCurrent);
                  },
          ),
        SizedBox(key: clinicianAnchor),
        panel([
          heading(t('Visit preparation chart', '진료 준비 차트')),
          Text(intakeMetrics(current!)),
          Text(
            t(
              'Patient-reported preparation sheet, not an official medical record. Uses saved information.',
              '환자 작성 준비표이며 의료기관 공식 진료기록은 아닙니다. 저장한 내용을 사용합니다.',
            ),
            style: const TextStyle(fontSize: 12),
          ),
          if (careProfile?['emergency'] is Map)
            ExpansionTile(
              title: Text(
                t('Include my information (optional)', '내 정보 포함 (선택)'),
              ),
              subtitle: Text(
                t(
                  'Only selected saved fields appear on the screen and PDF. Check that they are current.',
                  '선택한 저장 정보만 화면과 PDF에 표시됩니다. 현재 내용인지 확인하세요.',
                ),
              ),
              children: [
                for (final entry in visitPersonalFields.entries)
                  if (visitPersonalValue(
                    careProfile!['emergency'],
                    entry.key,
                  ).isNotEmpty)
                    CheckboxListTile(
                      title: Text(entry.value),
                      subtitle: Text(
                        visitPersonalValue(
                          careProfile!['emergency'],
                          entry.key,
                        ),
                      ),
                      value: selectedPersonalInfo.contains(entry.key),
                      onChanged: busy
                          ? null
                          : (value) => setState(() {
                              if (value == true) {
                                selectedPersonalInfo.add(entry.key);
                              } else {
                                selectedPersonalInfo.remove(entry.key);
                              }
                            }),
                    ),
              ],
            ),
          GentleAttention(
            enabled: current!['translation'] != null && !busy,
            child: button(
              t('Show to clinician', '의료진에게 보여주기'),
              busy
                  ? null
                  : () => run(() async {
                      final card = Map<String, dynamic>.from(current!);
                      card['personalInfo'] = selectedVisitPersonalInfo(
                        careProfile?['emergency'] as Map? ?? {},
                        selectedPersonalInfo,
                      );
                      final bytes = await buildVisitPdf(card);
                      if (!context.mounted) return;
                      await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => VisitSheetPage(
                            card: card,
                            bytes: bytes,
                            onHome: widget.onHome,
                            onReview: card['snapshot']['destination'] == null
                                ? null
                                : () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => ClinicReviewsPage(
                                          api: widget.api,
                                          hospital: Map<String, dynamic>.from(
                                            card['snapshot']['destination'],
                                          ),
                                          canReview: widget.canReview,
                                        ),
                                      ),
                                    );
                                  },
                          ),
                        ),
                      );
                    }),
            ),
          ),
        ]),
        button(
          t('Copy saved card', '저장한 카드 복사'),
          () => run(() async {
            await Clipboard.setData(ClipboardData(text: summary()));
            if (mounted) setState(() => message = t('Copied.', '복사했습니다.'));
          }),
          secondary: true,
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
  String t(String a, String b) => tr(a, b);
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
            items:
                [
                      'English',
                      'Korean',
                      'Chinese',
                      'Japanese',
                      'Vietnamese',
                      'French',
                      'Other',
                    ]
                    .map((v) => DropdownMenuItem(value: v, child: Text(tr(v))))
                    .toList(),
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
            '${current!['visitDate']} · ${tr(current!['language'])} · ${tr(const {'direct': 'Direct conversation', 'translation': 'Translation app', 'friend': 'With a friend'}[current!['method']] ?? current!['method'])}',
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
            items:
                [
                      '',
                      'English',
                      'Korean',
                      'Chinese',
                      'Japanese',
                      'Vietnamese',
                      'French',
                      'Other',
                    ]
                    .map(
                      (v) => DropdownMenuItem(
                        value: v,
                        child: Text(
                          v.isEmpty ? t('All languages', '전체 언어') : tr(v),
                        ),
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
              '${tr(p['language'])} · ${p['visitDate']}',
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
                child: Text(tr(v)),
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
  String t(String a, String b) => tr(a, b);
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
          'The directory uses a dated HIRA snapshot. Confirm opening hours and language support with the clinic.',
          '심평원 기준일 자료를 제공합니다. 운영시간과 외국어 지원은 의료기관에 직접 확인하세요.',
        ),
      ),
    ],
  );
}
