import 'dart:convert';

import 'package:dio/dio.dart';

import 'package:app_gui/config.dart';
import 'package:app_gui/models/message.dart';

class ChatService {
  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: AppConfig.baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: Duration.zero,
    ),
  );

  // 流式输出
  Future<void> sendMessageStream(
    String message,
    String uid,
    String sessionId, {
    required void Function(String content) onToken,
    required void Function(Message message) onDone,
    required void Function(Object error) onError,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.post<ResponseBody>(
        "/chat/stream",
        data: {'uid': uid, 'session_id': sessionId, 'message': message},
        options: Options(responseType: ResponseType.stream),
        cancelToken: cancelToken,
      );

      // cast 让类型从 Stream<Uint8List> 变为 Stream<List<int>>，匹配 utf8.decoder
      final byteStream = response.data!.stream;
      final textStream = byteStream.cast<List<int>>().transform(utf8.decoder);

      final contentBuffer = StringBuffer();
      final lineBuffer = StringBuffer();

      await for (final chunk in textStream) {
        if (cancelToken?.isCancelled ?? false) break;

        // SSE 事件以 \n\n 分隔
        lineBuffer.write(chunk);
        final buffered = lineBuffer.toString();
        final events = buffered.split('\n\n');
        // 最后一段可能是不完整事件，保留在 buffer 中
        lineBuffer
          ..clear()
          ..write(events.removeLast());

        for (final event in events) {
          final data = _extractEventData(event);
          if (data == null) continue;

          final json = jsonDecode(data) as Map<String, dynamic>;
          final type = json['type'] as String;

          switch (type) {
            case 'token':
              contentBuffer.write(json['content'] as String);
              onToken(contentBuffer.toString());
              break;
            case 'done':
              final msg = Message.fromJson(
                json['data'] as Map<String, dynamic>,
              );
              onDone(msg);
              return;
          }
        }
      }

      // 流结束但没收到 done 事件，把已有内容输出
      if (contentBuffer.isNotEmpty) {
        onToken(contentBuffer.toString());
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.cancel) {
        onError(ChatAbortException());
      } else {
        onError(ChatException(e.message ?? "Network Error"));
      }
    } catch (e) {
      onError(e);
    }
  }

  // 从一个 SSE 事件文本块中提取完整的 data 字段。
  // 按 SSE 规范，多行 `data:` 用 `\n` 拼接。
  static String? _extractEventData(String event) {
    final lines = event.split('\n');
    final dataLines = <String>[];
    for (final line in lines) {
      if (line.startsWith('data: ')) {
        dataLines.add(line.substring('data: '.length));
      } else if (line.startsWith('data:')) {
        // "data:" 后无空格，值为去掉 "data:" 后的部分（可能为空串）
        dataLines.add(line.substring('data:'.length));
      }
      // 忽略 ":", "event:", "id:", "retry:" 等其他字段
    }
    if (dataLines.isEmpty) return null;
    return dataLines.join('\n');
  }
}

// 普通网络异常
class ChatException implements Exception {
  final String message;
  ChatException(this.message);

  @override
  String toString() => message;
}

// 用户主动打断
class ChatAbortException implements Exception {
  @override
  String toString() => '已打断';
}
