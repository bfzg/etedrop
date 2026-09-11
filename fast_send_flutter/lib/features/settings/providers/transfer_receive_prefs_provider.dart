import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../services/local_storage_service.dart';

part 'transfer_receive_prefs_provider.g.dart';

@Riverpod(keepAlive: true)
class AutoReceiveLanTransfer extends _$AutoReceiveLanTransfer {
  @override
  bool build() => true;

  Future<void> setEnabled(bool value) async {
    state = true;
    await LocalStorageService.instance.set<bool>(
      StorageKeys.transferAutoReceiveLan,
      true,
    );
  }
}

/// 在线播放时是否对不兼容格式进行转码（默认开启）
@Riverpod(keepAlive: true)
class VideoTranscodeEnabled extends _$VideoTranscodeEnabled {
  @override
  bool build() {
    return LocalStorageService.instance.get<bool>(
          StorageKeys.videoTranscodeStream,
        ) ??
        true;
  }

  Future<void> setEnabled(bool value) async {
    state = value;
    await LocalStorageService.instance.set<bool>(
      StorageKeys.videoTranscodeStream,
      value,
    );
  }
}
