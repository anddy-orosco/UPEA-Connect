import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/chat_message_model.dart';
import 'api_service.dart';
import 'connectivity_service.dart';

/// Servicio del chat con IA e historial de conversaciones.
/// Vive en lib/services/ai_chat_service.dart
///
/// Endpoints del backend:
///   POST   /ai/chat                                   (envía mensaje; crea conversación si no hay id)
///   GET    /ai/conversations                          (lista)
///   GET    /ai/conversations/:id                      (mensajes)
///   DELETE /ai/conversations/:id
///   PATCH  /ai/conversations/:id/messages/:messageId  (estado de la tarjeta)
class AiChatService {
  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  static Map<String, String> _headers(String token) => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

  static const String _offlineChatMessage =
      'Sin conexión. El asistente necesita internet; vuelve a intentarlo cuando se restablezca.';

  static const String _offlineHistoryMessage =
      'Sin conexión. El historial del chat necesita internet.';

  static ChatSendResult _failure(String text, {String? code}) {
    return ChatSendResult(
      reply: ChatMessage(
        text: text,
        isUser: false,
        isError: true,
        errorCode: code,
      ),
      failed: true,
    );
  }

  // ───────────── Selección de modelo de IA ─────────────

  /// Valor que significa "que el servidor elija / pruebe todos en orden".
  static const String autoModel = 'auto';
  static const String _modelPrefKey = 'ai_model';

  static Future<String> getSelectedModel() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_modelPrefKey) ?? autoModel;
  }

  static Future<void> setSelectedModel(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_modelPrefKey, id);
  }

  /// Modelos que ofrece el servidor. Si no se puede consultar (sin internet),
  /// devuelve una lista vacía y la app solo ofrece "Automático".
  static Future<List<ChatModelOption>> fetchModels() async {
    try {
      final token = await _getToken();
      if (token == null) return [];

      final response = await http
          .get(
            Uri.parse('${ApiService.baseUrl}/ai/models'),
            headers: _headers(token),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) return [];

      final data = jsonDecode(response.body);
      final List<dynamic> list = data['models'] ?? [];
      return list
          .map((m) => ChatModelOption.fromJson(m as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Envía un mensaje. Si [conversationId] es null, el backend crea una
  /// conversación nueva y devuelve su id y título.
  static Future<ChatSendResult> sendMessage(
    String userText, {
    String? conversationId,
  }) async {
    final token = await _getToken();

    if (token == null) {
      return _failure(
          'Tu sesión expiró. Vuelve a iniciar sesión para usar el chat.');
    }

    if (!ConnectivityService.instance.isOnline) {
      return _failure(_offlineChatMessage);
    }

    final selectedModel = await getSelectedModel();

    try {
      final response = await http
          .post(
            Uri.parse('${ApiService.baseUrl}/ai/chat'),
            headers: _headers(token),
            body: jsonEncode({
              'message': userText,
              if (conversationId != null) 'conversationId': conversationId,
              if (selectedModel != autoModel) 'model': selectedModel,
            }),
          )
          .timeout(const Duration(seconds: 45));

      final data = jsonDecode(response.body);

      if (response.statusCode != 200) {
        final code = data['error']?.toString();

        // El modelo guardado ya no existe en el servidor: se vuelve a Automático.
        if (code == 'INVALID_MODEL') {
          await setSelectedModel(autoModel);
        }

        return _failure(
          data['message']?.toString() ??
              'El asistente no pudo responder. Intenta de nuevo.',
          code: code,
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

      return ChatSendResult(
        reply: ChatMessage(
          id: data['assistantMessageId'] as String?,
          text: reply,
          isUser: false,
          action: action,
          actionStatus: action != null ? 'PENDING' : null,
        ),
        conversationId: data['conversationId'] as String?,
        title: data['title'] as String?,
      );
    } catch (e) {
      if (ConnectivityService.isNetworkError(e) && e is! TimeoutException) {
        ConnectivityService.instance.reportFailure();
        return _failure(_offlineChatMessage);
      }
      return _failure(
        'No pude conectarme con la IA. Revisa tu conexión e intenta de nuevo.',
      );
    }
  }

  /// Lista las conversaciones del usuario (la más reciente primero).
  static Future<List<ChatConversation>> listConversations() async {
    final token = await _getToken();
    if (token == null) throw Exception('No hay sesión activa');

    try {
      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/ai/conversations'),
        headers: _headers(token),
      );
      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final List<dynamic> list = data['conversations'] ?? [];
        return list
            .map((c) => ChatConversation.fromJson(c as Map<String, dynamic>))
            .toList();
      }
      throw Exception(data['message'] ?? 'No se pudo cargar el historial');
    } catch (e) {
      if (ConnectivityService.isNetworkError(e)) {
        ConnectivityService.instance.reportFailure();
        throw Exception(_offlineHistoryMessage);
      }
      rethrow;
    }
  }

  /// Trae todos los mensajes de una conversación, en orden.
  static Future<List<ChatMessage>> getMessages(String conversationId) async {
    final token = await _getToken();
    if (token == null) throw Exception('No hay sesión activa');

    try {
      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/ai/conversations/$conversationId'),
        headers: _headers(token),
      );
      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final List<dynamic> list = data['messages'] ?? [];
        return list
            .map((m) => ChatMessage.fromBackend(m as Map<String, dynamic>))
            .toList();
      }
      throw Exception(data['message'] ?? 'No se pudo abrir la conversación');
    } catch (e) {
      if (ConnectivityService.isNetworkError(e)) {
        ConnectivityService.instance.reportFailure();
        throw Exception(_offlineHistoryMessage);
      }
      rethrow;
    }
  }

  static Future<void> deleteConversation(String conversationId) async {
    final token = await _getToken();
    if (token == null) throw Exception('No hay sesión activa');

    late final http.Response response;
    try {
      response = await http.delete(
        Uri.parse('${ApiService.baseUrl}/ai/conversations/$conversationId'),
        headers: _headers(token),
      );
    } catch (e) {
      if (ConnectivityService.isNetworkError(e)) {
        ConnectivityService.instance.reportFailure();
        throw Exception(_offlineHistoryMessage);
      }
      rethrow;
    }

    if (response.statusCode == 204 || response.statusCode == 200) return;

    String message = 'No se pudo borrar la conversación';
    try {
      message = jsonDecode(response.body)['message'] ?? message;
    } catch (_) {}
    throw Exception(message);
  }

  /// Marca la tarjeta de acción como 'DONE' o 'DISCARDED' en el backend.
  /// Es un guardado "de cortesía": si falla, no se interrumpe al usuario.
  static Future<void> markActionStatus({
    required String conversationId,
    required String messageId,
    required String status,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) return;

      await http.patch(
        Uri.parse(
            '${ApiService.baseUrl}/ai/conversations/$conversationId/messages/$messageId'),
        headers: _headers(token),
        body: jsonEncode({'actionStatus': status}),
      );
    } catch (_) {
      // Silencioso a propósito.
    }
  }
}
