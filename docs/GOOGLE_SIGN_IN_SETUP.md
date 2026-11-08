# Google login setup — prepared, not activated

MORI uses a Node.js + SQLite server, not Firebase. Existing email sessions remain supported.
Google authentication uses Flutter's official google_sign_in 7.2.0 plugin and the official google-auth-library on the server. No OAuth clients were available on 2026-11-08, so the user-facing Google button remains hidden. Fake credentials are never treated as a completed login.

## Create credentials
1. In Google Cloud Console, select a project and configure Google Auth Platform branding, audience and data access (openid, email, profile only). For testing, add the intended tester accounts. Do not request health or Drive scopes.
2. Create a Web application OAuth client. Add the exact web origins used for MORI, e.g. http://localhost:8791 for this local test and the eventual HTTPS deployment origin.
3. Set server `.env` `GOOGLE_CLIENT_IDS=<web client ID>`. Restart server. Client IDs are public identifiers; do not put client secrets in the app. This ID-token flow does not need a client secret.
4. Web: build with `--dart-define=GOOGLE_CLIENT_ID=<web ID> --dart-define=GOOGLE_SERVER_CLIENT_ID=<web ID>`. Uses Google's official rendered web button.
5. iOS: create an iOS OAuth client with bundle identifier `com.puchipa.carebridge`. Add the reversed iOS client ID to `CFBundleURLTypes/CFBundleURLSchemes` in `app/ios/Runner/Info.plist` as required by google_sign_in_ios. Build with `GOOGLE_CLIENT_ID=<iOS ID>` and `GOOGLE_SERVER_CLIENT_ID=<web ID>`. No placeholder URL scheme is installed.
6. Android: register the actual application ID and SHA signing fingerprints in the Android OAuth client; use the Web client ID as server client ID. Confirm the package setup against the official plugin documentation before a device release.

## Required activation QA
- Google account chooser → cancel → safe retry.
- Real verified account → private MORI session → restart → sign out.
- Repeat Google subject maps to the same account.
- Expired, forged or wrong-audience token rejected (official library verifies token signature/issuer/audience/expiry).
- Existing password account email collision rejected; never auto-link by email.
- iOS URL callback, browser popup/cookies and deployed origins verified on target devices.
- Guest records do not move to another account. Download first. Account-linking/migration is deferred.

Unit tests inject a synthetic verified payload and check app behavior; they do NOT prove a real Google login succeeded. Current OAuth configuration and real sign-in remain pending.

References:
- https://pub.dev/packages/google_sign_in
- https://pub.dev/packages/google_sign_in_ios
- https://pub.dev/packages/google_sign_in_web
- https://developers.google.com/identity/gsi/web/guides/verify-google-id-token
