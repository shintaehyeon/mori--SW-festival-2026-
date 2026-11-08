# MORI 두 사람 공동 발표 대본 — English / 한국어

영어만 낭독하세요. 바로 아래 한국어는 의미 확인용입니다. 시간은 편집 목표이며 실제 낭독 측정값이 아닙니다. 화면 조작을 포함해 5분 이내로 맞추세요. 가상 증상만 사용하고, 음성이 안 되면 타이핑으로 진행하세요.

## 01 · Caroline | 문제 발견과 정의

목표 시간: 00:00–00:55

[화면 · 읽지 않음] Caroline 얼굴 → MORI 시작 화면. 마지막 문장 뒤 태현님에게 전환.

Hello, I’m Caroline, a French international student studying in Korea. MORI started with a problem I experienced myself.

안녕하세요. 저는 프랑스에서 한국으로 유학 온 Caroline입니다. MORI는 제가 직접 겪은 문제에서 시작했습니다.

When I felt unwell, I did not know which clinic to visit or how to explain my symptoms in Korean.

아팠을 때 어느 병원에 가야 하는지, 제 증상을 한국어로 어떻게 설명해야 하는지 어려웠습니다.

With so many medical specialties, finding the right place can be confusing. And even after choosing a clinic, the language barrier remains.

진료과가 다양해서 어디로 가야 할지 혼란스러울 수 있습니다. 병원을 골라도 언어 장벽은 여전히 남습니다.

We wanted to connect these two steps: finding a clinic and preparing what to say. Our first focus is international students at Handong University.

우리는 병원을 찾는 일과 병원에서 할 말을 준비하는 일을 연결하고 싶었습니다. 첫 대상은 한동대학교 외국인 유학생입니다.

Now, my teammate will show how we built that journey in MORI.

이제 팀원이 이 과정을 MORI에서 어떻게 구현했는지 보여드리겠습니다.

## 02 · 태현 | 병원 찾기와 증상 입력

목표 시간: 00:55–02:10

[화면 · 읽지 않음] 프랑스어 앱: 병원 찾기 → 귀·코·목 → 양덕이비인후과 → 방문 준비 → 필요 시 게스트 → 가상 증상 입력.

Hi, I’m Taehyeon, the developer of MORI. Let me show a fictional example of a student with a sore throat.

안녕하세요. MORI 개발을 맡은 태현입니다. 목이 아픈 유학생의 가상 사례로 보여드리겠습니다.

The first screen separates emergency help from finding a clinic. Emergency information is available without an account. Today, we will follow the non-emergency path.

첫 화면에서는 긴급 도움과 병원 찾기를 구분합니다. 긴급 안내는 계정 없이 이용할 수 있습니다. 오늘은 비응급 방문 과정을 보여드리겠습니다.

I select ear, nose and throat, then choose Yangdeok ENT Clinic. The directory uses official HIRA data, but opening hours must be checked with the clinic.

귀·코·목을 선택하고 양덕이비인후과를 고릅니다. 목록은 심평원 공식 데이터를 사용하지만, 진료시간은 병원에 확인해야 합니다.

I tap “Prepare this visit.” A guest can continue without creating an account. The selected clinic stays connected to the visit sheet.

방문 준비하기를 누릅니다. 계정을 만들지 않고 게스트로 계속할 수 있습니다. 선택한 병원은 준비표까지 연결됩니다.

The student enters symptoms in French: “J’ai mal à la gorge depuis deux jours.” It means, “I have had a sore throat for two days.”

학생이 프랑스어로 “J’ai mal à la gorge depuis deux jours.”라고 입력합니다. “이틀 전부터 목이 아픕니다”라는 뜻입니다.

MORI asks about the symptom, its starting time, allergies, and medicines. Users can type, select quick answers, or use voice input on supported devices.

모리는 증상, 시작 시점, 알레르기, 복용약을 묻습니다. 직접 입력하거나 답변 버튼을 누르고, 지원 기기에서는 음성 입력도 사용할 수 있습니다.

## 03 · 태현 | 실제 번역과 핵심 결과

목표 시간: 02:10–03:30

[화면 · 읽지 않음] 입력 완료 → AI 전송 동의 → 번역 → 원문 확인 → 의료진에게 보여주기 → PDF 저장·열기. 번역 대기는 편집 가능. 가상 사례 자막 유지.

After saving the original text, MORI asks for permission to send the selected health information for AI translation. With consent, Gemini translates it into Korean.

원문을 저장한 뒤, 선택한 건강정보를 AI 번역에 보내도 되는지 묻습니다. 동의하면 Gemini가 한국어로 번역합니다.

The user checks their original information. We do not ask them to verify Korean they cannot read. The AI translation is clearly marked as not clinically verified.

사용자는 자신의 원래 입력 내용을 확인합니다. 읽을 수 없는 한국어를 검증하라고 요구하지 않습니다. AI 번역은 의료진 미검증 상태임을 명확히 표시합니다.

Now I tap “Show to clinician.” This is the key result: a sheet the student can actually show at the clinic.

이제 의료진에게 보여주기를 누릅니다. 이것이 핵심 결과입니다. 학생이 병원에서 실제로 보여줄 수 있는 준비표가 완성됩니다.

It includes the selected clinic, Korean symptoms, the original text, allergies, and medicines. Users can also choose to include saved personal information and emergency contacts.

선택한 병원, 한국어 증상, 원문, 알레르기, 복용약이 함께 담깁니다. 저장한 개인정보와 비상연락처도 원하는 항목만 선택해 포함할 수 있습니다.

The sheet can be shown on screen or saved as a PDF. This short example fits on one page. MORI does not diagnose a condition or make a booking.

준비표는 화면으로 보여주거나 PDF로 저장할 수 있습니다. 지금처럼 짧은 사례는 한 장에 들어갑니다. MORI는 질환을 진단하거나 예약을 대신하지 않습니다.

We tested the core flow with fictional cases, including actual Gemini translation and PDF download. Now, back to Caroline.

가상 사례를 이용해 실제 Gemini 번역과 PDF 다운로드까지 핵심 흐름을 검사했습니다. 이제 Caroline이 마무리하겠습니다.

## 04 · Caroline | 가치와 마무리

목표 시간: 03:30–04:15

[화면 · 읽지 않음] 완성된 준비표를 잠깐 유지 → Caroline 얼굴 → MORI 이름·핵심 문장. 두 분 함께 인사해도 좋음.

For me, the value is having something ready to show when explaining myself feels difficult.

저에게 중요한 가치는, 말로 설명하기 어려울 때 보여줄 수 있는 자료를 준비하는 것입니다.

We started with my experience, but we still need feedback from more international students and healthcare professionals. This prototype is a starting point, not proof of better medical outcomes.

제 경험에서 시작했지만, 더 많은 외국인 유학생과 의료진의 피드백이 필요합니다. 이번 시제품은 출발점이며 의료적 효과를 입증한 것은 아닙니다.

Our goal is to help students move from “I don’t know where to go or what to say” to “I have chosen a clinic, and my symptoms are ready to show.”

우리의 목표는 “어디로 가야 할지, 무슨 말을 해야 할지 모르겠다”에서 “갈 병원을 골랐고, 보여줄 증상을 준비했다”로 나아가도록 돕는 것입니다.

MORI: find a clinic, and explain your symptoms in Korean. Thank you.

MORI. 병원을 찾고, 내 증상을 한국어로 전하세요. 감사합니다.
