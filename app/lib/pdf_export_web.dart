import 'dart:async';
import 'dart:js_interop';
import 'dart:typed_data';
import 'package:web/web.dart' as web;

/// Use the browser directly: web export does not require a native print channel,
/// a PDF viewer library, or sending patient data to another server.
Future<bool> exportVisitPdf(Uint8List bytes) async {
  final body = web.document.body;
  if (body == null) return false;
  final url = web.URL.createObjectURL(
    web.Blob([bytes.toJS].toJS, web.BlobPropertyBag(type: 'application/pdf')),
  );
  final link = web.HTMLAnchorElement()
    ..href = url
    ..download = 'MORI_visit_preparation.pdf';
  try {
    body.append(link);
    link.click();
    return true;
  } finally {
    link.remove();
    // Revoking synchronously can cancel downloads in some browsers.
    Timer(const Duration(minutes: 1), () => web.URL.revokeObjectURL(url));
  }
}
