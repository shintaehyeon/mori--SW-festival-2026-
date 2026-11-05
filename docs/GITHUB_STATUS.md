# GitHub 버전 관리 — 2026-11-05

- 공식 원격: https://github.com/shintaehyeon/mori--SW-festival-2026-.git
- branch: main
- 인수인계 시작 시 실제 원격 main: a4de9042ed0ec16986f979cef4bbc2c483e15a4c
- 당시 로컬 Google Maps/병원 선택 연결 변경은 미커밋이었으며 README는 옛 CareBridge 상태였다.
- 이번 인수인계 커밋: 해당 변경과 최신 README, docs/HANDOFF.md, 소스 ZIP의 로컬 지도 설정 제외 보강을 함께 기록한다.
- 키/DB/인증정보/개인 건강정보와 빌드 캐시는 Git 제외. 예시 설정은 빈 키만 포함.
- 검증: 서버22, 앱22, analyze 통과. 실제 Google 지도 인증/AI 품질/실기기 공유는 미검증.
- 최종 푸시 결과와 정확한 이번 커밋 ID는 git log 및 원격 main에서 확인한다. 문서 안 자기 커밋 해시를 미리 만들지 않는다.

## 2026-11-06 다국어 변경

3251f5d 이후 6개 언어 UI/병원 읽기/PDF 글꼴/커뮤니티 언어 및 테스트·인수인계 문서를 추가했다. 이 변경은 main의 후속 커밋으로 관리한다. GitHub 동기화와 공개 서버 배포는 별개다. [LOCALIZATION.md](LOCALIZATION.md).
