import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:uuid/uuid.dart';

import 'package:app_gui/models/message.dart';
import 'package:app_gui/models/session.dart';
import 'package:app_gui/providers/session.dart';
import 'package:app_gui/providers/user.dart';
import 'package:app_gui/services/chat.dart';
import 'package:app_gui/widgets/chat/message_bubble.dart';
import 'package:app_gui/widgets/chat/session_banner.dart';

class ChatPage extends ConsumerStatefulWidget {
  const ChatPage({super.key});

  @override
  ChatPageState createState() => ChatPageState();
}

class ChatPageState extends ConsumerState<ChatPage> {
  final TextEditingController _controller = TextEditingController(); // 输入框控制器
  final FocusNode _focusNode = FocusNode(); // 聚焦节点，用于控制键盘
  final ChatService _chatService = ChatService(); // 聊天服务
  bool _hasText = false; // 输入框是否有文字（控制发送按钮是否可用）

  @override
  Widget build(BuildContext context) {
    final sessions = ref.watch(sessionsProvider);
    final currentSessionId = ref.watch(currentSessionIdProvider);
    final isReplying = ref.watch(isReplyingProvider);

    // 获取当前会话及消息
    Session? currentSession;
    if (currentSessionId != null) {
      currentSession = sessions
          .where((s) => s.id == currentSessionId)
          .firstOrNull;
    }
    final messages = currentSession?.messages ?? [];

    return Column(
      children: [
        Expanded(
          child: messages.isEmpty
              ? Center(
                  child: Text(
                    "Hi, ${ref.watch(nicknameProvider)}.",
                    style: const TextStyle(color: Colors.grey),
                  ),
                )
              : ListView.builder(
                  padding: EdgeInsets.all(8.w),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    return MessageBubble(
                      msg: msg,
                      isMe: msg.role == MessageRole.user,
                      sessionId: currentSession!.id,
                    );
                  },
                ),
        ),
        _buildInputBar(isReplying),
      ],
    );
  }

  // 构建底部输入栏
  Widget _buildInputBar(bool isReplying) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.2),
            offset: const Offset(0, -2),
            blurRadius: 4.r,
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            // 附件按钮
            IconButton(
              onPressed: _onAddFile,
              icon: const Icon(Icons.attach_file),
              color: Colors.grey[700],
            ),
            // 文本输入框
            Expanded(
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                onChanged: _onTextChanged,
                enabled: !isReplying,
                decoration: InputDecoration(
                  hintText: isReplying ? "正在连接神经元..." : "Send a message...",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24.r),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.grey[100],
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16.w,
                    vertical: 10.h,
                  ),
                ),
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _onSend(),
              ),
            ),
            // 打断按钮 / 发送按钮
            if (isReplying)
              IconButton(
                onPressed: _onAbort,
                icon: const Icon(Icons.stop_circle_outlined),
                color: Colors.red,
                tooltip: '打断回复',
              )
            else
              IconButton(
                onPressed: _hasText ? _onSend : null,
                icon: const Icon(Icons.send),
                color: Colors.black,
              ),
          ],
        ),
      ),
    );
  }

  // TODO
  void _onAddFile() {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Add file feature")));
  }

  void _onTextChanged(String text) {
    setState(() => _hasText = text.trim().isNotEmpty);
  }

  void _onAbort() {
    ref.read(sessionsProvider.notifier).abortReply();
    ref.read(isReplyingProvider.notifier).state = false;
  }

  Future<void> _onSend() async {
    // 验证输入
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    // 检查会话是否存在
    final uid = ref.read(uidProvider);
    String sessionId = ref.read(currentSessionIdProvider) ?? '';

    // 如果没有当前会话，创建新会话
    if (sessionId.isEmpty) {
      final newId = await ref
          .read(sessionsProvider.notifier)
          .createRemoteSession(uid, '新会话');

      if (newId == null) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('创建会话失败')));
        }
        return;
      }

      sessionId = newId;
      ref.read(currentSessionIdProvider.notifier).state = sessionId;
    }

    // 添加用户消息
    final now = DateTime.now();
    final userMessage = Message(
      id: const Uuid().v4(),
      sessionId: sessionId,
      role: MessageRole.user,
      content: text,
      promptTokens: 0,
      completionTokens: 0,
      totalTokens: 0,
      createdAt: now,
      updatedAt: now,
    );
    ref.read(sessionsProvider.notifier).addMessage(sessionId, userMessage);

    // 清空输入框
    setState(() => _hasText = false);
    _controller.clear();

    // 创建 AI 占位消息
    final aiMessageId = const Uuid().v4();
    ref
        .read(sessionsProvider.notifier)
        .addMessage(
          sessionId,
          Message(
            id: aiMessageId,
            sessionId: sessionId,
            role: MessageRole.ai,
            content: '',
            promptTokens: 0,
            completionTokens: 0,
            totalTokens: 0,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );

    // 启动流式请求
    final cancelToken = CancelToken();
    ref.read(sessionsProvider.notifier).currentCancelToken = cancelToken;
    ref.read(isReplyingProvider.notifier).state = true;

    await _chatService.sendMessageStream(
      text,
      uid,
      sessionId,
      cancelToken: cancelToken,
      onToken: (content) {
        ref
            .read(sessionsProvider.notifier)
            .updateMessageContent(sessionId, aiMessageId, content);
      },
      onDone: (message) {
        ref
            .read(sessionsProvider.notifier)
            .replaceMessage(sessionId, aiMessageId, message);
        ref.read(sessionsProvider.notifier).currentCancelToken = null;
        ref.read(isReplyingProvider.notifier).state = false;
      },
      onError: (error) {
        ref.read(sessionsProvider.notifier).currentCancelToken = null;
        ref.read(isReplyingProvider.notifier).state = false;

        if (error is ChatAbortException) return;
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('发送失败：$error')));
        }
      },
    );
  }

  // 从顶部滑入会话条幅
  void showSessionSwitcher() {
    final overlay = Overlay.of(context);
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => SessionBanner(onClose: () => entry.remove()),
    );
    overlay.insert(entry);
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }
}
