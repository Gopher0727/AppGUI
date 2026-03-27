import 'package:dio/dio.dart';

import 'package:app_gui/config.dart';
import 'package:app_gui/models/token_usage.dart';

class TokenUsageService {
  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: AppConfig.baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
    ),
  );

  // 拉取指定用户最近 [days] 天的 token 消耗记录
  // GET /token_usage?uid=xxx&days=30
  Future<List<TokenUsage>> fetchUsages(String uid, {int days = 30}) async {
    final response = await _dio.get(
      '/token_usage',
      queryParameters: {'uid': uid, 'days': days},
    );
    final data = response.data['data'] as List<dynamic>;
    return data
        .map((e) => TokenUsage.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
