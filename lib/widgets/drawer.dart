import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app_gui/providers/user.dart';

// 公共侧边栏
class AppDrawer extends ConsumerWidget {
  final void Function(int index) onNavigate;

  const AppDrawer({super.key, required this.onNavigate});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final avatar = ref.watch(avatarProvider);

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          // 头部，放置用户头像
          UserAccountsDrawerHeader(
            accountName: const Text("My Account"),
            accountEmail: null,
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              backgroundImage: avatar.isNotEmpty && avatar.startsWith("assets/")
                  ? AssetImage(avatar) as ImageProvider
                  : avatar.isNotEmpty
                  ? FileImage(File(avatar))
                  : null,
              child: avatar.isEmpty ? const Icon(Icons.person, size: 40) : null,
            ),
            decoration: BoxDecoration(color: Colors.grey[500]),
          ),

          // Chat 页面
          ListTile(
            leading: const Icon(Icons.send),
            title: const Text("Chat"),
            onTap: () {
              Navigator.pop(context);
              onNavigate(0);
            },
          ),

          // Memory 页面
          ListTile(
            leading: const Icon(Icons.local_library),
            title: const Text("Memory"),
            onTap: () {
              Navigator.pop(context);
              onNavigate(1);
            },
          ),

          // Settings 页面
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text("Settings"),
            onTap: () {
              Navigator.pop(context);
              onNavigate(2);
            },
          ),
        ],
      ),
    );
  }
}
