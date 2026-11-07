import 'package:carebridge/tutorial.dart';
import 'package:carebridge/localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUp(() => MoriLanguage.current.value = 'en');
  testWidgets('20 second demo progresses, stops and can replay', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(800, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(const MaterialApp(home: MoriTutorial()));
    expect(find.text('Explore care for your concern'), findsOneWidget);
    await tester.pump(const Duration(seconds: 5));
    expect(find.text('Describe it in your language'), findsOneWidget);
    await tester.pump(const Duration(seconds: 5));
    expect(find.text('Review the Korean translation'), findsOneWidget);
    await tester.pump(const Duration(seconds: 10));
    expect(find.text('Start my visit preparation'), findsOneWidget);
    expect(find.text('4/4 · 20s / 20s'), findsOneWidget);
    await tester.pump(const Duration(seconds: 10));
    expect(find.text('4/4 · 20s / 20s'), findsOneWidget);
    await tester.ensureVisible(find.text('Replay'));
    await tester.tap(find.text('Replay'));
    await tester.pump();
    expect(find.text('Explore care for your concern'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 6));
    expect(tester.takeException(), isNull);
  });
  testWidgets('pause and manual navigation give the reader control', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(800, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(const MaterialApp(home: MoriTutorial()));
    await tester.tap(find.text('Pause'));
    await tester.pump(const Duration(seconds: 7));
    expect(find.text('1/4 · 0s / 20s'), findsOneWidget);
    await tester.tap(find.byTooltip('Next'));
    await tester.pump();
    expect(find.text('Describe it in your language'), findsOneWidget);
    await tester.pump(const Duration(seconds: 7));
    expect(find.text('2/4 · 5s / 20s'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets('closing tutorial returns without starting a real visit', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(800, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    bool? result;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async {
                result = await Navigator.of(context).push<bool>(
                  MaterialPageRoute(builder: (_) => const MoriTutorial()),
                );
              },
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Close tutorial'));
    await tester.tap(find.text('Close tutorial'));
    await tester.pumpAndSettle();
    expect(result, false);
    await tester.pump(const Duration(seconds: 30));
    expect(tester.takeException(), isNull);
  });
}
