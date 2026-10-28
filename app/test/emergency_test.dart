import 'package:carebridge/emergency.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('SMS recipient and multilingual body survive URI encoding', () {
    const message = '도와주세요 & Call me + 지금\nLocation: Library';
    final uri = emergencySmsUri('+33612345678', message);
    expect(Uri.decodeComponent(uri.path), '+33612345678');
    expect(uri.queryParameters['body'], message);
    expect(uri.scheme, 'sms');
  });
}
