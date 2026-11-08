# MORI · Caroline 최종 사용성 테스트 (15분)

상태: 실행 전. 결과를 미리 합격으로 채우지 않는다.
참가자: Caroline, 프랑스인 한동대 유학생이자 공동 기획·발표 팀원.
관찰자: 신태현, 개발 담당. 본인이 경험한 문제를 바탕으로 만든 팀 내부 사용자 테스트이며 독립 표본 평가가 아니다.

## 1. 먼저 설명 없이 2분

프랑스어 홈을 보여주고 묻는다.

> À quoi sert cette application ? Que ferais-tu en premier si tu avais besoin d’une consultation non urgente ?

“이 앱은 무엇을 도와주나요? 비응급 진료가 필요하다면 무엇부터 하겠어요?”

정답을 알려주지 말고 본인 표현을 적는다. 병원 찾기와 한국어 증상 전달 중 하나라도 보이지 않는다면 홈 문구/버튼을 수정한다.

## 2. 핵심 과제 8분

아래 상황만 전달한다. 버튼 이름이나 순서를 먼저 알려주지 않는다.

> Ceci est un scénario fictif. Tu as mal à la gorge depuis deux jours. Trouve un établissement à Pohang et prépare ce que tu présenterais au personnel médical en coréen. Vérifie la traduction et conserve la fiche pour la retrouver plus tard.

가상 사례만 사용: `EXEMPLE FICTIF : J’ai mal à la gorge depuis deux jours.` / `Depuis deux jours.` 알레르기·복용약도 가상 값 또는 모름을 선택한다. 실제 건강정보를 무료 AI에 입력하지 않는다.

| 과제 | 합격 조건 | 결과/멈춘 화면/개입 여부 |
|---|---|---|
| 기관 탐색 | 진료과·기관 정보를 보고 본인이 선택 이유를 설명 | 미실시 |
| 증상 작성 | 증상과 시작 시점을 원문으로 저장 | 미실시 |
| 번역 | 동의 후 실제 번역 결과를 보고 원문과 비교 | 미실시 |
| 확인 | AI 초안과 사용자 확인 상태를 구분 | 미실시 |
| 의료진 표시 | 병원명·주소·한국어 증상·원문을 찾아 보여줌 | 미실시 |
| 다시 열기 | 다른 화면을 갔다가 동일 준비표를 다시 찾음 | 미실시 |
| PDF | 저장 후 파일을 열어 병원/원문/번역을 확인 | 미실시 |

30초 이상 멈추면 바로 답을 알려주지 말고 “지금 무엇을 하려고 했나요?”라고 묻는다. 도움을 주었으면 ‘도움 없이 완료’로 기록하지 않는다. 소요 시간은 실제 시작/종료 시각을 적고, 기존 방법과 비교하지 않았다면 시간 절감률을 만들지 않는다.

## 3. 마지막 5분: 고칠 것 선택

- Qu’est-ce qui t’a bloquée ? (막힌 지점)
- Qu’est-ce qui te manque pour montrer cette fiche au médecin ? (의사에게 보여주려면 부족한 것)
- As-tu cru que l’application avait réservé un rendez-vous ou posé un diagnostic ? (예약·진단으로 오인했는지)
- Quel écran supprimerais-tu ? (불필요한 화면)

개발자 처리 기준:
1. 저장/재조회/번역/표시 실패, 증상·병원 불일치 → 즉시 수정하고 해당 경로 재검사.
2. 문구 때문에 다음 단계 선택 불가 → 문구/버튼 위치만 고치고 다시 시도.
3. 새로운 워치·진단·실시간 통역 요청 → 후속 작업. 마감 직전 새 범위 추가 금지.

## 발표에 쓸 수 있는 문장

테스트 전: “프랑스인 유학생 팀원이 실제 겪은 의료 접근·언어 문제에서 출발했습니다. 가상 사례의 기능 동작을 검증했고, 사용자 사용성 평가는 별도로 진행합니다.”
테스트 후: “문제 당사자인 팀원 1명과 [실제 날짜]에 [실제 과제]를 테스트했습니다. [관찰된 어려움]을 수정했습니다.” 결과가 있을 때만 대괄호를 채운다. 의료진 유용성 검증이나 외국인 전체의 효과로 확대하지 않는다.

프랑스어 도입 예시:
> Je suis française et étudiante en Corée. Quand on est malade dans un pays qu’on ne connaît pas, il peut être difficile de savoir où aller et d’expliquer ses symptômes. MORI est né de cette difficulté que j’ai vécue. Avec mon coéquipier, qui développe l’application, nous avons relié la recherche d’un établissement à la préparation d’une fiche en coréen.

개인 경험의 구체적 병명이나 사건은 Caroline이 직접 확인한 내용만 덧붙인다.
