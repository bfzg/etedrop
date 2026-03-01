// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'device_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// DeviceManager 单例 Provider

@ProviderFor(DeviceManagerNotifier)
final deviceManagerProvider = DeviceManagerNotifierProvider._();

/// DeviceManager 单例 Provider
final class DeviceManagerNotifierProvider
    extends $NotifierProvider<DeviceManagerNotifier, DeviceManager> {
  /// DeviceManager 单例 Provider
  DeviceManagerNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'deviceManagerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$deviceManagerNotifierHash();

  @$internal
  @override
  DeviceManagerNotifier create() => DeviceManagerNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DeviceManager value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DeviceManager>(value),
    );
  }
}

String _$deviceManagerNotifierHash() =>
    r'a9adcc0ada3d00c84d68e09df5f6b646e85ef08c';

/// DeviceManager 单例 Provider

abstract class _$DeviceManagerNotifier extends $Notifier<DeviceManager> {
  DeviceManager build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<DeviceManager, DeviceManager>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<DeviceManager, DeviceManager>,
              DeviceManager,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

/// 设备连接状态

@ProviderFor(deviceConnected)
final deviceConnectedProvider = DeviceConnectedProvider._();

/// 设备连接状态

final class DeviceConnectedProvider
    extends $FunctionalProvider<bool, bool, bool>
    with $Provider<bool> {
  /// 设备连接状态
  DeviceConnectedProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'deviceConnectedProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$deviceConnectedHash();

  @$internal
  @override
  $ProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  bool create(Ref ref) {
    return deviceConnected(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$deviceConnectedHash() => r'3cdd8c2b9f18abb7ab64fd2962bc4c7f48a6c88a';

/// 设备 ID

@ProviderFor(deviceId)
final deviceIdProvider = DeviceIdProvider._();

/// 设备 ID

final class DeviceIdProvider
    extends $FunctionalProvider<String?, String?, String?>
    with $Provider<String?> {
  /// 设备 ID
  DeviceIdProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'deviceIdProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$deviceIdHash();

  @$internal
  @override
  $ProviderElement<String?> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  String? create(Ref ref) {
    return deviceId(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String?>(value),
    );
  }
}

String _$deviceIdHash() => r'2000b96dc9ff628d7cdf7c00c37ff6c3872e4777';

/// 设备名称

@ProviderFor(deviceName)
final deviceNameProvider = DeviceNameProvider._();

/// 设备名称

final class DeviceNameProvider
    extends $FunctionalProvider<String, String, String>
    with $Provider<String> {
  /// 设备名称
  DeviceNameProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'deviceNameProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$deviceNameHash();

  @$internal
  @override
  $ProviderElement<String> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  String create(Ref ref) {
    return deviceName(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String>(value),
    );
  }
}

String _$deviceNameHash() => r'cb5128458c39ca7bbb8981b007b67d41988f7838';
