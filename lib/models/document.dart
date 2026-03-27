import 'package:app_gui/models/chunk.dart';

enum DocumentStatus { pending, processing, done, failed }

DocumentStatus _parseDocStatus(String s) => switch (s) {
  'processing' => DocumentStatus.processing,
  'done' => DocumentStatus.done,
  'failed' => DocumentStatus.failed,
  _ => DocumentStatus.pending,
};

class Document {
  final String id;
  final String uid;
  final String? sessionId;
  final String filename;
  final String originalName;
  final String mimeType;
  final int size;
  final DocumentStatus status;
  final String parsedSummary;
  final String errorMsg;
  final List<Chunk> chunks;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Document({
    required this.id,
    required this.uid,
    this.sessionId,
    required this.filename,
    required this.originalName,
    required this.mimeType,
    required this.size,
    required this.status,
    required this.parsedSummary,
    required this.errorMsg,
    this.chunks = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  factory Document.fromJson(Map<String, dynamic> json) => Document(
    id: json['id'] as String,
    uid: json['uid'] as String,
    sessionId: json['session_id'] as String?,
    filename: json['filename'] as String,
    originalName: json['original_name'] as String,
    mimeType: json['mime_type'] as String? ?? '',
    size: json['size'] as int,
    status: _parseDocStatus(json['status'] as String),
    parsedSummary: json['parsed_summary'] as String? ?? '',
    errorMsg: json['error_msg'] as String? ?? '',
    chunks:
        (json['chunks'] as List<dynamic>?)
            ?.map((e) => Chunk.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [],
    createdAt: DateTime.parse(json['created_at'] as String),
    updatedAt: DateTime.parse(json['updated_at'] as String),
  );
}
