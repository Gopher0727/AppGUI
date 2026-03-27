enum MessageRole { user, ai }

class Message {
  final String id;
  final String sessionId;
  final MessageRole role;
  final String content;
  final int promptTokens;
  final int completionTokens;
  final int totalTokens;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Message({
    required this.id,
    required this.sessionId,
    required this.role,
    required this.content,
    required this.promptTokens,
    required this.completionTokens,
    required this.totalTokens,
    required this.createdAt,
    required this.updatedAt,
  });

  Message copyWith({
    String? id,
    String? sessionId,
    MessageRole? role,
    String? content,
    int? promptTokens,
    int? completionTokens,
    int? totalTokens,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Message(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      role: role ?? this.role,
      content: content ?? this.content,
      promptTokens: promptTokens ?? this.promptTokens,
      completionTokens: completionTokens ?? this.completionTokens,
      totalTokens: totalTokens ?? this.totalTokens,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory Message.fromJson(Map<String, dynamic> json) => Message(
    id: json['id'] as String,
    sessionId: json['session_id'] as String,
    role: json['role'] == 'user' ? MessageRole.user : MessageRole.ai,
    content: json['content'] as String,
    promptTokens: json['prompt_tokens'] as int,
    completionTokens: json['completion_tokens'] as int,
    totalTokens: json['total_tokens'] as int,
    createdAt: DateTime.parse(json['created_at'] as String),
    updatedAt: DateTime.parse(json['updated_at'] as String),
  );
}
