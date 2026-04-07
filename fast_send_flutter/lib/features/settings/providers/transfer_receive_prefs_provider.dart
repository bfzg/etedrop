import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../services/local_storage_service.dart';

part 'transfer_receive_prefs_provider.g.dart';

@Riverpod(keepAlive: true)
class AutoReceiveLanTransfer extends _$AutoReceiveLanTransfer {
  @override
  bool build() {
    return LocalStorageService.instance
            .get<bool>(StorageKeys.transferAutoReceiveLan) ??
        false;
  }

  Future<void> setEnabled(bool value) async {
    state = value;
    await LocalStorageService.instance.set<bool>(
      StorageKeys.transferAutoReceiveLan,
      value,
    );
  }
}
