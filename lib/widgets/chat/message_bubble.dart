import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:app_gui/models/message.dart';
import 'package:app_gui/providers/session.dart';

// 单条消息气泡，用户消息支持长按操作
class MessageBubble extends ConsumerWidget {
  const MessageBubble({
    super.key,
    required this.msg,
    required this.isMe,
    required this.sessionId,
  });

  final Message msg;
  final bool isMe;
  final String sessionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bubbleKey = GlobalKey();

    final bubble = Container(
      key: bubbleKey,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: isMe ? Colors.blue : Colors.grey[300],
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Text(
        msg.content,
        style: TextStyle(color: isMe ? Colors.white : Colors.black),
      ),
    );

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: isMe
          ? GestureDetector(
              onLongPress: () => _showActions(context, ref, bubbleKey),
              child: bubble,
            )
          : bubble,
    );
  }

  // 在气泡上方弹出操作条（Overlay）
  void _showActions(BuildContext context, WidgetRef ref, GlobalKey bubbleKey) {
    final renderBox =
        bubbleKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final bubbleOffset = renderBox.localToGlobal(Offset.zero);
    final bubbleSize = renderBox.size;

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _MessageActionMenu(
        bubbleOffset: bubbleOffset,
        bubbleSize: bubbleSize,
        onDismiss: () => entry.remove(),
        onCopy: () {
          entry.remove();
          Clipboard.setData(ClipboardData(text: msg.content));
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('已复制'),
              duration: Duration(seconds: 1),
            ),
          );
        },
        onRevoke: () {
          entry.remove();
          ref.read(sessionsProvider.notifier).removeMessage(sessionId, msg.id);
        },
      ),
    );

    Overlay.of(context).insert(entry);
  }
}

// 气泡上方操作菜单（Overlay）
class _MessageActionMenu extends StatefulWidget {
  const _MessageActionMenu({
    required this.bubbleOffset,
    required this.bubbleSize,
    required this.onDismiss,
    required this.onCopy,
    required this.onRevoke,
  });

  final Offset bubbleOffset;
  final Size bubbleSize;
  final VoidCallback onDismiss;
  final VoidCallback onCopy;
  final VoidCallback onRevoke;

  @override
  State<_MessageActionMenu> createState() => _MessageActionMenuState();
}

class _MessageActionMenuState extends State<_MessageActionMenu>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _fadeAnim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _ctrl.forward();
  }

  @override
  Widget build(BuildContext context) {
    const menuHeight = 40.0;
    const menuWidth = 190.0;
    const gap = 6.0;
    const arrowSize = 6.0;

    final screenWidth = MediaQuery.of(context).size.width;
    // 右对齐气泡右边，不超出屏幕边界
    double menuLeft =
        widget.bubbleOffset.dx + widget.bubbleSize.width - menuWidth;
    if (menuLeft < 8) menuLeft = 8;
    if (menuLeft + menuWidth > screenWidth - 8) {
      menuLeft = screenWidth - menuWidth - 8;
    }

    final menuTop = widget.bubbleOffset.dy - menuHeight - arrowSize - gap;

    return Stack(
      children: [
        // 透明遮罩，点击关闭
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: _dismiss,
          ),
        ),

        // 操作条主体
        Positioned(
          left: menuLeft,
          top: menuTop,
          child: FadeTransition(
            opacity: _fadeAnim,
            child: SlideTransition(
              position: _slideAnim,
              child: Material(
                color: Colors.transparent,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      height: menuHeight,
                      decoration: BoxDecoration(
                        color: const Color(0xFF2C2C2C),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _ActionItem(
                            icon: Icons.undo,
                            label: '撤回',
                            color: Colors.redAccent,
                            onTap: widget.onRevoke,
                          ),
                          Container(
                            width: 1,
                            height: 20,
                            color: Colors.white24,
                          ),
                          _ActionItem(
                            icon: Icons.copy_outlined,
                            label: '复制',
                            color: Colors.white,
                            onTap: widget.onCopy,
                          ),
                        ],
                      ),
                    ),
                    // 向下小三角，指向气泡
                    CustomPaint(
                      size: const Size(arrowSize * 2, arrowSize),
                      painter: _ArrowPainter(),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _dismiss() async {
    await _ctrl.reverse();
    widget.onDismiss();
  }
}

class _ActionItem extends StatelessWidget {
  const _ActionItem({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 6.h),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15.r, color: color),
            SizedBox(width: 5.w),
            Text(
              label,
              style: TextStyle(fontSize: 13.r, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}

class _ArrowPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0xFF2C2C2C);
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_) => false;
}
