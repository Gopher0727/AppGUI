class TokenUsage {
  final String id;
  final String uid;
  final String sessionId;
  final String messageId;
  final String model;
  final int promptTokens;
  final int completionTokens;
  final int totalTokens;
  final DateTime createdAt;

  const TokenUsage({
    required this.id,
    required this.uid,
    required this.sessionId,
    required this.messageId,
    required this.model,
    required this.promptTokens,
    required this.completionTokens,
    required this.totalTokens,
    required this.createdAt,
  });

  factory TokenUsage.fromJson(Map<String, dynamic> json) => TokenUsage(
    id: json['id'] as String,
    uid: json['uid'] as String,
    sessionId: json['session_id'] as String,
    messageId: json['message_id'] as String,
    model: json['model'] as String,
    promptTokens: json['prompt_tokens'] as int,
    completionTokens: json['completion_tokens'] as int,
    totalTokens: json['total_tokens'] as int,
    createdAt: DateTime.parse(json['created_at'] as String),
  );
}
