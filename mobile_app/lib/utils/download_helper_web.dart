// ignore_for_file: avoid_web_libraries_in_flutter
import 'dart:typed_data';
import 'package:web/web.dart' as web;
import 'dart:js_interop';

void downloadFile(List<int> bytes, String filename) {
  // Convert List<int> to Uint8List
  final uint8list = Uint8List.fromList(bytes);

  // Determine MIME type from filename
  String mimeType = 'application/octet-stream';
  if (filename.toLowerCase().endsWith('.pdf')) {
    mimeType = 'application/pdf';
  } else if (filename.toLowerCase().endsWith('.xlsx')) {
    mimeType = 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
  } else if (filename.toLowerCase().endsWith('.xls')) {
    mimeType = 'application/vnd.ms-excel';
  }

  // Create Blob from bytes using package:web
  final blob = web.Blob(
    [uint8list.toJS].toJS,
    web.BlobPropertyBag(type: mimeType),
  );

  final url = web.URL.createObjectURL(blob);

  // Create anchor and trigger download
  final anchor = web.document.createElement('a') as web.HTMLAnchorElement
    ..href = url
    ..download = filename
    ..style.display = 'none';

  web.document.body!.append(anchor);
  anchor.click();
  web.document.body!.removeChild(anchor);

  // Revoke blob URL to free memory
  web.URL.revokeObjectURL(url);
}
