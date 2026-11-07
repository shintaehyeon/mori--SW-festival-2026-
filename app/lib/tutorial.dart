import 'dart:async';
import 'package:flutter/material.dart';
import 'localization.dart';

/// A self-contained fictional walkthrough. Never accesses accounts or APIs.
class MoriTutorial extends StatefulWidget {
  const MoriTutorial({super.key});
  @override
  State<MoriTutorial> createState() => _MoriTutorialState();
}

class _MoriTutorialState extends State<MoriTutorial>
    with WidgetsBindingObserver {
  Timer? timer;
  int elapsed = 0;
  bool playing = true;
  int get step => (elapsed ~/ 5).clamp(0, 3);
  bool get done => elapsed >= 20;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!playing || done) return;
      setState(() {
        elapsed++;
        if (done) playing = false;
      });
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed && mounted) {
      setState(() => playing = false);
    }
  }

  @override
  void dispose() {
    timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void move(int target) => setState(() {
    elapsed = target.clamp(0, 3) * 5;
    playing = false;
  });
  @override
  Widget build(BuildContext context) {
    final titles = [
      tr('Explore care for your concern', '불편한 부위로 진료과 찾기'),
      tr('Describe it in your language', '내 언어로 증상 적기'),
      tr('Review the Korean translation', '한국어 번역 확인하기'),
      tr('Show your visit sheet', '의료진에게 준비표 보여주기'),
    ];
    final descriptions = [
      tr(
        'Explore body areas and departments, then check a clinic. This example does not select care for you.',
        '신체 그림과 진료과를 살펴보고 병원을 확인하세요. 이 예시는 진료과를 대신 판단하지 않습니다.',
      ),
      tr(
        'Add when it started, allergies and medication. Include only the daily records you choose.',
        '시작 시점·알레르기·복용약을 적고 필요한 일상 기록만 선택하세요.',
      ),
      tr(
        'Translate after consent. Compare with your original and correct anything that is wrong.',
        '전송 동의 후 번역합니다. 원문과 비교하고 잘못된 표현을 수정하세요.',
      ),
      tr(
        'Show the reviewed sheet to the clinician. Daily notes can help you explain what changed.',
        '확인한 준비표를 의료진에게 보여주세요. 일상 기록은 변화를 설명하는 데 도움이 됩니다.',
      ),
    ];
    final icons = [
      Icons.location_on_outlined,
      Icons.edit_note,
      Icons.translate,
      Icons.description_outlined,
    ];
    return Scaffold(
      appBar: AppBar(title: Text(tr('MORI in 20 seconds', '20초로 보는 MORI'))),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Text(
                  tr(
                    'Fictional demo · No data saved or sent',
                    '가상 시연 · 저장·외부 전송 없음',
                  ),
                  style: const TextStyle(fontSize: 12),
                ),
                const SizedBox(height: 12),
                LinearProgressIndicator(value: elapsed / 20),
                const SizedBox(height: 8),
                Text('${step + 1}/4 · ${elapsed}s / 20s'),
                const SizedBox(height: 20),
                Icon(icons[step], size: 48, color: const Color(0xFF28654F)),
                const SizedBox(height: 12),
                Text(
                  titles[step],
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 12),
                Text(descriptions[step]),
                const SizedBox(height: 20),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          tr('Example only', '가상 예시'),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        if (step == 0) ...[
                          Text(tr('Ear · Nose · Throat', '귀 · 코 · 목')),
                          const SizedBox(height: 8),
                          Text(
                            tr(
                              'Clinic details → Prepare for this visit',
                              '병원 상세 → 방문 준비',
                            ),
                          ),
                        ] else ...[
                          Text(
                            tr(
                              'My throat has hurt for two days.',
                              '이틀 전부터 목이 아파요.',
                            ),
                          ),
                          if (step >= 2) ...[
                            const Divider(height: 28),
                            const Text(
                              '한국어',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const Text(
                              '이틀 전부터 목이 아픕니다.',
                              style: TextStyle(fontSize: 22),
                            ),
                          ],
                          if (step == 3) ...[
                            const Divider(height: 28),
                            Text(
                              tr(
                                'Original + Korean + selected health information',
                                '원문 + 한국어 + 선택한 건강정보',
                              ),
                            ),
                            Text(
                              tr(
                                'Patient-prepared, not a diagnosis',
                                '환자 작성 자료 · 진단 아님',
                              ),
                            ),
                          ],
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      tooltip: tr('Previous', '이전'),
                      onPressed: step == 0 ? null : () => move(step - 1),
                      icon: const Icon(Icons.skip_previous),
                    ),
                    TextButton.icon(
                      onPressed: () => setState(() {
                        if (done) elapsed = 0;
                        playing = !playing;
                      }),
                      icon: Icon(
                        done
                            ? Icons.replay
                            : playing
                            ? Icons.pause
                            : Icons.play_arrow,
                      ),
                      label: Text(
                        done
                            ? tr('Replay', '다시 보기')
                            : playing
                            ? tr('Pause', '일시 정지')
                            : tr('Play', '재생'),
                      ),
                    ),
                    IconButton(
                      tooltip: tr('Next', '다음'),
                      onPressed: step == 3 ? null : () => move(step + 1),
                      icon: const Icon(Icons.skip_next),
                    ),
                  ],
                ),
                if (done) ...[
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: Text(
                      tr('Start my visit preparation', '내 진료 준비 시작하기'),
                    ),
                  ),
                ],
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text(tr('Close tutorial', '튜토리얼 닫기')),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
