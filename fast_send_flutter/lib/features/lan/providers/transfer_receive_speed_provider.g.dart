// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transfer_receive_speed_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 接收中瞬时速度（字节/秒），按 shareId 或单条消息 id 索引；传完需 [clear]。

@ProviderFor(TransferReceiveSpeed)
final transferReceiveSpeedProvider = TransferReceiveSpeedProvider._();

/// 接收中瞬时速度（字节/秒），按 shareId 或单条消息 id 索引；传完需 [clear]。
final class TransferReceiveSpeedProvider
    extends $NotifierProvider<TransferReceiveSpeed, Map<String, double>> {
  /// 接收中瞬时速度（字节/秒），按 shareId 或单条消息 id 索引；传完需 [clear]。
  TransferReceiveSpeedProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'transferReceiveSpeedProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$transferReceiveSpeedHash();

  @$internal
  @override
  TransferReceiveSpeed create() => TransferReceiveSpeed();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Map<String, double> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Map<String, double>>(value),
    );
  }
}

String _$transferReceiveSpeedHash() =>
    r'bd8c570a911cf86ff64bc62968cffede0341ba03';

/// 接收中瞬时速度（字节/秒），按 shareId 或单条消息 id 索引；传完需 [clear]。

abstract class _$TransferReceiveSpeed extends $Notifier<Map<String, double>> {
  Map<String, double> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<Map<String, double>, Map<String, double>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<Map<String, double>, Map<String, double>>,
              Map<String, double>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
