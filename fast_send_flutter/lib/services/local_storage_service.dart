// 本地存储服务

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'logger_service.dart';

class StorageKeys {
  static const String authToken = 'auth_token';
  static const String userInfo = 'user_info';
  static const String systemConfig = 'system_config';
  /// 局域网曾出现过的设备（用于离线仍展示头像）
  static const String lanRememberedDevices = 'lan_remembered_devices_v1';
}

/// 通用本地存储服务
/// 封装 SharedPreferences，支持基础类型、Map、对象存取
class LocalStorageService {
  static final LocalStorageService instance = LocalStorageService._internal();
  SharedPreferences? _prefs;

  LocalStorageService._internal();

  /// 初始化
  Future<void> init() async {
    if (_prefs != null) return;
    try {
      _prefs = await SharedPreferences.getInstance();
    } catch (e) {
      logger.e("LocalStorage 初始化失败: $e");
    }
  }

  SharedPreferences get _sp {
    if (_prefs == null) {
      throw Exception("LocalStorageService 未初始化，请先调用 init()");
    }
    return _prefs!;
  }

  /// 设置任意类型（String/int/bool/double/List&lt;String&gt;）
  Future<bool> set<T>(String key, T value) async {
    try {
      if (value is String) return _sp.setString(key, value);
      if (value is int) return _sp.setInt(key, value);
      if (value is bool) return _sp.setBool(key, value);
      if (value is double) return _sp.setDouble(key, value);
      if (value is List<String>) return _sp.setStringList(key, value);

      // 其他类型 → JSON 存储
      return _sp.setString(key, jsonEncode(value));
    } catch (e) {
      logger.e("保存失败 [$key]: $e");
      return false;
    }
  }

  /// 获取任意类型
  T? get<T>(String key, {T? defaultValue}) {
    try {
      final value = _sp.get(key);
      if (value == null) return defaultValue;

      if (T == String) return value as T;
      if (T == int) return value as T;
      if (T == bool) return value as T;
      if (T == double) return value as T;
      if (T == List<String>) return value as T;

      if (value is String) {
        return jsonDecode(value) as T;
      }
      return defaultValue;
    } catch (e) {
      logger.e("读取失败 [$key]: $e");
      return defaultValue;
    }
  }

  /// 存储 JSON 对象
  Future<bool> setJson<T>(
    String key,
    T value,
    Map<String, dynamic> Function(T) toJson,
  ) async {
    try {
      return await set<String>(key, jsonEncode(toJson(value)));
    } catch (e) {
      logger.e("保存 JSON 失败: $e");
      return false;
    }
  }

  /// 读取 JSON 对象
  T? getJson<T>(String key, T Function(Map<String, dynamic>) fromJson) {
    try {
      final str = _sp.getString(key);
      if (str == null || str.isEmpty) return null;
      return fromJson(jsonDecode(str));
    } catch (e) {
      logger.e("读取 JSON 失败: $e");
      return null;
    }
  }

  /// 删除指定 key
  Future<bool> remove(String key) async {
    try {
      return await _sp.remove(key);
    } catch (e) {
      logger.e("删除失败 [$key]: $e");
      return false;
    }
  }

  /// 清除所有数据
  Future<bool> clear() async {
    try {
      return await _sp.clear();
    } catch (e) {
      logger.e("清除失败: $e");
      return false;
    }
  }
}
