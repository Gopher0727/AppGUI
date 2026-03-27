import 'package:flutter/material.dart';

import 'package:app_gui/pages/chat.dart';
import 'package:app_gui/pages/memory.dart';
import 'package:app_gui/pages/settings.dart';
import 'package:app_gui/widgets/drawer.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  // 用于从 ChatPage 调用会话切换弹窗
  final GlobalKey<ChatPageState> _chatKey = GlobalKey<ChatPageState>();

  static const _titles = ['Chat', 'Memory', 'Settings'];

  void _onPageChanged(int index) {
    setState(() => _currentIndex = index);
  }

  void _switchToPage(int index) {
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_currentIndex]),
        elevation: 0,
        actions: [
          if (_currentIndex == 0)
            IconButton(
              onPressed: () => _chatKey.currentState?.showSessionSwitcher(),
              icon: const Icon(Icons.chat_bubble_outline),
            ),
        ],
      ),
      drawer: AppDrawer(onNavigate: _switchToPage),
      body: PageView(
        controller: _pageController,
        onPageChanged: _onPageChanged,
        children: [
          ChatPage(key: _chatKey),
          const MemoryPage(),
          const SettingsPage(),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}
