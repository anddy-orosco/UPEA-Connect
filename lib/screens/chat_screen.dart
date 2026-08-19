import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../models/chat_message_model.dart';
import '../services/ai_chat_service.dart';
import '../services/calendar_service.dart';
import '../services/notes_service.dart';
import '../models/event_model.dart';
import '../models/note_model.dart';
import '../models/note_page_model.dart';

/// Pantalla de chat con la IA.
/// Vive en lib/screens/chat_screen.dart
class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _messages.add(
      ChatMessage(
        text: 'Hola, soy tu asistente de UPEA-Connect. Puedo ayudarte con '
            'dudas de tus materias, o crear apuntes y eventos si me das '
            'los datos.',
        isUser: false,
      ),
    );
  }

  Future<void> _enviarMensaje() async {
    final texto = _controller.text.trim();
    if (texto.isEmpty) return;

    setState(() {
      _messages.add(ChatMessage(text: texto, isUser: true));
      _isLoading = true;
    });
    _controller.clear();
    _scrollToBottom();

    try {
      final respuesta = await AiChatService.sendMessage(texto);
      setState(() {
        _messages.add(respuesta);
      });
    } catch (e) {
      setState(() {
        _messages.add(
          ChatMessage(
            text: 'No pude conectarme con la IA. Intenta de nuevo.',
            isUser: false,
          ),
        );
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.grisClaro,
      appBar: AppBar(
        title: const Text(
          'Asistente UPEA',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: AppColors.azulPrincipal,
        foregroundColor: AppColors.blanco,
        elevation: 2,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(14),
              itemCount: _messages.length + (_isLoading ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length) {
                  return _buildTypingIndicator();
                }
                return _buildMessageBubble(_messages[index], index);
              },
            ),
          ),
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message, int index) {
    final isUser = message.isUser;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isUser ? AppColors.azulPrincipal : AppColors.blanco,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(14),
            topRight: const Radius.circular(14),
            bottomLeft: Radius.circular(isUser ? 14 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 14),
          ),
          border: isUser ? null : Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message.text,
              style: TextStyle(
                fontSize: 14,
                height: 1.4,
                color: isUser ? AppColors.blanco : AppColors.azulOscuro,
              ),
            ),
            if (message.action != null) ...[
              const SizedBox(height: 10),
              _buildActionCard(message.action!, index),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard(ChatAction action, int messageIndex) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.grisClaro,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Se cambió de Row a Column: los valores (sobre todo "contenido",
          // que puede ser un párrafo largo) no caben junto a la etiqueta
          // en una sola línea y se salían de la tarjeta.
          ...action.data.entries.map(
            (e) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    e.key,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${e.value}',
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.azulOscuro,
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
                  onPressed: () => _confirmarAccion(action),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.azulPrincipal,
                    foregroundColor: AppColors.blanco,
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
                  onPressed: () => _descartarAccion(messageIndex),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.grey.shade700,
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
  // Conexión real de las acciones del asistente con el backend.
  // Reemplaza el TODO anterior ("pendiente backend").
  // ─────────────────────────────────────────────────────────────

  // Quita la tarjeta de acción de un mensaje ya mostrado, sin borrar el
  // mensaje ni el texto de la IA. Como ChatAction/ChatMessage.action es
  // 'final', no se puede modificar in-place: se reemplaza el mensaje en
  // la lista por uno idéntico pero con action: null.
  void _descartarAccion(int messageIndex) {
    final anterior = _messages[messageIndex];
    setState(() {
      _messages[messageIndex] = ChatMessage(
        text: anterior.text,
        isUser: anterior.isUser,
        action: null,
      );
    });
  }

  Future<void> _confirmarAccion(ChatAction action) async {
    setState(() => _isLoading = true);

    try {
      if (action.type == 'crear_evento') {
        await _crearEventoDesdeAccion(action);
      } else if (action.type == 'crear_nota') {
        // FIX: el backend manda "crear_nota", no "crear_apunte".
        await _crearApunteDesdeAccion(action);
      } else {
        throw Exception('Tipo de acción desconocido: ${action.type}');
      }

      if (!mounted) return;
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
    // FIX: el backend manda la clave "materia" (no "curso" ni "courseName").
    final curso = (d['materia'] ?? d['curso'] ?? d['courseName'])?.toString();

    final nota = NoteModel(
      id: '',
      title: titulo,
      content: contenido,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      courseName: curso,
      // FIX: el editor (NoteEditorScreen / A4PageCanvas) lee el texto desde
      // pages[0].textContent, no desde 'content'. Sin esto, NoteModel usa
      // su default ([NotePageModel()], vacía) y la nota se guarda con
      // 'content' lleno pero la página en blanco -> el editor la muestra vacía.
      pages: [
        NotePageModel(
          pageIndex: 0,
          textContent: contenido,
        ),
      ],
    );

    await NotesService.saveNote(nota, isNew: true);
  }

  Widget _buildTypingIndicator() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.blanco,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: const SizedBox(
          width: 20,
          height: 12,
          child: Center(
            child: SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.azulPrincipal),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.blanco,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
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
                onSubmitted: (_) => _enviarMensaje(),
                decoration: InputDecoration(
                  hintText: 'Escribe tu pregunta...',
                  filled: true,
                  fillColor: AppColors.grisClaro,
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
              onTap: _isLoading ? null : _enviarMensaje,
              borderRadius: BorderRadius.circular(20),
              child: Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: AppColors.azulPrincipal,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_upward, color: AppColors.blanco, size: 20),
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
