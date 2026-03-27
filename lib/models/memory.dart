class Memory {
  final String id;
  final String uid;
  final String type; // 'user_memory' | 'ai_memory'
  final String category;
  final String content;
  final int importance;
  final String source; // 'manual' | 'auto_extracted'
  final String? sourceSessionId;
  final String? sourceDocumentId;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Memory({
    required this.id,
    required this.uid,
    required this.type,
    required this.category,
    required this.content,
    required this.importance,
    required this.source,
    this.sourceSessionId,
    this.sourceDocumentId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Memory.fromJson(Map<String, dynamic> json) => Memory(
    id: json['id'] as String,
    uid: json['uid'] as String,
    type: json['type'] as String,
    category: json['category'] as String? ?? '',
    content: json['content'] as String,
    importance: json['importance'] as int,
    source: json['source'] as String,
    sourceSessionId: json['source_session_id'] as String?,
    sourceDocumentId: json['source_document_id'] as String?,
    createdAt: DateTime.parse(json['created_at'] as String),
    updatedAt: DateTime.parse(json['updated_at'] as String),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'uid': uid,
    'type': type,
    'category': category,
    'content': content,
    'importance': importance,
    'source': source,
    if (sourceSessionId != null) 'source_session_id': sourceSessionId,
    if (sourceDocumentId != null) 'source_document_id': sourceDocumentId,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };
}
