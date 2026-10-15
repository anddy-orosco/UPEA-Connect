/// Modelos del chat con la IA.
/// Vive en lib/models/chat_message_model.dart

/// Un mensaje dentro del chat con la IA.
class ChatMessage {
  /// Id en el backend (null si el mensaje aún no se guardó o es local).
  final String? id;
  final String text;
  final bool isUser; // true = lo escribió el usuario, false = la IA
  final ChatAction? action; // acción sugerida por la IA (crear nota/evento), si aplica

  /// Estado de la tarjeta de acción: null | 'PENDING' | 'DONE' | 'DISCARDED'.
  final String? actionStatus;
  final DateTime createdAt;

  /// true si es un mensaje de error local (sin conexión, Gemini caído, etc.).
  final bool isError;

  /// Código del error del backend (ej. 'AI_QUOTA', 'AI_BUSY'), si lo hay.
  final String? errorCode;

  ChatMessage({
    this.id,
    required this.text,
    required this.isUser,
    this.action,
    this.actionStatus,
    DateTime? createdAt,
    this.isError = false,
    this.errorCode,
  }) : createdAt = createdAt ?? DateTime.now();

  ChatMessage copyWith({
    String? id,
    String? actionStatus,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      text: text,
      isUser: isUser,
      action: action,
      actionStatus: actionStatus ?? this.actionStatus,
      createdAt: createdAt,
      isError: isError,
      errorCode: errorCode,
    );
  }

  /// Construye un mensaje a partir del JSON del backend
  /// (GET /api/ai/conversations/:id).
  factory ChatMessage.fromBackend(Map<String, dynamic> json) {
    ChatAction? action;
    final rawAction = json['action'];
    if (rawAction is Map && rawAction['type'] != null) {
      action = ChatAction(
        type: rawAction['type'] as String,
        data: Map<String, dynamic>.from(rawAction['data'] as Map? ?? {}),
      );
    }

    return ChatMessage(
      id: json['id'] as String?,
      text: json['text'] as String? ?? '',
      isUser: json['role'] == 'USER',
      action: action,
      actionStatus: json['actionStatus'] as String?,
      createdAt:
          DateTime.tryParse(json['createdAt'] as String? ?? '')?.toLocal() ??
              DateTime.now(),
    );
  }
}

/// Acción estructurada que la IA puede proponer.
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

/// Resumen de una conversación (para la lista del historial).
class ChatConversation {
  final String id;
  final String title;
  final String lastMessage;
  final DateTime updatedAt;

  ChatConversation({
    required this.id,
    required this.title,
    required this.lastMessage,
    required this.updatedAt,
  });

  factory ChatConversation.fromJson(Map<String, dynamic> json) {
    return ChatConversation(
      id: json['id'] as String,
      title: json['title'] as String? ?? 'Nueva conversación',
      lastMessage: json['lastMessage'] as String? ?? '',
      updatedAt:
          DateTime.tryParse(json['updatedAt'] as String? ?? '')?.toLocal() ??
              DateTime.now(),
    );
  }
}

/// Modelo de IA que el usuario puede elegir (id para el backend, nombre y
/// descripción corta para mostrar en el selector).
class ChatModelOption {
  final String id;
  final String label;
  final String? description;

  const ChatModelOption({
    required this.id,
    required this.label,
    this.description,
  });

  factory ChatModelOption.fromJson(Map<String, dynamic> json) {
    final desc = json['description'] as String?;
    return ChatModelOption(
      id: json['id'] as String,
      label: json['label'] as String? ?? json['id'] as String,
      description: (desc == null || desc.trim().isEmpty) ? null : desc.trim(),
    );
  }
}

/// Resultado de enviar un mensaje a la IA.
class ChatSendResult {
  final ChatMessage reply;
  final String? conversationId;
  final String? title;
  final bool failed;

  ChatSendResult({
    required this.reply,
    this.conversationId,
    this.title,
    this.failed = false,
  });
}