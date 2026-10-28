import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'client_native.dart' if (dart.library.html) 'client_web.dart';

class Api {
  final client = makeClient();
  final storage = const FlutterSecureStorage();
  String? token;
  String get base {
    const configured = String.fromEnvironment('API_URL');
    if (configured.isNotEmpty) return configured;
    if (kIsWeb) {
      return Uri.base.port == 8090
          ? '${Uri.base.scheme}://${Uri.base.host}:8790'
          : Uri.base.origin;
    }
    return 'http://localhost:8790';
  }

  Future<void> restore() async {
    if (!kIsWeb) token = await storage.read(key: 'carebridge_session');
  }

  Future<void> setToken(String? value) async {
    token = value;
    if (!kIsWeb) {
      if (value == null) {
        await storage.delete(key: 'carebridge_session');
      } else {
        await storage.write(key: 'carebridge_session', value: value);
      }
    }
  }

  Future<dynamic> request(
    String path, {
    String method = 'GET',
    Object? body,
  }) async {
    final uri = Uri.parse('$base$path');
    final headers = <String, String>{
      'Content-Type': 'application/json',
      if (!kIsWeb) 'X-Client-Platform': 'native',
      if (token != null) 'Authorization': 'Bearer $token',
    };
    final req = await client
        .send(
          (method == 'GET'
              ? _request(method, uri, headers)
              : _request(method, uri, headers, body)),
        )
        .timeout(const Duration(seconds: 40));
    final text = await req.stream.bytesToString().timeout(
      const Duration(seconds: 40),
    );
    final dynamic data;
    try {
      data = jsonDecode(text);
    } catch (_) {
      throw Exception('Service returned an unreadable response.');
    }
    if (req.statusCode >= 400) {
      throw Exception(data['error'] ?? 'Request failed (${req.statusCode}).');
    }
    return data;
  }
}

http.Request _request(
  String method,
  Uri uri,
  Map<String, String> headers, [
  Object? body,
]) {
  final request = http.Request(method, uri)..headers.addAll(headers);
  if (body != null) request.body = jsonEncode(body);
  return request;
}
