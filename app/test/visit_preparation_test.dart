import 'package:flutter_test/flutter_test.dart';
import 'package:carebridge/visit_preparation.dart';

void main() {
  test('unknown and patient numbers survive; blanks do not become absent', () {
    expect(composeVisitConcern('목 통증 3/10', '', '', ''), '목 통증 3/10');
    final result = composeVisitConcern(
      'Pain',
      'unknown',
      'after food',
      'medicine?',
    );
    expect(result, contains('unknown'));
    expect(result, contains('after food'));
    expect(result, contains('medicine?'));
    expect(result, isNot(contains('None')));
  });
  test(
    'oversized combined input is rejected rather than silently truncated',
    () {
      expect(
        () => composeVisitConcern('a' * 1999, 'extra', '', ''),
        throwsFormatException,
      );
    },
  );
}
