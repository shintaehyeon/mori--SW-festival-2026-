import 'package:flutter/material.dart';
import 'api.dart';
import 'localization.dart';

const demoClinicId = '759c4c8431b9d65d8fbcc3d5';
bool isDemoClinic(Map hospital) => hospital['id'] == demoClinicId;

/// Examples are UI fixtures only, never seeded into the real review database.
class ClinicReviewsPage extends StatefulWidget {
  final Api api;
  final Map<String, dynamic> hospital;
  final bool canReview;
  const ClinicReviewsPage({
    super.key,
    required this.api,
    required this.hospital,
    required this.canReview,
  });
  @override
  State<ClinicReviewsPage> createState() => _ClinicReviewsPageState();
}

class _ClinicReviewsPageState extends State<ClinicReviewsPage> {
  final note = TextEditingController();
  final date = TextEditingController(
    text: DateTime.now().toIso8601String().substring(0, 10),
  );
  bool consent = false, busy = false;
  String method = 'translation';
  String? status;
  List<dynamic> posts = [];
  @override
  void initState() {
    super.initState();
    if (widget.canReview) load();
  }

  @override
  void dispose() {
    note.dispose();
    date.dispose();
    super.dispose();
  }

  Future<void> load() async {
    try {
      final result = await widget.api.request(
        '/api/posts?q=${Uri.encodeComponent(widget.hospital['name'])}',
      );
      if (mounted) {
        setState(
          () => posts = (result as List)
              .where((p) => p['place'] == widget.hospital['name'])
              .toList(),
        );
      }
    } catch (_) {
      if (mounted) {
        setState(() => status = tr('Unable to load experiences. Try again.'));
      }
    }
  }

  Future<void> publish() async {
    if (busy || !consent || !widget.canReview) return;
    if (note.text.trim().length < 10) {
      setState(() => status = tr('Please write at least 10 characters.'));
      return;
    }
    setState(() {
      busy = true;
      status = null;
    });
    try {
      await widget.api.request(
        '/api/posts',
        method: 'POST',
        body: {
          'title': widget.hospital['name'],
          'place': widget.hospital['name'],
          'body': note.text.trim(),
          'visitDate': date.text.trim(),
          'language':
              const {
                'ko': 'Korean',
                'en': 'English',
                'fr': 'French',
                'ja': 'Japanese',
                'zh': 'Chinese',
                'vi': 'Vietnamese',
              }[MoriLanguage.current.value] ??
              'Other',
          'method': method,
          'consent': true,
        },
      );
      if (!mounted) return;
      note.clear();
      setState(() {
        consent = false;
        status = tr('Experience published.');
      });
      await load();
    } catch (_) {
      if (mounted) {
        setState(
          () => status = tr('Could not publish. Check the date and try again.'),
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(tr('Visit experiences'))),
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          widget.hospital['name'],
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 16),
        if (isDemoClinic(widget.hospital))
          Card(
            color: const Color(0xFFFFF1CD),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tr('DEMO ONLY · Fictional reviews, not patient feedback'),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Text(tr('Example: The doctor was kind.')),
                  const SizedBox(height: 8),
                  Text(tr('Example: The clinic was very clean.')),
                ],
              ),
            ),
          ),
        const SizedBox(height: 16),
        if (!widget.canReview)
          Text(
            tr(
              'Sign in from the main screen to read or publish real experiences. The visit sheet works as a guest.',
            ),
          ),
        if (widget.canReview) ...[
          Text(tr('Real experiences · self-reported, visits not verified')),
          for (final post in posts)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text('${post['visitDate']}\n${post['body']}'),
              ),
            ),
          const SizedBox(height: 20),
          Text(
            tr('After your visit, help the next student.'),
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: date,
            decoration: InputDecoration(
              labelText: tr('Visit date (YYYY-MM-DD)'),
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: method,
            decoration: InputDecoration(labelText: tr('Communication method')),
            items: [
              DropdownMenuItem(
                value: 'translation',
                child: Text(tr('Translation app')),
              ),
              DropdownMenuItem(
                value: 'direct',
                child: Text(tr('Direct conversation')),
              ),
              DropdownMenuItem(
                value: 'friend',
                child: Text(tr('With a friend')),
              ),
            ],
            onChanged: busy ? null : (v) => setState(() => method = v!),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: note,
            maxLength: 3000,
            minLines: 3,
            maxLines: 6,
            decoration: InputDecoration(
              labelText: tr('Process, communication and tips'),
            ),
          ),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            value: consent,
            onChanged: busy
                ? null
                : (v) => setState(() => consent = v ?? false),
            title: Text(
              tr(
                'This is my experience and I agree to publish it. I removed other people’s private information.',
              ),
            ),
          ),
          FilledButton(
            onPressed: busy || !consent ? null : publish,
            child: Text(tr('Publish')),
          ),
        ],
        if (status != null) Semantics(liveRegion: true, child: Text(status!)),
        if (busy) const LinearProgressIndicator(),
      ],
    ),
  );
}
