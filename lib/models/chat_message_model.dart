/// Representa un mensaje dentro del chat con la IA.
/// Vive en lib/models/chat_message_model.dart
class ChatMessage {
  final String text;
  final bool isUser; // true = lo escribió el usuario, false = la IA
  final ChatAction? action; // acción sugerida por la IA (crear nota/evento), si aplica
 
  ChatMessage({
    required this.text,
    required this.isUser,
    this.action,
  });
}
 
/// Acción estructurada que la IA puede proponer (el "JSON" que pidió Anddy).
/// type: 'crear_evento' | 'crear_nota'
class ChatAction {
  final String type;
  final Map<String, dynamic> data;
 
  ChatAction({required this.type, required this.data});
 
  factory ChatAction.fromJson(Map<String, dynamic> json) {
    return ChatAction(
      type: json['accion'] as String,
      data: Map<String, dynamic>.from(json)..remove('accion'),
    );
  }
}
 