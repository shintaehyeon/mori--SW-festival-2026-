import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'localization.dart';

/// One speech recognizer per app; callbacks always target the active dialog.
class MoriSpeech {
  static final engine = SpeechToText();
  static VoidCallback? changed;
  static void Function(String)? statusChanged;
  static bool failed = false;
  static String? lastError;
  static Future<bool> initialize() => engine.initialize(
    onStatus: (status) {
      statusChanged?.call(status);
      changed?.call();
    },
    onError: (error) {
      lastError = error.errorMsg;
      failed = true;
      changed?.call();
    },
  );
}

class AnswerInput extends StatelessWidget {
  const AnswerInput({
    super.key,
    required this.question,
    required this.controller,
    this.choices = const [],
    this.lines = 2,
    this.appendChoices = false,
    this.onSkip,
  });
  final String question;
  final TextEditingController controller;
  final List<String> choices;
  final int lines;
  final bool appendChoices;
  final VoidCallback? onSkip;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      TextField(
        controller: controller,
        maxLines: lines,
        decoration: InputDecoration(
          labelText: question,
          alignLabelWithHint: true,
        ),
      ),
      const SizedBox(height: 10),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: choices
            .map(
              (choice) => OutlinedButton(
                onPressed: () {
                  // A quick answer replaces the field; never creates contradictory onset values.
                  final answer = MoriLanguage.text(choice);
                  if (appendChoices && controller.text.trim().isNotEmpty) {
                    if (!controller.text.split('\n').contains(answer)) {
                      controller.text = '${controller.text}\n$answer';
                    }
                  } else {
                    controller.text = answer;
                  }
                },
                child: Text(MoriLanguage.text(choice)),
              ),
            )
            .toList(),
      ),
      const SizedBox(height: 12),
      SizedBox(
        width: double.infinity,
        child: FilledButton.tonal(
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFFEDF3E8),
            foregroundColor: const Color(0xFF21664F),
            minimumSize: const Size(0, 112),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: const BoxDecoration(
                  color: Color(0xFF21664F),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.mic_rounded,
                  size: 30,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                MoriLanguage.text('Answer with MORI'),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          onPressed: () async {
            var skipped = false;
            final answer = await showDialog<String>(
              context: context,
              barrierDismissible: false,
              builder: (dialogContext) => VoiceAnswer(
                question: question,
                initial: controller.text,
                onSkip: onSkip == null
                    ? null
                    : () {
                        skipped = true;
                        Navigator.pop(dialogContext);
                      },
              ),
            );
            if (skipped && context.mounted) onSkip?.call();
            if (answer != null && context.mounted) controller.text = answer;
          },
        ),
      ),
      const SizedBox(height: 12),
    ],
  );
}

class VoiceAnswer extends StatefulWidget {
  const VoiceAnswer({
    super.key,
    required this.question,
    required this.initial,
    this.onSkip,
  });
  final VoidCallback? onSkip;
  final String question, initial;
  @override
  State<VoiceAnswer> createState() => _VoiceAnswerState();
}

class _VoiceAnswerState extends State<VoiceAnswer> with WidgetsBindingObserver {
  late final TextEditingController draft = TextEditingController(
    text: widget.initial,
  );
  final tts = FlutterTts();
  AudioPlayer? cuePlayer;
  bool endCueArmed = false;
  Timer? clock, startGuard;
  int elapsed = 0;
  String phase = 'idle';
  String? errorMessage;
  bool heardWords = false;

  void haltClock() {
    clock?.cancel();
    clock = null;
    startGuard?.cancel();
  }

  void fail(String message) {
    haltClock();
    accepting = false;
    endCueArmed = false;
    if (mounted) {
      setState(() {
        phase = 'error';
        errorMessage = message;
        working = false;
      });
    }
  }

  String speechErrorMessage() {
    final code = MoriSpeech.lastError ?? '';
    if (code.contains('permission') || code.contains('not_allowed')) {
      return 'Allow microphone and speech recognition in Settings, then try again.';
    }
    if (code.contains('no_match') || code.contains('speech_timeout')) {
      return 'No speech detected. Check your microphone and try again.';
    }
    if (code.contains('network')) {
      return 'Speech service connection failed. Check your connection and try again.';
    }
    return 'Microphone could not start. Check microphone access and the device audio input, then retry.';
  }

  Future<void> playCue(String name) async {
    try {
      final player = cuePlayer ??= AudioPlayer();
      final completed = player.onPlayerComplete.first.timeout(
        const Duration(milliseconds: 800),
        onTimeout: () {},
      );
      await player
          .play(AssetSource('audio/$name.wav'), volume: 0.6)
          .timeout(const Duration(seconds: 1));
      await completed;
    } catch (_) {
      // Muted/unsupported audio must never block symptom input.
    }
  }

  void speechStatus(String status) {
    if (!mounted || phase == 'error') return;
    if (status == 'listening') {
      haltClock();
      endCueArmed = true;
      setState(() {
        phase = 'listening';
        working = false;
        elapsed = 0;
      });
      clock = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() => elapsed++);
      });
    }
    if (status == 'notListening' || status == 'done') {
      haltClock();
      setState(() {
        phase = heardWords ? 'complete' : 'empty';
        working = false;
      });
    }
    if ((status == 'notListening' || status == 'done') && endCueArmed) {
      endCueArmed = false;
      if (!MoriSpeech.failed) unawaited(playCue('mic_end'));
    }
  }

  final language = MoriLanguage.current.value;
  bool working = false, unavailable = false, accepting = false;
  int epoch = 0;
  String get locale => {
    'en': 'en-US',
    'fr': 'fr-FR',
    'ko': 'ko-KR',
    'ja': 'ja-JP',
    'zh': 'zh-CN',
    'vi': 'vi-VN',
  }[language]!;
  String tr(String text) => MoriLanguage.text(text);
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    MoriLanguage.current.addListener(languageChanged);
    MoriSpeech.statusChanged = speechStatus;
    MoriSpeech.changed = () {
      if (MoriSpeech.failed) {
        fail(speechErrorMessage());
      } else if (mounted) {
        setState(() {});
      }
    };
  }

  void languageChanged() {
    stop();
    if (mounted) Navigator.pop(context);
  }

  Future<void> stop() async {
    endCueArmed = false;
    haltClock();
    phase = 'idle';
    epoch++;
    accepting = false;
    await cuePlayer?.stop();
    await MoriSpeech.engine.cancel();
    await tts.stop();
    if (mounted) setState(() {});
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) stop();
  }

  Future<void> listen() async {
    if (working) return;
    final attempt = ++epoch;
    setState(() {
      MoriSpeech.failed = false;
      MoriSpeech.lastError = null;
      errorMessage = null;
      heardWords = false;
      elapsed = 0;
      phase = 'starting';
      working = true;
      unavailable = false;
    });
    startGuard?.cancel();
    startGuard = Timer(const Duration(seconds: 20), () {
      if (mounted && attempt == epoch && phase == 'starting') {
        epoch++;
        fail(
          'Microphone could not start. Check microphone access and the device audio input, then retry.',
        );
        unawaited(MoriSpeech.engine.cancel());
      }
    });
    try {
      await tts.stop().timeout(const Duration(seconds: 2));
      final ready = await MoriSpeech.initialize();
      if (!mounted || attempt != epoch) return;
      final locales = ready ? await MoriSpeech.engine.locales() : [];
      if (!mounted || attempt != epoch) return;
      final matches = locales.where(
        (l) => l.localeId.replaceAll('_', '-') == locale,
      );
      if (!ready || matches.isEmpty || language != MoriLanguage.current.value) {
        fail(
          'Microphone could not start. Check microphone access and the device audio input, then retry.',
        );
        return;
      }
      await playCue('mic_start');
      if (!mounted || attempt != epoch) return;
      accepting = true;
      await MoriSpeech.engine.listen(
        onResult: (result) {
          if (mounted && accepting && attempt == epoch) {
            if (result.recognizedWords.isNotEmpty) {
              setState(() {
                heardWords = true;
                draft.text = result.recognizedWords;
                if (phase == 'empty') phase = 'complete';
              });
            }
            if (result.finalResult) {
              accepting = false;
              haltClock();
              setState(() => phase = heardWords ? 'complete' : 'empty');
            }
          }
        },
        listenOptions: SpeechListenOptions(
          localeId: matches.first.localeId,
          listenFor: const Duration(seconds: 45),
          pauseFor: const Duration(seconds: 5),
          cancelOnError: true,
          partialResults: true,
        ),
      );
    } catch (_) {
      if (mounted && attempt == epoch) {
        fail(
          'Microphone could not start. Check microphone access and the device audio input, then retry.',
        );
      }
    } finally {
      if (mounted && attempt == epoch && phase != 'starting') {
        setState(() => working = false);
      }
    }
  }

  Future<void> finishListening() async {
    // stop requests the final transcript; cancel intentionally discards it.
    await MoriSpeech.engine.stop();
    if (mounted) setState(() {});
  }

  Future<void> read() async {
    await stop();
    try {
      if (await tts.isLanguageAvailable(locale) != true) {
        if (mounted) setState(() => unavailable = true);
        return;
      }
      await tts.setLanguage(locale);
      if (mounted) await tts.speak(widget.question);
    } catch (_) {
      if (mounted) setState(() => unavailable = true);
    }
  }

  @override
  void dispose() {
    accepting = false;
    haltClock();
    MoriSpeech.changed = null;
    MoriSpeech.statusChanged = null;
    endCueArmed = false;
    cuePlayer?.dispose();
    MoriSpeech.engine.cancel();
    tts.stop();
    WidgetsBinding.instance.removeObserver(this);
    MoriLanguage.current.removeListener(languageChanged);
    draft.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.onSkip != null)
          Align(
            alignment: Alignment.topRight,
            child: TextButton(
              onPressed: () async {
                await stop();
                if (mounted) widget.onSkip?.call();
              },
              child: Text(tr('Skip to find care')),
            ),
          ),
        Text(widget.question),
      ],
    ),
    content: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            tr(
              'Voice is optional. Your device or browser provider may process audio online. Use fictional symptoms for this demo. Check the text before applying.',
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: working ? null : read,
            icon: const Icon(Icons.volume_up_outlined),
            label: Text(tr('Read question')),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: working
                ? null
                : MoriSpeech.engine.isListening
                ? finishListening
                : listen,
            icon: Icon(
              MoriSpeech.engine.isListening ? Icons.stop : Icons.mic_none,
            ),
            label: Text(
              tr(
                MoriSpeech.engine.isListening
                    ? 'Stop listening'
                    : 'Start microphone',
              ),
            ),
          ),
          if (phase != 'idle')
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(top: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: phase == 'listening'
                    ? const Color(0xFFFCE8E6)
                    : const Color(0xFFEDF3E8),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Icon(
                    phase == 'listening' ? Icons.mic : Icons.info_outline,
                    color: phase == 'listening'
                        ? Colors.red.shade700
                        : const Color(0xFF21664F),
                    size: 32,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    tr(
                      phase == 'starting'
                          ? 'Starting microphone…'
                          : phase == 'listening'
                          ? 'Listening now'
                          : phase == 'complete'
                          ? 'Listening finished. Check your text.'
                          : phase == 'empty'
                          ? 'No speech detected. Check your microphone and try again.'
                          : errorMessage ??
                                'Voice unavailable. You can type or use the answer buttons.',
                    ),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  if (phase == 'listening' || phase == 'complete')
                    Text(
                      '${(elapsed ~/ 60).toString().padLeft(2, '0')}:${(elapsed % 60).toString().padLeft(2, '0')}',
                      key: const Key('voice-elapsed'),
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              tr(
                'Listening stops after about 5 seconds without speech. Your device may stop sooner. Check the text before applying.',
              ),
            ),
          ),
          if (unavailable && phase != 'error')
            Text(
              tr('Voice unavailable. You can type or use the answer buttons.'),
            ),
          const SizedBox(height: 12),
          TextField(
            controller: draft,
            onChanged: (_) => accepting = false,
            minLines: 2,
            maxLines: 5,
            readOnly: working || MoriSpeech.engine.isListening,
            decoration: InputDecoration(
              labelText: tr('Check and edit your answer'),
            ),
          ),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: Text(tr('Cancel')),
      ),
      FilledButton(
        onPressed: working || MoriSpeech.engine.isListening
            ? null
            : () => Navigator.pop(context, draft.text),
        child: Text(tr('Use this answer')),
      ),
    ],
  );
}
