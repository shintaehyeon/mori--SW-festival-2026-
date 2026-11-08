# MORI: 5초 이해도 디자인 검수 — 2026-11-08

## 기준과 판정
대상은 한국에서 병원 이용과 의사소통에 어려움을 겪는 외국인 유학생이다.
첫 화면에서 무엇을 돕는지, 어디를 눌러야 하는지, 최종적으로 무엇을 얻는지 드러나야 한다.
이번 검수는 코드와 화면에 대한 휴리스틱 검수다. 실제 초보자의 5초 이해도 또는 임상적 유용성을 입증한 실험은 아니다.

## 적용
- 핵심 문구: “병원을 찾고, 내 증상을 한국어로 전하세요.” 6개 언어에 반영.
- 첫 화면 오른쪽 행동: 추상적인 ‘일반 진료’ 대신 ‘병원 찾기’. 왼쪽 긴급 경로 유지.
- 병원 검색창을 신체 그림·지도·세부 필터보다 먼저 배치.
- ‘병원 목록 보기’로 목록에 바로 이동. 검색 실행 후에도 결과로 이동. 오류는 상단에서 재시도.
- 검색 아이콘에 접근성 설명 추가. 새 목록 이동은 기기의 애니메이션 줄이기 설정 존중.
- 홈 설명은 한국어 정확성 검증을 요구하는 대신 사용자가 입력한 원본 정보 확인을 안내.
- 튜토리얼·커뮤니티 숨김, 기존 토끼 캐릭터와 병원 선택→방문 준비→한국어 준비표 흐름 유지.

색상은 기존 크림 #F6F8F2, 잉크 #193B32, 초록 #21664F, 옅은 초록 #EDF3E8, 긴급 빨강 계열을 유지한다.
기존 플랫폼 글꼴과 제목/본문 위계를 유지하며 새 카드·장식·애니메이션을 추가하지 않는다.

## 검토한 참고자료
제공된 10개 링크 중 Emil 저장소는 중복으로, 고유 저장소는 9개다. 전체 하위 스킬을 모두 검수하거나 설치한 것은 아니다.

| 자료 | 참고한 내용 / 적용 판단 |
|---|---|
| [Anthropic frontend-design](https://github.com/anthropics/skills/blob/main/skills/frontend-design/SKILL.md) | 구체적인 사용자 중심 문구와 행동 이름. 첫 문구·CTA에 적용 |
| [Emil UI cheatsheet](https://github.com/emilkowalski/skills/blob/main/ui-cheatsheet.md) | 읽기 편한 폭·안정적인 요소 배치 참고. 새 모션 라이브러리는 도입하지 않음 |
| [MengTo Skills](https://github.com/MengTo/Skills) | README의 구체적인 제약·작은 단위 수정 접근 참고 |
| [web-quality-skills](https://github.com/addyosmani/web-quality-skills) | 접근성·품질 검수 관점 참고. Lighthouse/WCAG 통과를 주장하지 않음 |
| [Superfuture design-review](https://github.com/Superfuture/design-review) | README의 위계·여백·상태별 구체적 개선 접근 참고 |
| [shadcn/ui](https://github.com/shadcn-ui/ui) | 구성요소 위계 참고. 웹용 구성요소를 Flutter에 직접 설치하지 않음 |
| [Impeccable](https://github.com/pbakaus/impeccable) | 불필요한 장식을 줄이고 핵심 행동을 드러내는 검수 방향 참고 |
| [Jakub better-interface](https://github.com/jakubkrehel/skills/blob/main/skills/better-interface/SKILL.md) | 취향보다 관찰 근거와 좁은 범위의 완결된 흐름. 전체 하위 분야 감사는 수행하지 않음 |
| [wshobson agents](https://github.com/wshobson/agents) | 범용 에이전트 구성은 이번 UI 수정에 불필요하여 미도입 |

외부 코드·이미지 복사나 패키지 설치 없이 원칙을 기존 Flutter 코드에 적용했다.

## 실제 초보자에게 남은 검수
앱을 처음 보는 사람에게 첫 화면을 5초만 보여준 뒤 가리고 다음을 묻는다.
1. 누구를 위한 앱이며 무엇을 해결해 주는가?
2. 지금 아픈데 응급 상황이 아니라면 무엇을 누르겠는가?
3. 마지막에 무엇을 얻을 것으로 예상하는가?

이어 설명 없이 병원 선택→가상 증상 입력→원본 확인→의료진에게 보여주기를 수행하게 한다.
멈춘 위치와 오해한 문구를 기록한다. 팀원이자 문제 당사자인 발표자의 테스트는 유용하지만 독립적인 초보자 평가와 구분한다.

## 검증 기록
- 앱 테스트 53개 통과, Flutter analyze 오류 없음.
- 390×844 테스트에서 검색창·목록 버튼의 초기 터치 가능 상태, 목록 이동 후 결과 노출 및 가입 없는 준비표 진입 확인.
- iPhone 16 Pro 시뮬레이터에서 상단 검색창과 목록 버튼을 확인하고 실제 목록으로 이동.
- 첫 화면 제목의 어색한 줄바꿈은 의미 단위 줄바꿈과 가운데 정렬로 보완.
- 웹 기본 JavaScript 빌드 및 iOS 시뮬레이터 빌드 검증. WebAssembly용 image 의존성 경고는 별도로 남아 있으며 Wasm 지원 완료를 의미하지 않음.
- 증거 화면: `screenshots/mori-search-first-20261108.png`.
- 실제 초보자 평가·의료진 평가·전체 접근성 인증은 미실시.
