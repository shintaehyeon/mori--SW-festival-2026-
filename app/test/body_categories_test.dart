import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:carebridge/body_categories.dart';
import 'package:carebridge/hospitals.dart' show hospitalMatchesQuery;

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
    'body filters use exact registered departments, excluding zero specialist counts',
    () {
      final category = bodyCategories.firstWhere((c) => c.id == 'organs');
      expect(
        matchesBodyCategory({
          'departments': [
            {'name': '내과', 'specialists': 0},
          ],
        }, category),
        isFalse,
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
  test('all categories exclude zero or unrelated specialists', () {
    for (final c in bodyCategories) {
      final name = c.departments.first;
      expect(
        matchesBodyCategory({
          'departments': [
            {'name': name, 'specialists': 1},
          ],
        }, c),
        isTrue,
      );
      expect(
        matchesBodyCategory({
          'departments': [
            {'name': name, 'specialists': 0},
            {'name': 'unrelated', 'specialists': 3},
          ],
        }, c),
        isFalse,
      );
      expect(
        matchesBodyCategory({
          'departments': [
            {'name': name},
          ],
        }, c),
        isFalse,
      );
    }
  });
  test(
    'ENT exact search excludes other specialty clinics with zero ENT specialists',
    () {
      final h = {
        'name': '내과 테스트의원',
        'departments': [
          {'name': '내과', 'specialists': 2},
          {'name': '이비인후과', 'specialists': 0},
        ],
      };
      expect(hospitalMatchesQuery(h, '이비인후과'), isFalse);
      expect(hospitalMatchesQuery(h, '내과'), isTrue);
      expect(hospitalMatchesQuery(h, '테스트의원'), isTrue);
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
