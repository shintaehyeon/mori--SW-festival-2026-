import 'dart:async';
import 'dart:js_interop';
import 'package:web/web.dart' as web;

Future<void>? _loading;
Future<void> loadGoogleMaps(String key) => _loading ??= _load(key);
Future<void> _load(String key) async {
  final done = Completer<void>();
  final script = web.HTMLScriptElement()
    ..src = Uri.https('maps.googleapis.com', '/maps/api/js', {
      'key': key,
      'v': 'weekly',
    }).toString()
    ..async = true;
  script.onload = ((web.Event _) {
    done.complete();
  }).toJS;
  script.onerror = ((web.Event _) {
    done.completeError(StateError('maps unavailable'));
  }).toJS;
  web.document.head!.append(script);
  await done.future.timeout(const Duration(seconds: 20));
}
