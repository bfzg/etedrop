import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'update_manifest.dart';

part 'update_state.g.dart';

@riverpod
class UpdateStateNotifier extends _$UpdateStateNotifier {
  @override
  ({UpdateManifest? manifest, bool hasUpdate, bool checked}) build() {
    return (manifest: null, hasUpdate: false, checked: false);
  }

  void setResult({required UpdateManifest? manifest, required bool hasUpdate}) {
    state = (manifest: manifest, hasUpdate: hasUpdate, checked: true);
  }

  void clearBadge() {
    state = (manifest: state.manifest, hasUpdate: false, checked: state.checked);
  }
}

