import 'package:flutter_app/services/local_storeage_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../core/models/login_response.dart';

part 'user_provider.g.dart';

@riverpod
class UserState extends _$UserState {
  @override
  FutureOr<LoginResponse?> build() async {
    // 启动时读取本地存储
    final prefs = LocalStorageService.instance;
    final userJson = prefs.getJson<LoginResponse>(
      StorageKeys.userInfo,
      LoginResponse.fromJson,
    );
    if (userJson != null) {
      return userJson;
    }
    return null;
  }

  // 登录成功时保存
  Future<void> login(LoginResponse resp) async {
    state = AsyncValue.data(resp);
    final prefs = LocalStorageService.instance;
    await prefs.setJson<LoginResponse>(
      StorageKeys.userInfo,
      resp,
      (u) => u.toJson(),
    );
  }

  // 退出清理
  Future<void> logout() async {
    state = const AsyncData(null);
    final prefs = LocalStorageService.instance;
    await prefs.remove(StorageKeys.userInfo);
  }

  // 获取用户信息
  LoginResponse? get userInfo => state.value;
  // 获取token
  String get token => state.value?.token ?? "";
}
