import 'package:carebridge/api.dart';
import 'package:carebridge/friends.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class SocialApi extends Api {
  final sent = <dynamic>[];
  @override
  Future<dynamic> request(
    String path, {
    String method = 'GET',
    Object? body,
  }) async {
    if (path == '/api/social/settings') {
      return {
        'visibility': 'private',
        'shareStatus': false,
        'condition': 'unknown',
        'note': '',
      };
    }
    if (path == '/api/avatar') {
      return {'name': 'MyMori', 'style': 'sprout', 'color': 'mint'};
    }
    if (path == '/api/social/friends') {
      return [
        {
          'id': 'friend',
          'nickname': 'FriendMori',
          'visibility': 'private',
          'online': null,
          'status': null,
        },
      ];
    }
    if (path == '/api/social/messages' && method == 'POST') {
      sent.add(body);
      return {};
    }
    return <dynamic>[];
  }
}

void main() {
  testWidgets(
    'private friend shows no inferred health and quick cheer submits to selected friend',
    (tester) async {
      tester.view.physicalSize = const Size(1200, 3000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final api = SocialApi();
      await tester.pumpWidget(
        MaterialApp(home: FriendsPage(api: api, ko: true)),
      );
      await tester.pumpAndSettle();
      expect(find.text('친구가 컨디션을 공유하지 않았어요.'), findsOneWidget);
      await tester.tap(find.text('20자 응원 보내기'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('오늘 고생했어!'));
      await tester.pump();
      await tester.tap(find.widgetWithText(FilledButton, '보내기'));
      await tester.pumpAndSettle();
      expect(api.sent.single, {'recipient': 'friend', 'body': '오늘 고생했어!'});
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
    },
  );
}
