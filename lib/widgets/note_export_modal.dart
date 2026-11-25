import 'package:flutter/material.dart';
import 'package:open_file/open_file.dart';
import 'package:share_plus/share_plus.dart';
import '../models/note_page_model.dart';
import '../services/pdf_export_service.dart';
import '../services/docx_export_service.dart';
import '../services/pptx_export_service.dart';
import '../theme/colors.dart';

enum ExportFormat { pdf, docx, pptx }

class NoteExportModal extends StatefulWidget {
  final List<NotePageModel> pages;
  final String title;
  final String? courseName;

  const NoteExportModal({
    super.key,
    required this.pages,
    required this.title,
    this.courseName,
  });

  static Future<void> show({
    required BuildContext context,
    required List<NotePageModel> pages,
    required String title,
    String? courseName,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => NoteExportModal(
        pages: pages,
        title: title,
        courseName: courseName,
      ),
    );
  }

  @override
  State<NoteExportModal> createState() => _NoteExportModalState();
}

class _NoteExportModalState extends State<NoteExportModal> {
  bool _isGenerating = false;
  String _statusText = '';
  String? _generatedFilePath;
  ExportFormat? _lastFormat;

  Future<void> _exportAs(ExportFormat format) async {
    setState(() {
      _isGenerating = true;
      _lastFormat = format;
      switch (format) {
        case ExportFormat.pdf:
          _statusText = 'Generando documento PDF vectorial...';
          break;
        case ExportFormat.docx:
          _statusText = 'Creando documento Word (.docx) compatible...';
          break;
        case ExportFormat.pptx:
          _statusText = 'Generando presentación de diapositivas...';
          break;
      }
    });

    try {
      String filePath;
      switch (format) {
        case ExportFormat.pdf:
          filePath = await PdfExportService.exportNotesToPdf(
            pages: widget.pages,
            title: widget.title,
            courseName: widget.courseName,
          );
          break;
        case ExportFormat.docx:
          filePath = await DocxExportService.exportNotesToDocx(
            pages: widget.pages,
            title: widget.title,
            courseName: widget.courseName,
          );
          break;
        case ExportFormat.pptx:
          filePath = await PptxExportService.exportNotesToPptx(
            widget.pages,
            widget.title,
          );
          break;
      }

      if (!mounted) return;

      setState(() {
        _isGenerating = false;
        _generatedFilePath = filePath;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isGenerating = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al exportar: $e'),
          backgroundColor: AppColors.rojoAlerta,
        ),
      );
    }
  }

  void _openFile() {
    if (_generatedFilePath != null) {
      OpenFile.open(_generatedFilePath!);
    }
  }

  void _shareFile() {
    if (_generatedFilePath != null) {
      Share.shareXFiles(
        [XFile(_generatedFilePath!)],
        text: 'Apuntes: ${widget.title} - UPEA Connect',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final cardBg = Theme.of(context).cardColor;

    return Container(
      padding: const EdgeInsets.only(top: 8, bottom: 28, left: 20, right: 20),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 20, spreadRadius: 4),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 44,
            height: 4.5,
            margin: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: colorScheme.onSurface.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(3),
            ),
          ),

          // Título del Modal
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.file_download_rounded, color: colorScheme.primary, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Exportar Apuntes',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '${widget.title.isEmpty ? "Sin título" : widget.title} • ${widget.pages.length} ${widget.pages.length == 1 ? "hoja" : "hojas"}',
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
          ),

          const Divider(height: 1),
          const SizedBox(height: 16),

          // Estado: Generando o Listo
          if (_isGenerating) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 36),
              child: Column(
                children: [
                  CircularProgressIndicator(color: colorScheme.primary),
                  const SizedBox(height: 18),
                  Text(
                    _statusText,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Compilando hojas, estilos y notas adjuntas...',
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ),
          ] else if (_generatedFilePath != null) ...[
            // Estado: ¡Archivo Listo para abrir o compartir!
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.verdeExito.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.verdeExito.withValues(alpha: 0.3)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: AppColors.verdeExito,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.check, color: Colors.white, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _lastFormat == ExportFormat.pdf
                                  ? '¡Documento PDF listo!'
                                  : _lastFormat == ExportFormat.docx
                                      ? '¡Documento Word listo!'
                                      : '¡Diapositivas listas!',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: AppColors.verdeExito,
                              ),
                            ),
                            Text(
                              _generatedFilePath!.split('/').last,
                              style: TextStyle(
                                fontSize: 11,
                                color: colorScheme.onSurface.withValues(alpha: 0.7),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _openFile,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colorScheme.primary,
                            foregroundColor: colorScheme.onPrimary,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          icon: const Icon(Icons.open_in_new_rounded, size: 18),
                          label: const Text('Abrir', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _shareFile,
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            side: BorderSide(color: colorScheme.primary),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          icon: Icon(Icons.share_rounded, size: 18, color: colorScheme.primary),
                          label: Text(
                            'Compartir',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.primary,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'O elige otro formato a continuación:',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 10),
          ] else ...[
            // Lista de formatos disponibles
            _buildExportOption(
              context: context,
              title: 'Documento PDF (.pdf)',
              badge: 'RECOMENDADO',
              badgeColor: Colors.deepOrange,
              description:
                  'Formato universal A4 vectorial listo para imprimir, enviar al docente o estudiar.',
              icon: Icons.picture_as_pdf_rounded,
              iconColor: Colors.red.shade700,
              bgColor: Colors.red.withValues(alpha: 0.08),
              onTap: () => _exportAs(ExportFormat.pdf),
            ),
            const SizedBox(height: 10),
            _buildExportOption(
              context: context,
              title: 'Documento Word (.docx)',
              badge: 'EDITABLE',
              badgeColor: Colors.blue.shade700,
              description:
                  'Editable en Microsoft Word, Google Docs y Office 365 con títulos, párrafos y notas.',
              icon: Icons.description_rounded,
              iconColor: Colors.blue.shade800,
              bgColor: Colors.blue.withValues(alpha: 0.08),
              onTap: () => _exportAs(ExportFormat.docx),
            ),
            const SizedBox(height: 10),
            _buildExportOption(
              context: context,
              title: 'Diapositivas PowerPoint (.pptx)',
              badge: 'EXPOSICIÓN',
              badgeColor: Colors.amber.shade900,
              description:
                  'Diapositivas verticales para exponer en proyector, pizarras digitales o defensas.',
              icon: Icons.slideshow_rounded,
              iconColor: Colors.orange.shade800,
              bgColor: Colors.orange.withValues(alpha: 0.08),
              onTap: () => _exportAs(ExportFormat.pptx),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildExportOption({
    required BuildContext context,
    required String title,
    required String badge,
    required Color badgeColor,
    required String description,
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required VoidCallback onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: isDark ? Colors.white.withValues(alpha: 0.04) : AppColors.grisClaro.withValues(alpha: 0.5),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            title,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: badgeColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            badge,
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5,
                              color: badgeColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 11,
                        color: colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Icon(
                Icons.chevron_right_rounded,
                color: colorScheme.onSurface.withValues(alpha: 0.3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
