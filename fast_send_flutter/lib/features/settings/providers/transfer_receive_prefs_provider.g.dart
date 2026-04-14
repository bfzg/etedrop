// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transfer_receive_prefs_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(AutoReceiveLanTransfer)
final autoReceiveLanTransferProvider = AutoReceiveLanTransferProvider._();

final class AutoReceiveLanTransferProvider
    extends $NotifierProvider<AutoReceiveLanTransfer, bool> {
  AutoReceiveLanTransferProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'autoReceiveLanTransferProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$autoReceiveLanTransferHash();

  @$internal
  @override
  AutoReceiveLanTransfer create() => AutoReceiveLanTransfer();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$autoReceiveLanTransferHash() =>
    r'd11e878c43d496f82ab540bc6a1a118cfe0e78b6';

abstract class _$AutoReceiveLanTransfer extends $Notifier<bool> {
  bool build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<bool, bool>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<bool, bool>,
              bool,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

@ProviderFor(VideoTranscodeEnabled)
final videoTranscodeEnabledProvider = VideoTranscodeEnabledProvider._();

final class VideoTranscodeEnabledProvider
    extends $NotifierProvider<VideoTranscodeEnabled, bool> {
  VideoTranscodeEnabledProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'videoTranscodeEnabledProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$videoTranscodeEnabledHash();

  @$internal
  @override
  VideoTranscodeEnabled create() => VideoTranscodeEnabled();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$videoTranscodeEnabledHash() =>
    r'a3f7c21d8e4b96f0152c3d47e8a1b05f9c2e7d4a';

abstract class _$VideoTranscodeEnabled extends $Notifier<bool> {
  bool build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<bool, bool>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<bool, bool>,
              bool,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
