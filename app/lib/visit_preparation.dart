import 'localization.dart';

/// Preserve only patient-entered facts; optional blanks are not negatives.
String composeVisitConcern(
  String concern,
  String course,
  String triggers,
  String questions,
) {
  final sections = <String>[concern.trim()];
  for (final entry in {
    '증상 변화 / Changes': course,
    '악화·완화 상황 / Better or worse': triggers,
    '의료진에게 질문 / Questions': questions,
  }.entries) {
    if (entry.value.trim().isNotEmpty) {
      sections.add('${entry.key}: ${entry.value.trim()}');
    }
  }
  final result = sections.join('\n\n');
  if (result.length > 2000) {
    throw FormatException(
      tr('Please shorten your answers to 2000 characters total.'),
    );
  }
  return result;
}
