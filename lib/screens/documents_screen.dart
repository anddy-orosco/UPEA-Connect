import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart';
import 'package:open_file/open_file.dart';
import '../models/document_model.dart';
import '../services/document_service.dart';

class DocumentsScreen extends StatefulWidget {
  const DocumentsScreen({super.key});

  @override
  State<DocumentsScreen> createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends State<DocumentsScreen> {
  List<DocumentModel> _documents = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDocuments();
  }

  Future<void> _loadDocuments() async {
    final prefs = await SharedPreferences.getInstance();
    final String? storedData = prefs.getString('user_documents_vault');

    if (storedData != null) {
      try {
        final List decoded = jsonDecode(storedData);
        setState(() {
          _documents = decoded.map((e) => DocumentModel.fromJson(e)).toList();
          _isLoading = false;
        });
        return;
      } catch (e) {
        debugPrint('Error decodificando documentos: $e');
      }
    }

    final initialDocs = [
      DocumentModel(
        id: '1',
        title: 'Matrícula Universitaria UPEA 2026',
        category: 'Matrícula Oficial',
        filePath: '',
        fileType: 'pdf',
        dateAdded: DateTime.now(),
      ),
      DocumentModel(
        id: '2',
        title: 'Carnet de Identidad',
        category: 'Identificación',
        filePath: '',
        fileType: 'image',
        dateAdded: DateTime.now(),
      ),
    ];
    await _saveToPrefs(initialDocs);
    setState(() {
      _documents = initialDocs;
      _isLoading = false;
    });
  }

  Future<void> _saveToPrefs(List<DocumentModel> docs) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(docs.map((e) => e.toJson()).toList());
    await prefs.setString('user_documents_vault', encoded);
  }

  Future<void> _shareDocument(DocumentModel doc) async {
    try {
      final box = context.findRenderObject() as RenderBox?;
      final size = MediaQuery.of(context).size;
      final position = box != null ? box.localToGlobal(Offset.zero) : Offset.zero;
      final shareOrigin = Rect.fromLTWH(position.dx, position.dy, size.width / 2, size.height / 2);

      if (doc.filePath.isNotEmpty) {
        if (kIsWeb) {
          await Share.share('📄 Documento oficial UPEA Connect: *${doc.title}* (Categoría: ${doc.category})');
        } else {
          final file = File(doc.filePath);
          if (file.existsSync()) {
            final ext = doc.filePath.split('.').last.toLowerCase();
            String mime = 'image/jpeg';
            if (ext == 'pdf') mime = 'application/pdf';
            if (ext == 'xlsx' || ext == 'xls') mime = 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
            if (ext == 'docx' || ext == 'doc') mime = 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';

            final xFile = XFile(
              doc.filePath,
              mimeType: mime,
              name: '${doc.title.replaceAll(' ', '_')}.$ext',
            );

            await Share.shareXFiles(
              [xFile],
              text: '📄 Documento oficial UPEA Connect:\n📌 ${doc.title}\n📂 Categoría: ${doc.category}',
              subject: doc.title,
              sharePositionOrigin: shareOrigin,
            );
          } else {
            await Share.share('📄 Documento oficial UPEA Connect: *${doc.title}*', sharePositionOrigin: shareOrigin);
          }
        }
      } else {
        await Share.share('📄 *${doc.title}*\nCategoría: ${doc.category}\nEnviado desde UPEA Connect 🚀', sharePositionOrigin: shareOrigin);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al compartir: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _openFilePickerForDocument({required Function(Map<String, String> fileData) onFileSelected}) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (modalContext) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(topLeft: Radius.circular(28), topRight: Radius.circular(28)),
          ),
          child: Material(
            color: Colors.transparent,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
                const SizedBox(height: 16),
                const Text('Seleccionar origen del archivo', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: Colors.indigo.shade50, shape: BoxShape.circle),
                    child: const Icon(Icons.photo_library_rounded, color: Colors.indigo),
                  ),
                  title: const Text('Galería de Fotos', style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: const Text('Sube imágenes o capturas', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  onTap: () async {
                    Navigator.pop(modalContext);
                    final fileData = await DocumentService.pickFromGallery();
                    if (fileData != null) {
                      onFileSelected(fileData);
                    }
                  },
                ),
                const Divider(),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: Colors.red.shade50, shape: BoxShape.circle),
                    child: const Icon(Icons.folder_open_rounded, color: Colors.red),
                  ),
                  title: const Text('Archivos del Dispositivo', style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: const Text('Sube documentos PDF, Word o Excel', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  onTap: () async {
                    Navigator.pop(modalContext);
                    final fileData = await DocumentService.pickDocumentFile();
                    if (fileData != null) {
                      onFileSelected(fileData);
                    }
                  },
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _replaceDocumentFile(DocumentModel doc) async {
    _openFilePickerForDocument(onFileSelected: (fileData) async {
      setState(() {
        final index = _documents.indexWhere((d) => d.id == doc.id);
        if (index != -1) {
          _documents[index] = DocumentModel(
            id: doc.id,
            title: doc.title,
            category: doc.category,
            filePath: fileData['path']!,
            fileType: fileData['type']!,
            dateAdded: doc.dateAdded,
          );
        }
      });

      await _saveToPrefs(_documents);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Archivo actualizado correctamente'), backgroundColor: Colors.green),
        );
      }
    });
  }

  void _showAddDocumentDialog() {
    final titleController = TextEditingController();
    String selectedCategory = 'Matrícula';

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              title: const Text('Subir Nuevo Documento', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Nombre del documento:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: titleController,
                      decoration: InputDecoration(
                        hintText: 'Ej. Kardex, Horario, Matrícula',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text('Categoría:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey)),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      value: selectedCategory,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'Matrícula', child: Text('Matrícula')),
                        DropdownMenuItem(value: 'Identificación', child: Text('Identificación / Carnet')),
                        DropdownMenuItem(value: 'Académico', child: Text('Académico / Horario')),
                        DropdownMenuItem(value: 'Otro', child: Text('Otro Trámite')),
                      ],
                      onChanged: (val) {
                        if (val != null) setDialogState(() => selectedCategory = val);
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                  onPressed: () {
                    final title = titleController.text.trim();
                    if (title.isNotEmpty) {
                      Navigator.pop(dialogContext);

                      _openFilePickerForDocument(onFileSelected: (fileData) async {
                        final newDoc = DocumentModel(
                          id: DateTime.now().millisecondsSinceEpoch.toString(),
                          title: title,
                          category: selectedCategory,
                          filePath: fileData['path']!,
                          fileType: fileData['type']!,
                          dateAdded: DateTime.now(),
                        );

                        setState(() {
                          _documents.insert(0, newDoc);
                        });

                        await _saveToPrefs(_documents);

                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('✅ Documento guardado con éxito'), backgroundColor: Colors.green),
                          );
                        }
                      });
                    }
                  },
                  child: const Text('Continuar y Elegir Archivo'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildPreviewContent(DocumentModel doc) {
    if (doc.filePath.isEmpty) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(_getIconForType(doc.fileType), size: 72, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 16),
          const Text('Sin archivo adjunto todavía', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black54)),
          const SizedBox(height: 6),
          const Text('Usa "Cambiar Archivo" para adjuntar uno.', style: TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      );
    }

    if (doc.fileType == 'image') {
      if (kIsWeb || doc.filePath.startsWith('data:')) {
        return Image.network(doc.filePath, fit: BoxFit.contain, width: double.infinity);
      }
      return Image.file(File(doc.filePath), fit: BoxFit.contain, width: double.infinity);
    }

    final iconColor = _getColorForType(doc.fileType);
    final fileName = doc.filePath.startsWith('data:') ? 'Documento sincronizado (Web)' : doc.filePath.split('/').last;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 150,
              height: 190,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.white, Colors.grey.shade50],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: iconColor.withOpacity(0.2),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
                border: Border.all(color: iconColor.withOpacity(0.3), width: 2),
              ),
              child: Stack(
                children: [
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: iconColor.withOpacity(0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(_getIconForType(doc.fileType), size: 52, color: iconColor),
                        ),
                        const SizedBox(height: 14),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: iconColor,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            doc.fileType.toUpperCase(),
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 0.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: iconColor.withOpacity(0.1),
                        borderRadius: const BorderRadius.only(
                          topRight: Radius.circular(20),
                          bottomLeft: Radius.circular(16),
                        ),
                      ),
                      child: Icon(Icons.verified_rounded, size: 16, color: iconColor),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text(
              doc.title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.black87),
            ),
            const SizedBox(height: 6),
            Text(
              fileName,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: iconColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                elevation: 0,
              ),
              icon: const Icon(Icons.open_in_new_rounded, size: 18),
              label: const Text('Abrir y Ver Documento'),
              onPressed: () async {
                if (!kIsWeb && doc.filePath.isNotEmpty) {
                  await OpenFile.open(doc.filePath);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('📄 Documento listo y disponible en tu bóveda.')),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showDocumentPreview(DocumentModel doc) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.8,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(topLeft: Radius.circular(28), topRight: Radius.circular(28)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(child: Text(doc.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87), overflow: TextOverflow.ellipsis)),
                    IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.pop(context)),
                  ],
                ),
                Text('Categoría: ${doc.category} • Tipo: ${doc.fileType.toUpperCase()}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 16),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(color: Colors.grey.shade50, border: Border.all(color: Colors.grey.shade200), borderRadius: BorderRadius.circular(20)),
                      child: _buildPreviewContent(doc),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Theme.of(context).colorScheme.primary,
                          side: BorderSide(color: Theme.of(context).colorScheme.primary),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        icon: const Icon(Icons.edit_rounded, size: 18),
                        label: const Text('Cambiar Archivo'),
                        onPressed: () {
                          Navigator.pop(context);
                          _replaceDocumentFile(doc);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          elevation: 0,
                        ),
                        icon: const Icon(Icons.share_rounded, size: 18),
                        label: const Text('Compartir'),
                        onPressed: () {
                          Navigator.pop(context);
                          _shareDocument(doc);
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case 'pdf': return Icons.picture_as_pdf_rounded;
      case 'excel': return Icons.table_chart_rounded;
      case 'presentation': return Icons.slideshow_rounded;
      case 'document': return Icons.article_rounded;
      default: return Icons.image_rounded;
    }
  }

  Color _getColorForType(String type) {
    switch (type) {
      case 'pdf': return Colors.red.shade600;
      case 'excel': return Colors.green.shade600;
      case 'presentation': return Colors.orange.shade600;
      case 'document': return Colors.blue.shade700;
      default: return Colors.blue.shade600;
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeCount = _documents.where((d) => d.filePath.isNotEmpty).length;
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 📂 Banner sincronizado exactamente con el color principal del AppBar global
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    primaryColor,
                    Color.lerp(primaryColor, Colors.black, 0.25) ?? primaryColor,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: primaryColor.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.folder_special_rounded, color: Colors.white, size: 30),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Tus Credenciales y Archivos',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$activeCount de ${_documents.length} documentos listos y seguros',
                          style: const TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  // Botón de añadir profesional integrado en el banner
                  Material(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: _showAddDocumentDialog,
                      child: const Padding(
                        padding: EdgeInsets.all(12.0),
                        child: Icon(Icons.add_rounded, color: Colors.white, size: 24),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Lista de documentos
            Expanded(
              child: ListView.builder(
                physics: const BouncingScrollPhysics(),
                itemCount: _documents.length,
                itemBuilder: (context, index) {
                  final doc = _documents[index];
                  final iconColor = _getColorForType(doc.fileType);
                  final hasValidImage = doc.filePath.isNotEmpty && doc.fileType == 'image' && (kIsWeb || File(doc.filePath).existsSync());

                  return Container(
                    margin: const EdgeInsets.only(bottom: 18),
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 12, offset: const Offset(0, 6))],
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(24),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(24),
                        onTap: () => _showDocumentPreview(doc),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              height: 160,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: iconColor.withOpacity(0.08),
                                borderRadius: const BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
                                image: hasValidImage
                                    ? DecorationImage(
                                  image: kIsWeb ? NetworkImage(doc.filePath) as ImageProvider : FileImage(File(doc.filePath)),
                                  fit: BoxFit.cover,
                                )
                                    : null,
                              ),
                              child: !hasValidImage
                                  ? Center(
                                child: Icon(
                                  _getIconForType(doc.fileType),
                                  size: 60,
                                  color: iconColor.withOpacity(0.85),
                                ),
                              )
                                  : Container(
                                decoration: BoxDecoration(
                                  borderRadius: const BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [Colors.transparent, Colors.black.withOpacity(0.3)],
                                  ),
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          doc.title,
                                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.black87),
                                        ),
                                        const SizedBox(height: 6),
                                        Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                              decoration: BoxDecoration(color: primaryColor.withOpacity(0.08), borderRadius: BorderRadius.circular(8)),
                                              child: Text(
                                                doc.category,
                                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: primaryColor),
                                              ),
                                            ),
                                            const SizedBox(width: 10),
                                            Text(
                                              doc.filePath.isNotEmpty
                                                  ? '• ${doc.fileType.toUpperCase()} Adjunto'
                                                  : '• Sin archivo',
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                                color: doc.filePath.isNotEmpty
                                                    ? Colors.green.shade700
                                                    : Colors.orange.shade800,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Material(
                                    color: primaryColor.withOpacity(0.08),
                                    borderRadius: BorderRadius.circular(14),
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(14),
                                      onTap: () => _shareDocument(doc),
                                      child: Padding(
                                        padding: const EdgeInsets.all(12.0),
                                        child: Icon(Icons.share_rounded, color: primaryColor, size: 20),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}