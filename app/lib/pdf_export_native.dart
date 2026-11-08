import 'dart:typed_data';
import 'package:printing/printing.dart';

Future<bool> exportVisitPdf(Uint8List bytes) =>
    Printing.sharePdf(bytes: bytes, filename: 'MORI_visit_preparation.pdf');
