import 'package:web/web.dart' as web;

/// Web implementation using standard DOM AnchorElement download attribute.
void triggerBrowserDownload(String base64Data, String fileName, String? fileType) {
  final ext = (fileType ?? '').toLowerCase();
  String mimeType = 'application/octet-stream';
  if (ext == 'pdf') {
    mimeType = 'application/pdf';
  } else if (ext == 'png') {
    mimeType = 'image/png';
  } else if (ext == 'jpg' || ext == 'jpeg') {
    mimeType = 'image/jpeg';
  }

  final anchor = web.document.createElement('a') as web.HTMLAnchorElement;
  anchor.href = 'data:$mimeType;base64,$base64Data';
  anchor.download = fileName;
  web.document.body?.appendChild(anchor);
  anchor.click();
  anchor.remove();
}
