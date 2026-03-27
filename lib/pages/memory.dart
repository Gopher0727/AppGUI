import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

import 'package:app_gui/models/memory.dart';
import 'package:app_gui/providers/user.dart';
import 'package:app_gui/services/memory.dart';

enum MemorySource { user, ai }

class MemoryPage extends ConsumerStatefulWidget {
  const MemoryPage({super.key});

  @override
  ConsumerState<MemoryPage> createState() => _MemoryPageState();
}

class _MemoryPageState extends ConsumerState<MemoryPage> {
  final MemoryService _memoryService = MemoryService();

  // 按 source 保存草稿内容，点空白退出时暂存，下次打开编辑框恢复
  final Map<MemorySource, String> _drafts = {};
  // 本地置顶状态（置顶是纯前端行为）
  final Set<String> _pinnedIds = {};
  // null = 正常上下分栏, user = 用户记忆全屏, ai = AI 记忆全屏
  MemorySource? _expandedSource;

  List<Memory> _items = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    // 延迟到 frame 结束后再读 ref，避免在 initState 中直接访问
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadMemories());
  }

  Future<void> _loadMemories() async {
    final uid = ref.read(uidProvider);
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final memories = await _memoryService.fetchMemory(uid);
      if (mounted) {
        setState(() {
          _items = memories;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = '加载失败，下拉重试';
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!, style: TextStyle(color: Colors.grey[600])),
            SizedBox(height: 12.h),
            FilledButton.tonal(
              onPressed: _loadMemories,
              child: const Text('重试'),
            ),
          ],
        ),
      );
    }

    final userMemories = _getMemories(MemorySource.user);
    final aiMemories = _getMemories(MemorySource.ai);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: RefreshIndicator(
          onRefresh: _loadMemories,
          child: _buildBody(userMemories, aiMemories),
        ),
      ),
    );
  }

  MemorySource _toSource(Memory m) {
    return m.type == 'ai_memory' ? MemorySource.ai : MemorySource.user;
  }

  List<Memory> _getMemories(MemorySource source) {
    final items = _items.where((m) => _toSource(m) == source).toList();

    // 置顶的排在最前，然后按时间倒序
    items.sort((a, b) {
      final aPinned = _pinnedIds.contains(a.id);
      final bPinned = _pinnedIds.contains(b.id);
      if (aPinned != bPinned) {
        return aPinned ? -1 : 1;
      }
      return b.createdAt.compareTo(a.createdAt);
    });
    return items;
  }

  Widget _buildBody(List<Memory> userMemories, List<Memory> aiMemories) {
    final showUser =
        _expandedSource == null || _expandedSource == MemorySource.user;
    final showAi =
        _expandedSource == null || _expandedSource == MemorySource.ai;

    return Column(
      children: [
        if (showUser)
          Expanded(
            child: _buildSection(
              title: '用户自定义记忆',
              icon: Icons.person_outline,
              color: Colors.orange,
              items: userMemories,
              emptyText: '还没有用户自定义记忆',
              source: MemorySource.user,
              onAdd: () => _showMemoryEditor(source: MemorySource.user),
            ),
          ),
        if (showUser && showAi) SizedBox(height: 12.h),
        if (showAi)
          Expanded(
            child: _buildSection(
              title: 'AI 生成记忆',
              icon: Icons.auto_awesome_outlined,
              color: Colors.blue,
              items: aiMemories,
              emptyText: '还没有 AI 生成记忆',
              source: MemorySource.ai,
              onAdd: () => _showMemoryEditor(source: MemorySource.ai),
            ),
          ),
      ],
    );
  }

  // 分区渲染
  Widget _buildSection({
    required String title,
    required IconData icon,
    required Color color,
    required List<Memory> items,
    required String emptyText,
    required MemorySource source,
    required VoidCallback onAdd,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12.r,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          // 标题栏 — 双击切换全屏
          GestureDetector(
            onDoubleTap: () {
              setState(() {
                if (_expandedSource == source) {
                  _expandedSource = null; // 已全屏 → 恢复
                } else {
                  _expandedSource = source; // 全屏展示
                }
              });
            },
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 10, 10),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 18.r,
                    backgroundColor: color.withValues(alpha: 0.12),
                    child: Icon(icon, color: color, size: 18),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      setState(() {
                        if (_expandedSource == source) {
                          _expandedSource = null;
                        } else {
                          _expandedSource = source;
                        }
                      });
                    },
                    icon: Icon(
                      _expandedSource == source
                          ? Icons.fullscreen_exit
                          : Icons.fullscreen,
                      size: 20,
                      color: Colors.grey[400],
                    ),
                    tooltip: _expandedSource == source ? '退出全屏' : '全屏浏览',
                  ),
                  IconButton(
                    onPressed: onAdd,
                    tooltip: '新增',
                    icon: const Icon(Icons.add),
                  ),
                ],
              ),
            ),
          ),
          Divider(height: 1.h, color: Colors.grey.shade200),
          Expanded(
            child: items.isEmpty
                ? Center(
                    child: Padding(
                      padding: EdgeInsets.all(20.w),
                      child: Text(
                        emptyText,
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ),
                  )
                : SlidableAutoCloseBehavior(
                    child: ListView.builder(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12.w,
                        vertical: 8.h,
                      ),
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        final item = items[index];
                        return _buildMemoryCard(item);
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  // 记忆卡片
  Widget _buildMemoryCard(Memory item) {
    final pinned = _pinnedIds.contains(item.id);
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12.r),
        child: Slidable(
          key: ValueKey(item.id),
          // 左滑 → 显示置顶图标
          startActionPane: ActionPane(
            motion: const BehindMotion(),
            extentRatio: 0.2,
            children: [
              SlidableAction(
                onPressed: (_) => _togglePin(item.id),
                backgroundColor: pinned ? Colors.grey : Colors.amber,
                foregroundColor: Colors.white,
                icon: pinned ? Icons.push_pin : Icons.push_pin_outlined,
              ),
            ],
          ),
          // 右滑 → 显示删除图标
          endActionPane: ActionPane(
            motion: const BehindMotion(),
            extentRatio: 0.2,
            children: [
              SlidableAction(
                onPressed: (_) => _deleteMemory(item.id),
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                icon: Icons.delete_outline,
              ),
            ],
          ),
          child: GestureDetector(
            onTap: () => _showMemoryEditor(item: item, source: _toSource(item)),
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
              decoration: BoxDecoration(
                color: pinned ? Colors.amber.shade50 : Colors.grey[50],
                border: Border.all(color: Colors.grey.shade200),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (pinned) ...[
                        Icon(
                          Icons.push_pin,
                          size: 14,
                          color: Colors.amber[700],
                        ),
                        SizedBox(width: 4.w),
                      ],
                      Expanded(
                        child: Text(
                          item.content,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: Colors.grey[800],
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 6.h),
                  Text(
                    _formatTime(item.createdAt),
                    style: TextStyle(fontSize: 11.sp, color: Colors.grey[500]),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _togglePin(String id) {
    setState(() {
      if (_pinnedIds.contains(id)) {
        _pinnedIds.remove(id);
      } else {
        _pinnedIds.add(id);
      }
    });
  }

  Future<void> _deleteMemory(String id) async {
    // 先从 UI 移除，再请求后端
    final removed = _items.where((m) => m.id == id).firstOrNull;
    setState(() {
      _items.removeWhere((m) => m.id == id);
      _pinnedIds.remove(id);
    });

    try {
      await _memoryService.deleteMemory(id);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('记忆已删除')));
      }
    } catch (e) {
      // 删除失败，回滚
      if (mounted && removed != null) {
        setState(() => _items.add(removed));
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('删除失败，请重试')));
      }
    }
  }

  Future<void> _showMemoryEditor({
    Memory? item,
    required MemorySource source,
  }) async {
    // 编辑已有记忆时用原内容，新增时用草稿（如果有）
    final initialText = item?.content ?? _drafts[source] ?? '';
    final contentController = TextEditingController(text: initialText);
    final isEditing = item != null;
    final sourceText = source == MemorySource.user ? '用户自定义' : 'AI 生成';

    final resultContent = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            12,
            24,
            12,
            MediaQuery.of(sheetContext).viewInsets.bottom + 12,
          ),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
            ),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isEditing ? '编辑记忆' : '新增记忆',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '当前类型：$sourceText',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: contentController,
                    maxLines: 4,
                    autofocus: true,
                    decoration: InputDecoration(
                      labelText: '内容',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () {
                        final content = contentController.text.trim();
                        if (content.isEmpty) {
                          ScaffoldMessenger.of(sheetContext).showSnackBar(
                            const SnackBar(content: Text('内容不能为空')),
                          );
                          return;
                        }
                        Navigator.pop(sheetContext, content);
                      },
                      child: Text(isEditing ? '保存修改' : '添加记忆'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    if (resultContent != null && resultContent.isNotEmpty && mounted) {
      _drafts.remove(source);
      await _saveMemory(id: item?.id, content: resultContent, source: source);
    } else {
      final draft = contentController.text.trim();
      if (draft.isNotEmpty) {
        _drafts[source] = draft;
      } else {
        _drafts.remove(source);
      }
    }
  }

  Future<void> _saveMemory({
    String? id,
    required String content,
    required MemorySource source,
  }) async {
    final uid = ref.read(uidProvider);
    final type = source == MemorySource.ai ? 'ai_memory' : 'user_memory';

    try {
      if (id == null) {
        // 新增
        final memory = await _memoryService.addMemory(
          uid: uid,
          content: content,
          type: type,
        );
        if (mounted) {
          setState(() => _items.insert(0, memory));
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('记忆已添加')));
        }
      } else {
        // 编辑
        final memory = await _memoryService.updateMemory(
          id: id,
          content: content,
        );
        if (mounted) {
          setState(() {
            final index = _items.indexWhere((m) => m.id == id);
            if (index != -1) {
              _items[index] = memory;
            }
          });
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('记忆已更新')));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('操作失败，请重试')));
      }
    }
  }

  String _formatTime(DateTime time) {
    String twoDigits(int value) => value.toString().padLeft(2, '0');
    return '${time.year}-${twoDigits(time.month)}-${twoDigits(time.day)} ${twoDigits(time.hour)}:${twoDigits(time.minute)}';
  }
}
