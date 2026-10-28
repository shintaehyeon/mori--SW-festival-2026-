import 'package:carebridge/wearable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:health/health.dart';

class TestReader implements WearableReader {
  int requests = 0, reads = 0;
  @override
  bool get supported => true;
  @override
  Future<bool> authorize(List<HealthDataType> types) async {
    requests++;
    return true;
  }

  @override
  Future<List<WearableSample>> read(
    List<HealthDataType> types,
    DateTime start,
    DateTime end,
  ) async {
    reads++;
    return [];
  }
}

void main() {
  test(
    'wearable normalization removes duplicates, invalid values and stale records without inventing normal data',
    () {
      final end = DateTime(2026, 10, 28, 12),
          start = DateTime(2026, 10, 27, 12);
      WearableSample sample(String id, num value, DateTime date) =>
          WearableSample(
            id: id,
            type: 'HEART_RATE',
            source: 'Test',
            unit: 'bpm',
            value: value,
            from: date,
            to: date,
          );
      final a = sample('a', 72, end);
      expect(
        normalizeWearableSamples(
          [
            a,
            a,
            sample('bad', double.nan, end),
            sample('old', 70, start.subtract(const Duration(days: 1))),
          ],
          start,
          end,
        ).length,
        1,
      );
      expect(normalizeWearableSamples([], start, end), isEmpty);
    },
  );
  testWidgets('health reads require separate consents and a selected type', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 6000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final reader = TestReader();
    await tester.pumpWidget(
      MaterialApp(home: WearablePage(ko: true, reader: reader)),
    );
    await tester.pumpAndSettle();
    expect(reader.requests, 0);
    final first = find.byType(CheckboxListTile).at(0),
        second = find.byType(CheckboxListTile).at(1);
    await tester.ensureVisible(first);
    await tester.tap(first);
    await tester.pump();
    expect(reader.requests, 0);
    await tester.ensureVisible(second);
    await tester.tap(second);
    await tester.pump();
    final toggle = find.widgetWithText(SwitchListTile, '심박수');
    await tester.ensureVisible(toggle);
    await tester.tap(toggle);
    await tester.pump();
    final button = find.widgetWithText(FilledButton, 'OS 권한 요청 · 최근 24시간 읽기');
    await tester.ensureVisible(button);
    await tester.tap(button);
    await tester.pumpAndSettle();
    expect(reader.requests, 1);
    expect(reader.reads, 1);
    expect(
      find.text('읽을 수 있는 기록이 없어요. 권한·기록 유무·동기화 지연을 확인하세요.'),
      findsOneWidget,
    );
  });
}
