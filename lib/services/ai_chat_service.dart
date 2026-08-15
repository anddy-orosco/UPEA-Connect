import '../models/chat_message_model.dart';

/// Servicio del chat con IA.
/// Vive en lib/services/ai_chat_service.dart
///
/// MODO ACTUAL: mock (respuestas simuladas), para probar la pantalla
/// sin depender del backend todavía.
///
/// Cuando el endpoint /api/ai/chat esté listo, solo hay que reemplazar
/// el contenido de sendMessage() por una llamada http.post, igual que
/// en api_service.dart. La firma de la función (lo que recibe y devuelve)
/// se queda igual, así que no hay que tocar chat_screen.dart.
class AiChatService {
  static Future<ChatMessage> sendMessage(String userText) async {
    // Simula latencia de red
    await Future.delayed(const Duration(milliseconds: 700));

    final lower = userText.toLowerCase();

    // Simulación simple de detección de intención "crear evento"
    if (lower.contains('crea un evento') || lower.contains('crear evento')) {
      return ChatMessage(
        text: 'Encontré estos datos para tu evento:',
        isUser: false,
        action: ChatAction(
          type: 'crear_evento',
          data: {
            'titulo': 'Examen de física',
            'fecha': '2026-08-20T10:00:00',
            'tipo': 'EXAM',
          },
        ),
      );
    }

    if (lower.contains('crea una nota') || lower.contains('crear nota')) {
      return ChatMessage(
        text: 'Encontré estos datos para tu apunte:',
        isUser: false,
        action: ChatAction(
          type: 'crear_nota',
          data: {
            'titulo': 'Nuevo apunte',
            'materia': 'General',
          },
        ),
      );
    }

    // Respuesta conversacional genérica (mock)
    return ChatMessage(
      text: 'Esto es una respuesta de prueba. Cuando conectemos el '
          'backend, aquí llegará la respuesta real de la IA.',
      isUser: false,
    );
  }
}