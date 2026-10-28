# 병원 데이터 출처
- 제공기관: 건강보험심사평가원
- 원본: https://www.data.go.kr/data/15051059/fileData.do
- 자료명: 전국 병의원 및 약국 현황_20260930
- 다운로드: 2026-10-28 (KST)
- 공공누리 제1유형: 출처표시
- ZIP 원본은 공급자가 2026년 10월 20일 변경한 자료입니다.
- scripts/import_hira.py는 원본 CSV를 cp949로 읽고 암호화요양기호로 기본/시설/진료과 정보를 결합합니다.
- server/resources/hospitals.json은 포항 669개 기관으로 제한한 스냅샷입니다. 실시간 개원/휴진/응급수용 정보가 아닙니다.
- 외국어 지원 및 후기·작성자 국적은 공공파일에 없으므로 추정하지 않았습니다.
- 신고 진료과목과 해당 진료과 전문의 보유는 서로 다릅니다. 전문의 수를 별도로 표시합니다.

# 후기 연결
- Google Places API (New): reviews 최대 5개, 관련성 순. 작성자의 국적을 확인하는 기능이 아닙니다. API 키·과금 설정 및 표시/보관 정책 준수가 필요합니다.
- https://developers.google.com/maps/documentation/places/web-service/reference/rest/v1/places
- https://developers.google.com/maps/documentation/places/web-service/policies
- Kakao Local 공개 응답, Naver Local Search 공개 응답에는 후기 본문 필드가 없습니다.
- 현재 앱은 외부 지도 검색 링크와 모리 자체 방문 경험 조회만 제공합니다. Google 후기 API 호출은 연결하지 않았습니다.
- 자체 방문 경험은 병원명 정확 일치로 연결하며 방문/국적 인증은 제공하지 않습니다. 추후 기관 ID 기반 연결로 교체해야 합니다.
