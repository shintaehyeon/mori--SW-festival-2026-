# MORI: finding care → preparing words

Value: 한국에서 아픈 유학생이 갈 병원을 찾고, 자신의 증상을 한국어로 전달하도록 돕는다.

## Revised hierarchy
- Sage/off-white background, white cards, dark green primary CTA, large clinic title, separate labelled address, explicit registered doctor count.
- Specialist count separate from declared department list; duplicate Korean translations removed. Full institutional details collapsed.
- Visit preparation visible without expanding. Google directions and phone are secondary. Removed redundant Google-review/Naver/Kakao links from results, not because every link was broken but to reduce competing choices.
- Google directions is an external link, not live capacity/appointments/imported reviews. Internal map still requires its map key.
- Guest continuation is the primary action after selecting a hospital; email account form collapsed. Original, translation review and PDF use existing server checks.
- Guest sessions expire at 24 hours. Expired user data is purged on the next server request. Users may delete immediately; guest records are not migrated to a signed-in account. Download the PDF before switching or signing out.
- Community experiences require a full account. Public-looking fake reviews are not seeded. The empty state shows clearly labelled writing prompts, not claimed visits to a real institution.
- Google login integration is prepared but hidden until client and server OAuth IDs are configured. No real OAuth success claimed.

## Original scope mapping
Core: clinic discovery (area 3), symptom preparation/translation (areas 2/4).
Supporting: optional health information (area 1), account-gated experience sharing after a visit (area 5).
No diagnosis, mandatory diary, booking or automated anomaly detection added.

## Design reference
https://www.figma.com/design/Vu7PioVBtWhCiyppfou9WT?node-id=3-2
Three editable concept screens, Noto Sans typography. English clinic names in the design are illustrative reading aids, not verified official business names. Running app retains official Korean names.

## Open-source applied / retained
| Package | Use | Status |
|---|---|---|
| Flutter Material 3 | ThemeData, Card, FilledButton, ExpansionTile and chips | Refined existing framework; no extra UI kit |
| google_sign_in 7.2.0 / google_sign_in_web 1.1.3 | Official client authentication | Added, OAuth setup pending |
| google-auth-library | Verify Google ID token on Node server | Added; synthetic integration tests |
| geolocator | Permission and device location | Existing, real handset validation pending |
| url_launcher | Phone / external Google directions | Existing |
| pdf / printing | One-page visit PDF and native sharing | Existing |
| Noto Sans / Nanum Gothic | Multilingual app/PDF typography | Existing local font assets |

Why no full new UI kit: the problem is information order and competing actions; native Material components can solve it without introducing a new theme framework before submission.
