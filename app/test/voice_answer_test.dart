import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:carebridge/voice_answer.dart';
import 'package:carebridge/localization.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('flutter_tts'),
          (_) async => 1,
        );
  });
  testWidgets(
    'skip closes voice draft and opens hospital search without applying',
    (tester) async {
      MoriLanguage.current.value = 'en';
      final c = TextEditingController(text: 'Original');
      var searched = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AnswerInput(
              question: 'Question',
              controller: c,
              onSkip: () => searched = true,
            ),
          ),
        ),
      );
      await tester.tap(find.text('Answer with MORI'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.byType(TextField),
        ),
        'Unconfirmed draft',
      );
      await tester.tap(find.text('Skip to find care'));
      await tester.pumpAndSettle();
      expect(searched, isTrue);
      expect(find.byType(AlertDialog), findsNothing);
      expect(c.text, 'Original');
    },
  );
  testWidgets('listening timer starts on recognizer status and stops on done', (
    tester,
  ) async {
    MoriLanguage.current.value = 'en';
    MoriSpeech.failed = false;
    await tester.pumpWidget(
      const MaterialApp(
        home: VoiceAnswer(question: 'Question', initial: ''),
      ),
    );
    expect(find.byKey(const Key('voice-elapsed')), findsNothing);
    MoriSpeech.statusChanged?.call('listening');
    await tester.pump();
    expect(find.text('Listening now'), findsOneWidget);
    expect(find.text('00:00'), findsOneWidget);
    await tester.pump(const Duration(seconds: 5));
    expect(find.text('00:05'), findsOneWidget);
    MoriSpeech.failed = true;
    MoriSpeech.statusChanged?.call('done');
    await tester.pump();
    expect(find.text('Listening now'), findsNothing);
    expect(
      find.text('No speech detected. Check your microphone and try again.'),
      findsOneWidget,
    );
    await tester.pump(const Duration(seconds: 2));
    expect(find.byKey(const Key('voice-elapsed')), findsNothing);
    await tester.pumpWidget(const SizedBox());
    MoriSpeech.failed = false;
  });
  testWidgets('recognizer error stops clock and shows permission guidance', (
    tester,
  ) async {
    MoriLanguage.current.value = 'en';
    await tester.pumpWidget(
      const MaterialApp(
        home: VoiceAnswer(question: 'Question', initial: ''),
      ),
    );
    MoriSpeech.statusChanged?.call('listening');
    await tester.pump(const Duration(seconds: 1));
    MoriSpeech.failed = true;
    MoriSpeech.lastError = 'error_permission';
    MoriSpeech.changed?.call();
    await tester.pump();
    expect(
      find.text(
        'Allow microphone and speech recognition in Settings, then try again.',
      ),
      findsOneWidget,
    );
    expect(find.byKey(const Key('voice-elapsed')), findsNothing);
    await tester.pumpWidget(const SizedBox());
    MoriSpeech.failed = false;
  });

  for (final apply in [false, true]) {
    testWidgets(
      'voice draft ${apply ? "applies explicitly" : "cancel preserves original"}',
      (tester) async {
        MoriLanguage.current.value = 'en';
        final c = TextEditingController(text: 'Original');
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: AnswerInput(question: 'Question', controller: c),
            ),
          ),
        );
        await tester.tap(find.text('Answer with MORI'));
        await tester.pumpAndSettle();
        await tester.enterText(
          find.descendant(
            of: find.byType(AlertDialog),
            matching: find.byType(TextField),
          ),
          'Edited',
        );
        expect(c.text, 'Original');
        await tester.tap(find.text(apply ? 'Use this answer' : 'Cancel'));
        await tester.pumpAndSettle();
        expect(c.text, apply ? 'Edited' : 'Original');
      },
    );
  }

  testWidgets('quick onset choices replace rather than contradict each other', (
    tester,
  ) async {
    MoriLanguage.current.value = 'en';
    final c = TextEditingController();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AnswerInput(
            question: 'When?',
            controller: c,
            choices: const ['Today', 'Yesterday'],
          ),
        ),
      ),
    );
    expect(c.text, isEmpty);
    await tester.tap(find.text('Today'));
    expect(c.text, 'Today');
    await tester.tap(find.text('Yesterday'));
    expect(c.text, 'Yesterday');
  });
  testWidgets('symptom choices preserve typed text and do not duplicate', (
    tester,
  ) async {
    final c = TextEditingController(text: 'My own detail');
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AnswerInput(
            question: 'What?',
            controller: c,
            appendChoices: true,
            choices: const ['Cough'],
          ),
        ),
      ),
    );
    await tester.tap(find.text('Cough'));
    await tester.tap(find.text('Cough'));
    expect(c.text, 'My own detail\nCough');
  });
}
