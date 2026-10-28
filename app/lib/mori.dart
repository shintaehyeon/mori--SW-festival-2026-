import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'api.dart';

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
  const MoriHome({super.key, required this.api, required this.ko});
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
    'style': 'sprout',
    'color': 'mint',
  };
  List<dynamic> entries = [];
  bool loading = true, busy = false;
  String? error;
  String t(String en, String ko) => widget.ko ? ko : en;
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
          avatar = Map<String, dynamic>.from(data[0]);
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
    var style = avatar['style'] as String, color = avatar['color'] as String;
    final selected = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, change) => AlertDialog(
          title: Text(t('My little avatar', '나의 작은 분신 만들기')),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  height: 150,
                  width: 220,
                  child: CustomPaint(
                    painter: MoriPainter(
                      style: style,
                      color: color,
                      condition: 'good',
                      phase: 0,
                    ),
                  ),
                ),
                TextField(
                  controller: name,
                  maxLength: 20,
                  decoration: InputDecoration(
                    labelText: t('My Mori nickname', '내 모리 아바타 닉네임'),
                  ),
                ),
                Wrap(
                  spacing: 6,
                  children: [
                    for (final s in ['sprout', 'cat', 'bunny'])
                      ChoiceChip(
                        label: Text(
                          {
                            'sprout': t('Sprout', '새싹'),
                            'cat': t('Cat', '고양이'),
                            'bunny': t('Bunny', '토끼'),
                          }[s]!,
                        ),
                        selected: style == s,
                        onSelected: (_) => change(() => style = s),
                      ),
                  ],
                ),
                Wrap(
                  spacing: 6,
                  children: [
                    for (final c in ['mint', 'peach', 'lavender'])
                      ChoiceChip(
                        label: Text(
                          {
                            'mint': t('Mint', '민트'),
                            'peach': t('Peach', '복숭아'),
                            'lavender': t('Lavender', '라벤더'),
                          }[c]!,
                        ),
                        selected: color == c,
                        onSelected: (_) => change(() => color = c),
                      ),
                  ],
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
                        label: Text(entry.value),
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
    if (loading) return const Center(child: CircularProgressIndicator());
    final days = growthDays(entries), level = growthLevel(growthDays(entries));
    final todayEntries = entries.where((e) => e['date'] == localDay()).toList();
    final todayIntakes = todayEntries
        .expand((e) => (e['intakes'] as List? ?? <dynamic>[]))
        .toSet();
    final condition = todayEntries.isEmpty
        ? 'unknown'
        : todayEntries.first['condition'] as String;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF1E5),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            t('MORI · YOUR LITTLE EVERYDAY FRIEND', 'MORI · 매일 돌보는 작은 친구'),
            style: const TextStyle(
              fontSize: 11,
              letterSpacing: 1.2,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Text(
                  avatar['name'],
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              IconButton(
                tooltip: t('Customize avatar', '아바타 설정'),
                onPressed: busy ? null : customize,
                icon: const Icon(Icons.tune_rounded),
              ),
            ],
          ),
          Text(
            t(
              'A little version of you. Let’s check in together.',
              '나의 작은 분신, 오늘도 함께 안부를 나눠요.',
            ),
          ),
          Semantics(
            label: t(
              'Your self-reported condition: $condition',
              '직접 기록한 오늘의 컨디션: $condition',
            ),
            child: SizedBox(
              height: 240,
              child: AnimatedBuilder(
                animation: motion,
                builder: (context, _) => CustomPaint(
                  painter: MoriPainter(
                    style: avatar['style'],
                    color: avatar['color'],
                    condition: condition,
                    phase: motion.value,
                  ),
                ),
              ),
            ),
          ),
          Text(
            todayEntries.isEmpty
                ? t('Tell me how you feel today 🌿', '오늘 네 이야기를 들려줄래? 🌿')
                : condition == 'low'
                ? t(
                    'A hard day is welcome here, too.',
                    '힘든 날의 너도 소중해. 천천히 쉬어가자.',
                  )
                : t(
                    'Thank you for checking in with me!',
                    '오늘도 내 이야기를 들려줘서 고마워!',
                  ),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Lv. $level · ${t('Growing together', '함께 자라는 중')}'),
              Text('$days ${t('days recorded', '일의 안부')}'),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: (days % 3) / 3,
            minHeight: 8,
            borderRadius: BorderRadius.circular(8),
          ),
          const SizedBox(height: 8),
          Text(
            t(
              'One growth day per date. A level every 3 days, whatever your mood.',
              '날짜당 한 번, 안부 3일마다 한 단계 자라요. 아픈 날에도 똑같이 성장해요.',
            ),
            style: const TextStyle(fontSize: 12),
          ),
          const SizedBox(height: 16),
          if (todayIntakes.isNotEmpty) ...[
            Text(
              t('Recorded today', '오늘 남긴 섭취 기록'),
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            Wrap(
              spacing: 6,
              children: [
                for (final key in todayIntakes)
                  Chip(label: Text(intakeLabels[key] ?? key.toString())),
              ],
            ),
          ],
          FilledButton.icon(
            onPressed: busy ? null : checkIn,
            icon: const Icon(Icons.favorite_outline),
            label: Text(
              todayEntries.isEmpty
                  ? t('Care for myself today', '오늘의 나 돌보기')
                  : t('Add to today’s story', '오늘 이야기 더 남기기'),
            ),
          ),
          Text(
            t(
              'The expression reflects your entries, not a diagnosis. Missing a day never hurts your friend.',
              '표정은 직접 입력한 컨디션을 반영하며 진단이 아니에요. 하루를 건너뛰어도 친구가 아프거나 사라지지 않아요.',
            ),
            style: const TextStyle(fontSize: 12, color: Colors.black54),
          ),
          if (error != null) ...[
            Text(error!, style: const TextStyle(color: Colors.red)),
            TextButton(onPressed: load, child: Text(t('Retry', '다시 불러오기'))),
          ],
        ],
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
