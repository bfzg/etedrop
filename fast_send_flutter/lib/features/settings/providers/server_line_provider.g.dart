// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'server_line_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(ServerLinePreferenceNotifier)
final serverLinePreferenceProvider = ServerLinePreferenceNotifierProvider._();

final class ServerLinePreferenceNotifierProvider
    extends
        $NotifierProvider<ServerLinePreferenceNotifier, ServerLinePreference> {
  ServerLinePreferenceNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'serverLinePreferenceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$serverLinePreferenceNotifierHash();

  @$internal
  @override
  ServerLinePreferenceNotifier create() => ServerLinePreferenceNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ServerLinePreference value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ServerLinePreference>(value),
    );
  }
}

String _$serverLinePreferenceNotifierHash() =>
    r'1229de71012d69e64f87d4111b6b35f20a448326';

abstract class _$ServerLinePreferenceNotifier
    extends $Notifier<ServerLinePreference> {
  ServerLinePreference build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<ServerLinePreference, ServerLinePreference>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ServerLinePreference, ServerLinePreference>,
              ServerLinePreference,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

@ProviderFor(serverEndpoints)
final serverEndpointsProvider = ServerEndpointsProvider._();

final class ServerEndpointsProvider
    extends
        $FunctionalProvider<ServerEndpoints, ServerEndpoints, ServerEndpoints>
    with $Provider<ServerEndpoints> {
  ServerEndpointsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'serverEndpointsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$serverEndpointsHash();

  @$internal
  @override
  $ProviderElement<ServerEndpoints> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  ServerEndpoints create(Ref ref) {
    return serverEndpoints(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ServerEndpoints value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ServerEndpoints>(value),
    );
  }
}

String _$serverEndpointsHash() => r'31c4f2974127e5390f956531c02d71308df6df02';
