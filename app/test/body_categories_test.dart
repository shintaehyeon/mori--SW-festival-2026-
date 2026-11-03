import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:carebridge/body_categories.dart';

void main() {
  test('every department in official snapshot has an English label', () {
    final data = jsonDecode(
      File('../server/resources/hospitals.json').readAsStringSync(),
    );
    for (final hospital in data['hospitals']) {
      for (final department in hospital['departments']) {
        expect(
          specialtyEnglish.containsKey(department['name']),
          isTrue,
          reason: department['name'],
        );
      }
    }
  });
  test(
    'body filters use exact registered departments, including zero specialist counts',
    () {
      final category = bodyCategories.firstWhere((c) => c.id == 'organs');
      expect(
        matchesBodyCategory({
          'departments': [
            {'name': '내과', 'specialists': 0},
          ],
        }, category),
        isTrue,
      );
      expect(
        matchesBodyCategory({
          'departments': [
            {'name': '한방내과', 'specialists': 1},
          ],
        }, category),
        isFalse,
      );
      expect(matchesBodyCategory({'departments': []}, category), isFalse);
      expect(matchesBodyCategory({'departments': []}, null), isTrue);
    },
  );
  testWidgets('illustration categories fit a small phone and can be selected', (
    tester,
  ) async {
    BodyCategory? selected;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: SizedBox(
              width: 320,
              child: BodyCategoryPicker(
                selected: null,
                ko: false,
                onSelect: (v) => selected = v,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Internal organs'));
    expect(selected?.id, 'organs');
    expect(tester.takeException(), isNull);
  });
}
