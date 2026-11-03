# Gemini 서버 설정

server/.env.example을 참고하여 무시되는 server/.env에 AI_PROVIDER=gemini, GEMINI_API_KEY=<로컬에서만 입력>, GEMINI_MODEL=gemini-2.5-flash를 설정한다. AI Gateway 키는 이 모드에서 사용하지 않는다. 키를 앱·Git·채팅에 넣지 않는다. 서버를 재시작하고 /api/health의 aiConfigured를 확인한다. 이는 설정 존재 확인일 뿐 키 유효성/모델 접근/품질 검증이 아니다.

가상 사례로 원문 카드 저장 → AI 번역 → 원문/번역 대조 → 사용자 확인을 수행한다. 약명·숫자·부정·시간·없음/모름을 직접 점검한다. 네트워크 실패/차단/불완전 응답 시 원문을 유지한다. 현재 번역 출력은 한국어이며 전체 앱 다국어 번역이 아니다.
