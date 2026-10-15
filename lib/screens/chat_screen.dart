import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../services/connectivity_service.dart';
import '../theme/colors.dart';
import '../models/chat_message_model.dart';
import '../services/ai_chat_service.dart';
import '../services/calendar_service.dart';
import '../services/notes_service.dart';
import '../models/event_model.dart';
import '../models/note_model.dart';
import '../models/note_page_model.dart';
import '../widgets/chat_markdown.dart';
import 'chat_history_screen.dart';

String _dos(int n) => n.toString().padLeft(2, '0');

class _Sugerencia {
  final IconData icon;
  final String text;
  const _Sugerencia(this.icon, this.text);
}

/// Pantalla de chat con la IA (con historial de conversaciones).
/// Vive en lib/screens/chat_screen.dart
class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  static const List<_Sugerencia> _sugerencias = [
    _Sugerencia(Icons.school_outlined, 'Explícame qué es una derivada'),
    _Sugerencia(Icons.event_available_outlined,
        'Recuérdame mañana a las 10:00 estudiar Física'),
    _Sugerencia(Icons.note_add_outlined,
        'Hazme un apunte sobre las leyes de Newton'),
    _Sugerencia(Icons.calendar_month_outlined,
        'Ayúdame a organizar mi semana de estudio'),
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

  bool _hasText = false;
  bool _showScrollDown = false;

  /// Modelo de IA elegido ('auto' = el servidor prueba todos en orden).
  String _selectedModel = AiChatService.autoModel;
  List<ChatModelOption> _models = [];

  @override
  void initState() {
    super.initState();
    _loadModels();
    _controller.addListener(() {
      final has = _controller.text.trim().isNotEmpty;
      if (has != _hasText) setState(() => _hasText = has);
    });
    _scrollController.addListener(_onScroll);
  }

  Future<void> _loadModels() async {
    final selected = await AiChatService.getSelectedModel();
    final models = await AiChatService.fetchModels();
    if (!mounted) return;

    setState(() {
      _models = models;
      // Si el modelo guardado ya no está en la lista, vuelve a Automático.
      final existe = models.any((m) => m.id == selected);
      _selectedModel = existe ? selected : AiChatService.autoModel;
    });
  }

  String get _modelLabel {
    if (_selectedModel == AiChatService.autoModel) return 'Automático';
    for (final m in _models) {
      if (m.id == _selectedModel) return m.label;
    }
    return 'Automático';
  }

  Future<void> _abrirSelectorModelo() async {
    // Se refresca la lista por si el servidor la cambió o no se había podido cargar.
    if (_models.isEmpty) await _loadModels();
    if (!mounted) return;

    final colorScheme = Theme.of(context).colorScheme;

    final elegido = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        Widget opcion(String id, String titulo, String? subtitulo,
            {String? etiqueta}) {
          final seleccionado = id == _selectedModel;
          return InkWell(
            onTap: () => Navigator.pop(ctx, id),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                titulo,
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w600,
                                  color: colorScheme.onSurface,
                                ),
                              ),
                            ),
                            if (etiqueta != null) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: colorScheme.primary.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  etiqueta,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: colorScheme.primary,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        if (subtitulo != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            subtitulo,
                            style: TextStyle(
                              fontSize: 13,
                              color: colorScheme.onSurface.withOpacity(0.6),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (seleccionado)
                    Icon(Icons.check, color: colorScheme.primary),
                ],
              ),
            ),
          );
        }

        final filas = <Widget>[
          opcion(
            AiChatService.autoModel,
            'Automático',
            'Si un modelo se satura o llega a su límite, usa otro.',
            etiqueta: 'Recomendado',
          ),
          for (final m in _models) opcion(m.id, m.label, m.description),
        ];

        // Separadores finos entre filas, como en la lista de modelos de Claude.
        final conLineas = <Widget>[];
        for (var i = 0; i < filas.length; i++) {
          if (i > 0) {
            conLineas.add(Divider(
              height: 1,
              color: colorScheme.onSurface.withOpacity(0.08),
            ));
          }
          conLineas.add(filas[i]);
        }

        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                    Expanded(
                      child: Text(
                        'Seleccionar modelo',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ),
                    const SizedBox(width: 48), // equilibra el botón de cerrar
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: colorScheme.onSurface.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(children: conLineas),
                ),
                if (_models.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(
                      'No se pudo cargar la lista de modelos. Revisa tu conexión.',
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );

    if (elegido == null || !mounted) return;

    await AiChatService.setSelectedModel(elegido);
    if (!mounted) return;
    setState(() => _selectedModel = elegido);
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final pos = _scrollController.position;
    final show = pos.maxScrollExtent - pos.pixels > 250;
    if (show != _showScrollDown) setState(() => _showScrollDown = show);
  }

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

  Future<void> _copiar(String texto) async {
    await Clipboard.setData(ClipboardData(text: texto));
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('Mensaje copiado'),
          duration: Duration(seconds: 1),
        ),
      );
  }

  // ───────────────────────── Historial ─────────────────────────

  void _nuevoChat() {
    setState(() {
      _messages.clear();
      _conversationId = null;
      _lastFailedText = null;
      _showScrollDown = false;
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

  // ───────────────────────── Utilidades de UI ─────────────────────────

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

  String _hora(DateTime d) => '${_dos(d.hour)}:${_dos(d.minute)}';

  bool _mismoDia(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  String _etiquetaDia(DateTime d) {
    final hoy = DateTime.now();
    if (_mismoDia(d, hoy)) return 'Hoy';
    if (_mismoDia(d, hoy.subtract(const Duration(days: 1)))) return 'Ayer';
    return '${_dos(d.day)}/${_dos(d.month)}/${d.year}';
  }

  // ───────────────────────── Build ─────────────────────────

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 2,
        title: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: colorScheme.onPrimary.withOpacity(0.18),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.auto_awesome,
                  size: 18, color: colorScheme.onPrimary),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Asistente UPEA',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                InkWell(
                  onTap: _isLoading ? null : _abrirSelectorModelo,
                  borderRadius: BorderRadius.circular(8),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          'Modelo: $_modelLabel',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w400,
                            color: colorScheme.onPrimary.withOpacity(0.85),
                          ),
                        ),
                      ),
                      Icon(
                        Icons.arrow_drop_down,
                        size: 18,
                        color: colorScheme.onPrimary.withOpacity(0.85),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            ),
          ],
        ),
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

    return Stack(
      children: [
        ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
          itemCount: _messages.length + (_isLoading ? 1 : 0),
          itemBuilder: (context, index) {
            if (index == _messages.length) {
              return _buildTypingIndicator(colorScheme);
            }

            final message = _messages[index];
            final mostrarDia = index == 0 ||
                !_mismoDia(_messages[index - 1].createdAt, message.createdAt);

            return Column(
              children: [
                if (mostrarDia)
                  _buildDaySeparator(_etiquetaDia(message.createdAt), colorScheme),
                _buildMessageBubble(
                  message,
                  index,
                  colorScheme,
                  isLast: index == _messages.length - 1,
                ),
              ],
            );
          },
        ),
        if (_showScrollDown)
          Positioned(
            right: 14,
            bottom: 10,
            child: FloatingActionButton.small(
              heroTag: null,
              elevation: 3,
              backgroundColor: Theme.of(context).cardColor,
              foregroundColor: colorScheme.primary,
              onPressed: () => _scrollToBottom(),
              child: const Icon(Icons.keyboard_arrow_down),
            ),
          ),
      ],
    );
  }

  Widget _buildDaySeparator(String label, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: colorScheme.onSurface.withOpacity(0.07),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(ColorScheme colorScheme, {double size = 30}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.primary,
            colorScheme.primary.withOpacity(0.7),
          ],
        ),
      ),
      child: Icon(Icons.auto_awesome,
          size: size * 0.55, color: colorScheme.onPrimary),
    );
  }

  Widget _buildEmptyState(ColorScheme colorScheme) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildAvatar(colorScheme, size: 68),
              const SizedBox(height: 16),
              Text(
                'Hola, soy tu asistente UPEA',
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Resuelvo dudas de tus materias y puedo crear apuntes o eventos en tu calendario.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.4,
                  color: colorScheme.onSurface.withOpacity(0.65),
                ),
              ),
              const SizedBox(height: 22),
              ..._sugerencias.map(
                (s) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Material(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(14),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () => _enviar(s.text),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: colorScheme.onSurface.withOpacity(0.1),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                color: colorScheme.primary.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(s.icon,
                                  size: 18, color: colorScheme.primary),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                s.text,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: colorScheme.onSurface,
                                ),
                              ),
                            ),
                            Icon(
                              Icons.arrow_forward_ios,
                              size: 13,
                              color: colorScheme.onSurface.withOpacity(0.35),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
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
    final maxWidth = MediaQuery.of(context).size.width * (isUser ? 0.78 : 0.74);

    final bubble = GestureDetector(
      onLongPress: () => _copiar(message.text),
      child: Container(
        constraints: BoxConstraints(maxWidth: maxWidth),
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
        decoration: BoxDecoration(
          color: isUser ? colorScheme.primary : Theme.of(context).cardColor,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isUser ? 18 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 18),
          ),
          border: isUser
              ? null
              : Border.all(
                  color: message.isError
                      ? Colors.red.withOpacity(0.5)
                      : colorScheme.onSurface.withOpacity(0.08),
                ),
          boxShadow: isUser
              ? null
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
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
            if (isUser || message.isError)
              Text(
                message.text,
                style: TextStyle(fontSize: 14, height: 1.4, color: textColor),
              )
            else
              ChatMarkdown(
                text: message.text,
                style: TextStyle(fontSize: 14, height: 1.4, color: textColor),
                codeBackground: colorScheme.onSurface.withOpacity(0.08),
              ),
            if (message.isError &&
                isLast &&
                _lastFailedText != null &&
                !_isLoading) ...[
              const SizedBox(height: 6),
              Wrap(
                spacing: 4,
                children: [
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
                  if (message.errorCode == 'AI_QUOTA' ||
                      message.errorCode == 'AI_BUSY' ||
                      message.errorCode == 'INVALID_MODEL')
                    TextButton.icon(
                      onPressed: _abrirSelectorModelo,
                      icon: const Icon(Icons.swap_horiz, size: 18),
                      label: const Text('Cambiar modelo'),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        minimumSize: const Size(0, 32),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                ],
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
                  color: textColor.withOpacity(0.55),
                ),
              ),
            ),
          ],
        ),
      ),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            _buildAvatar(colorScheme),
            const SizedBox(width: 8),
          ],
          Flexible(child: bubble),
        ],
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

  String _etiquetaCampo(String key) {
    switch (key) {
      case 'titulo':
        return 'Título';
      case 'fecha':
        return 'Fecha y hora';
      case 'tipo':
        return 'Tipo';
      case 'materia':
        return 'Materia';
      case 'contenido':
        return 'Contenido';
      default:
        return key;
    }
  }

  String _valorLegible(String key, dynamic value) {
    final raw = '$value';

    if (key == 'fecha') {
      final d = DateTime.tryParse(raw);
      if (d != null) {
        return '${_dos(d.day)}/${_dos(d.month)}/${d.year}  ${_hora(d)}';
      }
    }

    if (key == 'tipo') {
      switch (raw) {
        case 'EXAM':
          return 'Examen';
        case 'ASSIGNMENT':
          return 'Tarea';
        case 'CLASS':
          return 'Clase';
        case 'REMINDER':
          return 'Recordatorio';
        case 'OTHER':
          return 'Otro';
      }
    }

    return raw;
  }

  Widget _buildActionCard(ChatAction action, int messageIndex, ColorScheme colorScheme) {
    final esEvento = action.type == 'crear_evento';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.onSurface.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.primary.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: colorScheme.primary.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  esEvento ? Icons.event : Icons.sticky_note_2_outlined,
                  size: 16,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                esEvento ? 'Evento sugerido' : 'Apunte sugerido',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Column en vez de Row: los valores (sobre todo "contenido",
          // que puede ser un párrafo largo) no caben junto a la etiqueta.
          ...action.data.entries.map(
            (e) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _etiquetaCampo(e.key),
                    style: TextStyle(
                      fontSize: 11,
                      color: colorScheme.onSurface.withOpacity(0.55),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _valorLegible(e.key, e.value),
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
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
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    esEvento ? 'Crear evento' : 'Crear apunte',
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
                      borderRadius: BorderRadius.circular(10),
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _buildAvatar(colorScheme),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
                bottomRight: Radius.circular(18),
                bottomLeft: Radius.circular(4),
              ),
              border: Border.all(color: colorScheme.onSurface.withOpacity(0.08)),
            ),
            child: _TypingDots(color: colorScheme.primary),
          ),
        ],
      ),
    );
  }

  Widget _buildInputBar(ColorScheme colorScheme) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fillColor = isDark ? Colors.white.withOpacity(0.07) : AppColors.grisClaro;
    final online = context.watch<ConnectivityService>().isOnline;
    final puedeEnviar = _hasText && !_isLoading && online;

    return Container(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(top: BorderSide(color: colorScheme.onSurface.withOpacity(0.1))),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: fillColor,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: TextField(
                  controller: _controller,
                  minLines: 1,
                  maxLines: 5,
                  maxLength: 2000,
                  textCapitalization: TextCapitalization.sentences,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _enviarDesdeInput(),
                  style: TextStyle(color: colorScheme.onSurface),
                  decoration: InputDecoration(
                    hintText: online
                        ? 'Escribe tu pregunta...'
                        : 'Sin conexión: el asistente necesita internet',
                    hintStyle:
                        TextStyle(color: colorScheme.onSurface.withOpacity(0.5)),
                    counterText: '',
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 11,
                    ),
                    border: InputBorder.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: puedeEnviar
                    ? colorScheme.primary
                    : colorScheme.primary.withOpacity(0.35),
                shape: BoxShape.circle,
              ),
              child: Material(
                color: Colors.transparent,
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: puedeEnviar ? _enviarDesdeInput : null,
                  child: Icon(Icons.arrow_upward,
                      color: colorScheme.onPrimary, size: 22),
                ),
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

/// Tres puntitos que "saltan" mientras la IA escribe.
class _TypingDots extends StatefulWidget {
  final Color color;
  const _TypingDots({required this.color});

  @override
  State<_TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<_TypingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat();

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (context, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            final t = (_anim.value - i * 0.18) % 1.0;
            final s = math.sin(t * math.pi);
            return Container(
              width: 7,
              height: 7,
              margin: const EdgeInsets.symmetric(horizontal: 2),
              transform: Matrix4.translationValues(0, -3 * s, 0),
              decoration: BoxDecoration(
                color: widget.color.withOpacity(0.35 + 0.65 * s),
                shape: BoxShape.circle,
              ),
            );
          }),
        );
      },
    );
  }
}
