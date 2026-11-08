# MORI 제출 보충자료: 활용 기술과 언어 범위

2026-11-08 로컬 소스·의존성 파일 확인. 설치 여부와 실제 서비스 연결 완료는 구분합니다.

## 주요 Flutter 패키지

| 패키지 | 잠금 버전 | 역할 | 공식 프로젝트 |
|---|---|---|---|
| speech_to_text | 7.4.0 | 기기 음성 인식 | https://pub.dev/packages/speech_to_text |
| flutter_tts | 4.2.5 | 질문 읽기 | https://pub.dev/packages/flutter_tts |
| audioplayers | 6.7.1 | 시작·종료음 | https://pub.dev/packages/audioplayers |
| pdf | 3.12.0 | PDF 생성 | https://pub.dev/packages/pdf |
| printing | 5.14.3 | PDF 인쇄·공유 | https://pub.dev/packages/printing |
| http | 1.6.0 | HTTP 통신 | https://pub.dev/packages/http |
| flutter_secure_storage | 11.2.0 | 세션 저장 | https://pub.dev/packages/flutter_secure_storage |
| url_launcher | 6.3.3 | 외부 전화·지도 링크 | https://pub.dev/packages/url_launcher |
| geolocator | 14.1.2 | 위치 권한·좌표 | https://pub.dev/packages/geolocator |
| latlong2 | 0.10.1 | 좌표·거리 처리 | https://pub.dev/packages/latlong2 |

## 기반 기술·글꼴
- Flutter / Material: https://github.com/flutter/flutter
- Node.js: https://github.com/nodejs/node
- SQLite: https://sqlite.org/
- Zod: https://github.com/colinhacks/zod
- Noto 글꼴: https://github.com/notofonts / 앱 assets/fonts의 OFL 파일 포함
- Nanum Gothic: https://github.com/google/fonts/tree/main/ofl/nanumgothic / 앱 assets/fonts/OFL.txt 포함

## API·공개자료·링크 구분
- Gemini generateContent API: https://ai.google.dev/api/generate-content — 서버 직접 REST 호출. 자체 오픈소스 모델이 아님.
- speech_to_text / flutter_tts: OS·브라우저 음성 서비스 호출. MORI의 별도 Gemini 음성 처리 API가 아님.
- HIRA 공개자료: https://www.data.go.kr/data/15051059/fileData.do — 파일 가공 후 자체 API 제공. 실시간 HIRA API 호출로 표현하지 않음.
- Google Maps: 외부 길찾기 링크. 내부 타일 지도·Places 후기 API 실제 연결 완료로 표현하지 않음.
- 자체 API: Node.js HTTP / SQLite. Firebase 미사용.

## 의존성은 있으나 시연 완료 기능과 구분할 항목
- google_maps_flutter: 내부 지도 키 설정 필요.
- google_sign_in / google_sign_in_web / google-auth-library: OAuth 설정 필요, 완료 기능 목록에서 제외.
- health: 건강 플랫폼 연동 준비 코드, 핵심 제출 시연에서 제외.
- ai (Vercel AI SDK): 공통 요청 구성과 대체 공급자 경로에 사용. 현재 Gemini 분기는 직접 REST 요청이며 별도 Vercel API 서비스 연결을 주장하지 않음.

## 언어 선정 근거 및 해석
- 한국어·영어·중국어(간체)·베트남어·일본어·프랑스어 UI.
- 중국어·베트남어는 주요 유학생 집단을 고려할 근거가 있음. 나머지는 공통 접근성·의료진 전달·실제 팀원 사례·초기 범위에 따른 선택.
- 국적 상위 6개국을 모두 지원한다는 뜻이 아님. 모든 언어 품질을 실제 사용자에게 검증했다는 뜻도 아님.
- 공식 참고: https://www.studyinkorea.go.kr/ko/why/koreaStatistics.do
- 해당 페이지의 국적 비중 도표와 국적별 인원 표에 서로 맞지 않는 표시가 있어, 본 보충문에는 정확한 비중이나 순위를 인용하지 않았음.

이 문서는 주요 활용 목록이며 전체 전이 의존성의 법적 라이선스 감사 완료를 의미하지 않습니다. 전체 의존성은 pubspec.lock / package-lock.json을 참고하세요.
