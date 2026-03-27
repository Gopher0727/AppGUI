import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import 'package:app_gui/models/token_usage.dart';
import 'package:app_gui/providers/user.dart';
import 'package:app_gui/services/token_usage.dart';

enum TokenPeriod { week, month }

// 当前选中的时间周期
final tokenPeriodProvider = StateProvider<TokenPeriod>(
  (ref) => TokenPeriod.week,
);

// 从后端拉取 token 消耗记录（30 天），结果由 Riverpod 缓存
// uid 变化时重新请求
final tokenUsageListProvider = FutureProvider<List<TokenUsage>>((ref) async {
  final uid = ref.watch(uidProvider);
  return TokenUsageService().fetchUsages(uid, days: 30);
});

// 根据时间周期过滤后的数据
final filteredTokenUsageProvider = Provider<List<TokenUsage>>((ref) {
  final asyncData = ref.watch(tokenUsageListProvider);
  final period = ref.watch(tokenPeriodProvider);
  final now = DateTime.now();
  final all = asyncData.value ?? [];
  final cutoff = switch (period) {
    TokenPeriod.week => now.subtract(const Duration(days: 7)),
    TokenPeriod.month => now.subtract(const Duration(days: 30)),
  };
  return all.where((u) => u.createdAt.isAfter(cutoff)).toList()
    ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
});
