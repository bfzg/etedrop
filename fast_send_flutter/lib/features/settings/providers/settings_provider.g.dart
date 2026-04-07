// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'settings_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 执行桌面端异步设置；勿用 autoDispose，否则 await 间隙 Ref 会被回收，invalidate 抛错且开关不刷新。

@ProviderFor(SettingsNotifier)
final settingsProvider = SettingsNotifierProvider._();

/// 执行桌面端异步设置；勿用 autoDispose，否则 await 间隙 Ref 会被回收，invalidate 抛错且开关不刷新。
final class SettingsNotifierProvider
    extends $AsyncNotifierProvider<SettingsNotifier, void> {
  /// 执行桌面端异步设置；勿用 autoDispose，否则 await 间隙 Ref 会被回收，invalidate 抛错且开关不刷新。
  SettingsNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'settingsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$settingsNotifierHash();

  @$internal
  @override
  SettingsNotifier create() => SettingsNotifier();
}

String _$settingsNotifierHash() => r'8fa2dce59de26511d055f9c8a791ff549a8cc843';

/// 执行桌面端异步设置；勿用 autoDispose，否则 await 间隙 Ref 会被回收，invalidate 抛错且开关不刷新。

abstract class _$SettingsNotifier extends $AsyncNotifier<void> {
  FutureOr<void> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<void>, void>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<void>, void>,
              AsyncValue<void>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

@ProviderFor(autoStartEnabled)
final autoStartEnabledProvider = AutoStartEnabledProvider._();

final class AutoStartEnabledProvider
    extends $FunctionalProvider<AsyncValue<bool>, bool, FutureOr<bool>>
    with $FutureModifier<bool>, $FutureProvider<bool> {
  AutoStartEnabledProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'autoStartEnabledProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$autoStartEnabledHash();

  @$internal
  @override
  $FutureProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<bool> create(Ref ref) {
    return autoStartEnabled(ref);
  }
}

String _$autoStartEnabledHash() => r'17ede1e713d8369c17267e268fbd4554b5ec2edd';

@ProviderFor(minimizeToTrayEnabled)
final minimizeToTrayEnabledProvider = MinimizeToTrayEnabledProvider._();

final class MinimizeToTrayEnabledProvider
    extends $FunctionalProvider<AsyncValue<bool>, bool, FutureOr<bool>>
    with $FutureModifier<bool>, $FutureProvider<bool> {
  MinimizeToTrayEnabledProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'minimizeToTrayEnabledProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$minimizeToTrayEnabledHash();

  @$internal
  @override
  $FutureProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<bool> create(Ref ref) {
    return minimizeToTrayEnabled(ref);
  }
}

String _$minimizeToTrayEnabledHash() =>
    r'54d5c4b64213c6a67b8d9284eaea1202350dc93a';
