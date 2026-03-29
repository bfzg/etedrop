// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'lan_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(LanManager)
final lanManagerProvider = LanManagerProvider._();

final class LanManagerProvider
    extends $NotifierProvider<LanManager, List<LanDevice>> {
  LanManagerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'lanManagerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$lanManagerHash();

  @$internal
  @override
  LanManager create() => LanManager();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<LanDevice> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<LanDevice>>(value),
    );
  }
}

String _$lanManagerHash() => r'862658af5fde761d95926c09315826b7d99f5d4d';

abstract class _$LanManager extends $Notifier<List<LanDevice>> {
  List<LanDevice> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<List<LanDevice>, List<LanDevice>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<List<LanDevice>, List<LanDevice>>,
              List<LanDevice>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
