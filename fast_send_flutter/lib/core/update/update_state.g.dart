// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'update_state.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(UpdateStateNotifier)
final updateStateProvider = UpdateStateNotifierProvider._();

final class UpdateStateNotifierProvider
    extends
        $NotifierProvider<
          UpdateStateNotifier,
          ({bool checked, bool hasUpdate, UpdateManifest? manifest})
        > {
  UpdateStateNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'updateStateProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$updateStateNotifierHash();

  @$internal
  @override
  UpdateStateNotifier create() => UpdateStateNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(
    ({bool checked, bool hasUpdate, UpdateManifest? manifest}) value,
  ) {
    return $ProviderOverride(
      origin: this,
      providerOverride:
          $SyncValueProvider<
            ({bool checked, bool hasUpdate, UpdateManifest? manifest})
          >(value),
    );
  }
}

String _$updateStateNotifierHash() =>
    r'fd39a6097c7541ae3dcf92b2c8ba966d50f74835';

abstract class _$UpdateStateNotifier
    extends
        $Notifier<({bool checked, bool hasUpdate, UpdateManifest? manifest})> {
  ({bool checked, bool hasUpdate, UpdateManifest? manifest}) build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref
            as $Ref<
              ({bool checked, bool hasUpdate, UpdateManifest? manifest}),
              ({bool checked, bool hasUpdate, UpdateManifest? manifest})
            >;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                ({bool checked, bool hasUpdate, UpdateManifest? manifest}),
                ({bool checked, bool hasUpdate, UpdateManifest? manifest})
              >,
              ({bool checked, bool hasUpdate, UpdateManifest? manifest}),
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
