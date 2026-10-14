import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../models/chat_message_model.dart';
import '../services/ai_chat_service.dart';
import '../services/calendar_service.dart';
import '../services/notes_service.dart';
import '../models/event_model.dart';
import '../models/note_model.dart';
import '../models/note_page_model.dart';
import 'chat_history_screen.dart';

/// Pantalla de chat con la IA (con historial de conversaciones).
/// Vive en lib/screens/chat_screen.dart
class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  static const List<String> _sugerencias = [
    'Explícame qué es una derivada',
    'Recuérdame mañana a las 10:00 estudiar Física',
    'Hazme un apunte sobre las leyes de Newton',
    'Ayúdame a organizar mi semana de estudio',
  ];

  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];

  /// Id de la conversación abierta. null = chat nuevo (se crea al enviar
  /// el primer mensaje).
  String? _conversationId;

  /// true mientras se espera la respuesta de la IA o se ejecuta una acción.
  bool _isLoading = false;

  /// true mientras se carga una conversación del historial.
  bool _loadingConversation = false;

  /// Texto del último envío que falló (para el botón "Reintentar").
  String? _lastFailedText;

  // ───────────────────────── Envío de mensajes ─────────────────────────

  void _enviarDesdeInput() {
    final texto = _controller.text.trim();
    if (texto.isEmpty || _isLoading) return;
    _controller.clear();
    _enviar(texto);
  }

  Future<void> _enviar(String texto, {bool reintento = false}) async {
    if (texto.isEmpty || _isLoading) return;

    setState(() {
      if (reintento) {
        // Quita el mensaje de error; el mensaje del usuario ya está en pantalla.
        if (_messages.isNotEmpty && _messages.last.isError) {
          _messages.removeLast();
        }
      } else {
        _messages.add(ChatMessage(text: texto, isUser: true));
      }
      _lastFailedText = null;
      _isLoading = true;
    });
    _scrollToBottom();

    final result = await AiChatService.sendMessage(
      texto,
      conversationId: _conversationId,
    );
    if (!mounted) return;

    setState(() {
      if (result.conversationId != null) {
        _conversationId = result.conversationId;
      }
      _messages.add(result.reply);
      if (result.failed) _lastFailedText = texto;
      _isLoading = false;
    });
    _scrollToBottom();
  }

  void _reintentar() {
    final texto = _lastFailedText;
    if (texto == null) return;
    _enviar(texto, reintento: true);
  }

  // ───────────────────────── Historial ─────────────────────────

  void _nuevoChat() {
    setState(() {
      _messages.clear();
      _conversationId = null;
      _lastFailedText = null;
    });
  }

  Future<void> _abrirHistorial() async {
    final result = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => ChatHistoryScreen(
          currentId: _conversationId,
          onDeleted: (id) {
            // Si borraron la conversación que estaba abierta, se limpia el chat.
            if (id == _conversationId) _nuevoChat();
          },
        ),
      ),
    );

    if (!mounted || result == null) return;

    if (result == ChatHistoryScreen.newChat) {
      _nuevoChat();
    } else {
      await _abrirConversacion(result);
    }
  }

  Future<void> _abrirConversacion(String id) async {
    if (id == _conversationId) return;

    setState(() => _loadingConversation = true);
    try {
      final mensajes = await AiChatService.getMessages(id);
      if (!mounted) return;
      setState(() {
        _messages
          ..clear()
          ..addAll(mensajes);
        _conversationId = id;
        _lastFailedText = null;
        _loadingConversation = false;
      });
      _scrollToBottom(jump: true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingConversation = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ───────────────────────── UI ─────────────────────────

  void _scrollToBottom({bool jump = false}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      final max = _scrollController.position.maxScrollExtent;
      if (jump) {
        _scrollController.jumpTo(max);
      } else {
        _scrollController.animateTo(
          max,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  String _hora(DateTime d) {
    String dos(int n) => n.toString().padLeft(2, '0');
    return '${dos(d.hour)}:${dos(d.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          'Asistente UPEA',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 2,
        actions: [
          IconButton(
            tooltip: 'Historial',
            icon: const Icon(Icons.history),
            onPressed: _isLoading ? null : _abrirHistorial,
          ),
          IconButton(
            tooltip: 'Nuevo chat',
            icon: const Icon(Icons.add_comment_outlined),
            onPressed: _isLoading ? null : _nuevoChat,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(child: _buildMessages(colorScheme)),
          _buildInputBar(colorScheme),
        ],
      ),
    );
  }

  Widget _buildMessages(ColorScheme colorScheme) {
    if (_loadingConversation) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_messages.isEmpty && !_isLoading) {
      return _buildEmptyState(colorScheme);
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(14),
      itemCount: _messages.length + (_isLoading ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _messages.length) {
          return _buildTypingIndicator(colorScheme);
        }
        return _buildMessageBubble(
          _messages[index],
          index,
          colorScheme,
          isLast: index == _messages.length - 1,
        );
      },
    );
  }

  Widget _buildEmptyState(ColorScheme colorScheme) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: colorScheme.primary.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.auto_awesome, color: colorScheme.primary, size: 30),
            ),
            const SizedBox(height: 16),
            Text(
              'Hola, soy tu asistente UPEA',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Puedo resolver dudas de tus materias, y crear apuntes o eventos en tu calendario.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                height: 1.4,
                color: colorScheme.onSurface.withOpacity(0.65),
              ),
            ),
            const SizedBox(height: 20),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: _sugerencias
                  .map(
                    (s) => ActionChip(
                      label: Text(s, style: const TextStyle(fontSize: 12)),
                      onPressed: () => _enviar(s),
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(
    ChatMessage message,
    int index,
    ColorScheme colorScheme, {
    required bool isLast,
  }) {
    final isUser = message.isUser;
    final textColor = isUser ? colorScheme.onPrimary : colorScheme.onSurface;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isUser ? colorScheme.primary : Theme.of(context).cardColor,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(14),
            topRight: const Radius.circular(14),
            bottomLeft: Radius.circular(isUser ? 14 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 14),
          ),
          border: isUser
              ? null
              : Border.all(
                  color: message.isError
                      ? Colors.red.withOpacity(0.5)
                      : colorScheme.onSurface.withOpacity(0.12),
                ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (message.isError)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, size: 16, color: Colors.red),
                    const SizedBox(width: 6),
                    Text(
                      'No se pudo enviar',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.red.shade400,
                      ),
                    ),
                  ],
                ),
              ),
            Text(
              message.text,
              style: TextStyle(fontSize: 14, height: 1.4, color: textColor),
            ),
            if (message.isError &&
                isLast &&
                _lastFailedText != null &&
                !_isLoading) ...[
              const SizedBox(height: 6),
              TextButton.icon(
                onPressed: _reintentar,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Reintentar'),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: const Size(0, 32),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ],
            if (message.action != null) ...[
              const SizedBox(height: 10),
              _buildActionArea(message, index, colorScheme),
            ],
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                _hora(message.createdAt),
                style: TextStyle(
                  fontSize: 10,
                  color: textColor.withOpacity(0.6),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Según el estado de la acción: tarjeta (pendiente), "Creado" o "Descartado".
  Widget _buildActionArea(ChatMessage message, int index, ColorScheme colorScheme) {
    final action = message.action!;

    if (message.actionStatus == 'DONE') {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_circle, size: 18, color: AppColors.verdeExito),
          const SizedBox(width: 6),
          Text(
            action.type == 'crear_evento' ? 'Evento creado' : 'Apunte creado',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.verdeExito,
            ),
          ),
        ],
      );
    }

    if (message.actionStatus == 'DISCARDED') {
      return Text(
        'Descartado',
        style: TextStyle(
          fontSize: 12,
          fontStyle: FontStyle.italic,
          color: colorScheme.onSurface.withOpacity(0.5),
        ),
      );
    }

    return _buildActionCard(action, index, colorScheme);
  }

  Widget _buildActionCard(ChatAction action, int messageIndex, ColorScheme colorScheme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.onSurface.withOpacity(0.05),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Column en vez de Row: los valores (sobre todo "contenido",
          // que puede ser un párrafo largo) no caben junto a la etiqueta.
          ...action.data.entries.map(
            (e) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    e.key,
                    style: TextStyle(fontSize: 12, color: colorScheme.onSurface.withOpacity(0.6)),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${e.value}',
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: _isLoading
                      ? null
                      : () => _confirmarAccion(action, messageIndex),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    action.type == 'crear_evento'
                        ? 'Crear evento'
                        : 'Crear apunte',
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: _isLoading
                      ? null
                      : () => _marcarAccion(messageIndex, 'DISCARDED'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: colorScheme.onSurface.withOpacity(0.75),
                    side: BorderSide(color: colorScheme.onSurface.withOpacity(0.25)),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Descartar', style: TextStyle(fontSize: 13)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // Acciones del asistente (crear evento / apunte) y su estado.
  // ─────────────────────────────────────────────────────────────

  /// Cambia el estado de la tarjeta ('DONE' o 'DISCARDED') en pantalla y
  /// lo guarda en el backend, para que al reabrir la conversación no
  /// vuelva a aparecer como pendiente.
  void _marcarAccion(int index, String status) {
    if (index < 0 || index >= _messages.length) return;

    final msg = _messages[index];
    setState(() => _messages[index] = msg.copyWith(actionStatus: status));

    final convId = _conversationId;
    final msgId = msg.id;
    if (convId != null && msgId != null) {
      AiChatService.markActionStatus(
        conversationId: convId,
        messageId: msgId,
        status: status,
      );
    }
  }

  Future<void> _confirmarAccion(ChatAction action, int messageIndex) async {
    setState(() => _isLoading = true);

    try {
      if (action.type == 'crear_evento') {
        await _crearEventoDesdeAccion(action);
      } else if (action.type == 'crear_nota') {
        // El backend manda "crear_nota", no "crear_apunte".
        await _crearApunteDesdeAccion(action);
      } else {
        throw Exception('Tipo de acción desconocido: ${action.type}');
      }

      if (!mounted) return;
      _marcarAccion(messageIndex, 'DONE');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            action.type == 'crear_evento'
                ? 'Evento creado en tu calendario.'
                : 'Apunte creado correctamente.',
          ),
          backgroundColor: AppColors.verdeExito,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'No se pudo completar la acción: ${e.toString().replaceFirst('Exception: ', '')}',
          ),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _crearEventoDesdeAccion(ChatAction action) async {
    final d = action.data;

    final titulo = (d['titulo'] ?? d['title'] ?? 'Evento sin título').toString();
    final tipo = (d['tipo'] ?? d['category'] ?? 'OTHER').toString();

    final fechaRaw = (d['fecha'] ?? d['date'])?.toString();
    if (fechaRaw == null) {
      throw Exception('La IA no envió una fecha válida para el evento');
    }
    final fecha = DateTime.parse(fechaRaw);

    final startTime = TimeOfDay(hour: fecha.hour, minute: fecha.minute);
    final endDateTime = fecha.add(const Duration(hours: 1));
    final endTime = TimeOfDay(hour: endDateTime.hour, minute: endDateTime.minute);

    final evento = EventModel(
      id: '',
      title: titulo,
      description: '',
      date: DateTime(fecha.year, fecha.month, fecha.day),
      startTime: startTime,
      endTime: endTime,
      category: tipo,
      color: AppColors.azulPrincipal,
    );

    await CalendarService().addEvent(evento);
  }

  Future<void> _crearApunteDesdeAccion(ChatAction action) async {
    final d = action.data;

    final titulo = (d['titulo'] ?? d['title'] ?? 'Apunte sin título').toString();
    final contenido =
        (d['contenido'] ?? d['content'] ?? d['resumen'] ?? '').toString();
    // El backend manda la clave "materia" (no "curso" ni "courseName").
    final curso = (d['materia'] ?? d['curso'] ?? d['courseName'])?.toString();

    final nota = NoteModel(
      id: '',
      title: titulo,
      content: contenido,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      courseName: curso,
      // El editor (NoteEditorScreen / A4PageCanvas) lee el texto desde
      // pages[0].textContent, no desde 'content'.
      pages: [
        NotePageModel(
          pageIndex: 0,
          textContent: contenido,
        ),
      ],
    );

    await NotesService.saveNote(nota, isNew: true);
  }

  Widget _buildTypingIndicator(ColorScheme colorScheme) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: colorScheme.onSurface.withOpacity(0.12)),
        ),
        child: SizedBox(
          width: 20,
          height: 12,
          child: Center(
            child: SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputBar(ColorScheme colorScheme) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fillColor = isDark ? Colors.white.withOpacity(0.07) : AppColors.grisClaro;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(top: BorderSide(color: colorScheme.onSurface.withOpacity(0.12))),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                minLines: 1,
                maxLines: 4,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _enviarDesdeInput(),
                style: TextStyle(color: colorScheme.onSurface),
                decoration: InputDecoration(
                  hintText: 'Escribe tu pregunta...',
                  hintStyle: TextStyle(color: colorScheme.onSurface.withOpacity(0.5)),
                  filled: true,
                  fillColor: fillColor,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            InkWell(
              onTap: _isLoading ? null : _enviarDesdeInput,
              borderRadius: BorderRadius.circular(20),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _isLoading
                      ? colorScheme.primary.withOpacity(0.4)
                      : colorScheme.primary,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.arrow_upward, color: colorScheme.onPrimary, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}
