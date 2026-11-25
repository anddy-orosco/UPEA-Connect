import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/note_model.dart';
import '../models/note_page_model.dart';
import '../services/notes_service.dart';
import '../services/connectivity_service.dart';
import '../services/api_service.dart';
import '../theme/colors.dart';
import '../widgets/a4_page_canvas.dart';
import '../widgets/rich_text_toolbar.dart';
import '../widgets/note_export_modal.dart';

class NoteEditorScreen extends StatefulWidget {
  final NoteModel? note;

  const NoteEditorScreen({super.key, this.note});

  @override
  State<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends State<NoteEditorScreen> {
  final _titleController = TextEditingController();
  final _courseController = TextEditingController();

  List<NotePageModel> _pages = [NotePageModel(pageIndex: 0)];
  final PageController _pageController = PageController();
  final Map<int, TextEditingController> _pageTextControllers = {};

  int _currentPage = 0;
  double _fontSize = 16.0;
  bool _isBold = false;
  bool _isItalic = false;
  TextAlign _textAlign = TextAlign.left;
  PaperStyle _paperStyle = PaperStyle.ruled;
  bool _isLoading = false;
  bool _isStudyMode = false; // Modo estudio sin barras de edición

  final Map<String, Future<void>> _pendingImageUploads = {};

  @override
  void initState() {
    super.initState();
    if (widget.note != null) {
      _titleController.text = widget.note!.title;
      _courseController.text = widget.note!.courseName ?? '';
      if (widget.note!.pages.isNotEmpty) {
        _pages = widget.note!.pages;
      } else {
        _pages = [NotePageModel(pageIndex: 0, textContent: widget.note!.content)];
      }
    }

    // Limpieza automática: elimina cualquier flotante de examen que pudiera estar bloqueando la vista
    for (final page in _pages) {
      final examAlerts = page.floatingElements
          .where((e) => e.elementType == FloatingElementType.examAlert)
          .toList();
      for (final alert in examAlerts) {
        final alertText = alert.text.trim();
        if (alertText.isNotEmpty) {
          page.textContent = '${page.textContent.trim()}\n\n╔═══════════════════════════════════════════╗\n  $alertText\n╚═══════════════════════════════════════════╝\n';
        }
      }
      page.floatingElements
          .removeWhere((e) => e.elementType == FloatingElementType.examAlert);
    }

    for (int i = 0; i < _pages.length; i++) {
      _pageTextControllers[i] = TextEditingController(text: _pages[i].textContent);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _courseController.dispose();
    for (var controller in _pageTextControllers.values) {
      controller.dispose();
    }
    _pageController.dispose();
    super.dispose();
  }

  TextEditingController _getController(int index) {
    if (!_pageTextControllers.containsKey(index)) {
      _pageTextControllers[index] = TextEditingController(
        text: index < _pages.length ? _pages[index].textContent : '',
      );
    }
    return _pageTextControllers[index]!;
  }

  void _syncPageControllers() {
    for (int i = 0; i < _pages.length; i++) {
      if (_pageTextControllers.containsKey(i)) {
        _pages[i].textContent = _pageTextControllers[i]!.text;
      }
    }
  }

  void _addNewPage() {
    _syncPageControllers();
    setState(() {
      final newIndex = _pages.length;
      _pages.add(NotePageModel(pageIndex: newIndex));
      _pageTextControllers[newIndex] = TextEditingController();
      _currentPage = newIndex;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_pageController.hasClients) {
        _pageController.animateToPage(
          _pages.length - 1,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  void _deleteCurrentPage() {
    if (_pages.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Un apunte debe tener al menos una hoja.'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Hoja Actual'),
        content: Text('¿Deseas eliminar la página ${_currentPage + 1}? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _syncPageControllers();
              setState(() {
                _pages.removeAt(_currentPage);
                // Reindexar páginas
                for (int i = 0; i < _pages.length; i++) {
                  _pages[i].pageIndex = i;
                }
                // Limpiar y reconstruir controladores
                _pageTextControllers.clear();
                for (int i = 0; i < _pages.length; i++) {
                  _pageTextControllers[i] = TextEditingController(text: _pages[i].textContent);
                }
                if (_currentPage >= _pages.length) {
                  _currentPage = _pages.length - 1;
                }
              });
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.rojoAlerta),
            child: const Text('Eliminar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _addFloatingTextBox() {
    setState(() {
      _pages[_currentPage].floatingElements.add(
        FloatingElement(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          position: const Offset(36, 60),
          width: 190,
          height: 120,
          text: '',
        ),
      );
    });
  }

  Future<void> _addFloatingImage() async {
    if (!ConnectivityService.instance.isOnline) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sin conexión: las imágenes necesitan internet para subirse al servidor.'),
          backgroundColor: AppColors.rojoAlerta,
        ),
      );
      return;
    }

    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);

    if (image == null) return;

    final elementId = DateTime.now().millisecondsSinceEpoch.toString();

    setState(() {
      _pages[_currentPage].floatingElements.add(
        FloatingElement(
          id: elementId,
          position: const Offset(40, 80),
          width: 210,
          height: 160,
          imagePath: image.path,
          isImage: true,
        ),
      );
    });

    final uploadFuture = _uploadFloatingImage(
      currentPageAtStart: _currentPage,
      elementId: elementId,
      image: image,
    );
    _pendingImageUploads[elementId] = uploadFuture;
    try {
      await uploadFuture;
    } catch (_) {
    } finally {
      _pendingImageUploads.remove(elementId);
    }
  }

  Future<void> _uploadFloatingImage({
    required int currentPageAtStart,
    required String elementId,
    required XFile image,
  }) async {
    try {
      final bytes = await image.readAsBytes();
      final uploadedUrl = await ApiService.uploadImage(
        bytes,
        image.name,
        mimeType: image.mimeType,
      );

      if (!mounted) return;

      final elements = _pages[currentPageAtStart].floatingElements;
      final idx = elements.indexWhere((e) => e.id == elementId);

      if (idx != -1) {
        setState(() {
          elements[idx].imagePath = uploadedUrl;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No se pudo subir la imagen: $e'),
            backgroundColor: AppColors.rojoAlerta,
          ),
        );
      }
      rethrow;
    }
  }

  // ===========================================================================
  // INSERCIÓN RÁPIDA DE ESTRUCTURAS DE ESTUDIO
  // ===========================================================================

  void _insertTextAtCursor(String textToInsert) {
    final controller = _getController(_currentPage);
    final text = controller.text;
    final selection = controller.selection;

    if (selection.isValid && selection.start >= 0) {
      final newText = text.replaceRange(selection.start, selection.end, textToInsert);
      controller.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: selection.start + textToInsert.length),
      );
    } else {
      controller.text = '$text\n$textToInsert';
    }
    _pages[_currentPage].textContent = controller.text;
  }

  void _insertBullet() => _insertTextAtCursor('• ');

  void _insertNumbered() {
    final controller = _getController(_currentPage);
    final count = RegExp(r'^\d+\.', multiLine: true).allMatches(controller.text).length + 1;
    _insertTextAtCursor('$count. ');
  }

  void _insertChecklist() => _insertTextAtCursor('☐ ');

  void _openExamAlertModal() {
    String alertType = '🔥 PREGUNTA FIJA';
    final textController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          final cardBg = Theme.of(ctx).cardColor;
          final bottomInset = MediaQuery.of(ctx).viewInsets.bottom;

          return Container(
            padding: EdgeInsets.only(
              top: 16,
              left: 20,
              right: 20,
              bottom: bottomInset + 20,
            ),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              boxShadow: const [
                BoxShadow(color: Colors.black26, blurRadius: 15, spreadRadius: 2),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.local_fire_department_rounded, color: Color(0xFFDC2626), size: 24),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Ojo Examen (Alerta de Parcial)',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'Pregunta clave, fórmula o advertencia del docente',
                            style: TextStyle(fontSize: 11, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Selector de Tipo de Alerta
                Wrap(
                  spacing: 8,
                  children: [
                    '🔥 PREGUNTA FIJA',
                    '⚠️ CUIDADO / TRAMPA',
                    '💡 FÓRMULA CLAVE',
                  ].map((tipo) {
                    final isSel = alertType == tipo;
                    return ChoiceChip(
                      label: Text(tipo, style: TextStyle(fontSize: 11, fontWeight: isSel ? FontWeight.bold : FontWeight.normal)),
                      selected: isSel,
                      selectedColor: const Color(0xFFDC2626).withValues(alpha: 0.15),
                      labelStyle: TextStyle(color: isSel ? const Color(0xFFDC2626) : null),
                      onSelected: (val) {
                        if (val) setModalState(() => alertType = tipo);
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),

                // Campo de Texto de la Alerta
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF5F5),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFFECACA), width: 1.2),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: TextField(
                    controller: textController,
                    autofocus: true,
                    maxLines: 4,
                    minLines: 2,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF7F1D1D)),
                    decoration: const InputDecoration(
                      hintText: 'Ej: Dijkstra no admite pesos negativos. Entra fijo al 2do parcial...',
                      hintStyle: TextStyle(fontSize: 13, color: Color(0xFFF87171), fontStyle: FontStyle.italic),
                      border: InputBorder.none,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Botón único y directo para insertar en el apunte
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      final text = textController.text.trim();
                      if (text.isNotEmpty) {
                        final block = '\n╔═══════════════════════════════════════════╗\n'
                            '  $alertType:\n'
                            '  $text\n'
                            '╚═══════════════════════════════════════════╝\n';
                        _insertTextAtCursor(block);
                      }
                      Navigator.pop(ctx);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFDC2626),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: const Icon(Icons.add_task_rounded, size: 20),
                    label: const Text('Insertar Ojo Examen en el Apunte', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _openCodeSnippetModal() {
    String selectedLang = 'Java';
    final textController = TextEditingController();
    const languages = ['Java', 'Python', 'C++', 'SQL', 'Dart', 'JavaScript', 'Pseudocódigo', 'C#', 'Bash'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          final cardBg = Theme.of(ctx).cardColor;
          final bottomInset = MediaQuery.of(ctx).viewInsets.bottom;

          return Container(
            padding: EdgeInsets.only(
              top: 16,
              left: 20,
              right: 20,
              bottom: bottomInset + 20,
            ),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              boxShadow: const [
                BoxShadow(color: Colors.black26, blurRadius: 15, spreadRadius: 2),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.code_rounded, color: Color(0xFF2563EB), size: 24),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Bloque de Código / Algoritmo',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'Inserta código formateado para materias de Sistemas',
                            style: TextStyle(fontSize: 11, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Selector de Lenguaje
                SizedBox(
                  height: 36,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: languages.length,
                    itemBuilder: (ctx, i) {
                      final lang = languages[i];
                      final isSel = selectedLang == lang;
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: ChoiceChip(
                          label: Text(lang, style: TextStyle(fontSize: 11, fontWeight: isSel ? FontWeight.bold : FontWeight.normal)),
                          selected: isSel,
                          selectedColor: const Color(0xFF2563EB).withValues(alpha: 0.15),
                          labelStyle: TextStyle(color: isSel ? const Color(0xFF2563EB) : null),
                          onSelected: (val) {
                            if (val) setModalState(() => selectedLang = lang);
                          },
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),

                // Editor de Código
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFF334155), width: 1.2),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: TextField(
                    controller: textController,
                    autofocus: true,
                    maxLines: 5,
                    minLines: 3,
                    style: const TextStyle(
                      fontFamily: 'Courier',
                      fontSize: 13,
                      color: Color(0xFF38BDF8),
                      height: 1.35,
                    ),
                    decoration: const InputDecoration(
                      hintText: '// Escribe o pega tu código aquí...',
                      hintStyle: TextStyle(fontSize: 12, color: Colors.white30, fontFamily: 'monospace'),
                      border: InputBorder.none,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Botones de acción
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          final text = textController.text.trim();
                          if (text.isNotEmpty) {
                            final block = '\n// ─── CÓDIGO [$selectedLang] ───────────────────\n'
                                '$text\n'
                                '// ─────────────────────────────────────────────\n';
                            _insertTextAtCursor(block);
                          }
                          Navigator.pop(ctx);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1E293B),
                          foregroundColor: const Color(0xFF38BDF8),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        icon: const Icon(Icons.note_add_rounded, size: 18),
                        label: const Text('Insertar en Apunte', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          final text = textController.text.trim();
                          if (text.isNotEmpty) {
                            setState(() {
                              _pages[_currentPage].floatingElements.add(
                                FloatingElement(
                                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                                  position: const Offset(36, 120),
                                  width: 280,
                                  height: 175,
                                  text: text,
                                  elementType: FloatingElementType.codeSnippet,
                                  language: selectedLang,
                                ),
                              );
                            });
                          }
                          Navigator.pop(ctx);
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          side: const BorderSide(color: Color(0xFF1E293B)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        icon: const Icon(Icons.terminal_rounded, size: 16),
                        label: const Text('Terminal', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ===========================================================================
  // EXPORTACIÓN UNIFICADA (WORD, PDF, PPTX)
  // ===========================================================================

  void _showExportModal() {
    _syncPageControllers();
    final title = _titleController.text.trim().isEmpty ? 'Apunte Sin Título' : _titleController.text.trim();
    NoteExportModal.show(
      context: context,
      pages: _pages,
      title: title,
      courseName: _courseController.text.trim().isNotEmpty ? _courseController.text.trim() : null,
    );
  }

  // ===========================================================================
  // GUARDAR APUNTE
  // ===========================================================================

  Future<void> _saveNote() async {
    _syncPageControllers();

    if (!ConnectivityService.instance.isOnline) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(ConnectivityService.offlineWriteMessage),
          backgroundColor: AppColors.rojoAlerta,
        ),
      );
      return;
    }

    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor escribe un título para tu apunte'),
          backgroundColor: AppColors.rojoAlerta,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (_pendingImageUploads.isNotEmpty) {
        await Future.wait(
          _pendingImageUploads.values.toList(),
          eagerError: false,
        ).catchError((_) => <void>[]);
      }

      final buffer = StringBuffer();
      for (int i = 0; i < _pages.length; i++) {
        final page = _pages[i];
        if (page.textContent.trim().isNotEmpty) {
          buffer.writeln(page.textContent.trim());
        }
        for (final elem in page.floatingElements) {
          if (elem.elementType == FloatingElementType.examAlert && elem.text.trim().isNotEmpty) {
            buffer.writeln('\n[!] OJO EXAMEN:\n${elem.text.trim()}\n');
          } else if (elem.elementType == FloatingElementType.codeSnippet && elem.text.trim().isNotEmpty) {
            final lang = elem.language ?? 'codigo';
            buffer.writeln('\n```$lang\n${elem.text.trim()}\n```\n');
          } else if (!elem.isImage && elem.text.trim().isNotEmpty) {
            buffer.writeln('\n[Nota: ${elem.text.trim()}]\n');
          }
        }
        if (i < _pages.length - 1) {
          buffer.writeln('\n---\n');
        }
      }
      final fullContent = buffer.toString().trim();
      final now = DateTime.now();
      final isNew = widget.note == null;

      final note = NoteModel(
        id: widget.note?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        title: _titleController.text.trim(),
        content: fullContent,
        createdAt: widget.note?.createdAt ?? now,
        updatedAt: now,
        courseName: _courseController.text.trim().isNotEmpty
            ? _courseController.text.trim()
            : null,
        pages: _pages,
      );

      await NotesService.saveNote(note, isNew: isNew);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isNew ? '✓ Apunte creado con éxito' : '✓ Apunte guardado'),
            backgroundColor: AppColors.verdeExito,
            duration: const Duration(seconds: 1),
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar: ${e.toString().replaceFirst("Exception: ", "")}'),
            backgroundColor: AppColors.rojoAlerta,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  int get _wordCount {
    _syncPageControllers();
    final full = _pages.map((p) => p.textContent).join(' ');
    if (full.trim().isEmpty) return 0;
    return full.trim().split(RegExp(r'\s+')).length;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final cardColor = Theme.of(context).cardColor;
    final isKeyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          title: Text(
            widget.note == null ? 'Nuevo Cuaderno' : 'Editar Apunte',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          elevation: 0,
          actions: [
            // Botón Modo Estudio (Pantalla Completa Zen)
            IconButton(
              icon: Icon(_isStudyMode ? Icons.edit_note_rounded : Icons.menu_book_rounded),
              tooltip: _isStudyMode ? 'Modo Edición' : 'Modo Estudio (Zen)',
              onPressed: () => setState(() => _isStudyMode = !_isStudyMode),
            ),
            // Botón Exportar (Word, PDF, Diapositivas)
            IconButton(
              icon: const Icon(Icons.ios_share_rounded),
              tooltip: 'Exportar en Word o PDF',
              onPressed: _showExportModal,
            ),
            // Botón Guardar
            TextButton(
              onPressed: _isLoading ? null : _saveNote,
              style: TextButton.styleFrom(foregroundColor: colorScheme.onPrimary),
              child: _isLoading
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        color: colorScheme.onPrimary,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      'Guardar',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
            ),
          ],
        ),
        body: _isLoading
            ? Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
                ),
              )
            : Column(
                children: [
                  // ===========================================================
                  // CAMPOS SUPERIORES: TÍTULO Y MATERIA (Ocultos en Modo Estudio)
                  // ===========================================================
                  if (!_isStudyMode) ...[
                    Container(
                      color: cardColor,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _titleController,
                              decoration: InputDecoration(
                                hintText: 'Título del tema (ej. Árboles AVL)...',
                                hintStyle: TextStyle(
                                  color: colorScheme.onSurface.withValues(alpha: 0.4),
                                  fontSize: 16,
                                ),
                                border: InputBorder.none,
                              ),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 17,
                                color: colorScheme.onSurface,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            width: 140,
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: colorScheme.primary.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: TextField(
                              controller: _courseController,
                              decoration: InputDecoration(
                                hintText: 'Materia...',
                                hintStyle: TextStyle(
                                  color: colorScheme.primary.withValues(alpha: 0.6),
                                  fontSize: 13,
                                ),
                                border: InputBorder.none,
                                isDense: true,
                              ),
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: colorScheme.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Divider(height: 1, color: colorScheme.onSurface.withValues(alpha: 0.08)),

                    // =========================================================
                    // BARRA DE HERRAMIENTAS DE ESTUDIO ENRIQUECIDA
                    // =========================================================
                    RichTextToolbar(
                      fontSize: _fontSize,
                      onFontSizeChanged: (newSize) => setState(() => _fontSize = newSize),
                      isBold: _isBold,
                      isItalic: _isItalic,
                      onToggleBold: () => setState(() => _isBold = !_isBold),
                      onToggleItalic: () => setState(() => _isItalic = !_isItalic),
                      onToggleBullet: _insertBullet,
                      onToggleNumbered: _insertNumbered,
                      onToggleChecklist: _insertChecklist,
                      onInsertExamCallout: _openExamAlertModal,
                      onInsertCodeBlock: _openCodeSnippetModal,
                      onAlignmentChanged: (align) => setState(() => _textAlign = align),
                      currentAlign: _textAlign,
                      currentPaperStyle: _paperStyle,
                      onPaperStyleChanged: (style) => setState(() => _paperStyle = style),
                      onAddTextBox: _addFloatingTextBox,
                      onAddImage: _addFloatingImage,
                    ),
                    Divider(height: 1, color: colorScheme.onSurface.withValues(alpha: 0.08)),
                  ],

                  // ===========================================================
                  // ÁREA DE TRABAJO - LIENZO HOJA A4 CON PAGINACIÓN FLUIDA
                  // ===========================================================
                  Expanded(
                    child: PageView.builder(
                      controller: _pageController,
                      itemCount: _pages.length,
                      onPageChanged: (page) => setState(() => _currentPage = page),
                      itemBuilder: (context, index) {
                        return A4PageCanvas(
                          pageModel: _pages[index],
                          textController: _getController(index),
                          fontSize: _fontSize,
                          isBold: _isBold,
                          isItalic: _isItalic,
                          textAlign: _textAlign,
                          paperStyle: _paperStyle,
                          onChanged: (text) => _pages[index].textContent = text,
                          onPageModified: () => setState(() {}),
                        );
                      },
                    ),
                  ),

                  // ===========================================================
                  // PAGINADOR INFERIOR Y ESTADÍSTICAS (Oculto cuando el teclado está activo)
                  // ===========================================================
                  if (!isKeyboardVisible)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: cardColor,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            offset: const Offset(0, -2),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Contador de palabras y navegación de hojas
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.chevron_left_rounded),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                onPressed: _currentPage > 0
                                    ? () => _pageController.previousPage(
                                          duration: const Duration(milliseconds: 250),
                                          curve: Curves.easeInOut,
                                        )
                                    : null,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Pág ${_currentPage + 1} de ${_pages.length}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: colorScheme.onSurface,
                                ),
                              ),
                              const SizedBox(width: 4),
                              IconButton(
                                icon: const Icon(Icons.chevron_right_rounded),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                onPressed: _currentPage < _pages.length - 1
                                    ? () => _pageController.nextPage(
                                          duration: const Duration(milliseconds: 250),
                                          curve: Curves.easeInOut,
                                        )
                                    : null,
                              ),
                              const SizedBox(width: 10),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: colorScheme.onSurface.withValues(alpha: 0.06),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  '$_wordCount palabras',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: colorScheme.onSurface.withValues(alpha: 0.6),
                                  ),
                                ),
                              ),
                            ],
                          ),

                          // Acciones de hoja (+ Hoja / Eliminar Hoja)
                          Row(
                            children: [
                              if (_pages.length > 1)
                                IconButton(
                                  icon: const Icon(Icons.delete_outline_rounded, size: 20),
                                  tooltip: 'Eliminar esta hoja',
                                  color: AppColors.rojoAlerta,
                                  onPressed: _deleteCurrentPage,
                                ),
                              ElevatedButton.icon(
                                onPressed: _addNewPage,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: colorScheme.primary,
                                  foregroundColor: colorScheme.onPrimary,
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                icon: const Icon(Icons.add_rounded, size: 18),
                                label: const Text('Hoja', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                ],
              ),
      ),
    );
  }
}
