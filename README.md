# MORI (모리) — 외국인을 위한 진료 준비 앱

> 인수인계 기준: 2026-11-05 KST. 이 README는 현재 상태를 요약하며, 날짜별 개발 문서에는 이전 상태가 함께 남아 있습니다. 최신 섹션과 실제 코드를 우선 확인하세요. **시제품이며 공개 운영·실제 AI 품질·의료진 유용성 검증 완료를 의미하지 않습니다.**

## 1. 무엇을 만드는가

한국어로 증상을 설명하기 어려운 외국인 학생·거주자가 **자기 언어로 방문 이유와 경과를 정리하고, 한국 병원에 보여줄 진료 준비표를 만드는 앱**입니다.

- 서비스: **MORI / 모리**, 팀: **Puchipa**
- 최초 신청 주제: AI 기반 외국인 맞춤형 건강관리 및 의료 접근 지원 모바일 애플리케이션 개발
- 대상: 한국 병원 이용 경험이 적고 한국어 설명에 어려움이 있는 외국인 학생부터 시작
- 사용 순간: 아파서 일반 진료를 준비할 때. 긴급 도움 경로는 로그인 없이 접근
- 내부 Flutter 패키지 `carebridge`, 번들 `com.puchipa.carebridge`는 호환성을 위해 유지. 표시 이름과 기획명은 MORI
- 공식 저장소: https://github.com/shintaehyeon/mori--SW-festival-2026- (main)

### 킬러 기능과 사용 이유 — 아직 검증할 가설

**병원에 보여줄 한 장**: 방문 이유·변화·시작 시점·복용약·알레르기를 첫 장에 모으고 원문과 상세 기록을 별첨으로 보존합니다.

병원 위치 검색이나 문장 번역만으로는 기존 도구 대비 사용 이유가 약합니다. 모리는 무엇을 기록할지 안내하고, 미응답을 사실로 추정하지 않으며, 사용자가 선택한 기록을 의사소통 자료로 만드는 과정에 집중합니다. PDF 자체, 귀여운 캐릭터, 기능 개수는 경쟁 우위의 증거가 아닙니다. 의료진이 읽는지, 일반 번역보다 누락이 줄어드는지, 입력 부담이 적은지는 검증 전입니다.

### 핵심 사용자 흐름

1. 첫 화면: 긴급 도움 / 일반 진료 선택
2. 일반 진료: 부위·진료과·기관 유형·거리로 병원 탐색
3. 병원 상세에서 방문 준비 선택 → 필요한 경우 로그인
4. 방문 이유 → 시작 시점 → 변화·악화/완화·질문(선택)
5. 알레르기·복약·수치와 포함할 일상 기록 확인 → 원문 저장
6. AI 설정 시 한국어 번역 → 사용자가 원문과 대조·수정·확인
7. 의료진 표시 / 첫 장 요약 + 전체 기록 PDF

병원 선택은 현재 세션의 화면 안내입니다. 예약, 서버 영구 저장, PDF의 방문 병원 필드로 연결된 것은 아닙니다.

## 2. 현재 구현 상태

| 영역 | 구현 | 남은 검증·제약 |
|---|---|---|
| 계정 | 가입·로그인·로그아웃·탈퇴, 계정별 소유권 | 이메일 인증·비밀번호 복구 없음 |
| 건강기록 | 알레르기/약 있음·없음·모름, 날짜별 컨디션·수면·메모 | 식단/기침/발진 전용 체크는 제안 단계 |
| 섭취 | 술·비타민 C·약·영양제 체크와 메모 | 미선택은 섭취 없음으로 간주하지 않음 |
| 방문 준비 | 방문 이유·시작·변화·악화/완화·질문, 선택 기록 사본 | 원문 통합 증상 2000자 제한. 동적 AI 문진 아님 |
| PDF | A4 첫 장 요약 + 원문/번역/선택 기록 별첨, 한글 폰트 | 실기기 저장·공유·인쇄 전체 검증 남음 |
| 번역 | Gemini 직접 API 또는 AI Gateway 구조, 수치/응답 검사, 대조·확인 | 마지막 설정 점검에서 키 미설정. 실모델 호출·품질 미검증 |
| 병원 | HIRA 포항669곳, 진료과·신체그림·언어별 검색어·전화·길찾기 | 실시간 진료/빈 병상/외국어 가능 여부 아님 |
| 기관 구분 | 일반의료535, 한국 전통의학134, 약국237 별도 | 약국237곳 양약/한약 유형 미확인. 상호로 추정 금지 |
| 위치 | 사용자 요청 시 1회 위치·직선거리 정렬 | 실제 기기 GPS/거부/근사 위치 검증 남음 |
| 지도 | 최신 코드 Google Maps SDK·병원 핀·외부 길찾기 | 키 없으면 외부 지도 버튼. 실제 SDK 타일/인증 미검증 |
| 긴급 | 112/119 전화 화면, 가족 SMS 작성 화면, 사전 프로필 | 자동 신고·자동 전송·수신 보장 없음 |
| 커뮤니티 | 경험·질문·댓글·신고, 친구 초대·수락·차단·20자 응원 | 실제 방문/국적 인증·푸시 알림·신고 운영 화면 없음 |
| 접속 집계 | 동의한 학교/직장/지역 집계, 30초 갱신·90초 만료 | 자기신고·단일 서버 메모리. 실제 캠퍼스 전체 집계 아님 |
| 아바타 | 새싹/고양이/토끼·색·닉네임·기록일 성장 | 의료 상태 자동 감지 없음 |
| 워치 | HealthKit/Health Connect READ 동의·심박/수면 코드 | 실제 Apple/Galaxy Watch 수신 미검증. PDF 자동 반영 없음 |

### PDF의 정확한 동작

첫 장은 저장 내용의 **발췌**이며 새로운 진단이나 의미 요약을 생성하지 않습니다. 확인된 번역만 첫 장에 사용합니다. 미확인 번역은 원문을 대체하지 않고 별첨에 표시됩니다. 긴 내용은 발췌 표시 후 전체를 다음 장에 보존합니다. ‘한 장’은 PDF 전체 페이지 수가 아니라 첫 장의 빠른 확인용 요약을 뜻합니다.

예시: [가상 진료 준비표](docs/examples/MORI_visit_sample.pdf). 실제 환자 자료가 아닙니다. 의료기관 공식 기록·진단서가 아니며 임상적 유용성은 검증 전입니다.

## 3. 기획 결정과 범위 제한

최초 필수 영역: 기본 건강정보/일상 기록, AI 증상 정리, 의료기관 이용 지원, 한국어 요약/번역, 외국인 의료경험 커뮤니티. [최초 기획 대비 기록](docs/ORIGINAL_SCOPE.md)을 먼저 읽으세요.

- 아바타: 기록을 돕는 안내자. 육성게임이 제품 목적을 대신하지 않음
- 친구·워치: 사용자 요청 보조 확장. 제출 전 추가 확장은 보류
- Firebase/Supabase: 논의했지만 **전환하지 않았음**. 현재 Node+SQLite. 마감 직전 전면 이전보다 핵심 흐름과 기존 서버 배포 검증 우선
- 하루 마감 체크: 기침/통증/가려움/발진과 특이 음식·상황을 짧게 기록하는 안은 적합한 후보. **아직 미구현**, AI·PDF 검증 뒤 기존 기록 화면의 작은 보완으로만 추진
- 전체 식단·칼로리·음식 사진 AI·자동 질병 진단·종합 건강점수·음식과 증상 인과 추정은 범위 밖
- Google Maps가 현재 구현. OSM 관련 문서·스크린샷은 과거 검증 이력이며 최신 지도 동작 증거로 재사용하지 않음

상세: [제품 결정](docs/PRODUCT_FOCUS.md), [다음 작업자 인수인계](docs/HANDOFF.md).

## 4. 기술 구조와 코드 위치

Flutter/Dart → Node.js HTTP API → SQLite. 앱에서 PDF 생성. AI 비밀 키는 서버에만 위치. Firebase/Supabase는 사용하지 않습니다.

| 파일/폴더 | 책임 |
|---|---|
| app/lib/main.dart | 진입·인증·홈·건강기록·방문 카드·커뮤니티 |
| app/lib/api.dart, client_*.dart | API 주소·네이티브 토큰·웹 쿠키 통신 |
| app/lib/visit_preparation.dart | 선택 문진 답변을 원문에 결합, 길이 제한 |
| app/lib/visit_pdf.dart | 첫 장 요약 모델, PDF 및 웹 미리보기 |
| app/lib/hospitals.dart | 병원 탐색·위치·방문 준비 연결 |
| app/lib/body_categories.dart, facility_categories.dart | 부위/진료과·일반/전통/약국 필터 |
| app/lib/maps/ | Google SDK 지도 및 웹 로더 |
| app/lib/emergency.dart, mori.dart, friends.dart, presence.dart, wearable.dart | 보조 기능별 화면 |
| server/src/app.js, validation.js | API 라우팅·권한·입력 스키마 |
| server/src/db.js, social.js | SQLite·계정/기록·친구 처리 |
| server/src/ai.js | Gemini/Gateway 호출·응답/수치 검증 |
| server/resources/ | HIRA에서 추출한 공개 병원·약국 JSON |
| scripts/import_hira.py | 공개 CSV 결합·포항 데이터 추출 |
| app/test/, server/test/ | 앱/서버 검증 |

## 5. 새 작업 환경에서 실행

Flutter SDK, Node.js 22.13 이상(기존 작업 환경 Node25)을 사용합니다. 정확한 패키지는 lockfile 기준입니다. PDF와 image 의존성 호환 때문에 `image: 4.5.4` 고정을 임의 해제하지 마세요.

```sh
cd server
npm ci
npm run dev
```

다른 터미널에서:

```sh
cd app
flutter pub get
flutter build web --no-wasm-dry-run
```

http://localhost:8790 을 엽니다. Node 서버가 app/build/web과 API를 같은 주소에서 제공합니다. 첫 실행은 가상 계정/자료를 사용하세요. 별도 웹 개발은 `flutter run -d web-server --web-port=8090`이며 API는8790으로 연결됩니다.

```sh
# iOS 시뮬레이터 (app 폴더)
flutter run -d <device-id> --dart-define=API_URL=http://localhost:8790
# Android 에뮬레이터
flutter run -d <device-id> --dart-define=API_URL=http://10.0.2.2:8790
```

실제 휴대폰의 localhost는 개발 PC가 아닙니다. 외부 접근 가능한 서버 주소·HTTPS·플랫폼 네트워크 정책을 별도로 설정해야 합니다. 공개 HTTPS 배포 주소는 현재 인수인계에서 확인되지 않았습니다. 과거 QA에는8791 포트를 사용했습니다. 기본 실행은8790이며 앱/API/Maps 예시 포트를 맞추세요.

### AI 설정

`server/.env.example`을 `server/.env`로 복사해 로컬에서 키를 입력합니다. 기존 .env를 덮어쓰지 마세요. Gemini는 `AI_PROVIDER=gemini`, `GEMINI_API_KEY`, `GEMINI_MODEL`을 사용합니다. 서버 재시작 후 `/api/health`의 aiConfigured 확인 → 가상 카드 실제 번역 → 원문 대조 → 확인 상태/PDF까지 검증합니다. aiConfigured=true는 키가 있다는 뜻으로 인증 성공이나 번역 품질 증거가 아닙니다. [설정 안내](docs/GEMINI_SETUP.md)

### Google Maps 설정

플랫폼별 키와 API 제한을 사용합니다. `app/config/maps.example.json`을 로컬 설정으로 복사하고 API_URL도 실행 서버에 맞춥니다. `flutter run/build ... --dart-define-from-file=config/maps.ios.json` 방식. 실제 값이 든 설정은 Git/출품 ZIP에서 제외합니다. 클라이언트 지도 키와 서버 Gemini 키는 다릅니다. [지도 설정·확인 절차](docs/GOOGLE_MAPS_SETUP.md)

## 6. 검증과 알려진 한계

```sh
cd server
npm test
# app 폴더에서
flutter analyze
flutter test
flutter build web --no-wasm-dry-run
```

이전 검증: 서버22개, Google Maps 추가 후 앱22개, analyze·웹/iOS 시뮬레이터 빌드 성공 기록. Android debug 빌드는 Google Maps 교체 이전 성공이며 최신 지도 버전 Android 검증과 혼동하지 마세요. 최신 재실행 결과는 [인수인계 검증 기록](docs/HANDOFF.md)을 확인하세요.

- 가상 응답 AI 테스트 ≠ 실제 모델·의료 번역 평가
- 시뮬레이터 GPS ≠ 실제 기기 위치/워치 검증
- PDF 생성 성공 ≠ 휴대폰 파일 저장/인쇄 성공
- 친구/접속 기능 테스트 ≠ 실제 외국인 커뮤니티 확보
- 기록 생성 테스트는 가상 PDF 예시를 다시 저장하여 Git diff를 만들 수 있음
- 서버 테스트는 로컬 임시 포트를 열어야 함. `listen EPERM`이면 환경 권한 문제를 확인
- 자동검사 통과 후에도 iOS·Android 실제 핵심 흐름과 외국인/의료진 검토가 남음

## 7. 개인정보와 데이터 취급

DB `server/data/carebridge.sqlite`, .env, 로컬 지도 설정, 토큰·인증서·사용자 건강정보는 업로드하지 않습니다. 비밀번호는 scrypt, 웹은 HttpOnly 세션, 네이티브 토큰은 secure storage입니다. SQLite 건강정보 본문은 별도 디스크 암호화가 구현되지 않았습니다. 운영 저장 보호·동의·백업은 추가 검토가 필요합니다.

이전 puchipa.sqlite 등 사용자 DB를 정리 명목으로 삭제하지 마세요. PDF를 외부 저장하면 앱에서 카드를 삭제해도 그 파일은 남습니다. 워치값은 현재 메모리 조회용이며 서버/AI/친구에 자동 전달하지 않습니다. 위치는 조회 시 기기에서 거리 계산에 사용하고, 지도 제공자는 타일/SDK 요청 정보를 받습니다. 자유문장 속 개인정보를 자동 익명화한다고 주장하지 않습니다.

HIRA 데이터 기준2026-09-30, 출처/가공/공공누리 조건: [데이터 안내](reference-data/README.md). 전체 ZIP은 Git 제외되어 있으므로 데이터 재생성 시 공식 원본을 별도 확보합니다. Google Places 후기 API 연동은 없습니다.

## 8. 제출과 남은 우선순위

**2026-11-08(일) 23:59 KST**, [3] 스마트 SW 공모전_SW융합. 내부 목표11/7 18시 기능 동결, 11/8 오전 영상·12시 제출. 목표는 완료 증거가 아닙니다.

필수: 연구보고서 PDF, 발표 PPT+소스 ZIP, 720p 이상·5분 이내 MP4를 올린 유튜브 공개/일부공개 링크, 팀원 정보. PDF/ZIP 이름 앞 `[3]`. SW융합은 앱스토어 출시/APK 필수로 안내되지 않았습니다.

1. 실제 AI 번역과 실패 복구/원문 보존 검증
2. 휴대폰에서 병원 선택→기록→PDF 저장, 다른 기기 접속 검증
3. 외국인2명 이상 사용 확인·가능하면 의료진 검토 (미실시 결과를 만들지 않기)
4. 최종 연구 PDF·PPT·영상·ZIP 제작과 파일/링크 검사
5. 폼 제출 후 완료 증거 보관

현재 최종 제출물과 접수 완료는 확인되지 않았습니다. 앱의 진료 준비표 PDF는 출품 연구보고서가 아닙니다. `python3 scripts/package.py`는 개발 소스 ZIP을 만들며 최종 출품 패키지를 완성하지 않습니다.

## 9. 인수인계 문서 읽는 순서

1. [HANDOFF](docs/HANDOFF.md) — 즉시 할 일·완료 조건·변경 금지 사항
2. [PRODUCT_FOCUS](docs/PRODUCT_FOCUS.md) — 제품 판단·반증 가능한 검증
3. [ORIGINAL_SCOPE](docs/ORIGINAL_SCOPE.md) — 최초 약속과 변경 이력
4. [TECHNICAL_OVERVIEW](docs/TECHNICAL_OVERVIEW.md) — 기술과 검증 이력
5. [SUBMISSION](docs/SUBMISSION.md), [PRESENTATION_SCRIPT](docs/PRESENTATION_SCRIPT.md) — 출품 형식·대본
6. [GEMINI_SETUP](docs/GEMINI_SETUP.md), [GOOGLE_MAPS_SETUP](docs/GOOGLE_MAPS_SETUP.md)
7. [친구](docs/FRIENDS_PRIVACY.md), [웨어러블](docs/WEARABLE_ALGORITHM.md), [QA](docs/QA_2026-11-02.md)

코드 변경 시 구현/테스트/미검증을 구분해서 위 문서를 갱신하세요. 의료진 유용성·진단 정확도·시간 절감·법적 적합성을 검증 없이 성과로 적지 않습니다.

## 최신 수동 QA — 2026-11-06
[iOS 시뮬레이터 QA 결과](docs/QA_2026-11-06.md): 병원→원문 카드 저장→PDF 파일 저장 및 재실행 유지 확인. 실제 AI/지도 인증/실물 기기는 미검증.

## 2026-11-06 다국어 업데이트

한국어·중국어 간체·일본어·베트남어·영어·프랑스어 UI 및 기기별 언어 저장을 구현했습니다. 병원 공식 한국어 명칭 아래에 로마자 읽기와 번역된 기관 종류를 표시합니다. PDF는 한국어/영어 항목명과 6개 언어 원문을 보존합니다. 원어민 검수·실제 의료 번역 품질 검증은 남아 있습니다. 상세 구현/테스트/한계: [LOCALIZATION.md](docs/LOCALIZATION.md).
