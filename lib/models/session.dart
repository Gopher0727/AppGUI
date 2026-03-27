import 'package:app_gui/models/document.dart';
import 'package:app_gui/models/message.dart';

class Session {
  final String id;
  final String uid;
  final String title;
  final String modelId;
  final String systemPrompt;
  final int messageCount;
  final DateTime? lastMessageAt;
  final List<Message> messages;
  final List<Document> documents;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Session({
    required this.id,
    required this.uid,
    required this.title,
    required this.modelId,
    required this.systemPrompt,
    required this.messageCount,
    this.lastMessageAt,
    this.messages = const [],
    this.documents = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  factory Session.fromJson(Map<String, dynamic> json) => Session(
    id: json['id'] as String,
    uid: json['uid'] as String,
    title: json['title'] as String,
    modelId: json['model_id'] as String,
    systemPrompt: json['system_prompt'] as String? ?? '',
    messageCount: json['message_count'] as int,
    lastMessageAt: json['last_message_at'] == null
        ? null
        : DateTime.parse(json['last_message_at'] as String),
    messages:
        (json['messages'] as List<dynamic>?)
            ?.map((e) => Message.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [],
    documents:
        (json['documents'] as List<dynamic>?)
            ?.map((e) => Document.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [],
    createdAt: DateTime.parse(json['created_at'] as String),
    updatedAt: DateTime.parse(json['updated_at'] as String),
  );

  Session copyWith({
    String? id,
    String? uid,
    String? title,
    String? modelId,
    String? systemPrompt,
    int? messageCount,
    DateTime? lastMessageAt,
    List<Message>? messages,
    List<Document>? documents,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Session(
      id: id ?? this.id,
      uid: uid ?? this.uid,
      title: title ?? this.title,
      modelId: modelId ?? this.modelId,
      systemPrompt: systemPrompt ?? this.systemPrompt,
      messageCount: messageCount ?? this.messageCount,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      messages: messages ?? this.messages,
      documents: documents ?? this.documents,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'uid': uid,
    'title': title,
    'model_id': modelId,
    'system_prompt': systemPrompt,
    'message_count': messageCount,
    'last_message_at': lastMessageAt?.toIso8601String(),
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };
}
