import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:carebridge/campus_support.dart';
import 'package:carebridge/localization.dart';

void main() {
  testWidgets('six languages fit and contacts open without health data', (
    tester,
  ) async {
    MoriLanguage.catalog = jsonDecode(
      File('assets/i18n/catalog.json').readAsStringSync(),
    );
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(() => MoriLanguage.current.value = 'en');
    final opened = <Uri>[];
    for (final language in MoriLanguage.names.keys) {
      MoriLanguage.current.value = language;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: HandongSupport(onOpen: opened.add),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: language);
      for (final target in [
        '+82 54-260-1765',
        'oiahelp@handong.edu',
        'exchange@handong.edu',
      ]) {
        final finder = find.text(target);
        await tester.ensureVisible(finder);
        await tester.tap(finder);
        await tester.pump();
      }
      expect(opened[opened.length - 3].toString(), 'tel:+82542601765');
      expect(
        opened[opened.length - 2].toString(),
        'mailto:oiahelp@handong.edu',
      );
      expect(opened.last.toString(), 'mailto:exchange@handong.edu');
      expect(opened.last.hasQuery, isFalse);
    }
  });
}
