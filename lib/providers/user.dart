import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('必须在 ProviderScope 中 override');
});

// 头像 Provider
final avatarProvider = StateNotifierProvider<AvatarNotifier, String>((ref) {
  return AvatarNotifier(ref.watch(sharedPreferencesProvider));
});

class AvatarNotifier extends StateNotifier<String> {
  static const _key = "avatar_path";
  final SharedPreferences _prefs;

  AvatarNotifier(this._prefs) : super("assets/default_avatar.png") {
    final savedPath = _prefs.getString(_key);
    if (savedPath != null && File(savedPath).existsSync()) {
      state = savedPath;
    }
  }

  void updateAvatar(String newAvatar) {
    state = newAvatar;
  }

  Future<void> setAvatar(String path) async {
    state = path;
    await _prefs.setString(_key, path);
  }
}

// 昵称 Provider
final nicknameProvider = StateNotifierProvider<NicknameNotifier, String>((ref) {
  return NicknameNotifier(ref.watch(sharedPreferencesProvider));
});

class NicknameNotifier extends StateNotifier<String> {
  static const _key = "nickname";
  final SharedPreferences _prefs;

  NicknameNotifier(this._prefs) : super("User") {
    final savedName = _prefs.getString(_key);
    if (savedName != null) {
      state = savedName;
    }
  }

  Future<void> setNickname(String name) async {
    state = name;
    await _prefs.setString(_key, name);
  }
}

// UID Provider
final uidProvider = StateNotifierProvider<UidNotifier, String>((ref) {
  return UidNotifier(ref.watch(sharedPreferencesProvider));
});

class UidNotifier extends StateNotifier<String> {
  static const _key = "user_uid";
  final SharedPreferences _prefs;

  UidNotifier(this._prefs) : super("") {
    String? savedUid = _prefs.getString(_key);
    if (savedUid == null || savedUid.isEmpty) {
      savedUid = const Uuid().v4();
      _prefs.setString(_key, savedUid);
    }
    state = savedUid;
  }
}
