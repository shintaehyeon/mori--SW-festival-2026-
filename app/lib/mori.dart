import 'localization.dart';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'api.dart';

/// Decorative guide only; it does not diagnose or assess the user's condition.
class DoctorMori extends StatelessWidget {
  const DoctorMori({super.key});
  @override
  Widget build(BuildContext context) => Image.asset(
    'assets/images/mori_doctor_rabbit.png',
    fit: BoxFit.contain,
    excludeFromSemantics: true,
    filterQuality: FilterQuality.medium,
  );
}

const intakeLabels = <String, String>{
  'alcohol': '🍺 술 / Alcohol',
  'vitamin_c': '🍊 비타민 C / Vitamin C',
  'medication': '💊 약 / Medication',
  'supplement': '🌿 영양제 / Supplement',
};
String intakeNote(String note, Set<String> selected, String detail) => [
  if (note.trim().isNotEmpty) note.trim(),
  if (selected.isNotEmpty)
    '섭취 기록 / Intake: ${selected.map((key) => intakeLabels[key]!).join(', ')}',
  if (selected.isNotEmpty && detail.trim().isNotEmpty)
    '상세 / Details: ${detail.trim()}',
].join('\n');

int growthDays(List<dynamic> entries) =>
    entries.map((e) => e['date']).toSet().length;
int growthLevel(int days) => 1 + days ~/ 3;
String localDay() {
  final d = DateTime.now();
  return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}

class MoriHome extends StatefulWidget {
  final Api api;
  final bool ko;
  final VoidCallback? onHistory;
  const MoriHome({
    super.key,
    required this.api,
    required this.ko,
    this.onHistory,
  });
  @override
  State<MoriHome> createState() => _MoriHomeState();
}

class _MoriHomeState extends State<MoriHome>
    with SingleTickerProviderStateMixin {
  late final AnimationController motion = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 3),
  )..repeat(reverse: true);
  Map<String, dynamic> avatar = {
    'name': 'Mori',
    'style': 'bunny',
    'color': 'mint',
  };
  List<dynamic> entries = [];
  bool loading = true, busy = false;
  String? error;
  String t(String en, String ko) => tr(en, ko);
  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    try {
      final data = await Future.wait([
        widget.api.request('/api/avatar'),
        widget.api.request('/api/journals'),
      ]);
      if (mounted) {
        setState(() {
          avatar = {...Map<String, dynamic>.from(data[0]), 'style': 'bunny'};
          entries = List<dynamic>.from(data[1]);
          loading = false;
          error = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          loading = false;
          error = e.toString();
        });
      }
    }
  }

  @override
  void dispose() {
    motion.dispose();
    super.dispose();
  }

  Future<void> customize() async {
    final name = TextEditingController(text: avatar['name']);
    final style = avatar['style'] as String, color = avatar['color'] as String;
    final selected = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, change) => AlertDialog(
          title: Text(t('My little avatar', '나의 작은 분신 만들기')),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(height: 150, width: 220, child: const DoctorMori()),
                TextField(
                  controller: name,
                  maxLength: 20,
                  decoration: InputDecoration(
                    labelText: t('My Mori nickname', '내 모리 아바타 닉네임'),
                  ),
                ),
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
                    'name': name.text.trim(),
                    'style': style,
                    'color': color,
                  });
                }
              },
              child: Text(t('Save avatar', '아바타 저장')),
            ),
          ],
        ),
      ),
    );
    if (selected == null || !mounted) return;
    setState(() => busy = true);
    try {
      final saved = await widget.api.request(
        '/api/avatar',
        method: 'PUT',
        body: selected,
      );
      if (mounted) setState(() => avatar = Map<String, dynamic>.from(saved));
    } catch (e) {
      if (mounted) setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> checkIn() async {
    var condition = 'okay';
    final selected = <String>{};
    final detail = TextEditingController();
    final note = TextEditingController(),
        sleep = TextEditingController(text: '7');
    var invalid = false;
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, change) => AlertDialog(
          title: Text(t('How are you today?', '오늘의 나는 어때?')),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Wrap(
                  spacing: 6,
                  children: [
                    for (final c in ['good', 'okay', 'low'])
                      ChoiceChip(
                        label: Text(
                          {
                            'good': t('Good', '좋아요'),
                            'okay': t('Okay', '보통이에요'),
                            'low': t('Low', '힘들어요'),
                          }[c]!,
                        ),
                        selected: condition == c,
                        onSelected: (_) => change(() => condition = c),
                      ),
                  ],
                ),
                TextField(
                  controller: sleep,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: t('Sleep hours', '수면 시간'),
                    errorText: invalid
                        ? t('Enter 0–24 hours', '0–24시간을 입력해 주세요')
                        : null,
                  ),
                ),
                const SizedBox(height: 16),
                Text(t('What did you have today?', '오늘 무엇을 먹거나 마셨나요?')),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    for (final entry in intakeLabels.entries)
                      FilterChip(
                        label: Text(
                          tr(
                            entry.value.split(' / ').last,
                            entry.value.split(' / ').first,
                          ),
                        ),
                        selected: selected.contains(entry.key),
                        onSelected: (on) => change(() {
                          if (on) {
                            selected.add(entry.key);
                          } else {
                            selected.remove(entry.key);
                          }
                        }),
                      ),
                  ],
                ),
                Text(
                  t(
                    'Tap what applies. Unchecked means not recorded, not “none”.',
                    '해당하는 항목을 눌러요. 미선택은 ‘없음’이 아니라 ‘기록 안 함’입니다.',
                  ),
                  style: const TextStyle(fontSize: 12),
                ),
                if (selected.isNotEmpty)
                  TextField(
                    controller: detail,
                    maxLength: 200,
                    decoration: InputDecoration(
                      labelText: t(
                        'Optional: name, amount, time',
                        '선택: 이름 · 양 · 시간',
                      ),
                      hintText: t(
                        'e.g. Vitamin C 500 mg at 9 AM',
                        '예: 비타민 C 500mg 오전 9시',
                      ),
                    ),
                  ),
                TextField(
                  controller: note,
                  maxLength: 600,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: t('Your body & your day', '몸 상태와 오늘의 이야기'),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(t('Later', '다음에')),
            ),
            FilledButton(
              onPressed: () {
                final hours = double.tryParse(sleep.text);
                if (hours == null ||
                    !hours.isFinite ||
                    hours < 0 ||
                    hours > 24) {
                  change(() => invalid = true);
                  return;
                }
                Navigator.pop(context, {
                  'date': localDay(),
                  'condition': condition,
                  'sleep': hours,
                  'note': intakeNote(note.text, selected, detail.text),
                  'intakes': selected.toList(),
                });
              },
              child: Text(t('Tell Mori', '모리에게 알려주기')),
            ),
          ],
        ),
      ),
    );
    if (result == null || !mounted) return;
    setState(() => busy = true);
    try {
      await widget.api.request('/api/journals', method: 'POST', body: result);
      await load();
    } catch (e) {
      if (mounted) setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final todayEntries = entries.where((e) => e['date'] == localDay()).toList();
    final condition = todayEntries.isEmpty
        ? 'unknown'
        : todayEntries.first['condition'] as String;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              t('Mori reflects your daily check-in', '오늘의 나를 기록하는 모리'),
              style: Theme.of(context).textTheme.titleLarge,
            ),
            Row(
              children: [
                Semantics(
                  label: t(
                    'Your self-reported condition: $condition',
                    '직접 기록한 오늘의 컨디션: $condition',
                  ),
                  child: SizedBox(
                    width: 100,
                    height: 110,
                    child: const DoctorMori(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    t(
                      'Record how you feel. Look back at changes and choose notes for your next visit.',
                      '매일 컨디션을 기록하고 변화를 돌아보세요. 필요한 기록은 진료 준비표에 담을 수 있어요.',
                    ),
                  ),
                ),
                IconButton(
                  tooltip: t('Customize avatar', '아바타 설정'),
                  onPressed: customize,
                  icon: const Icon(Icons.edit_outlined),
                ),
              ],
            ),
            if (loading) const LinearProgressIndicator(),
            Text(
              todayEntries.isEmpty
                  ? t('No check-in today', '오늘은 아직 기록이 없어요')
                  : '${t('Today', '오늘')}: ${MoriLanguage.conditionLabel(condition)}',
            ),
            const SizedBox(height: 8),
            FilledButton.tonal(
              onPressed: busy || loading ? null : checkIn,
              child: Text(t('Record how I feel today', '오늘의 컨디션 기록하기')),
            ),
            if (widget.onHistory != null)
              TextButton(
                onPressed: widget.onHistory,
                child: Text(t('Look back at my records', '지난 기록 돌아보기')),
              ),
            Text(
              t(
                'Mori reflects what you enter. It does not automatically detect illness or monitor emergencies.',
                '모리는 직접 입력한 상태를 반영합니다. 질병이나 이상을 자동 감지하거나 응급상황을 감시하지 않습니다.',
              ),
              style: const TextStyle(fontSize: 12),
            ),
            if (error != null)
              TextButton(onPressed: load, child: Text(t('Retry', '다시 불러오기'))),
          ],
        ),
      ),
    );
  }
}

class MoriPainter extends CustomPainter {
  final String style, color, condition;
  final double phase;
  MoriPainter({
    required this.style,
    required this.color,
    required this.condition,
    required this.phase,
  });
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(
          size.width / 2,
          size.height * .57 - 6 * math.sin(phase * math.pi),
        ),
        r = math.min(size.width * .26, size.height * .32);
    final body = Paint()
      ..color =
          ({
            'mint': const Color(0xFFA6DCC5),
            'peach': const Color(0xFFFFC6AB),
            'lavender': const Color(0xFFCDBEF0),
          }[color] ??
          const Color(0xFFA6DCC5));
    final dark = Paint()
      ..color = const Color(0xFF254C40)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;
    // Soft pastel backdrop and tiny sparkles; decoration never encodes a health score.
    canvas.drawCircle(
      center,
      r * 1.35,
      Paint()..color = const Color(0xFFFFF6EA),
    );
    for (final sign in [-1, 1]) {
      final point = center + Offset(sign * r * 1.5, -r * .65);
      final sparkle = Paint()
        ..color = const Color(0xFFD6A1C9)
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(
        point - const Offset(0, 6),
        point + const Offset(0, 6),
        sparkle,
      );
      canvas.drawLine(
        point - const Offset(6, 0),
        point + const Offset(6, 0),
        sparkle,
      );
      canvas.drawCircle(
        center + Offset(sign * r * 1.27, r * .7),
        3,
        Paint()..color = const Color(0xFFEFBBA0),
      );
    }
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(center.dx, size.height * .91),
        width: r * 1.6,
        height: 12,
      ),
      Paint()..color = const Color(0x18254C40),
    );
    if (style == 'bunny') {
      for (final sign in [-1, 1]) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: center + Offset(sign * r * .42, -r * .95),
              width: r * .36,
              height: r * 1.2,
            ),
            Radius.circular(r),
          ),
          body,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: center + Offset(sign * r * .42, -r * 1.08),
              width: r * .17,
              height: r * .75,
            ),
            Radius.circular(r),
          ),
          Paint()..color = const Color(0xFFF3BCC8),
        );
      }
    }
    if (style == 'cat') {
      for (final sign in [-1, 1]) {
        final ear = Path()
          ..moveTo(center.dx + sign * r * .95, center.dy - r * .3)
          ..lineTo(center.dx + sign * r * .78, center.dy - r * 1.12)
          ..lineTo(center.dx + sign * r * .22, center.dy - r * .72)
          ..close();
        canvas.drawPath(ear, body);
      }
    }
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: center, width: r * 2, height: r * 1.8),
        Radius.circular(r * .8),
      ),
      body,
    );
    if (style == 'sprout') {
      canvas.drawLine(
        center + Offset(0, -r * .8),
        center + Offset(0, -r * 1.3),
        dark,
      );
      for (final sign in [-1, 1]) {
        canvas.drawOval(
          Rect.fromCenter(
            center: center + Offset(sign * r * .24, -r * 1.25),
            width: r * .5,
            height: r * .24,
          ),
          Paint()..color = const Color(0xFF4A8A55),
        );
      }
    }
    for (final sign in [-1, 1]) {
      final eye = center + Offset(sign * r * .36, -r * .08);
      if (condition == 'low') {
        canvas.drawLine(
          eye - const Offset(5, 0),
          eye + const Offset(5, 0),
          dark,
        );
      } else {
        canvas.drawCircle(eye, 3.8, Paint()..color = const Color(0xFF254C40));
      }
      canvas.drawOval(
        Rect.fromCenter(
          center: center + Offset(sign * r * .62, r * .17),
          width: 16,
          height: 9,
        ),
        Paint()..color = const Color(0x88F09B9B),
      );
    }
    final mouth = Path();
    if (condition == 'good') {
      mouth.moveTo(center.dx - 10, center.dy + r * .23);
      mouth.quadraticBezierTo(
        center.dx,
        center.dy + r * .47,
        center.dx + 10,
        center.dy + r * .23,
      );
    } else if (condition == 'low') {
      mouth.moveTo(center.dx - 8, center.dy + r * .32);
      mouth.quadraticBezierTo(
        center.dx,
        center.dy + r * .19,
        center.dx + 8,
        center.dy + r * .32,
      );
    } else {
      mouth.moveTo(center.dx - 6, center.dy + r * .28);
      mouth.lineTo(center.dx + 6, center.dy + r * .28);
    }
    canvas.drawPath(mouth, dark);
    for (final sign in [-1, 1]) {
      canvas.drawOval(
        Rect.fromCenter(
          center: center + Offset(sign * r * .48, r * .9),
          width: r * .48,
          height: r * .21,
        ),
        body,
      );
    }
  }

  @override
  bool shouldRepaint(covariant MoriPainter old) =>
      old.phase != phase ||
      old.style != style ||
      old.color != color ||
      old.condition != condition;
}
