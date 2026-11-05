import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// UI language is local to this device. Never translates patient-entered text.
class MoriLanguage {
  static const names = {
    'ko': '한국어',
    'zh': '简体中文',
    'ja': '日本語',
    'vi': 'Tiếng Việt',
    'en': 'English',
    'fr': 'Français',
  };
  static final current = ValueNotifier<String>('en');
  static Map<String, dynamic> catalog = {};
  static const storage = FlutterSecureStorage();
  static Future<void> initialize() async {
    catalog = jsonDecode(
      await rootBundle.loadString('assets/i18n/catalog.json'),
    );
    String? saved;
    try {
      saved = await storage.read(key: 'mori_ui_language');
    } catch (_) {}
    final device =
        WidgetsBinding.instance.platformDispatcher.locale.languageCode;
    current.value = names.containsKey(saved)
        ? saved!
        : (names.containsKey(device) ? device : 'en');
  }

  static Future<void> select(String code) async {
    if (!names.containsKey(code)) return;
    current.value = code;
    await storage.write(key: 'mori_ui_language', value: code);
  }

  static String text(String en, [String? ko]) {
    final code = current.value;
    const prefix = 'Your self-reported condition: ';
    if (en.startsWith(prefix) &&
        en != r'Your self-reported condition: $condition') {
      final state = conditionLabel(en.substring(prefix.length));
      final template =
          catalog[r'Your self-reported condition: $condition']?[code] ??
          (code == 'ko'
              ? r'직접 기록한 오늘의 컨디션: $condition'
              : r'Your self-reported condition: $condition');
      return (template as String).replaceAll(r'$condition', state);
    }

    if (code == 'ko' && ko != null) return ko;
    if (code == 'en') return (catalog[en]?['en'] as String?) ?? en;
    final row = catalog[en] as Map?;
    if (row != null) return row[code] as String? ?? en;
    // Legacy dynamic labels: explicit placeholders, never arbitrary user text.
    final contact = RegExp(r'^Contact name (\d+)$').firstMatch(en);
    if (contact != null) {
      return text(
        r'Contact name ${i + 1}',
      ).replaceAll(r'${i + 1}', contact[1]!);
    }
    return en;
  }

  static String conditionLabel(dynamic code) => text(switch (code) {
    'good' => 'Good',
    'okay' => 'Okay',
    'low' => 'Low',
    _ => 'Unknown',
  });
}

String tr(String en, [String? ko]) => MoriLanguage.text(en, ko);

class LanguagePicker extends StatelessWidget {
  final VoidCallback? onChanged;
  const LanguagePicker({super.key, this.onChanged});
  @override
  Widget build(BuildContext context) => PopupMenuButton<String>(
    tooltip: '한국어 · 中文 · 日本語 · Tiếng Việt · English · Français',
    initialValue: MoriLanguage.current.value,
    onSelected: (code) async {
      try {
        await MoriLanguage.select(code);
      } catch (_) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                tr(
                  'Language changed for this session; could not save preference.',
                ),
              ),
            ),
          );
        }
      }
      onChanged?.call();
    },
    itemBuilder: (_) => MoriLanguage.names.entries
        .map(
          (e) => CheckedPopupMenuItem<String>(
            value: e.key,
            checked: e.key == MoriLanguage.current.value,
            child: Text(e.value),
          ),
        )
        .toList(),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.language, size: 20),
          const SizedBox(width: 4),
          Text(MoriLanguage.current.value.toUpperCase()),
        ],
      ),
    ),
  );
}
