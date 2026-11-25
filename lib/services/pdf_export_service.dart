import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:http/http.dart' as http;
import '../models/note_page_model.dart';
import 'pptx_save_helper.dart';

class PdfExportService {
  /// Exporta los apuntes completos a un documento PDF vectorial A4 de alta calidad.
  static Future<String> exportNotesToPdf({
    required List<NotePageModel> pages,
    required String title,
    String? courseName,
  }) async {
    final pdf = pw.Document(
      title: title,
      author: 'UPEA Connect',
      subject: courseName ?? 'Apuntes Universitarios',
      creator: 'UPEA Connect - Carrera de Ingeniería de Sistemas',
    );

    final cleanTitle = title.trim().isEmpty ? 'Apunte_Sin_Titulo' : title.trim();
    final formattedDate = DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now());

    // Descargar o cargar imágenes en memoria para incrustarlas en el PDF
    final Map<String, Uint8List> imagesCache = {};
    for (final page in pages) {
      for (final elem in page.floatingElements) {
        if (elem.isImage && elem.imagePath != null && elem.imagePath!.isNotEmpty) {
          final path = elem.imagePath!;
          if (!imagesCache.containsKey(path)) {
            final bytes = await _loadImageBytes(path);
            if (bytes != null) {
              imagesCache[path] = bytes;
            }
          }
        }
      }
    }

    // Colores institucionales UPEA para el PDF
    final primaryColor = PdfColor.fromHex('1A365D'); // Azul UPEA
    final accentColor = PdfColor.fromHex('C53030');  // Rojo UPEA
    final darkTextColor = PdfColor.fromHex('1A202C');
    final secondaryTextColor = PdfColor.fromHex('4A5568');
    final lightBgColor = PdfColor.fromHex('F7FAFC');
    final noteBoxBg = PdfColor.fromHex('FFFDE7');    // Amarillo post-it suave
    final noteBoxBorder = PdfColor.fromHex('FFE082');

    // Construir cada página del apunte
    for (int i = 0; i < pages.length; i++) {
      final pageModel = pages[i];
      final pageNumber = i + 1;
      final totalPages = pages.length;

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.symmetric(horizontal: 36, vertical: 36),
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // =============================================================
                // ENCABEZADO INSTITUCIONAL
                // =============================================================
                pw.Container(
                  padding: const pw.EdgeInsets.only(bottom: 10),
                  decoration: pw.BoxDecoration(
                    border: pw.Border(
                      bottom: pw.BorderSide(color: primaryColor, width: 2),
                    ),
                  ),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            'UNIVERSIDAD PÚBLICA DE EL ALTO',
                            style: pw.TextStyle(
                              fontSize: 9,
                              fontWeight: pw.FontWeight.bold,
                              color: secondaryTextColor,
                              letterSpacing: 1.0,
                            ),
                          ),
                          pw.SizedBox(height: 2),
                          pw.Text(
                            cleanTitle,
                            style: pw.TextStyle(
                              fontSize: 18,
                              fontWeight: pw.FontWeight.bold,
                              color: primaryColor,
                            ),
                          ),
                          if (courseName != null && courseName.trim().isNotEmpty) ...[
                            pw.SizedBox(height: 3),
                            pw.Container(
                              padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: pw.BoxDecoration(
                                color: lightBgColor,
                                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                                border: pw.Border.all(color: primaryColor, width: 0.5),
                              ),
                              child: pw.Text(
                                'Materia: ${courseName.trim()}',
                                style: pw.TextStyle(
                                  fontSize: 9,
                                  fontWeight: pw.FontWeight.bold,
                                  color: primaryColor,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.end,
                        children: [
                          pw.Container(
                            padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: pw.BoxDecoration(
                              color: primaryColor,
                              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                            ),
                            child: pw.Text(
                              'Pág. $pageNumber de $totalPages',
                              style: pw.TextStyle(
                                color: PdfColors.white,
                                fontSize: 9,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                          ),
                          pw.SizedBox(height: 4),
                          pw.Text(
                            formattedDate,
                            style: pw.TextStyle(
                              fontSize: 8,
                              color: secondaryTextColor,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                pw.SizedBox(height: 16),

                // =============================================================
                // CUERPO DEL APUNTE
                // =============================================================
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      // Texto principal de la hoja
                      if (pageModel.textContent.trim().isNotEmpty)
                        pw.Container(
                          width: double.infinity,
                          child: _buildTextParagraphs(pageModel.textContent, darkTextColor, primaryColor, accentColor),
                        )
                      else
                        pw.Text(
                          '(Página sin texto)',
                          style: pw.TextStyle(
                            fontSize: 11,
                            fontStyle: pw.FontStyle.italic,
                            color: PdfColors.grey500,
                          ),
                        ),

                      pw.SizedBox(height: 12),

                      // Elementos flotantes de la página (Notas adhesivas y Fotos)
                      if (pageModel.floatingElements.isNotEmpty) ...[
                        pw.Divider(color: PdfColors.grey300, thickness: 0.5),
                        pw.SizedBox(height: 6),
                        pw.Text(
                          'NOTAS ADJUNTAS Y ELEMENTOS:',
                          style: pw.TextStyle(
                            fontSize: 8,
                            fontWeight: pw.FontWeight.bold,
                            color: secondaryTextColor,
                            letterSpacing: 0.8,
                          ),
                        ),
                        pw.SizedBox(height: 8),

                        pw.Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: pageModel.floatingElements.map((elem) {
                            if (elem.isImage && elem.imagePath != null) {
                              final bytes = imagesCache[elem.imagePath!];
                              if (bytes != null) {
                                return pw.Container(
                                  width: 140,
                                  height: 110,
                                  padding: const pw.EdgeInsets.all(4),
                                  decoration: pw.BoxDecoration(
                                    border: pw.Border.all(color: PdfColors.grey400, width: 0.8),
                                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                                  ),
                                  child: pw.Image(
                                    pw.MemoryImage(bytes),
                                    fit: pw.BoxFit.contain,
                                  ),
                                );
                              }
                            }

                            // Elemento OJO EXAMEN
                            if (elem.elementType == FloatingElementType.examAlert && elem.text.trim().isNotEmpty) {
                              return pw.Container(
                                width: 220,
                                padding: const pw.EdgeInsets.all(8),
                                decoration: pw.BoxDecoration(
                                  color: PdfColor.fromHex('FFF5F5'),
                                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                                  border: pw.Border(
                                    left: pw.BorderSide(color: accentColor, width: 3.5),
                                    top: const pw.BorderSide(color: PdfColors.red200, width: 0.8),
                                    right: const pw.BorderSide(color: PdfColors.red200, width: 0.8),
                                    bottom: const pw.BorderSide(color: PdfColors.red200, width: 0.8),
                                  ),
                                ),
                                child: pw.Column(
                                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                                  children: [
                                    pw.Row(
                                      children: [
                                        pw.Text(
                                          'OJO EXAMEN',
                                          style: pw.TextStyle(
                                            fontSize: 8.5,
                                            fontWeight: pw.FontWeight.bold,
                                            color: accentColor,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                        pw.SizedBox(width: 4),
                                        pw.Container(
                                          padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                          decoration: pw.BoxDecoration(
                                            color: accentColor,
                                            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(2)),
                                          ),
                                          child: pw.Text(
                                            'CLAVE',
                                            style: pw.TextStyle(
                                              fontSize: 6,
                                              color: PdfColors.white,
                                              fontWeight: pw.FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    pw.SizedBox(height: 4),
                                    pw.Text(
                                      elem.text.trim(),
                                      style: pw.TextStyle(
                                        fontSize: 9,
                                        fontWeight: pw.FontWeight.bold,
                                        color: PdfColor.fromHex('7F1D1D'),
                                        lineSpacing: 1.25,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }

                            // Elemento CÓDIGO / ALGORITMO
                            if (elem.elementType == FloatingElementType.codeSnippet && elem.text.trim().isNotEmpty) {
                              final lang = elem.language ?? 'Código';
                              return pw.Container(
                                width: 230,
                                padding: const pw.EdgeInsets.all(8),
                                decoration: pw.BoxDecoration(
                                  color: PdfColor.fromHex('0F172A'),
                                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                                  border: pw.Border.all(color: PdfColor.fromHex('334155'), width: 1),
                                ),
                                child: pw.Column(
                                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                                  children: [
                                    pw.Row(
                                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                                      children: [
                                        pw.Text(
                                          '// $lang',
                                          style: pw.TextStyle(
                                            fontSize: 7.5,
                                            fontWeight: pw.FontWeight.bold,
                                            color: PdfColor.fromHex('38BDF8'),
                                          ),
                                        ),
                                        pw.Text(
                                          'UPEA Connect',
                                          style: const pw.TextStyle(
                                            fontSize: 6.5,
                                            color: PdfColors.grey500,
                                          ),
                                        ),
                                      ],
                                    ),
                                    pw.SizedBox(height: 4),
                                    pw.Text(
                                      elem.text.trim(),
                                      style: pw.TextStyle(
                                        font: pw.Font.courier(),
                                        fontSize: 8,
                                        color: PdfColor.fromHex('F8FAFC'),
                                        lineSpacing: 1.2,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }

                            // Nota de texto adhesiva estándar
                            if (elem.text.trim().isNotEmpty) {
                              return pw.Container(
                                width: 170,
                                padding: const pw.EdgeInsets.all(8),
                                decoration: pw.BoxDecoration(
                                  color: noteBoxBg,
                                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                                  border: pw.Border.all(color: noteBoxBorder, width: 1),
                                ),
                                child: pw.Column(
                                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                                  children: [
                                    pw.Row(
                                      children: [
                                        pw.Container(
                                          width: 6,
                                          height: 6,
                                          decoration: pw.BoxDecoration(
                                            color: accentColor,
                                            shape: pw.BoxShape.circle,
                                          ),
                                        ),
                                        pw.SizedBox(width: 4),
                                        pw.Text(
                                          'Nota Adhesiva',
                                          style: pw.TextStyle(
                                            fontSize: 7.5,
                                            fontWeight: pw.FontWeight.bold,
                                            color: primaryColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                    pw.SizedBox(height: 4),
                                    pw.Text(
                                      elem.text.trim(),
                                      style: pw.TextStyle(
                                        fontSize: 9,
                                        color: darkTextColor,
                                        lineSpacing: 1.2,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }

                            return pw.SizedBox();
                          }).toList(),
                        ),
                      ],
                    ],
                  ),
                ),

                // =============================================================
                // PIE DE PÁGINA
                // =============================================================
                pw.Container(
                  padding: const pw.EdgeInsets.only(top: 8),
                  decoration: const pw.BoxDecoration(
                    border: pw.Border(
                      top: pw.BorderSide(color: PdfColors.grey300, width: 0.5),
                    ),
                  ),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        'Generado con UPEA Connect • Carrera de Ingeniería de Sistemas',
                        style: pw.TextStyle(
                          fontSize: 7.5,
                          color: secondaryTextColor,
                        ),
                      ),
                      pw.Text(
                        'Página $pageNumber de $totalPages',
                        style: pw.TextStyle(
                          fontSize: 7.5,
                          fontWeight: pw.FontWeight.bold,
                          color: primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      );
    }

    // Generar bytes del documento PDF
    final Uint8List pdfBytes = await pdf.save();

    // Guardar en el dispositivo
    final sanitizedFileName = cleanTitle
        .replaceAll(RegExp(r'[\\/:*?"<>|]'), '_')
        .replaceAll(' ', '_');
    final filename = '$sanitizedFileName.pdf';

    return await PptxSaveHelper.saveAndDownload(pdfBytes, filename);
  }

  /// Procesa los párrafos de texto reconociendo títulos, viñetas y texto regular
  static pw.Widget _buildTextParagraphs(
    String rawText,
    PdfColor textColor,
    PdfColor primaryColor,
    PdfColor accentColor,
  ) {
    final lines = rawText.split('\n');
    final List<pw.Widget> widgets = [];

    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) {
        widgets.add(pw.SizedBox(height: 4));
        continue;
      }

      // Título estilo Markdown # o MAYÚSCULAS cortas
      if (trimmed.startsWith('# ')) {
        widgets.add(
          pw.Padding(
            padding: const pw.EdgeInsets.only(top: 6, bottom: 2),
            child: pw.Text(
              trimmed.substring(2),
              style: pw.TextStyle(
                fontSize: 14,
                fontWeight: pw.FontWeight.bold,
                color: primaryColor,
              ),
            ),
          ),
        );
      } else if (trimmed.startsWith('## ')) {
        widgets.add(
          pw.Padding(
            padding: const pw.EdgeInsets.only(top: 4, bottom: 2),
            child: pw.Text(
              trimmed.substring(3),
              style: pw.TextStyle(
                fontSize: 12,
                fontWeight: pw.FontWeight.bold,
                color: primaryColor,
              ),
            ),
          ),
        );
      } else if (trimmed.startsWith('• ') || trimmed.startsWith('- ') || trimmed.startsWith('* ')) {
        // Viñeta
        final bulletText = trimmed.replaceFirst(RegExp(r'^[•\-\*]\s*'), '');
        widgets.add(
          pw.Padding(
            padding: const pw.EdgeInsets.only(left: 8, bottom: 2),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Container(
                  margin: const pw.EdgeInsets.only(top: 4, right: 6),
                  width: 3.5,
                  height: 3.5,
                  decoration: pw.BoxDecoration(
                    color: primaryColor,
                    shape: pw.BoxShape.circle,
                  ),
                ),
                pw.Expanded(
                  child: pw.Text(
                    bulletText,
                    style: pw.TextStyle(
                      fontSize: 10,
                      color: textColor,
                      lineSpacing: 1.3,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      } else if (RegExp(r'^\d+\.\s').hasMatch(trimmed)) {
        // Lista numerada
        widgets.add(
          pw.Padding(
            padding: const pw.EdgeInsets.only(left: 8, bottom: 2),
            child: pw.Text(
              trimmed,
              style: pw.TextStyle(
                fontSize: 10,
                color: textColor,
                lineSpacing: 1.3,
              ),
            ),
          ),
        );
      } else if (trimmed.startsWith('[!]') || trimmed.toUpperCase().contains('OJO EXAMEN')) {
        // Caja de alerta para examen
        widgets.add(
          pw.Container(
            margin: const pw.EdgeInsets.symmetric(vertical: 4),
            padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: pw.BoxDecoration(
              color: PdfColor.fromHex('FFF5F5'),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
              border: pw.Border.all(color: accentColor, width: 0.8),
            ),
            child: pw.Text(
              trimmed,
              style: pw.TextStyle(
                fontSize: 9.5,
                fontWeight: pw.FontWeight.bold,
                color: accentColor,
              ),
            ),
          ),
        );
      } else {
        // Párrafo normal
        widgets.add(
          pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 3),
            child: pw.Text(
              trimmed,
              style: pw.TextStyle(
                fontSize: 10,
                color: textColor,
                lineSpacing: 1.35,
              ),
            ),
          ),
        );
      }
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: widgets,
    );
  }

  /// Carga los bytes de una imagen remota o local
  static Future<Uint8List?> _loadImageBytes(String path) async {
    try {
      if (path.startsWith('http')) {
        final res = await http.get(Uri.parse(path)).timeout(const Duration(seconds: 10));
        if (res.statusCode == 200) {
          return res.bodyBytes;
        }
      } else if (!kIsWeb) {
        final file = File(path);
        if (await file.exists()) {
          return await file.readAsBytes();
        }
      }
    } catch (_) {}
    return null;
  }
}
