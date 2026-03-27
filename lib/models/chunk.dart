class Chunk {
  final String id;
  final String documentId;
  final int sequence;
  final String content;
  final int tokenCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Chunk({
    required this.id,
    required this.documentId,
    required this.sequence,
    required this.content,
    required this.tokenCount,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Chunk.fromJson(Map<String, dynamic> json) => Chunk(
    id: json['id'] as String,
    documentId: json['document_id'] as String,
    sequence: json['sequence'] as int,
    content: json['content'] as String,
    tokenCount: json['token_count'] as int,
    createdAt: DateTime.parse(json['created_at'] as String),
    updatedAt: DateTime.parse(json['updated_at'] as String),
  );
}
