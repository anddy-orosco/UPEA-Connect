import 'dart:typed_data';

// Selecciona automáticamente la implementación correcta según la plataforma
import 'pptx_save_helper_stub.dart'
if (dart.library.io) 'pptx_save_helper_mobile.dart'
if (dart.library.html) 'pptx_save_helper_web.dart';

abstract class PptxSaveHelper {
  static Future<String> saveAndDownload(List<int> bytes, String filename) {
    return saveAndDownloadImpl(bytes, filename);
  }

  static Future<Uint8List?> readLocalFile(String path) {
    return readLocalFileImpl(path);
  }
}