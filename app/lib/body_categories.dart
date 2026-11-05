import 'localization.dart';
import 'package:flutter/material.dart';

const specialtyEnglish = {
  '내과': 'Internal medicine',
  '가정의학과': 'Family medicine',
  '외과': 'General surgery',
  '신경과': 'Neurology',
  '신경외과': 'Neurosurgery',
  '정신건강의학과': 'Psychiatry',
  '정형외과': 'Orthopedics',
  '재활의학과': 'Rehabilitation medicine',
  '마취통증의학과': 'Anesthesiology & pain medicine',
  '심장혈관흉부외과': 'Cardiovascular & thoracic surgery',
  '안과': 'Ophthalmology',
  '이비인후과': 'ENT (ear, nose & throat)',
  '피부과': 'Dermatology',
  '비뇨의학과': 'Urology',
  '산부인과': 'Obstetrics & gynecology',
  '소아청소년과': 'Pediatrics',
  '성형외과': 'Plastic surgery',
  '응급의학과': 'Emergency medicine',
  '영상의학과': 'Radiology',
  '진단검사의학과': 'Laboratory medicine',
  '병리과': 'Pathology',
  '방사선종양학과': 'Radiation oncology',
  '핵의학과': 'Nuclear medicine',
  '예방의학과': 'Preventive medicine',
  '직업환경의학과': 'Occupational & environmental medicine',
  '결핵과': 'Tuberculosis medicine',
  '치과': 'Dentistry',
  '구강내과': 'Oral medicine',
  '구강병리과': 'Oral pathology',
  '구강악안면외과': 'Oral & maxillofacial surgery',
  '소아치과': 'Pediatric dentistry',
  '예방치과': 'Preventive dentistry',
  '영상치의학과': 'Oral & maxillofacial radiology',
  '치과교정과': 'Orthodontics',
  '치과보존과': 'Conservative dentistry',
  '치과보철과': 'Prosthodontics',
  '치주과': 'Periodontics',
  '통합치의학과': 'Advanced general dentistry',
  '한방내과': 'Korean medicine: internal medicine',
  '한방부인과': 'Korean medicine: gynecology',
  '한방소아과': 'Korean medicine: pediatrics',
  '한방신경정신과': 'Korean medicine: neuropsychiatry',
  '한방안·이비인후·피부과': 'Korean medicine: eyes, ENT & skin',
  '한방재활의학과': 'Korean medicine: rehabilitation',
  '사상체질과': 'Sasang constitutional medicine',
  '침구과': 'Acupuncture & moxibustion',
};
String bilingualSpecialty(String name) =>
    '${tr(specialtyEnglish[name] ?? 'Translation unavailable', name)} · $name';

class BodyCategory {
  final String id, en, ko;
  final List<String> departments;
  const BodyCategory(this.id, this.en, this.ko, this.departments);
}

const bodyCategories = [
  BodyCategory('head', 'Head & nerves', '머리·신경', ['신경과', '신경외과']),
  BodyCategory('eyes', 'Eyes', '눈', ['안과']),
  BodyCategory('ent', 'Ear · nose · throat', '귀·코·목', ['이비인후과']),
  BodyCategory('teeth', 'Teeth', '치아', [
    '치과',
    '구강내과',
    '구강악안면외과',
    '소아치과',
    '예방치과',
    '치과교정과',
    '치과보존과',
    '치과보철과',
    '치주과',
    '통합치의학과',
  ]),
  BodyCategory('organs', 'Internal organs', '장기·내과', ['내과', '가정의학과']),
  BodyCategory('bones', 'Bones & joints', '뼈·관절', ['정형외과', '재활의학과']),
  BodyCategory('skin', 'Skin', '피부', ['피부과']),
  BodyCategory('pelvis', 'Pelvic health', '골반·비뇨·여성', ['비뇨의학과', '산부인과']),
  BodyCategory('general', 'General care', '전신·어느 과일까?', ['가정의학과', '내과']),
];
bool matchesBodyCategory(Map h, BodyCategory? category) =>
    category == null ||
    (h['departments'] as List? ?? []).any(
      (d) => category.departments.contains(d['name']),
    );

class BodyCategoryPicker extends StatelessWidget {
  final String? selected;
  final bool ko;
  final ValueChanged<BodyCategory?> onSelect;
  const BodyCategoryPicker({
    super.key,
    required this.selected,
    required this.ko,
    required this.onSelect,
  });
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(
        tr('Explore care by body area', '어느 부위를 찾고 있나요?'),
        style: Theme.of(context).textTheme.titleLarge,
      ),
      Text(
        tr(
          'Explore departments by picture. Not a diagnosis or urgency assessment.',
          '그림으로 관련 진료과를 탐색해요. 진단·응급도 판정이 아닙니다.',
        ),
      ),
      const SizedBox(height: 12),
      LayoutBuilder(
        builder: (context, c) {
          final columns = c.maxWidth < 500 ? 3 : 5;
          return Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final item in bodyCategories)
                SizedBox(
                  width: (c.maxWidth - 8 * (columns - 1)) / columns,
                  child: Semantics(
                    button: true,
                    selected: selected == item.id,
                    label: tr(item.en, item.ko),
                    child: Material(
                      color: selected == item.id
                          ? const Color(0xFFD9EEE4)
                          : Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(
                          color: selected == item.id
                              ? const Color(0xFF28654F)
                              : const Color(0xFFE1E6E3),
                          width: selected == item.id ? 2 : 1,
                        ),
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () => onSelect(item),
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: Column(
                            children: [
                              SizedBox(
                                height: 78,
                                width: 64,
                                child: CustomPaint(
                                  painter: BodyAreaPainter(item.id),
                                ),
                              ),
                              SizedBox(
                                height: 72,
                                child: Center(
                                  child: Text(
                                    tr(item.en, item.ko),
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
      if (selected != null)
        TextButton.icon(
          onPressed: () => onSelect(null),
          icon: const Icon(Icons.close),
          label: Text(tr('Clear filter · all hospitals', '선택 해제 · 전체 병원')),
        ),
    ],
  );
}

// Original vector illustration; no medical triage logic.
class BodyAreaPainter extends CustomPainter {
  final String area;
  const BodyAreaPainter(this.area);
  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 100, size.height / 120);
    final base = Paint()..color = const Color(0xFFD8E6E0),
        h = Paint()..color = const Color(0xFFDE795B);
    void line(Offset a, Offset b, Paint p, double width) {
      canvas.drawLine(
        a,
        b,
        Paint()
          ..color = p.color
          ..strokeWidth = width
          ..strokeCap = StrokeCap.round,
      );
    }

    canvas.drawCircle(const Offset(50, 17), 13, base);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(33, 33, 34, 43),
        const Radius.circular(12),
      ),
      base,
    );
    line(const Offset(36, 39), const Offset(24, 70), base, 11);
    line(const Offset(64, 39), const Offset(76, 70), base, 11);
    line(const Offset(41, 74), const Offset(38, 109), base, 13);
    line(const Offset(59, 74), const Offset(62, 109), base, 13);
    if (area == 'head') {
      canvas.drawOval(const Rect.fromLTWH(40, 7, 20, 18), h);
      line(const Offset(50, 8), const Offset(50, 23), base, 2);
    }
    if (area == 'eyes') {
      canvas.drawOval(const Rect.fromLTWH(37, 13, 26, 9), h);
      canvas.drawCircle(const Offset(44, 17), 2, base);
      canvas.drawCircle(const Offset(56, 17), 2, base);
    }
    if (area == 'ent') {
      canvas.drawCircle(const Offset(36, 17), 4, h);
      canvas.drawCircle(const Offset(64, 17), 4, h);
      line(const Offset(50, 18), const Offset(50, 32), h, 5);
    }
    if (area == 'teeth') {
      canvas.drawPath(
        Path()
          ..moveTo(42, 19)
          ..quadraticBezierTo(38, 9, 48, 12)
          ..quadraticBezierTo(61, 7, 60, 17)
          ..lineTo(56, 28)
          ..quadraticBezierTo(53, 32, 51, 23)
          ..quadraticBezierTo(48, 21, 47, 29)
          ..quadraticBezierTo(44, 31, 42, 19),
        h,
      );
    }
    if (area == 'organs') {
      canvas.drawOval(const Rect.fromLTWH(37, 38, 11, 17), h);
      canvas.drawOval(const Rect.fromLTWH(52, 38, 11, 17), h);
      canvas.drawPath(
        Path()
          ..moveTo(50, 54)
          ..lineTo(50, 60)
          ..cubicTo(70, 54, 64, 76, 48, 69)
          ..quadraticBezierTo(43, 63, 50, 60),
        h,
      );
      line(const Offset(41, 74), const Offset(58, 74), h, 3);
      line(const Offset(41, 78), const Offset(56, 78), h, 3);
    }
    if (area == 'bones') {
      line(const Offset(41, 77), const Offset(38, 106), h, 5);
      line(const Offset(59, 77), const Offset(62, 106), h, 5);
      canvas.drawCircle(const Offset(39, 93), 5, h);
      canvas.drawCircle(const Offset(61, 93), 5, h);
    }
    if (area == 'skin') {
      for (final p in [
        const Offset(30, 50),
        const Offset(67, 57),
        const Offset(46, 42),
        const Offset(60, 95),
      ]) {
        canvas.drawCircle(p, 4, h);
      }
    }
    if (area == 'pelvis') {
      canvas.drawOval(const Rect.fromLTWH(36, 65, 28, 17), h);
    }
    if (area == 'general') {
      line(const Offset(50, 41), const Offset(50, 66), h, 9);
      line(const Offset(38, 53), const Offset(62, 53), h, 9);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant BodyAreaPainter old) => area != old.area;
}
