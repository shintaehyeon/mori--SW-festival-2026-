/// Explicit patient selection only; never infer anatomy from symptom text.
const visitBodyRegions = {
  'head': '머리 / Head',
  'neck': '목 / Neck',
  'chest': '가슴 / Chest',
  'abdomen': '배 / Abdomen',
  'pelvis': '골반 / Pelvis',
  'back': '등·허리 / Back',
  'arms': '팔 / Arms',
  'legs': '다리 / Legs',
};

String visitBodySvg(String? region) {
  const points = {
    'head': [50, 20],
    'neck': [50, 40],
    'chest': [50, 63],
    'abdomen': [50, 90],
    'pelvis': [50, 112],
    'back': [150, 82],
    'arms': [25, 85],
    'legs': [42, 149],
  };
  final p = points[region];
  String figure(int x) =>
      '''<g transform="translate($x 0)" fill="#e5ece9" stroke="#73877e" stroke-width="1.5">
  <circle cx="50" cy="20" r="14"/>
  <path d="M44 34 L44 42 L33 46 Q29 48 26 58 L12 100 Q10 108 16 109 Q21 109 23 103 L34 73 L33 111 L35 120 L32 175 Q32 181 39 181 Q45 181 46 175 L50 128 L54 175 Q55 181 62 181 Q68 181 68 175 L65 120 L67 111 L66 73 L77 103 Q79 109 84 109 Q90 108 88 100 L74 58 Q71 48 67 46 L56 42 L56 34 Z"/>
  </g>''';
  return '''<svg xmlns="http://www.w3.org/2000/svg" width="200" height="190" viewBox="0 0 200 190">
  ${figure(0)}${figure(100)}
  ${p == null ? '' : '<circle cx="${p[0]}" cy="${p[1]}" r="11" fill="#f7c1ad" stroke="#a64126" stroke-width="2"/><circle cx="${p[0]}" cy="${p[1]}" r="3" fill="#a64126"/>'}
  ${region == 'arms' || region == 'legs' ? '<circle cx="${region == 'arms' ? 75 : 58}" cy="${region == 'arms' ? 85 : 149}" r="11" fill="#f7c1ad" stroke="#a64126" stroke-width="2"/>' : ''}
  </svg>''';
}
