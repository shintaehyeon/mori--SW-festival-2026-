import 'package:carebridge/startup_cover.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'cover holds one second then fades and does not replay on rebuild',
    (tester) async {
      Widget app() => const MaterialApp(
        home: StartupCover(child: Scaffold(body: Text('Care entry'))),
      );
      await tester.pumpWidget(app());
      expect(find.byKey(const ValueKey('mori-startup-cover')), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 999));
      expect(find.byKey(const ValueKey('mori-startup-cover')), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 1));
      expect(find.byKey(const ValueKey('mori-startup-cover')), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 250));
      expect(find.byKey(const ValueKey('mori-startup-cover')), findsOneWidget);
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('mori-startup-cover')), findsNothing);
      expect(find.text('Care entry'), findsOneWidget);
      await tester.pumpWidget(app());
      expect(find.byKey(const ValueKey('mori-startup-cover')), findsNothing);
    },
  );
  testWidgets('disposing before timeout cancels pending timer', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: StartupCover(child: SizedBox())),
    );
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 2));
    expect(tester.takeException(), isNull);
  });
}
