import 'package:carebridge/api.dart';
import 'package:carebridge/emergency.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  testWidgets('Guest sees personal information and saves via session callback', (tester) async {
    var sessions = 0;
    var saves = 0;
    final api = Api(client: MockClient((request) async {
      expect(request.url.path, '/api/emergency-profile');
      expect(request.method, 'PUT');
      saves++;
      return http.Response('{}', 200);
    }));
    await tester.pumpWidget(MaterialApp(home: EmergencyPage(api: api, signedIn: false, ko: false, onEnsureSession: () async { sessions++; })));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('My information in Korea'), 350, scrollable: find.byType(Scrollable).first);
    expect(find.text('My information in Korea'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Save information & contacts'), 450, scrollable: find.byType(Scrollable).first);
    await tester.tap(find.text('Save information & contacts'));
    await tester.pumpAndSettle();
    expect(sessions, 1);
    expect(saves, 1);
    expect(find.text('Information saved privately.'), findsOneWidget);
  });
}
