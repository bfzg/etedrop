// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'share_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// ShareService 单例 Provider（keepAlive：避免 autoDispose 后新实例与磁盘状态竞态，且保证分享查找与列表共用同一内存态）

@ProviderFor(ShareServiceNotifier)
final shareServiceProvider = ShareServiceNotifierProvider._();

/// ShareService 单例 Provider（keepAlive：避免 autoDispose 后新实例与磁盘状态竞态，且保证分享查找与列表共用同一内存态）
final class ShareServiceNotifierProvider
    extends $NotifierProvider<ShareServiceNotifier, ShareService> {
  /// ShareService 单例 Provider（keepAlive：避免 autoDispose 后新实例与磁盘状态竞态，且保证分享查找与列表共用同一内存态）
  ShareServiceNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'shareServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$shareServiceNotifierHash();

  @$internal
  @override
  ShareServiceNotifier create() => ShareServiceNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ShareService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ShareService>(value),
    );
  }
}

String _$shareServiceNotifierHash() =>
    r'2329cc0570caa099899d7ca2e0bce8691734f300';

/// ShareService 单例 Provider（keepAlive：避免 autoDispose 后新实例与磁盘状态竞态，且保证分享查找与列表共用同一内存态）

abstract class _$ShareServiceNotifier extends $Notifier<ShareService> {
  ShareService build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<ShareService, ShareService>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ShareService, ShareService>,
              ShareService,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

/// 分享列表

@ProviderFor(ShareList)
final shareListProvider = ShareListProvider._();

/// 分享列表
final class ShareListProvider
    extends $AsyncNotifierProvider<ShareList, List<ShareInfo>> {
  /// 分享列表
  ShareListProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'shareListProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$shareListHash();

  @$internal
  @override
  ShareList create() => ShareList();
}

String _$shareListHash() => r'3061d493d7b627e2255fd8fce650b8c5ea6db7e5';

/// 分享列表

abstract class _$ShareList extends $AsyncNotifier<List<ShareInfo>> {
  FutureOr<List<ShareInfo>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<List<ShareInfo>>, List<ShareInfo>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<ShareInfo>>, List<ShareInfo>>,
              AsyncValue<List<ShareInfo>>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
