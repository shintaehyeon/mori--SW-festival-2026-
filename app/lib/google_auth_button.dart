import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'api.dart';
import 'localization.dart';
import 'google_web_button_stub.dart'
    if (dart.library.js_interop) 'google_web_button.dart';

class GoogleAuthButton extends StatefulWidget {
  final Api api;
  final void Function(Map<String, dynamic>) onLogin;
  const GoogleAuthButton({super.key, required this.api, required this.onLogin});
  @override
  State<GoogleAuthButton> createState() => _GoogleAuthButtonState();
}

class _GoogleAuthButtonState extends State<GoogleAuthButton> {
  static Future<void>? initialization;
  StreamSubscription<GoogleSignInAuthenticationEvent>? subscription;
  bool ready = false, busy = false;
  String? error;
  static const clientId = String.fromEnvironment('GOOGLE_CLIENT_ID');
  static const serverId = String.fromEnvironment('GOOGLE_SERVER_CLIENT_ID');
  @override
  void initState() {
    super.initState();
    setup();
  }

  Future<void> setup() async {
    // Missing OAuth configuration is not presented as a working sign-in button.
    if (clientId.isEmpty || serverId.isEmpty) return;
    try {
      final config = await widget.api.request('/api/auth/config');
      if (config['googleEnabled'] != true || !mounted) return;
      initialization ??= GoogleSignIn.instance.initialize(
        clientId: clientId,
        serverClientId: serverId,
      );
      await initialization;
      if (!mounted) return;
      subscription = GoogleSignIn.instance.authenticationEvents.listen(
        (event) {
          if (event is GoogleSignInAuthenticationEventSignIn) {
            exchange(event.user);
          }
        },
        onError: (Object e) {
          if (mounted) {
            setState(
              () => error = tr(
                'Google sign-in could not be completed. Please try again.',
              ),
            );
          }
        },
      );
      setState(() => ready = true);
    } catch (_) {
      if (mounted) {
        setState(
          () => error = tr(
            'Google sign-in could not be completed. Please try again.',
          ),
        );
      }
    }
  }

  Future<void> exchange(GoogleSignInAccount account) async {
    if (busy) return;
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final idToken = account.authentication.idToken;
      if (idToken == null) throw Exception('Missing ID token');
      final r = await widget.api.request(
        '/api/auth/google',
        method: 'POST',
        body: {'idToken': idToken},
      );
      if (r['token'] != null) await widget.api.setToken(r['token']);
      if (mounted) widget.onLogin(Map<String, dynamic>.from(r['user']));
    } catch (_) {
      if (mounted) {
        setState(
          () => error = tr(
            'Google sign-in could not be completed. Please try again.',
          ),
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  void dispose() {
    subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(
    children: [
      if (ready && kIsWeb) webGoogleButton(),
      if (ready && !kIsWeb)
        OutlinedButton.icon(
          icon: const Icon(Icons.account_circle_outlined),
          label: Text(tr('Continue with Google', 'Google로 로그인')),
          onPressed: busy
              ? null
              : () async {
                  try {
                    await GoogleSignIn.instance.authenticate();
                  } catch (_) {
                    if (mounted) {
                      setState(
                        () => error = tr(
                          'Google sign-in could not be completed. Please try again.',
                        ),
                      );
                    }
                  }
                },
        ),
      if (busy) const LinearProgressIndicator(),
      if (error != null)
        Text(error!, style: const TextStyle(color: Colors.red)),
    ],
  );
}
