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

## 이후 후보
- speech_to_text: 버튼을 눌러 짧은 문장을 입력하는 음성인식. 인식된 원문을 먼저 수정하도록 설계.
- flutter_tts: 확인된 번역을 사용자가 눌러 읽어주는 기능.
둘 다 이번에 설치/실기기 검증하지 않았다. 실시간 통역 완성으로 발표하지 않는다.

참고: https://github.com/colinhacks/zod · https://github.com/vercel/ai · https://github.com/DavBfr/dart_pdf
