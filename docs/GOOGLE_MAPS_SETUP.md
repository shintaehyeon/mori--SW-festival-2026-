# Google Maps 연결

현재: Google Maps Flutter 지도/병원 핀/선택 카드와 외부 길찾기를 구현했다. 실제 API 키가 없어 지도 타일 표시는 미검증이다. 키가 없으면 SDK 지도를 생성하지 않고 외부 Google Maps 버튼을 보여준다. 병원 원본은 HIRA이며 Google Places에서 병원·후기를 가져오는 구조가 아니다.

## 키 만들기
1. https://console.cloud.google.com/google/maps-apis/overview 에서 프로젝트 생성/선택.
2. Google Maps Platform에 결제 계정 연결. 실제 과금 조건/예산 알림은 본인 계정에서 확인.
3. 사용할 플랫폼 API만 활성화: iPhone은 Maps SDK for iOS, Android는 Maps SDK for Android, 웹은 Maps JavaScript API.
4. 사용자 인증 정보에서 플랫폼별 API 키 발급. iOS 키는 번들 ID `com.puchipa.carebridge`, Android 키는 패키지명 `com.puchipa.carebridge`와 해당 서명 SHA-1, 웹 키는 허용 웹사이트(개발 `http://localhost:8791/*`, 운영 도메인)로 제한. API 제한도 해당 Maps API만 허용.
5. `app/config/maps.example.json`을 `app/config/maps.ios.json` 등으로 복사하고 빈 GOOGLE_MAPS_API_KEY 값에 로컬에서 입력. 로컬 파일은 Git 제외. 서로 다른 플랫폼 키를 같은 파일로 재사용하지 않는다. 키를 채팅이나 Git에 붙이지 않는다.

## 실행
app 폴더에서:
```sh
flutter run -d <아이폰 시뮬레이터 ID> --dart-define-from-file=config/maps.ios.json
flutter build web --dart-define-from-file=config/maps.web.json
flutter run -d <Android 기기 ID> --dart-define-from-file=config/maps.android.json
```
동일한 build define을 Dart, iOS 시작 코드, Android Manifest에 전달한다. 웹은 지도 열기 시 Maps JavaScript를 로드한다. 클라이언트 키는 앱/웹에 포함되므로 애플리케이션·API 제한이 필요하다. Gemini 서버 키와는 별개다.

## 실제 키 입력 후 확인
- 지도 열기 → Google 배경/로고와 병원 핀 표시, 필터 변경 시 핀 변경.
- 위치 동의 후 거리순·현재 위치 확인. 거부 시 목록 검색 지속.
- 핀 선택 → 병원 주소·Google 길찾기. 경로는 Google에서 계산하며 앱 거리는 직선거리.
- 병원 상세 → 방문 준비하기 → 선택한 방문 예정 병원과 진료 준비표 화면. 선택은 현재 세션의 화면 안내이며 예약/서버 저장/PDF 병원 필드 추가가 아니다.
- 키 제한 오류·오프라인·실제 기기 GPS는 별도 확인. 키가 존재해도 API 인증 성공을 보장하지 않는다.

공식 문서: https://developers.google.com/maps/flutter-package/config
