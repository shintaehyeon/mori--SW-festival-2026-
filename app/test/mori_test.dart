import 'package:carebridge/mori.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
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
