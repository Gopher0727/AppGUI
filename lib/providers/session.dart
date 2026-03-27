import 'package:dio/dio.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:uuid/uuid.dart';

import 'package:app_gui/models/message.dart';
import 'package:app_gui/models/session.dart';
import 'package:app_gui/services/session.dart';

// 当前选中的会话 ID
final currentSessionIdProvider = StateProvider<String?>((ref) => null);

// 当前是否正在等待 AI 回复（用于 UI 显示打断按钮）
final isReplyingProvider = StateProvider<bool>((ref) => false);

// 所有会话列表
final sessionsProvider = StateNotifierProvider<SessionsNotifier, List<Session>>(
  (ref) {
    return SessionsNotifier();
  },
);

class SessionsNotifier extends StateNotifier<List<Session>> {
  SessionsNotifier() : super([]);

  final SessionService _sessionService = SessionService();

  CancelToken? currentCancelToken; // 当前 AI 请求的取消令牌，非 null 时表示有请求进行中

  // 创建远程会话（完全独立的业务逻辑）
  // 生成 UUID -> 调用后端 API -> 添加到状态 -> 返回会话 ID
  Future<String?> createRemoteSession(String uid, String title) async {
    final session = await _sessionService.createSession(
      sessionId: const Uuid().v4(),
      uid: uid,
      title: title,
    );
    state = [...state, session];
    return session.id;
  }

  // 删除会话（同步到后端）
  // 先从 UI 移除 -> 调用后端 -> 失败则回滚
  Future<String?> deleteSession(String id) async {
    final removed = state.firstWhere((s) => s.id == id);
    final newList = state.where((s) => s.id != id).toList();
    state = newList;

    try {
      // 调用后端删除
      await _sessionService.deleteSession(id);
      return newList.isNotEmpty ? newList.first.id : null;
    } catch (e) {
      // 删除失败，回滚
      state = [...state, removed];
      rethrow;
    }
  }

  // 更新会话标题（同步到后端）
  // 先更新 UI -> 调用后端 -> 失败则回滚
  Future<void> updateSessionTitle(String id, String title) async {
    final original = state.firstWhere((s) => s.id == id);
    state = state.map((s) {
      if (s.id != id) return s;
      return s.copyWith(title: title, updatedAt: DateTime.now());
    }).toList();

    try {
      // 调用后端更新
      final updated = await _sessionService.updateSessionTitle(
        sessionId: id,
        title: title,
      );
      // 用后端返回的数据替换
      state = state.map((s) => s.id == id ? updated : s).toList();
    } catch (e) {
      // 更新失败，回滚
      state = state.map((s) => s.id == id ? original : s).toList();
      rethrow;
    }
  }

  // 加载用户的所有会话
  Future<void> loadSessions(String uid) async {
    final sessions = await _sessionService.fetchSessions(uid);
    state = sessions;
  }

  // 添加消息到指定会话
  void addMessage(String sessionId, Message message) {
    state = state.map((s) {
      if (s.id != sessionId) return s;
      return s.copyWith(
        messages: [...s.messages, message],
        messageCount: s.messageCount + 1,
        lastMessageAt: message.createdAt,
        updatedAt: message.createdAt,
      );
    }).toList();
  }

  // 撤回（删除）指定消息
  void removeMessage(String sessionId, String messageId) {
    state = state.map((s) {
      if (s.id != sessionId) return s;
      final updated = s.messages.where((m) => m.id != messageId).toList();
      return s.copyWith(
        messages: updated,
        messageCount: updated.length,
        updatedAt: DateTime.now(),
      );
    }).toList();
  }

  // 更新消息内容（流式追加 AI 回复时使用）
  void updateMessageContent(
    String sessionId,
    String messageId,
    String content,
  ) {
    state = state.map((s) {
      if (s.id != sessionId) return s;
      return s.copyWith(
        messages: s.messages.map((m) {
          if (m.id != messageId) return m;
          return m.copyWith(content: content, updatedAt: DateTime.now());
        }).toList(),
        updatedAt: DateTime.now(),
      );
    }).toList();
  }

  // 用后端返回的完整 Message 替换本地占位消息（更新 id、token 统计等）
  void replaceMessage(String sessionId, String placeholderId, Message message) {
    state = state.map((s) {
      if (s.id != sessionId) return s;
      return s.copyWith(
        messages: s.messages.map((m) {
          if (m.id != placeholderId) return m;
          return message;
        }).toList(),
        updatedAt: message.updatedAt,
      );
    }).toList();
  }

  // 取消当前正在进行的 AI 请求
  void abortReply() {
    currentCancelToken?.cancel('用户打断');
    currentCancelToken = null;
  }
}
