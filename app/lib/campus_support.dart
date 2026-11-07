import 'package:flutter/material.dart';
import 'localization.dart';

/// Public university contacts; never attaches a student's health information.
class HandongSupport extends StatelessWidget {
  final void Function(Uri) onOpen;
  const HandongSupport({super.key, required this.onOpen});
  static final phone = Uri(scheme: 'tel', path: '+82542601765');
  static final general = Uri(scheme: 'mailto', path: 'oiahelp@handong.edu');
  static final exchange = Uri(scheme: 'mailto', path: 'exchange@handong.edu');
  static final source = Uri.parse(
    'https://www.handong.edu/eng/connect/announcements/?id=51825&mode=view',
  );
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        tr('Handong international student support'),
        style: Theme.of(context).textTheme.titleLarge,
      ),
      const SizedBox(height: 8),
      Text(
        tr(
          'For Handong students who need help with university life or finding the right university office.',
        ),
      ),
      const SizedBox(height: 8),
      Text(
        tr(
          'University support is not an emergency service. Hours and response times are unconfirmed. In an emergency, use 119 or 112 without waiting for a reply.',
        ),
      ),
      const SizedBox(height: 12),
      Text(tr('Academic affairs / student life')),
      OutlinedButton.icon(
        onPressed: () => onOpen(phone),
        icon: const Icon(Icons.call_outlined),
        label: const Text('+82 54-260-1765'),
      ),
      Text(tr('General student enquiries')),
      TextButton.icon(
        onPressed: () => onOpen(general),
        icon: const Icon(Icons.email_outlined),
        label: const Text('oiahelp@handong.edu'),
      ),
      Text(tr('Exchange / visiting students')),
      TextButton.icon(
        onPressed: () => onOpen(exchange),
        icon: const Icon(Icons.email_outlined),
        label: const Text('exchange@handong.edu'),
      ),
      Text(
        tr(
          'Email opens a draft only. No health details are attached. MORI is a student project, not an official university service.',
        ),
      ),
      TextButton.icon(
        onPressed: () => onOpen(source),
        icon: const Icon(Icons.open_in_new),
        label: Text(tr('University source · checked 2026-11-08')),
      ),
      TextButton(
        onPressed: () =>
            onOpen(Uri.parse('https://www.handong.edu/eng/connect/contacts/')),
        child: Text(tr('Official exchange contacts')),
      ),
    ],
  );
}
