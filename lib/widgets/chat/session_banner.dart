import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:app_gui/models/session.dart';
import 'package:app_gui/providers/session.dart';
import 'package:app_gui/providers/user.dart';

class SessionBanner extends ConsumerStatefulWidget {
  const SessionBanner({super.key, required this.onClose});

  final VoidCallback onClose;

  @override
  ConsumerState<SessionBanner> createState() => _SessionBannerState();
}

class _SessionBannerState extends ConsumerState<SessionBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _animController.forward();
  }

  // 删除会话
  Future<void> _deleteSession(String id) async {
    final currentId = ref.read(currentSessionIdProvider);

    try {
      final newId = await ref.read(sessionsProvider.notifier).deleteSession(id);

      // 如果删除的是当前选中的会话，切换到其他会话或清空选中
      if (id == currentId) {
        ref.read(currentSessionIdProvider.notifier).state = newId;
      }

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('会话已删除')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('删除失败：$e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final sessions = ref.watch(sessionsProvider);
    final currentId = ref.watch(currentSessionIdProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final topPadding = MediaQuery.of(context).padding.top + kToolbarHeight;

    return Stack(
      children: [
        // 半透明遮罩，点击关闭
        Positioned.fill(
          child: GestureDetector(
            onTap: _dismiss,
            child: const ColoredBox(color: Colors.transparent),
          ),
        ),

        // 条幅主体
        Positioned(
          top: topPadding,
          left: 0,
          right: 0,
          child: SlideTransition(
            position: _slideAnim,
            child: Material(
              elevation: 4,
              color: colorScheme.surface,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildHeader(colorScheme),
                  const Divider(height: 1),
                  _buildSessionList(sessions, currentId, colorScheme),
                  SizedBox(height: 4.h),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(ColorScheme colorScheme) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
      child: Row(
        children: [
          Text(
            '会话列表',
            style: TextStyle(
              fontSize: 13.r,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
          const Spacer(),
          // 新建会话按钮
          InkWell(
            onTap: () async {
              final uid = ref.read(uidProvider);
              final newId = await ref
                  .read(sessionsProvider.notifier)
                  .createRemoteSession(uid, '新会话');

              if (newId != null) {
                ref.read(currentSessionIdProvider.notifier).state = newId;
                _dismiss();
              }
            },
            borderRadius: BorderRadius.circular(6.r),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add, size: 15.r, color: colorScheme.primary),
                  SizedBox(width: 2.w),
                  Text(
                    '新建',
                    style: TextStyle(
                      fontSize: 12.r,
                      color: colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionList(
    List<Session> sessions,
    String? currentId,
    ColorScheme colorScheme,
  ) {
    // 空会话列表
    if (sessions.isEmpty) {
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 24.h),
        child: Center(
          child: Text(
            '暂无会话',
            style: TextStyle(color: Colors.grey.shade400, fontSize: 14.r),
          ),
        ),
      );
    }

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: sessions.length > 5 ? 280.h : double.infinity,
      ),
      child: ListView.builder(
        shrinkWrap: true,
        padding: EdgeInsets.symmetric(vertical: 4.h),
        itemCount: sessions.length,
        itemBuilder: (context, index) {
          final session = sessions[index];
          final isSelected = session.id == currentId;

          return InkWell(
            onTap: () {
              ref.read(currentSessionIdProvider.notifier).state = session.id;
              _dismiss();
            },
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
              child: Row(
                children: [
                  Icon(
                    isSelected ? Icons.chat_rounded : Icons.chat_outlined,
                    size: 16.r,
                    color: isSelected
                        ? colorScheme.primary
                        : Colors.grey.shade400,
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Text(
                      session.title,
                      style: TextStyle(
                        fontSize: 14.r,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.normal,
                        color: isSelected
                            ? colorScheme.primary
                            : Colors.grey.shade800,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  // 消息数量
                  if (session.messageCount > 0)
                    Padding(
                      padding: EdgeInsets.only(right: 8.w),
                      child: Text(
                        '${session.messageCount}',
                        style: TextStyle(
                          fontSize: 11.r,
                          color: Colors.grey.shade400,
                        ),
                      ),
                    ),
                  // 删除按钮
                  GestureDetector(
                    onTap: () => _deleteSession(session.id),
                    child: Icon(
                      Icons.close,
                      size: 15.r,
                      color: Colors.grey.shade400,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _dismiss() async {
    await _animController.reverse();
    widget.onClose();
  }
}
