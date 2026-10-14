import 'package:flutter/material.dart';
import '../models/chat_message_model.dart';
import '../services/ai_chat_service.dart';

/// Lista de conversaciones anteriores con la IA.
/// Vive en lib/screens/chat_history_screen.dart
///
/// Al tocar una conversación, hace pop con su id.
/// Al tocar "Nuevo chat", hace pop con [ChatHistoryScreen.newChat].
class ChatHistoryScreen extends StatefulWidget {
  static const String newChat = '__new_chat__';

  /// Id de la conversación abierta ahora (se resalta en la lista).
  final String? currentId;

  /// Se llama cuando el usuario borra una conversación.
  final void Function(String id)? onDeleted;

  const ChatHistoryScreen({super.key, this.currentId, this.onDeleted});

  @override
  State<ChatHistoryScreen> createState() => _ChatHistoryScreenState();
}

class _ChatHistoryScreenState extends State<ChatHistoryScreen> {
  List<ChatConversation> _items = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final items = await AiChatService.listConversations();
      if (!mounted) return;
      setState(() {
        _items = items;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  String _fecha(DateTime d) {
    final now = DateTime.now();
    String dos(int n) => n.toString().padLeft(2, '0');
    final mismoDia =
        d.year == now.year && d.month == now.month && d.day == now.day;
    return mismoDia ? '${dos(d.hour)}:${dos(d.minute)}' : '${dos(d.day)}/${dos(d.month)}';
  }

  Future<bool> _confirmarBorrado(ChatConversation c) async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Borrar conversación'),
        content: Text('Se borrará "${c.title}" y todos sus mensajes.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Borrar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmado != true) return false;

    try {
      await AiChatService.deleteConversation(c.id);
      return true;
    } catch (e) {
      if (!mounted) return false;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Colors.red,
        ),
      );
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          'Conversaciones',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 2,
        actions: [
          IconButton(
            tooltip: 'Nuevo chat',
            icon: const Icon(Icons.add_comment_outlined),
            onPressed: () => Navigator.pop(context, ChatHistoryScreen.newChat),
          ),
        ],
      ),
      body: _buildBody(colorScheme),
    );
  }

  Widget _buildBody(ColorScheme colorScheme) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.cloud_off_outlined,
                  size: 42, color: colorScheme.onSurface.withOpacity(0.5)),
              const SizedBox(height: 12),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: TextStyle(color: colorScheme.onSurface),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _cargar,
                icon: const Icon(Icons.refresh),
                label: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    if (_items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.chat_bubble_outline,
                  size: 42, color: colorScheme.onSurface.withOpacity(0.4)),
              const SizedBox(height: 12),
              Text(
                'Aún no tienes conversaciones.\nEscribe tu primera pregunta al asistente.',
                textAlign: TextAlign.center,
                style: TextStyle(color: colorScheme.onSurface.withOpacity(0.7)),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _cargar,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: _items.length,
        separatorBuilder: (_, __) => Divider(
          height: 1,
          color: colorScheme.onSurface.withOpacity(0.08),
        ),
        itemBuilder: (context, index) {
          final c = _items[index];
          final seleccionada = c.id == widget.currentId;

          return Dismissible(
            key: ValueKey(c.id),
            direction: DismissDirection.endToStart,
            background: Container(
              color: Colors.red,
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: const Icon(Icons.delete_outline, color: Colors.white),
            ),
            confirmDismiss: (_) => _confirmarBorrado(c),
            onDismissed: (_) {
              setState(() => _items.removeWhere((x) => x.id == c.id));
              widget.onDeleted?.call(c.id);
            },
            child: ListTile(
              selected: seleccionada,
              selectedTileColor: colorScheme.primary.withOpacity(0.08),
              leading: Icon(
                Icons.chat_bubble_outline,
                color: seleccionada
                    ? colorScheme.primary
                    : colorScheme.onSurface.withOpacity(0.6),
              ),
              title: Text(
                c.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                c.lastMessage,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: Text(
                _fecha(c.updatedAt),
                style: TextStyle(
                  fontSize: 12,
                  color: colorScheme.onSurface.withOpacity(0.55),
                ),
              ),
              onTap: () => Navigator.pop(context, c.id),
            ),
          );
        },
      ),
    );
  }
}
