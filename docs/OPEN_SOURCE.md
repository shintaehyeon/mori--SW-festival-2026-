# MORI 오픈소스 활용 — 2026-11-08

제출 전 핵심은 증상 원문 보존→한국어 번역 확인→진료 준비표다. 이미 설치된 검증/문서 도구를 우선 활용하며 라이브러리 수를 늘리기 위해 새 의존성을 추가하지 않는다.

| 구성 | 설치 버전/라이선스 | 실제 역할 |
|---|---|---|
| Zod |4.6.7 / MIT|증상/번역 JSON 스키마 검증과 Gemini 출력 형식 정의|
| Vercel AI SDK(ai) |7.0.155 / Apache-2.0|기존 AI Gateway 경로. 현재 Gemini 직접 호출 경로는 REST+Zod이므로 SDK로 Gemini를 호출한다고 설명하지 않음|
| dart_pdf(pdf) |3.12.0 / Apache-2.0|인체 도식·원문·확인한 번역을 PDF 준비자료로 생성|
| printing |5.14.3 / Apache-2.0|네이티브 PDF 미리보기·공유/인쇄 인터페이스|

버전/라이선스는 설치 패키지의 package.json/pubspec.yaml/LICENSE에서 확인했다. Flutter·기타 패키지·글꼴에도 각각 라이선스가 있으며 이 표는 전체 종속성 목록이 아니다.

Gemini API와 Google Maps API는 오픈소스 모델/무료 공개 데이터로 분류하지 않는다. 무료 등급에도 별도 사용 조건이 있다.

## 음성 입력·읽기 (최종 시연판에 구현)
- speech_to_text 7.4.0: 기기·브라우저 음성 인식으로 짧은 증상 입력.
- flutter_tts 4.2.5: 선택 언어 질문 읽기, 기기 언어 지원에 의존.
- audioplayers 6.7.1: 직접 합성한 시작·종료 효과음 재생.
- 시뮬레이터 동작 확인은 기기별·언어별 인식 품질 검증과 다르다.

참고: https://github.com/colinhacks/zod · https://github.com/vercel/ai · https://github.com/DavBfr/dart_pdf

## 2026-11-08 UI / authentication update
- Flutter Material 3: existing Card, FilledButton, ExpansionTile and ThemeData refined. No additional UI kit installed.
- google_sign_in 7.2.0 and google_sign_in_web 1.1.3: official Flutter plugins (BSD-3-Clause), prepared client login; OAuth setup pending.
- google-auth-library 11.3.3: Apache-2.0, official Google Node ID-token verification.
- Existing geolocator, url_launcher, google_maps_flutter, pdf and printing retained. Internal Google Maps key and Google Sign-In OAuth IDs are separate.
- Editable Figma specification and usage rationale: UI_JOURNEY_2026-11-08.md.
- https://pub.dev/packages/google_sign_in
- https://github.com/googleapis/google-auth-library-nodejs
- https://docs.flutter.dev/cookbook/design/themes
