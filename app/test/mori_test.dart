import 'package:carebridge/mori.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('intake notes preserve user entry and do not infer absence', () {
    expect(intakeNote('', <String>{}, ''), '');
    final note = intakeNote('두통', {'vitamin_c', 'alcohol'}, '500mg 오전 9시');
    expect(note, contains('Vitamin C'));
    expect(note, contains('Alcohol'));
    expect(note, contains('500mg 오전 9시'));
  });
  test(
    'growth counts unique dates regardless of condition and levels each 3 days',
    () {
      final entries = [
        {'date': '2026-10-28', 'condition': 'low'},
        {'date': '2026-10-28', 'condition': 'good'},
        {'date': '2026-10-27', 'condition': 'low'},
        {'date': '2026-10-26', 'condition': 'okay'},
      ];
      expect(growthDays(entries), 3);
      expect(growthLevel(growthDays(entries)), 2);
      expect(growthLevel(0), 1);
    },
  );
}
