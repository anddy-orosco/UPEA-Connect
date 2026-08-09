import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import '../models/note_page_model.dart';

class PptxExportService {
  static Future<String> exportNotesToPptx(List<NotePageModel> pages, String title) async {
    try {
      final StringBuffer buffer = StringBuffer();
      buffer.writeln('=== DOCUMENTO DE NOTAS: $title ===\n');

      for (int i = 0; i < pages.length; i++) {
        final page = pages[i];
        buffer.writeln('--- Página / Diapositiva ${i + 1} ---');

        if (page.textContent.isNotEmpty) {
          buffer.writeln('Contenido Principal:');
          buffer.writeln(page.textContent);
          buffer.writeln();
        }

        if (page.floatingElements.isNotEmpty) {
          buffer.writeln('Elementos Flotantes:');
          for (var elem in page.floatingElements) {
            if (elem.isImage) {
              buffer.writeln(' - [Imagen] Posición: (${elem.position.dx.toInt()}, ${elem.position.dy.toInt()})');
            } else if (elem.text.isNotEmpty) {
              buffer.writeln(' - [Texto Flotante]: ${elem.text}');
            }
          }
          buffer.writeln();
        }
      }

      final content = buffer.toString();
      final filename = '$title.txt';

      if (kIsWeb) {
        // Genera la descarga física del archivo en el navegador
        final bytes = utf8.encode(content);
        final blob = html.Blob([bytes], 'text/plain;charset=utf-8');
        final url = html.Url.createObjectUrlFromBlob(blob);
        final anchor = html.AnchorElement(href: url)
          ..setAttribute('download', filename)
          ..click();
        html.Url.revokeObjectUrl(url);
        return 'Archivo descargado automáticamente ($filename)';
      } else {
        final outputDir = await getApplicationDocumentsDirectory();
        final filePath = '${outputDir.path}/$filename';
        final file = File(filePath);
        await file.writeAsString(content);
        return filePath;
      }
    } catch (e) {
      return 'Error al exportar: $e';
    }
  }
}