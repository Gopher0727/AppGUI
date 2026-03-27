import 'package:dio/dio.dart';

import 'package:app_gui/config.dart';
import 'package:app_gui/models/session.dart';

class SessionService {
  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: AppConfig.baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
    ),
  );

  // 创建会话
  Future<Session> createSession({
    required String sessionId,
    required String uid,
    required String title,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/session',
      data: {'session_id': sessionId, 'uid': uid, 'title': title},
    );
    final data = response.data!['data'] as Map<String, dynamic>;
    return Session.fromJson(data);
  }

  // 删除会话
  Future<void> deleteSession(String sessionId) async {
    await _dio.delete('/session/$sessionId');
  }

  // 更新会话标题
  // TODO
  Future<Session> updateSessionTitle({
    required String sessionId,
    required String title,
  }) async {
    final response = await _dio.put<Map<String, dynamic>>(
      '/session/$sessionId',
      data: {'title': title},
    );
    final data = response.data!['data'] as Map<String, dynamic>;
    return Session.fromJson(data);
  }

  // 获取用户的所有会话
  Future<List<Session>> fetchSessions(String uid) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/sessions',
      queryParameters: {'uid': uid},
    );
    final data = response.data!['data'] as List<dynamic>;
    return data
        .map((e) => Session.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
