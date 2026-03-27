import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:app_gui/pages/home.dart';
import 'package:app_gui/providers/user.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: const ChatAgent(),
    ),
  );
}

class ChatAgent extends StatelessWidget {
  const ChatAgent({super.key});

  @override
  Widget build(BuildContext context) {
    // 使用 ScreenUtilInit 组件
    return ScreenUtilInit(
      // 设计稿尺寸
      designSize: const Size(396, 844),
      // 是否支持由于系统字体缩放导致你的字体也缩放
      minTextAdapt: false,
      // 避免键盘弹起导致高度被重新计算
      splitScreenMode: true,

      builder: (context, child) {
        return MaterialApp(
          // 移除调试模式提示
          debugShowCheckedModeBanner: false,

          home: const HomePage(),
        );
      },
    );
  }
}
