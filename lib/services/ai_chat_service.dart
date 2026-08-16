import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/chat_message_model.dart';
import 'api_service.dart';

/// Servicio del chat con IA.
/// Vive en lib/services/ai_chat_service.dart
///
/// Ya conectado al backend real (/api/ai/chat -> Gemini).
/// Reemplaza la versión mock anterior; la firma de sendMessage() se
/// mantiene igual, así que chat_screen.dart no necesita cambios.
class AiChatService {
  static Future<ChatMessage> sendMessage(String userText) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    if (token == null) {
      return ChatMessage(
        text: 'Tu sesión expiró. Vuelve a iniciar sesión para usar el chat.',
        isUser: false,
      );
    }

    try {
      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/ai/chat'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'message': userText}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode != 200) {
        return ChatMessage(
          text: data['message'] ?? 'El asistente no pudo responder. Intenta de nuevo.',
          isUser: false,
        );
      }

      final String reply = data['reply'] ?? '';
      ChatAction? action;

      if (data['action'] != null) {
        final actionJson = data['action'] as Map<String, dynamic>;
        action = ChatAction(
          type: actionJson['type'] as String,
          data: Map<String, dynamic>.from(actionJson['data'] as Map),
        );
      }

      return ChatMessage(text: reply, isUser: false, action: action);
    } catch (e) {
      return ChatMessage(
        text: 'No pude conectarme con la IA. Revisa tu conexión e intenta de nuevo.',
        isUser: false,
      );
    }
  }
}
