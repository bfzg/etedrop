import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../models/share_record.dart';
import '../services/share_service.dart';

part 'share_provider.g.dart';

/// ShareService 单例 Provider
@riverpod
class ShareServiceNotifier extends _$ShareServiceNotifier {
  final ShareService _service = ShareService();
  bool _initialized = false;

  @override
  ShareService build() {
    return _service;
  }

  Future<ShareService> ensureInit() async {
    if (!_initialized) {
      await _service.init();
      _initialized = true;
    }
    return _service;
  }
}

/// 分享列表
@riverpod
class ShareList extends _$ShareList {
  @override
  FutureOr<List<ShareInfo>> build() async {
    final service = ref.watch(shareServiceProvider);
    final notifier = ref.read(shareServiceProvider.notifier);
    await notifier.ensureInit();
    return service.listShares();
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
  }

  Future<ShareInfo> createShare(
    String relativePath, {
    required String fileName,
    required int fileSize,
    String? password,
    int? expiresIn,
  }) async {
    final service = ref.read(shareServiceProvider);
    final info = await service.createShare(
      relativePath,
      fileName: fileName,
      fileSize: fileSize,
      password: password,
      expiresIn: expiresIn,
    );
    ref.invalidateSelf();
    return info;
  }

  Future<void> deleteShare(String code) async {
    final service = ref.read(shareServiceProvider);
    await service.deleteShare(code);
    ref.invalidateSelf();
  }
}
