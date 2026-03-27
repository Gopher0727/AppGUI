import 'dart:io';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

import 'package:app_gui/models/token_usage.dart';
import 'package:app_gui/providers/token_usage.dart';
import 'package:app_gui/providers/user.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _nicknameController = TextEditingController();
  bool _isEditing = false;

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      final savedPath = await _saveImageLocally(image);
      if (savedPath != null) {
        ref.read(avatarProvider.notifier).setAvatar(savedPath);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Avatar changed successfully")),
          );
        }
      }
    }
  }

  Future<String?> _saveImageLocally(XFile image) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final fileName = 'avatar_${DateTime.now().millisecondsSinceEpoch}.png';
      final savedPath = '${appDir.path}/$fileName';
      final File newImage = await File(image.path).copy(savedPath);
      return newImage.path;
    } catch (e) {
      debugPrint('Error saving image: $e');
      return null;
    }
  }

  void _saveNickname() {
    final newName = _nicknameController.text.trim();
    if (newName.isNotEmpty) {
      ref.read(nicknameProvider.notifier).setNickname(newName);
    }
    setState(() {
      _isEditing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final avatarPath = ref.watch(avatarProvider);
    final nickname = ref.watch(nicknameProvider);
    final uid = ref.watch(uidProvider);

    if (!_isEditing) {
      _nicknameController.text = nickname;
    }

    return SingleChildScrollView(
      padding: EdgeInsets.all(20.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── 用户信息区 ──────────────────────────────────────
          Center(
            child: Column(
              children: [
                // 头像（可点击换图）
                GestureDetector(
                  onTap: _pickImage,
                  child: Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      CircleAvatar(
                        radius: 44.r,
                        backgroundImage: avatarPath.startsWith("assets/")
                            ? AssetImage(avatarPath) as ImageProvider
                            : FileImage(File(avatarPath)),
                      ),
                      Container(
                        padding: EdgeInsets.all(4.r),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Theme.of(context).colorScheme.surface,
                            width: 2,
                          ),
                        ),
                        child: Icon(
                          Icons.camera_alt,
                          size: 12.r,
                          color: Theme.of(context).colorScheme.onPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 12.h),

                // 昵称行：只读时显示文字+铅笔，编辑时变为输入框+确认
                _isEditing
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 160.w,
                            child: TextField(
                              controller: _nicknameController,
                              autofocus: true,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 18.r,
                                fontWeight: FontWeight.w600,
                              ),
                              decoration: InputDecoration(
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 10.w,
                                  vertical: 6.h,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8.r),
                                ),
                              ),
                              onSubmitted: (_) => _saveNickname(),
                            ),
                          ),
                          SizedBox(width: 6.w),
                          IconButton(
                            onPressed: _saveNickname,
                            icon: const Icon(Icons.check_circle_rounded),
                            color: Theme.of(context).colorScheme.primary,
                            iconSize: 24.r,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      )
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            nickname,
                            style: TextStyle(
                              fontSize: 18.r,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(width: 6.w),
                          GestureDetector(
                            onTap: () => setState(() => _isEditing = true),
                            child: Icon(
                              Icons.edit_outlined,
                              size: 16.r,
                              color: Colors.grey.shade400,
                            ),
                          ),
                        ],
                      ),
                SizedBox(height: 10.h),

                // UID chip
                GestureDetector(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: uid));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('UID 已复制'),
                        duration: Duration(seconds: 1),
                      ),
                    );
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 12.w,
                      vertical: 5.h,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .surfaceContainerHighest
                          .withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(20.r),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'UID',
                          style: TextStyle(
                            fontSize: 11.r,
                            color: Colors.grey.shade500,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(width: 6.w),
                        Flexible(
                          child: Text(
                            uid,
                            style: TextStyle(
                              fontSize: 11.r,
                              color: Colors.grey.shade600,
                              fontFamily: 'monospace',
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        SizedBox(width: 4.w),
                        Icon(
                          Icons.copy_outlined,
                          size: 12.r,
                          color: Colors.grey.shade400,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 32.h),

          // ── Token 消耗折线图 ────────────────────────────────
          const _TokenUsageChart(),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    super.dispose();
  }
}

// Token 消耗折线图组件
class _TokenUsageChart extends ConsumerWidget {
  const _TokenUsageChart();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final period = ref.watch(tokenPeriodProvider);
    final usagesAsync = ref.watch(tokenUsageListProvider);
    final usages = ref.watch(filteredTokenUsageProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 标题行 + 周期切换按钮
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              "Token 消耗",
              style: TextStyle(fontSize: 15.r, fontWeight: FontWeight.w600),
            ),
            _PeriodToggle(current: period),
          ],
        ),
        SizedBox(height: 12.h),

        // 图表容器
        Container(
          height: 200.h,
          padding: EdgeInsets.only(right: 12.w, top: 8.h, bottom: 4.h),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: usagesAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('加载失败：$e')),
            data: (_) => usages.isEmpty
                ? const Center(child: Text("暂无数据"))
                : _LineChart(usages: usages, period: period),
          ),
        ),

        SizedBox(height: 8.h),
        _TokenSummary(usages: usages),
      ],
    );
  }
}

// 周期切换按钮
class _PeriodToggle extends ConsumerWidget {
  const _PeriodToggle({required this.current});

  final TokenPeriod current;

  static const _labels = {TokenPeriod.week: '7d', TokenPeriod.month: '30d'};

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: TokenPeriod.values.map((p) {
        final selected = p == current;
        return Padding(
          padding: EdgeInsets.only(left: 4.w),
          child: GestureDetector(
            onTap: () => ref.read(tokenPeriodProvider.notifier).state = p,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
              decoration: BoxDecoration(
                color: selected
                    ? Theme.of(context).colorScheme.primary
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(20.r),
                border: Border.all(
                  color: selected
                      ? Theme.of(context).colorScheme.primary
                      : Colors.grey.shade400,
                  width: 1,
                ),
              ),
              child: Text(
                _labels[p]!,
                style: TextStyle(
                  fontSize: 12.r,
                  color: selected
                      ? Theme.of(context).colorScheme.onPrimary
                      : Colors.grey.shade600,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// 折线图主体
class _LineChart extends StatelessWidget {
  const _LineChart({required this.usages, required this.period});

  final List<TokenUsage> usages;
  final TokenPeriod period;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;

    // 按天聚合（同一天的 totalTokens 求和）
    final Map<String, int> aggregated = {};
    for (final u in usages) {
      final key =
          '${u.createdAt.year}-${u.createdAt.month.toString().padLeft(2, '0')}-${u.createdAt.day.toString().padLeft(2, '0')}';
      aggregated[key] = (aggregated[key] ?? 0) + u.totalTokens;
    }

    final sortedKeys = aggregated.keys.toList()..sort();
    final spots = sortedKeys.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), aggregated[e.value]!.toDouble());
    }).toList();

    final maxY = spots.isEmpty
        ? 3000.0
        : (spots.map((s) => s.y).reduce((a, b) => a > b ? a : b) * 1.2);

    // X 轴标签：根据周期显示不同密度
    final int labelStep = switch (period) {
      TokenPeriod.week => 1,
      TokenPeriod.month => 5,
    };

    return LineChart(
      LineChartData(
        minX: 0,
        maxX: (sortedKeys.length - 1).toDouble(),
        minY: 0,
        maxY: maxY,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: maxY / 4,
          getDrawingHorizontalLine: (value) =>
              FlLine(color: Colors.grey.withValues(alpha: 0.2), strokeWidth: 1),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 44.w,
              interval: maxY / 4,
              getTitlesWidget: (value, meta) {
                if (value == 0) return const SizedBox.shrink();
                final label = value >= 1000
                    ? '${(value / 1000).toStringAsFixed(1)}k'
                    : value.toInt().toString();
                return Text(
                  label,
                  style: TextStyle(fontSize: 10.r, color: Colors.grey),
                );
              },
            ),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 22.h,
              interval: labelStep.toDouble(),
              getTitlesWidget: (value, meta) {
                final idx = value.toInt();
                if (idx < 0 || idx >= sortedKeys.length) {
                  return const SizedBox.shrink();
                }
                // 只在特定步长处显示
                if (idx % labelStep != 0) return const SizedBox.shrink();
                final parts = sortedKeys[idx].split('-');
                final label = '${parts[1]}/${parts[2]}';
                return Transform.rotate(
                  angle: period == TokenPeriod.month ? -0.5 : 0,
                  child: Text(
                    label,
                    style: TextStyle(fontSize: 9.r, color: Colors.grey),
                  ),
                );
              },
            ),
          ),
        ),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => Theme.of(
              context,
            ).colorScheme.inverseSurface.withValues(alpha: 0.9),
            getTooltipItems: (spots) => spots.map((s) {
              final idx = s.x.toInt();
              final dateStr = idx < sortedKeys.length ? sortedKeys[idx] : '';
              return LineTooltipItem(
                '$dateStr\n${s.y.toInt()} tokens',
                TextStyle(
                  color: Theme.of(context).colorScheme.onInverseSurface,
                  fontSize: 11.r,
                ),
              );
            }).toList(),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            curveSmoothness: 0.3,
            color: color,
            barWidth: 2.5,
            dotData: FlDotData(
              show: period != TokenPeriod.month,
              getDotPainter: (_, _, _, _) => FlDotCirclePainter(
                radius: 3,
                color: color,
                strokeWidth: 1.5,
                strokeColor: Colors.white,
              ),
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  color.withValues(alpha: 0.25),
                  color.withValues(alpha: 0.0),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// 汇总信息
class _TokenSummary extends StatelessWidget {
  const _TokenSummary({required this.usages});

  final List<TokenUsage> usages;

  // 换算基准：
  // 1 本普通小说 ≈ 13 万汉字 ≈ 130,000 tokens（中文约1字≈1token）
  // 1 首古诗 ≈ 40 tokens；
  // 1 篇新闻 ≈ 800 tokens
  static String _semantic(int total) {
    if (total <= 0) return '';
    const novelTokens = 130000;
    const newsTokens = 800;
    const poemTokens = 40;

    if (total >= novelTokens) {
      final novels = total / novelTokens;
      return '相当于阅读 ${novels.toStringAsFixed(1)} 本小说';
    } else if (total >= newsTokens * 10) {
      final news = (total / newsTokens).round();
      return '相当于阅读 $news 篇新闻';
    } else {
      final poems = (total / poemTokens).round();
      return '相当于阅读 $poems 首古诗';
    }
  }

  @override
  Widget build(BuildContext context) {
    final total = usages.fold<int>(0, (sum, u) => sum + u.totalTokens);
    final prompt = usages.fold<int>(0, (sum, u) => sum + u.promptTokens);
    final completion = usages.fold<int>(
      0,
      (sum, u) => sum + u.completionTokens,
    );

    final semanticText = _semantic(total);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _StatChip(label: '总计', value: _fmt(total)),
            SizedBox(width: 8.w),
            _StatChip(label: '输入', value: _fmt(prompt), dimmed: true),
            SizedBox(width: 8.w),
            _StatChip(label: '输出', value: _fmt(completion), dimmed: true),
          ],
        ),
        if (semanticText.isNotEmpty) ...[
          SizedBox(height: 4.h),
          Text(
            semanticText,
            style: TextStyle(fontSize: 11.r, color: Colors.grey.shade500),
          ),
        ],
      ],
    );
  }

  String _fmt(int n) => n >= 1000 ? '${(n / 1000).toStringAsFixed(1)}k' : '$n';
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.label,
    required this.value,
    this.dimmed = false,
  });

  final String label;
  final String value;
  final bool dimmed;

  @override
  Widget build(BuildContext context) {
    final color = dimmed ? Colors.grey.shade500 : Colors.grey.shade700;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$label ',
          style: TextStyle(fontSize: 12.r, color: Colors.grey),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 13.r,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }
}
