# MORI / Puchipa scope guard

User instruction (2026-10-28): Always check development against the originally submitted proposal before starting changes. Do not let later feature requests silently replace the original purpose.

## Source of truth
Read `docs/ORIGINAL_SCOPE.md` before feature planning and implementation. The original attachment is a preserved reference, not a newly verified application receipt. Do not edit synced sources or rewrite the original proposal to match implementation.

## Required checks
1. Map each proposed change to one of the five original feature areas.
2. Keep the primary user and outcome: foreign students/residents in Korea who need help finding appropriate local medical services and communicating their reason for visiting.
3. Classify changes as core, supporting, or scope expansion. Explicitly flag expansion to the user before implementation; do not silently drop a required original area.
4. Later user instructions may change scope; record the change and its implications instead of claiming it was in the original proposal. Do not repeatedly ask for approval already given.
5. Prioritize the complete medical-access journey and required submission artifacts over avatar decoration, leveling, or other optional features.
6. Distinguish implemented, tested, unverified, and planned features. In particular AI configuration is not a working AI integration; map links are not imported reviews; English text does not verify foreign nationality.
7. For meaningful milestones, update `docs/ORIGINAL_SCOPE.md` with evidence and remaining gaps after inspecting current code and validation results.

## Submission and presentation maintenance
User instruction (2026-10-28): Keep technical explanations and the presentation script aligned with the actual submission format throughout development.
- Read docs/SUBMISSION.md before submission-related work.
- After material implementation or validation changes, update docs/TECHNICAL_OVERVIEW.md and docs/PRESENTATION_SCRIPT.md with the actual final behavior, evidence, and remaining gaps.
- Keep report, slides, video narration, source package, and live implementation consistent. Do not describe planned integrations as completed.
- SW융합 deliverables are research PDF, ZIP containing presentation PPT and source if any, and a YouTube link to a >=720p MP4 <=5 minutes. Prefix report/result names with [3]. Do not apply a different division's APK requirement.
- Documentation drafts are not final PDF/PPT/video deliverables. Verify the exported artifacts and submission receipt before calling submission complete.

## Version control
User-authorized canonical repository: https://github.com/shintaehyeon/mori--SW-festival-2026-.git
Use this checkout and origin for future version control; inspect current branch/status/remote before changes. Keep commits reviewable. Never force-push or discard unrelated work. Exclude user databases, health records, .env secrets, credentials, generated build caches, and dependencies. The official public HIRA snapshot may be regenerated with the documented import process; retain the processed hospital JSON and provenance in Git.
