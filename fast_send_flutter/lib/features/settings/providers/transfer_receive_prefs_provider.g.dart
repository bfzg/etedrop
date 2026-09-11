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
    r'2b422742a105e2e27e54438ea8526c3756ef22ba';

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

/// 在线播放时是否对不兼容格式进行转码（默认开启）

@ProviderFor(VideoTranscodeEnabled)
final videoTranscodeEnabledProvider = VideoTranscodeEnabledProvider._();

/// 在线播放时是否对不兼容格式进行转码（默认开启）
final class VideoTranscodeEnabledProvider
    extends $NotifierProvider<VideoTranscodeEnabled, bool> {
  /// 在线播放时是否对不兼容格式进行转码（默认开启）
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
    r'79eb21e065d446acf456d85ea53de2d79ce56d96';

/// 在线播放时是否对不兼容格式进行转码（默认开启）

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
