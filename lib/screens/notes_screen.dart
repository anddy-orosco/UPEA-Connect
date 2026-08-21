import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:open_file/open_file.dart';
import 'package:flutter/foundation.dart';
import '../theme/colors.dart';
import '../models/note_model.dart';
import '../models/note_page_model.dart';
import '../services/notes_service.dart';
import '../services/api_service.dart';
import '../services/pptx_export_service.dart';
import '../widgets/rich_text_toolbar.dart';
import '../widgets/a4_page_canvas.dart';

class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  List<NoteModel> _notes = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  Future<void> _loadNotes() async {
    setState(() {
      _isLoading = true;
    });

    final notes = await NotesService.getNotes();

    setState(() {
      _notes = notes;
      _isLoading = false;
    });
  }

  List<NoteModel> get _filteredNotes {
    if (_searchQuery.isEmpty) return _notes;

    return _notes.where((note) =>
    note.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        note.content.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        (note.courseName?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false)
    ).toList();
  }

  // El listado (GET /notes) no trae páginas ni elementos flotantes, así que
  // antes de abrir el editor sobre una nota existente hay que pedir la nota
  // completa con GET /notes/:id. Si esa carga falla, no se abre el editor.
  Future<void> _createOrEditNote({NoteModel? existingNote}) async {
    NoteModel? noteToEdit = existingNote;

    if (existingNote != null) {
      final loadingColor = Theme.of(context).colorScheme.primary;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(loadingColor),
          ),
        ),
      );

      try {
        noteToEdit = await NotesService.getNoteById(existingNote.id);
      } catch (e) {
        if (mounted) {
          Navigator.of(context, rootNavigator: true).pop(); // cierra el loading
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('No se pudo cargar la nota: $e'),
              backgroundColor: AppColors.rojoAlerta,
            ),
          );
        }
        return;
      }

      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop(); // cierra el loading
      }
    }

    if (!mounted) return;

    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => NoteEditorScreen(note: noteToEdit),
      ),
    );

    if (result == true) {
      _loadNotes();
    }
  }

  Future<void> _deleteNote(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar nota'),
        content: const Text('¿Estás seguro de que quieres eliminar esta nota?'),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.rojoAlerta,
              foregroundColor: AppColors.blanco,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await NotesService.deleteNote(id);
      _loadNotes();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Nota eliminada'),
            backgroundColor: AppColors.rojoAlerta,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Mismo criterio que login_screen.dart: relleno claro/translúcido en
    // modo oscuro en vez de un gris/blanco fijo que no se distinguía del
    // fondo negro.
    final fillColor = isDark ? Colors.white.withOpacity(0.07) : AppColors.grisClaro;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          // Barra de búsqueda
          Container(
            padding: const EdgeInsets.all(16),
            color: Theme.of(context).cardColor,
            child: TextField(
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
              style: TextStyle(color: colorScheme.onSurface),
              decoration: InputDecoration(
                hintText: 'Buscar notas...',
                hintStyle: TextStyle(color: colorScheme.onSurface.withOpacity(0.5)),
                prefixIcon: Icon(Icons.search, color: colorScheme.primary),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: fillColor,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),

          // Lista de notas
          Expanded(
            child: _isLoading
                ? Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
              ),
            )
                : _filteredNotes.isEmpty
                ? _buildEmptyState(colorScheme)
                : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _filteredNotes.length,
              itemBuilder: (context, index) {
                final note = _filteredNotes[index];
                return _buildNoteCard(note, colorScheme);
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _createOrEditNote(),
        backgroundColor: colorScheme.primary,
        child: Icon(Icons.add, color: colorScheme.onPrimary),
      ),
    );
  }

  Widget _buildEmptyState(ColorScheme colorScheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.note_alt_outlined,
            size: 100,
            color: colorScheme.onSurface.withOpacity(0.3),
          ),
          const SizedBox(height: 20),
          Text(
            'No hay notas',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Toca el botón + para crear una nota',
            style: TextStyle(
              fontSize: 16,
              color: colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoteCard(NoteModel note, ColorScheme colorScheme) {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _createOrEditNote(existingNote: note),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      note.title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ),
                  if (note.courseName != null && note.courseName!.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(left: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        note.courseName!,
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                note.content,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 14,
                  color: colorScheme.onSurface.withOpacity(0.7),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Última modificación: ${dateFormat.format(note.updatedAt)}',
                      style: TextStyle(
                        fontSize: 11,
                        color: colorScheme.onSurface.withOpacity(0.5),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.delete_outline,
                      color: AppColors.rojoAlerta,
                      size: 20,
                    ),
                    onPressed: () => _deleteNote(note.id),
                    constraints: const BoxConstraints(),
                    padding: EdgeInsets.zero,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// EDITOR CON SOPORTE COMPLETO DE ELEMENTOS FLOTANTES, IMÁGENES Y GUARDADO
// ============================================================================

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
  bool _isLoading = false;

  // Subidas de imagen en curso (id del elemento -> Future de la subida).
  // _saveNote espera a que todas terminen antes de guardar, para no mandar
  // al backend una ruta local en vez de la URL subida.
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

  void _addNewPage() {
    setState(() {
      final newIndex = _pages.length;
      _pages.add(NotePageModel(pageIndex: newIndex));
      _pageTextControllers[newIndex] = TextEditingController();
    });
    _pageController.animateToPage(
      _pages.length - 1,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _addFloatingTextBox() {
    setState(() {
      _pages[_currentPage].floatingElements.add(
        FloatingElement(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          position: const Offset(40, 40),
          width: 180,
          height: 100,
          text: '',
        ),
      );
    });
  }

  // Al elegir la imagen, se agrega de inmediato al lienzo con la ruta local
  // (para que se vea al instante mientras sube) y en paralelo se suben sus
  // bytes al backend. Cuando la subida termina, se reemplaza la ruta local
  // por la URL pública, que es la que realmente se guarda al llamar a
  // NotesService.saveNote. Usar bytes (XFile.readAsBytes) en vez de un
  // dart:io File hace que esto funcione igual en celular y en web.
  Future<void> _addFloatingImage() async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image == null) return;

    final elementId = DateTime.now().millisecondsSinceEpoch.toString();

    setState(() {
      _pages[_currentPage].floatingElements.add(
        FloatingElement(
          id: elementId,
          position: const Offset(50, 100),
          width: 200,
          height: 150,
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
      // El error ya se le mostró al usuario dentro de _uploadFloatingImage;
      // acá solo evitamos que la excepción se propague sin manejar.
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
      // Se relanza para que _saveNote sepa (vía Future.wait) que esta
      // subida en particular falló y pueda descartar esa imagen al guardar.
      rethrow;
    }
  }

  Future<void> _exportToPptx() async {
    if (_titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Escribe un título para exportar'),
          backgroundColor: AppColors.rojoAlerta,
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Generando archivo de exportación...')),
    );

    // Sincronizar textos antes de exportar
    _syncPageControllers();

    final result = await PptxExportService.exportNotesToPptx(_pages, _titleController.text.trim());

    if (mounted) {
      if (kIsWeb) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result),
            backgroundColor: AppColors.verdeExito,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Exportado con éxito en: $result'),
            backgroundColor: AppColors.verdeExito,
            action: SnackBarAction(
              label: 'Abrir',
              textColor: AppColors.blanco,
              onPressed: () => OpenFile.open(result),
            ),
          ),
        );
      }
    }
  }

  void _syncPageControllers() {
    for (int i = 0; i < _pages.length; i++) {
      if (_pageTextControllers.containsKey(i)) {
        _pages[i].textContent = _pageTextControllers[i]!.text;
      }
    }
  }

  Future<void> _saveNote() async {
    _syncPageControllers();

    final fullContent = _pages.map((p) => p.textContent).join('\n---\n');

    if (_titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('El título de la nota es obligatorio'),
          backgroundColor: AppColors.rojoAlerta,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Si hay imágenes subiéndose todavía, hay que esperarlas: si se
      // guarda antes de tiempo, la nota se manda con la ruta local del
      // celular en vez de la URL, y el backend la rechaza por no ser una
      // URL válida. Se ignoran los errores acá porque _uploadFloatingImage
      // ya le avisó al usuario cuál imagen falló; lo que importa es que,
      // para cuando sigamos, ya no quede ninguna subida en curso.
      if (_pendingImageUploads.isNotEmpty) {
        await Future.wait(
          _pendingImageUploads.values.toList(),
          eagerError: false,
        ).catchError((_) => <void>[]);
      }

      // Cualquier imagen que siga sin una URL real (http/https) es porque
      // su subida falló y no se pudo reintentar a tiempo: se descarta para
      // no romper la validación del backend, y se avisa al usuario.
      var removedFailedImage = false;
      for (final page in _pages) {
        final before = page.floatingElements.length;
        page.floatingElements.removeWhere(
          (e) => e.isImage && !(e.imagePath?.startsWith('http') ?? false),
        );
        if (page.floatingElements.length != before) {
          removedFailedImage = true;
        }
      }

      if (removedFailedImage && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Una imagen no se pudo subir y no se guardó'),
            backgroundColor: AppColors.rojoAlerta,
          ),
        );
      }

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
        pages: _pages, // Se envían las páginas con sus textos e imágenes flotantes
      );

      // isNew le dice a NotesService.saveNote si debe hacer POST (nota
      // nueva) o PUT sobre note.id (edición de una nota existente).
      await NotesService.saveNote(note, isNew: isNew);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isNew ? '✓ Nota creada' : '✓ Nota actualizada'),
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
            content: Text('Error al guardar: $e'),
            backgroundColor: AppColors.rojoAlerta,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final cardColor = Theme.of(context).cardColor;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(widget.note == null ? 'Nueva Nota' : 'Editar Nota'),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.slideshow),
            tooltip: 'Exportar Documento',
            onPressed: _exportToPptx,
          ),
          TextButton(
            onPressed: _isLoading ? null : _saveNote,
            style: TextButton.styleFrom(
              foregroundColor: colorScheme.onPrimary,
            ),
            child: _isLoading
                ? SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                color: colorScheme.onPrimary,
                strokeWidth: 2,
              ),
            )
                : const Text(
              'Guardar',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
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
          // Campos Superiores (Título y Materia)
          Container(
            color: cardColor,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _titleController,
                    decoration: InputDecoration(
                      hintText: 'Título de la nota...',
                      hintStyle: TextStyle(color: colorScheme.onSurface.withOpacity(0.4)),
                      border: InputBorder.none,
                    ),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 140,
                  child: TextField(
                    controller: _courseController,
                    decoration: InputDecoration(
                      hintText: 'Materia (Opcional)',
                      hintStyle: TextStyle(color: colorScheme.onSurface.withOpacity(0.4)),
                      border: InputBorder.none,
                    ),
                    style: TextStyle(fontSize: 14, color: colorScheme.onSurface.withOpacity(0.75)),
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: colorScheme.onSurface.withOpacity(0.1)),

          // Barra de herramientas de texto enriquecido
          RichTextToolbar(
            fontSize: _fontSize,
            onFontSizeChanged: (newSize) => setState(() => _fontSize = newSize),
            onToggleBold: () => setState(() => _isBold = !_isBold),
            onToggleItalic: () => setState(() => _isItalic = !_isItalic),
            onToggleBullet: () {
              final controller = _getController(_currentPage);
              controller.text = '${controller.text}\n• ';
            },
            onAlignmentChanged: (align) => setState(() => _textAlign = align),
            onAddTextBox: _addFloatingTextBox,
            onAddImage: _addFloatingImage,
          ),
          Divider(height: 1, color: colorScheme.onSurface.withOpacity(0.1)),

          // ÁREA DE TRABAJO - Lienzo Hoja A4 con Paginación
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
                  onChanged: (text) => _pages[index].textContent = text,
                );
              },
            ),
          ),

          // Paginador Inferior
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: cardColor,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Página ${_currentPage + 1} de ${_pages.length}',
                  style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.onSurface),
                ),
                ElevatedButton.icon(
                  onPressed: _addNewPage,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                  ),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Agregar Hoja'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
