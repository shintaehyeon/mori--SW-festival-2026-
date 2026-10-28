import 'package:carebridge/api.dart';
import 'package:carebridge/presence.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class PresenceApi extends Api {
  bool handong = false;
  int beats = 0;
  bool fail = false;
  @override
  Future<dynamic> request(
    String path, {
    String method = 'GET',
    Object? body,
  }) async {
    if (path == '/api/presence/settings') {
      if (method == 'PUT') handong = (body as Map)['enabled'];
      return {
        'enabled': handong,
        'organizationType': 'school',
        'organization': '테스트대학교',
        'region': '포항시',
      };
    }
    if (method == 'DELETE') return {};
    if (fail) throw Exception('Disconnected');
    beats++;
    return {'count': handong ? 1 : 0, 'includesMe': handong};
  }
}

void main() {
  testWidgets(
    'presence starts opted out, counts real responses and shows unknown on failure',
    (tester) async {
      final api = PresenceApi();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: PresencePanel(api: api, ko: true)),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('커뮤니티 · 최근 접속 0 명'), findsOneWidget);
      await tester.tap(find.byType(SwitchListTile));
      await tester.pumpAndSettle();
      expect(api.handong, true);
      expect(find.text('나도 포함된 숫자예요.'), findsOneWidget);
      api.fail = true;
      await tester.pump(const Duration(seconds: 30));
      await tester.pumpAndSettle();
      expect(find.text('연결 끊김 · 접속 수 확인 불가'), findsOneWidget);
      expect(find.text('커뮤니티 · 최근 접속 1 명'), findsNothing);
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
    },
  );
}
