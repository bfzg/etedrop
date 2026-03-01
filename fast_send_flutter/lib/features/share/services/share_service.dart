import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../../core/config/constants.dart';
import '../models/share_record.dart';

/// 文件分享服务
/// 对应 Electron: src/ipc/share/handlers.ts
class ShareService {
  final Map<String, ShareRecord> _shares = {};
  String? _sharesFilePath;

  /// 初始化，加载本地分享记录
  Future<void> init() async {
    final appDir = await getApplicationSupportDirectory();
    _sharesFilePath = p.join(appDir.path, AppConstants.sharesFileName);
    await _loadShares();
  }

  Future<void> _loadShares() async {
    if (_sharesFilePath == null) return;
    try {
      final file = File(_sharesFilePath!);
      if (await file.exists()) {
        final data = await file.readAsString();
        final List<dynamic> arr = jsonDecode(data);
        _shares.clear();
        for (final item in arr) {
          final record = ShareRecord.fromJson(item as Map<String, dynamic>);
          _shares[record.code] = record;
        }
      }
    } catch (_) {
      _shares.clear();
    }
  }

  Future<void> _saveShares() async {
    if (_sharesFilePath == null) return;
    final arr = _shares.values.map((s) => s.toJson()).toList();
    await File(_sharesFilePath!).writeAsString(jsonEncode(arr));
  }

  /// 生成 8 位十六进制分享码
  /// 对应 Electron: generateCode() → crypto.randomBytes(4).toString('hex').toUpperCase()
  String _generateCode() {
    final random = Random.secure();
    final bytes = List<int>.generate(4, (_) => random.nextInt(256));
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join().toUpperCase();
  }

  /// SHA256 哈希密码
  /// 对应 Electron: hashPassword() → crypto.createHash('sha256')
  String _hashPassword(String password) {
    return sha256.convert(utf8.encode(password)).toString();
  }

  /// 创建分享
  /// 对应 Electron: createShare handler
  Future<ShareInfo> createShare(
    String relativePath, {
    required String fileName,
    required int fileSize,
    String? password,
    int? expiresIn,
  }) async {
    final code = _generateCode();
    final record = ShareRecord(
      code: code,
      path: relativePath,
      fileName: fileName,
      size: fileSize,
      passwordHash: password != null ? _hashPassword(password) : null,
      createdAt: DateTime.now().millisecondsSinceEpoch,
      expiresAt: expiresIn != null
          ? DateTime.now().millisecondsSinceEpoch + expiresIn
          : null,
    );

    _shares[code] = record;
    await _saveShares();

    return ShareInfo(
      code: record.code,
      path: record.path,
      fileName: record.fileName,
      size: record.size,
      hasPassword: record.passwordHash != null,
      createdAt: record.createdAt,
      expiresAt: record.expiresAt,
    );
  }

  /// 获取分享信息
  /// 对应 Electron: getShare handler
  ShareInfo? getShare(String code, {String? password}) {
    final record = _shares[code];
    if (record == null) return null;

    if (record.expiresAt != null &&
        DateTime.now().millisecondsSinceEpoch > record.expiresAt!) {
      _shares.remove(code);
      _saveShares();
      return null;
    }

    if (record.passwordHash != null) {
      if (password == null || _hashPassword(password) != record.passwordHash) {
        return null;
      }
    }

    return ShareInfo(
      code: record.code,
      path: record.path,
      fileName: record.fileName,
      size: record.size,
      hasPassword: record.passwordHash != null,
      createdAt: record.createdAt,
      expiresAt: record.expiresAt,
    );
  }

  /// 删除分享
  /// 对应 Electron: deleteShare handler
  Future<bool> deleteShare(String code) async {
    if (!_shares.containsKey(code)) return false;
    _shares.remove(code);
    await _saveShares();
    return true;
  }

  /// 列出所有分享（自动清理过期）
  /// 对应 Electron: listShares handler
  Future<List<ShareInfo>> listShares() async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final expired = <String>[];
    final result = <ShareInfo>[];

    for (final record in _shares.values) {
      if (record.expiresAt != null && now > record.expiresAt!) {
        expired.add(record.code);
        continue;
      }
      result.add(ShareInfo(
        code: record.code,
        path: record.path,
        fileName: record.fileName,
        size: record.size,
        hasPassword: record.passwordHash != null,
        createdAt: record.createdAt,
        expiresAt: record.expiresAt,
      ));
    }

    if (expired.isNotEmpty) {
      for (final code in expired) {
        _shares.remove(code);
      }
      await _saveShares();
    }

    return result;
  }

  /// 生成分享链接
  /// 对应 Electron: getShareUrl / getShareLink
  String getShareUrl(String shareCode, String deviceId) {
    return '${AppConstants.webBaseUrl}/share/$deviceId/$shareCode';
  }
}
