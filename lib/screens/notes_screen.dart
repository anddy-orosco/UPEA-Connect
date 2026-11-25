import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/colors.dart';
import '../models/note_model.dart';
import '../services/notes_service.dart';
import '../services/connectivity_service.dart';
import '../widgets/note_export_modal.dart';
import 'notes_editor_screen.dart';

class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  List<NoteModel> _notes = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _selectedCourse = 'Todas';
  bool _isGridView = true; // Cuadernos en cuadrícula vs Lista compacta

  String? _loadError;
  bool _wasOnline = ConnectivityService.instance.isOnline;

  @override
  void initState() {
    super.initState();
    _loadNotes();
    ConnectivityService.instance.addListener(_onConnectivityChanged);
  }

  @override
  void dispose() {
    ConnectivityService.instance.removeListener(_onConnectivityChanged);
    super.dispose();
  }

  void _onConnectivityChanged() {
    final online = ConnectivityService.instance.isOnline;
    if (online && !_wasOnline) _loadNotes(silent: true);
    _wasOnline = online;
  }

  String _errorText(String prefix, Object e) {
    final msg = e.toString().replaceFirst('Exception: ', '');
    if (msg == ConnectivityService.offlineWriteMessage) return msg;
    return '$prefix: $msg';
  }

  void _showOfflineMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(ConnectivityService.offlineWriteMessage),
        backgroundColor: AppColors.rojoAlerta,
      ),
    );
  }

  Future<void> _loadNotes({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _isLoading = true;
        _loadError = null;
      });
    }

    try {
      final notes = await NotesService.getNotes();
      if (!mounted) return;
      setState(() {
        _notes = notes;
        _isLoading = false;
        _loadError = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        if (!silent) _loadError = _errorText('No se pudieron cargar las notas', e);
      });
    }
  }

  List<String> get _availableCourses {
    final courses = <String>{'Todas'};
    for (final note in _notes) {
      if (note.courseName != null && note.courseName!.trim().isNotEmpty) {
        courses.add(note.courseName!.trim());
      }
    }
    return courses.toList();
  }

  List<NoteModel> get _filteredNotes {
    var result = _notes;

    // Filtro por materia
    if (_selectedCourse != 'Todas') {
      result = result
          .where((n) => n.courseName?.trim().toLowerCase() == _selectedCourse.toLowerCase())
          .toList();
    }

    // Filtro por búsqueda
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      result = result.where((note) =>
          note.title.toLowerCase().contains(query) ||
          note.content.toLowerCase().contains(query) ||
          (note.courseName?.toLowerCase().contains(query) ?? false)
      ).toList();
    }

    return result;
  }

  Future<void> _createOrEditNote({NoteModel? existingNote}) async {
    if (existingNote == null && !ConnectivityService.instance.isOnline) {
      _showOfflineMessage();
      return;
    }

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
          Navigator.of(context, rootNavigator: true).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_errorText('No se pudo cargar la nota', e)),
              backgroundColor: AppColors.rojoAlerta,
            ),
          );
        }
        return;
      }

      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
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

  Future<void> _exportDirectly(NoteModel note) async {
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

    NoteModel fullNote = note;
    try {
      fullNote = await NotesService.getNoteById(note.id);
    } catch (_) {}

    if (!mounted) return;
    Navigator.of(context, rootNavigator: true).pop();

    NoteExportModal.show(
      context: context,
      pages: fullNote.pages,
      title: fullNote.title,
      courseName: fullNote.courseName,
    );
  }

  Future<void> _deleteNote(String id) async {
    if (!ConnectivityService.instance.isOnline) {
      _showOfflineMessage();
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar nota'),
        content: const Text('¿Estás seguro de que quieres eliminar esta nota?'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.rojoAlerta,
              foregroundColor: Colors.white,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
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
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_errorText('No se pudo eliminar la nota', e)),
              backgroundColor: AppColors.rojoAlerta,
            ),
          );
        }
      }
    }
  }

  Color _getCourseSpineColor(String? course) {
    if (course == null || course.isEmpty) return AppColors.azulPrincipal;
    final hash = course.hashCode;
    const colors = [
      Color(0xFF1E3A8A), // Azul marino
      Color(0xFF047857), // Verde esmeralda
      Color(0xFF7C3AED), // Púrpura
      Color(0xFFB45309), // Ámbar oscuro
      Color(0xFFBE123C), // Rubí
      Color(0xFF0F766E), // Teal
      Color(0xFF4338CA), // Índigo
    ];
    return colors[hash.abs() % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = Theme.of(context).cardColor;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: RefreshIndicator(
          onRefresh: () => _loadNotes(silent: false),
          color: colorScheme.primary,
          child: Column(
            children: [
              // ===============================================================
              // HEADER DE BÚSQUEDA Y CAMBIO DE VISTA
              // ===============================================================
              Container(
                color: cardColor,
                padding: const EdgeInsets.only(left: 16, right: 12, top: 12, bottom: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 42,
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white.withValues(alpha: 0.08) : AppColors.grisClaro,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: TextField(
                          onChanged: (val) => setState(() => _searchQuery = val),
                          style: TextStyle(color: colorScheme.onSurface, fontSize: 14),
                          decoration: InputDecoration(
                            hintText: 'Buscar en mis apuntes...',
                            hintStyle: TextStyle(
                              color: colorScheme.onSurface.withValues(alpha: 0.45),
                              fontSize: 13,
                            ),
                            prefixIcon: Icon(Icons.search_rounded, color: colorScheme.primary, size: 20),
                            suffixIcon: _searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear, size: 16),
                                    onPressed: () => setState(() => _searchQuery = ''),
                                  )
                                : null,
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Toggle Cuadrícula / Lista
                    IconButton(
                      icon: Icon(
                        _isGridView ? Icons.view_agenda_outlined : Icons.grid_view_rounded,
                        color: colorScheme.primary,
                      ),
                      tooltip: _isGridView ? 'Vista Lista' : 'Vista Cuadernos',
                      onPressed: () => setState(() => _isGridView = !_isGridView),
                    ),
                  ],
                ),
              ),

              // ===============================================================
              // FILTRO POR MATERIAS (Chips horizontales)
              // ===============================================================
              if (_availableCourses.length > 1)
                Container(
                  color: cardColor,
                  height: 42,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _availableCourses.length,
                    itemBuilder: (context, index) {
                      final course = _availableCourses[index];
                      final isSelected = _selectedCourse.toLowerCase() == course.toLowerCase();
                      return Padding(
                        padding: const EdgeInsets.only(right: 8, bottom: 6),
                        child: ChoiceChip(
                          label: Text(
                            course,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                              color: isSelected ? colorScheme.onPrimary : colorScheme.onSurface,
                            ),
                          ),
                          selected: isSelected,
                          selectedColor: colorScheme.primary,
                          backgroundColor: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.04),
                          side: BorderSide.none,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          onSelected: (selected) {
                            if (selected) {
                              setState(() => _selectedCourse = course);
                            }
                          },
                        ),
                      );
                    },
                  ),
                ),

              Divider(height: 1, color: colorScheme.onSurface.withValues(alpha: 0.08)),

              // ===============================================================
              // CONTENIDO PRINCIPAL: CUADERNOS O LISTA
              // ===============================================================
              Expanded(
                child: _isLoading
                    ? Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
                        ),
                      )
                    : _loadError != null
                        ? _buildLoadErrorState(colorScheme)
                        : _filteredNotes.isEmpty
                            ? _buildEmptyState(colorScheme)
                            : _isGridView
                                ? _buildGridView(colorScheme, isDark)
                                : _buildListView(colorScheme),
              ),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _createOrEditNote(),
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          icon: const Icon(Icons.edit_note_rounded, size: 24),
          label: const Text(
            'Nuevo Apunte',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // MODO CUADRÍCULA DE CUADERNOS (ESTILO NOTION / GOODNOTES)
  // ===========================================================================

  Widget _buildGridView(ColorScheme colorScheme, bool isDark) {
    return GridView.builder(
      physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        childAspectRatio: 0.82,
      ),
      itemCount: _filteredNotes.length,
      itemBuilder: (context, index) {
        final note = _filteredNotes[index];
        return _buildNotebookCard(note, colorScheme, isDark);
      },
    );
  }

  Widget _buildNotebookCard(NoteModel note, ColorScheme colorScheme, bool isDark) {
    final spineColor = _getCourseSpineColor(note.courseName);
    final cardBg = Theme.of(context).cardColor;
    final formattedDate = DateFormat('dd/MM/yyyy').format(note.updatedAt);

    return Material(
      color: cardBg,
      elevation: 2,
      shadowColor: Colors.black26,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: () => _createOrEditNote(existingNote: note),
        borderRadius: BorderRadius.circular(12),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Lomo / Tapa del cuaderno con color de la materia
              Container(
                height: 8,
                color: spineColor,
              ),

              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Badge de Materia
                      if (note.courseName != null && note.courseName!.trim().isNotEmpty) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: spineColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            note.courseName!.trim(),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: spineColor,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(height: 6),
                      ],

                      // Título del apunte
                      Text(
                        note.title.isEmpty ? 'Sin título' : note.title,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),

                      // Extracto del texto
                      Expanded(
                        child: Text(
                          note.content.isEmpty ? 'Toca para comenzar a escribir...' : note.content,
                          style: TextStyle(
                            fontSize: 11,
                            color: colorScheme.onSurface.withValues(alpha: 0.6),
                            height: 1.35,
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),

                      // Barra inferior de la tarjeta
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            formattedDate,
                            style: TextStyle(
                              fontSize: 10,
                              color: colorScheme.onSurface.withValues(alpha: 0.45),
                            ),
                          ),
                          PopupMenuButton<String>(
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            icon: Icon(
                              Icons.more_vert_rounded,
                              size: 18,
                              color: colorScheme.onSurface.withValues(alpha: 0.6),
                            ),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            onSelected: (val) {
                              if (val == 'edit') {
                                _createOrEditNote(existingNote: note);
                              } else if (val == 'export') {
                                _exportDirectly(note);
                              } else if (val == 'delete') {
                                _deleteNote(note.id);
                              }
                            },
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: 'edit',
                                child: Row(
                                  children: [
                                    Icon(Icons.edit_rounded, size: 16),
                                    SizedBox(width: 8),
                                    Text('Editar Apunte', style: TextStyle(fontSize: 13)),
                                  ],
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'export',
                                child: Row(
                                  children: [
                                    Icon(Icons.ios_share_rounded, size: 16, color: Colors.blue),
                                    SizedBox(width: 8),
                                    Text('Exportar Word/PDF', style: TextStyle(fontSize: 13)),
                                  ],
                                ),
                              ),
                              const PopupMenuDivider(),
                              const PopupMenuItem(
                                value: 'delete',
                                child: Row(
                                  children: [
                                    Icon(Icons.delete_outline_rounded, size: 16, color: AppColors.rojoAlerta),
                                    SizedBox(width: 8),
                                    Text('Eliminar', style: TextStyle(fontSize: 13, color: AppColors.rojoAlerta)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // MODO LISTA COMPACTA
  // ===========================================================================

  Widget _buildListView(ColorScheme colorScheme) {
    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: _filteredNotes.length,
      itemBuilder: (context, index) {
        final note = _filteredNotes[index];
        return _buildNoteListCard(note, colorScheme);
      },
    );
  }

  Widget _buildNoteListCard(NoteModel note, ColorScheme colorScheme) {
    final spineColor = _getCourseSpineColor(note.courseName);
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 1.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _createOrEditNote(existingNote: note),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Barra vertical lateral de color
              Container(
                width: 4,
                height: 52,
                margin: const EdgeInsets.only(right: 12, top: 2),
                decoration: BoxDecoration(
                  color: spineColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            note.title.isEmpty ? 'Sin título' : note.title,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSurface,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (note.courseName != null && note.courseName!.trim().isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: spineColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              note.courseName!.trim(),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: spineColor,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      note.content.isEmpty ? 'Sin contenido adicional' : note.content,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onSurface.withValues(alpha: 0.65),
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Última edición: ${dateFormat.format(note.updatedAt)}',
                      style: TextStyle(
                        fontSize: 10,
                        color: colorScheme.onSurface.withValues(alpha: 0.45),
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                padding: EdgeInsets.zero,
                icon: Icon(
                  Icons.more_vert_rounded,
                  size: 20,
                  color: colorScheme.onSurface.withValues(alpha: 0.5),
                ),
                onSelected: (val) {
                  if (val == 'export') {
                    _exportDirectly(note);
                  } else if (val == 'delete') {
                    _deleteNote(note.id);
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'export',
                    child: Row(
                      children: [
                        Icon(Icons.ios_share_rounded, size: 16, color: Colors.blue),
                        SizedBox(width: 8),
                        Text('Exportar Word/PDF', style: TextStyle(fontSize: 13)),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline_rounded, size: 16, color: AppColors.rojoAlerta),
                        SizedBox(width: 8),
                        Text('Eliminar', style: TextStyle(fontSize: 13, color: AppColors.rojoAlerta)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadErrorState(ColorScheme colorScheme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off, size: 54, color: colorScheme.onSurface.withValues(alpha: 0.3)),
            const SizedBox(height: 14),
            Text(
              _loadError!,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colorScheme.onSurface.withValues(alpha: 0.6),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadNotes,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Reintentar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(ColorScheme colorScheme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.menu_book_rounded,
                size: 54,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isNotEmpty || _selectedCourse != 'Todas'
                  ? 'No se encontraron notas'
                  : 'Tu espacio de estudio está listo',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface.withValues(alpha: 0.8),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _searchQuery.isNotEmpty || _selectedCourse != 'Todas'
                  ? 'Prueba con otro término de búsqueda o cambia de materia'
                  : 'Crea tu primer apunte con hojas rayadas, cuadriculadas, notas adhesivas y expórtalo en Word o PDF.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: colorScheme.onSurface.withValues(alpha: 0.5),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => _createOrEditNote(),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Crear Primer Cuaderno'),
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
