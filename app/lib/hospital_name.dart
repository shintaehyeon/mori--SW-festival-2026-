import 'package:flutter/material.dart';
import 'localization.dart';

/// Syllable-based reading aid, NOT an official foreign-language business name.
/// Ambiguous brand names and Korean sound changes need human review.
String romanizedHospitalName(String name) {
  const onset = [
    'g',
    'kk',
    'n',
    'd',
    'tt',
    'r',
    'm',
    'b',
    'pp',
    's',
    'ss',
    '',
    'j',
    'jj',
    'ch',
    'k',
    't',
    'p',
    'h',
  ];
  const vowel = [
    'a',
    'ae',
    'ya',
    'yae',
    'eo',
    'e',
    'yeo',
    'ye',
    'o',
    'wa',
    'wae',
    'oe',
    'yo',
    'u',
    'wo',
    'we',
    'wi',
    'yu',
    'eu',
    'ui',
    'i',
  ];
  const coda = [
    '',
    'k',
    'k',
    'k',
    'n',
    'n',
    'n',
    't',
    'l',
    'k',
    'm',
    'l',
    'l',
    'l',
    'p',
    'l',
    'm',
    'p',
    'p',
    't',
    't',
    'ng',
    't',
    't',
    'k',
    't',
    'p',
    't',
  ];
  // Separate familiar institution suffixes, preserving the Korean sound.
  final spaced = name
      .replaceAllMapped(
        RegExp(r'(종합병원|요양병원|한방병원|치과의원|한의원|의원|병원|약국)$'),
        (m) => ' ${m[0]}',
      )
      .trim();
  final out = StringBuffer();
  for (final rune in spaced.runes) {
    final n = rune - 0xac00;
    if (n < 0 || n > 11171) {
      out.writeCharCode(rune);
      continue;
    }
    out.write('${onset[n ~/ 588]}${vowel[(n % 588) ~/ 28]}${coda[n % 28]}');
  }
  return out
      .toString()
      .replaceAll(RegExp(r'\s+'), ' ')
      .split(' ')
      .map((s) => s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}')
      .join(' ');
}

String localizedHospitalReading(String name) {
  final endings = {
    '종합병원': 'General hospital',
    '요양병원': 'Long-term care hospital',
    '치과의원': 'Dental clinic',
    '치과병원': 'Dental hospital',
    '한방병원': 'Korean medicine hospital · Traditional medicine',
    '한의원': 'Korean medicine clinic · Traditional medicine',
    '의원': 'Clinic',
    '병원': 'Hospital',
    '약국': 'Pharmacy · unverified',
  };
  for (final entry in endings.entries) {
    if (name.endsWith(entry.key)) {
      final stem = name.substring(0, name.length - entry.key.length).trim();
      return '${romanizedHospitalName(stem)} · ${tr(entry.value)}';
    }
  }
  return romanizedHospitalName(name);
}

class HospitalName extends StatelessWidget {
  final String name;
  const HospitalName(this.name, {super.key});
  @override
  Widget build(BuildContext context) {
    // Subscribe to Flutter locale changes, including already open routes.
    Localizations.localeOf(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(name),
        if (MoriLanguage.current.value != 'ko') ...[
          const SizedBox(height: 3),
          Text(
            localizedHospitalReading(name),
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          Text(
            '${tr('Romanized reading (approx.)')}: ${romanizedHospitalName(name)}',
            style: TextStyle(
              fontSize: 10,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }
}
