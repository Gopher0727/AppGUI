import 'package:dio/dio.dart';

import 'package:app_gui/config.dart';
import 'package:app_gui/models/memory.dart';

class MemoryService {
  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: AppConfig.baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
    ),
  );

  // 前端添加记忆，发送到后端入库
  // POST /memory
  Future<Memory> addMemory({
    required String uid,
    required String content,
    String type = 'user_memory',
    String category = '',
    String source = 'manual',
    int importance = 5,
    String? sessionId,
  }) async {
    final response = await _dio.post(
      '/memory',
      data: {
        'uid': uid,
        'content': content,
        'type': type,
        'category': category,
        'source': source,
        'importance': importance,
        'session_id': ?sessionId,
      },
    );
    return Memory.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  // 编辑记忆
  // PUT /memory/:id
  Future<Memory> updateMemory({
    required String id,
    String? content,
    String? category,
    int? importance,
    String? type,
  }) async {
    final response = await _dio.patch(
      '/memory/$id',
      data: {
        'content': ?content,
        'category': ?category,
        'importance': ?importance,
        'type': ?type,
      },
    );
    return Memory.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  // 删除记忆
  // DELETE /memory/:id
  Future<void> deleteMemory(String id) async {
    await _dio.delete('/memory/$id');
  }

  // 获取指定用户的所有记忆
  // GET /memory?uid=xxx
  Future<List<Memory>> fetchMemory(String uid) async {
    final response = await _dio.get('/memory', queryParameters: {'uid': uid});
    final data = response.data['data'] as List<dynamic>;
    return data.map((e) => Memory.fromJson(e as Map<String, dynamic>)).toList();
  }
}
