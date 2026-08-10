import 'dart:html' as html;
import 'dart:typed_data';

Future<String> saveAndDownloadImpl(List<int> bytes, String filename) async {
  final blob = html.Blob(
    [bytes],
    'application/vnd.openxmlformats-officedocument.presentationml.presentation',
  );
  final url = html.Url.createObjectUrlFromBlob(blob);
  final anchor = html.AnchorElement(href: url)
    ..setAttribute('download', filename)
    ..style.display = 'none';

  html.document.body?.children.add(anchor);
  anchor.click();
  html.document.body?.children.remove(anchor);
  html.Url.revokeObjectUrl(url);

  return 'Archivo descargado en el navegador';
}

Future<Uint8List?> readLocalFileImpl(String path) async {
  return null;
}