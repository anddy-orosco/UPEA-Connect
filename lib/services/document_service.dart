import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

class DocumentService {
  static String detectFileType(String pathOrName) {
    final ext = pathOrName.split('.').last.toLowerCase();
    if (ext == 'pdf') return 'pdf';
    if (ext == 'xls' || ext == 'xlsx' || ext == 'csv') return 'excel';
    if (ext == 'doc' || ext == 'docx' || ext == 'txt') return 'document';
    if (ext == 'ppt' || ext == 'pptx') return 'presentation';
    return 'image';
  }

  static Future<Map<String, String>?> pickFromGallery() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (image != null) {
        if (kIsWeb) {
          final bytes = await image.readAsBytes();
          final base64String = base64Encode(bytes);
          return {
            'path': 'data:image/jpeg;base64,$base64String',
            'type': 'image',
          };
        }

        final appDir = await getApplicationDocumentsDirectory();
        final localPath = '${appDir.path}/${DateTime.now().millisecondsSinceEpoch}_${image.name}';
        await File(image.path).copy(localPath);

        return {'path': localPath, 'type': 'image'};
      }
    } catch (e) {
      debugPrint('Error en galería: $e');
    }
    return null;
  }

  static Future<Map<String, String>?> pickDocumentFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf', 'doc', 'docx', 'xls', 'xlsx', 'txt'],
        withData: true, // Vital para leer bytes en Web y evitar el error de 'path'
      );

      if (result != null && result.files.single != null) {
        final platformFile = result.files.single;

        if (kIsWeb) {
          if (platformFile.bytes != null) {
            final mime = _getMimeType(platformFile.name);
            final base64String = base64Encode(platformFile.bytes!);
            return {
              'path': 'data:$mime;base64,$base64String',
              'type': detectFileType(platformFile.name),
            };
          }
          return null;
        }

        if (platformFile.path != null) {
          final appDir = await getApplicationDocumentsDirectory();
          final localPath = '${appDir.path}/${DateTime.now().millisecondsSinceEpoch}_${platformFile.name}';

          await File(platformFile.path!).copy(localPath);
          final fileType = detectFileType(localPath);

          return {'path': localPath, 'type': fileType};
        }
      }
    } catch (e) {
      debugPrint('Error al seleccionar archivo: $e');
    }
    return null;
  }

  static String _getMimeType(String fileName) {
    final ext = fileName.split('.').last.toLowerCase();
    if (ext == 'pdf') return 'application/pdf';
    if (ext == 'png') return 'image/png';
    if (ext == 'jpg' || ext == 'jpeg') return 'image/jpeg';
    if (ext == 'xlsx' || ext == 'xls') return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
    if (ext == 'docx' || ext == 'doc') return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
    return 'application/octet-stream';
  }
}