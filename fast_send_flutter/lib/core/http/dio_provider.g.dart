// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dio_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(httpService)
final httpServiceProvider = HttpServiceProvider._();

final class HttpServiceProvider
    extends $FunctionalProvider<HttpService, HttpService, HttpService>
    with $Provider<HttpService> {
  HttpServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'httpServiceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$httpServiceHash();

  @$internal
  @override
  $ProviderElement<HttpService> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  HttpService create(Ref ref) {
    return httpService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(HttpService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<HttpService>(value),
    );
  }
}

String _$httpServiceHash() => r'da503b28efaf4597b2e829c8b398c523953c861c';
