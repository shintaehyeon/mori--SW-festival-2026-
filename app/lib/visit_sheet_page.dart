import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'localization.dart';
import 'visit_pdf.dart';
import 'pdf_export.dart';

/// Export does not upload the sheet. A platform acknowledgement is not proof
/// that the user saved the file; the visible status deliberately says requested.
class VisitSheetPage extends StatefulWidget {
  final Map<String, dynamic> card;
  final Uint8List bytes;
  final VoidCallback? onHome, onReview;
  final Future<bool> Function(Uint8List)? exportPdf;
  const VisitSheetPage({
    super.key,
    required this.card,
    required this.bytes,
    this.exportPdf,
    this.onHome,
    this.onReview,
  });
  @override
  State<VisitSheetPage> createState() => _VisitSheetPageState();
}

class _VisitSheetPageState extends State<VisitSheetPage> {
  bool exporting = false;
  String? status;
  Future<void> export() async {
    if (exporting) return;
    setState(() {
      exporting = true;
      status = null;
    });
    try {
      final requested =
          await (widget.exportPdf?.call(widget.bytes) ??
              exportVisitPdf(widget.bytes));
      if (!mounted) return;
      setState(
        () => status = tr(
          requested
              ? 'PDF export requested. Check your downloads or complete the share dialog.'
              : 'PDF export was not completed. Try again; you can still show this screen.',
        ),
      );
    } catch (_) {
      if (mounted) {
        setState(
          () => status = tr(
            'PDF export was not completed. Try again; you can still show this screen.',
          ),
        );
      }
    } finally {
      if (mounted) setState(() => exporting = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(tr('Patient-reported visit sheet')),
      actions: [
        IconButton(
          tooltip: tr('Back to home'),
          icon: const Icon(Icons.home_outlined),
          onPressed: () {
            Navigator.of(context).pop();
            widget.onHome?.call();
          },
        ),
      ],
    ),
    body: Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: exporting ? null : export,
                  icon: const Icon(Icons.download_outlined),
                  label: Text(tr('Save / share PDF')),
                ),
              ),
              if (status != null)
                Semantics(
                  liveRegion: true,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(status!),
                  ),
                ),
            ],
          ),
        ),
        Expanded(child: ClinicalVisitView(card: widget.card)),
        if (widget.onReview != null)
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: OutlinedButton.icon(
                onPressed: widget.onReview,
                icon: const Icon(Icons.rate_review_outlined),
                label: Text(tr('Finished your visit? Leave an experience')),
              ),
            ),
          ),
      ],
    ),
  );
}
