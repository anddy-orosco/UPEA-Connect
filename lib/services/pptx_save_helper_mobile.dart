import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';

Future<String> saveAndDownloadImpl(List<int> bytes, String filename) async {
  final outputDir = await getApplicationDocumentsDirectory();
  final filePath = '${outputDir.path}/$filename';
  final file = File(filePath);
  await file.writeAsBytes(bytes, flush: true);
  return filePath;
}

Future<Uint8List?> readLocalFileImpl(String path) async {
  final file = File(path);
  if (await file.exists()) {
    return await file.readAsBytes();
  }
  return null;
}