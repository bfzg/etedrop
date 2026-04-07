// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'webrtc_keepalive_prefs_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(WebrtcKeepalivePreference)
final webrtcKeepalivePreferenceProvider = WebrtcKeepalivePreferenceProvider._();

final class WebrtcKeepalivePreferenceProvider
    extends $NotifierProvider<WebrtcKeepalivePreference, bool> {
  WebrtcKeepalivePreferenceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'webrtcKeepalivePreferenceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$webrtcKeepalivePreferenceHash();

  @$internal
  @override
  WebrtcKeepalivePreference create() => WebrtcKeepalivePreference();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$webrtcKeepalivePreferenceHash() =>
    r'8513dd3e79e86627461842b45a860d2fd9742e86';

abstract class _$WebrtcKeepalivePreference extends $Notifier<bool> {
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
