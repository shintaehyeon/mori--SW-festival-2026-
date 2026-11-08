import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'localization.dart';

/// Public guidance informs question topics, not diagnosis or institutional approval.
const visitQuestionSources = [
  (
    '1, 2, 3, 4, 5 · NIH / NLM MedlinePlus',
    'Talking With Your Doctor',
    'https://medlineplus.gov/talkingwithyourdoctor.html',
  ),
  (
    '1, 2, 3, 4, 5 · NHS',
    'What to ask your doctor or other healthcare professional',
    'https://www.nhs.uk/nhs-services/gps/what-to-ask-your-doctor/',
  ),
  (
    '3 · FDA',
    'Stop – Learn – Go: Tips for Talking with Your Pharmacist',
    'https://www.fda.gov/drugs/information-consumers-and-patients-drugs/stop-learn-go-tips-talking-your-pharmacist-learn-how-use-medicines-safely',
  ),
];

class QuestionSources extends StatelessWidget {
  const QuestionSources({super.key});
  @override
  Widget build(BuildContext context) => ExpansionTile(
    tilePadding: EdgeInsets.zero,
    leading: const Icon(Icons.library_books_outlined, size: 20),
    title: Text(tr('Question sources')),
    childrenPadding: const EdgeInsets.only(bottom: 12),
    expandedCrossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(
        tr(
          'Adapted by MORI from public health guidance. Not an official hospital form or a validated diagnostic questionnaire.',
        ),
      ),
      const SizedBox(height: 12),
      for (final source in visitQuestionSources) ...[
        Text(source.$1, style: Theme.of(context).textTheme.titleSmall),
        TextButton.icon(
          icon: const Icon(Icons.open_in_new, size: 16),
          label: Text(source.$2),
          onPressed: () async {
            await launchUrl(
              Uri.parse(source.$3),
              mode: LaunchMode.externalApplication,
            );
          },
        ),
        SelectableText(source.$3, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 12),
      ],
    ],
  );
}
